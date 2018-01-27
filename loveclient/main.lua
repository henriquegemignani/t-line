
local constants = require("constants")
local state = require("state")
local images = require("images")

local game = {}

--[[
 * Converts an HSV color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
 * Assumes h, s, and v are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  v       The value
 * @return  Array           The RGB representation
 *
 * Credits: https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
]]
local function hsvToRgb(h, s, v, a)
  local r, g, b

  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);

  i = i % 6

  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end

  return r * 255, g * 255, b * 255, a * 255
end

local function genButton(x, label, hue)
    return { x = x, y = 14/16, label = label,
             width = 50, height = 50,
             saturation = 0.8,
             hue = hue or 1,
             onRelease = function() end, }
end

local function alignedPrint(msg, x, y, anchorX, anchorY, theFont)
    theFont = theFont or font
    local numLines = select(2, msg:gsub("\n", ""))
    local w = theFont:getWidth(msg)
    local h = theFont:getHeight() * (numLines + 1)
    love.graphics.setFont(theFont)
    love.graphics.print(msg, x - w * anchorX, y - h * anchorY)
end

local function drawPulse(intensity, letter, x, y)
    local lineWidth = 10
    local pulseWidth = 10
    for col = -lineWidth * 2, lineWidth * 2 do
        local pointPos = 0

        local distance = math.abs(col / 2)
        if distance <= pulseWidth then
            pointPos = intensity * math.cos( (math.pi / 2) * (distance / pulseWidth) )
        end

        love.graphics.rectangle("fill",
            x + col / 2,
            y - pointPos + intensity / 2 - 8,
            1,
            1)
    end
    alignedPrint(letter, x, y + 10, 0.5, 0.5, smallFont)
end

local function createDrawPulse(intensity, letter)
    return function(...)
        return drawPulse(intensity, letter, ...)
    end
end

local buttons = {}
local alphaHue = constants.alphaWave.hue
local betaHue  = constants.betaWave.hue
buttons.pulse_alpha_plus  = genButton( 2.0/16, createDrawPulse( 10, "α"), alphaHue)
buttons.pulse_alpha_minus = genButton( 3.5/16, createDrawPulse(-10, "α"), alphaHue)
buttons.pulse_beta_plus   = genButton( 5.0/16, createDrawPulse( 10, "β"), betaHue)
buttons.pulse_beta_minus  = genButton( 6.5/16, createDrawPulse(-10, "β"), betaHue)
buttons.affinity_alpha    = genButton( 9.5/16, "+ψα", alphaHue)
buttons.velocity_alpha    = genButton(11.0/16, "+vα", alphaHue)
buttons.affinity_beta     = genButton(12.5/16, "+ψβ", betaHue)
buttons.velocity_beta     = genButton(14.0/16, "+vβ", betaHue)

local function genGlobals()
    screenWidth, screenHeight = love.graphics.getDimensions()
    centerX = screenWidth / 2
    centerY = screenHeight / 2
    love.graphics.setFont(font)
    print("GEN GLOBALS")
end

function love.resize()
    genGlobals()
end

function love.load()
    require("lurker").postswap = genGlobals
    require("lurker").preswap = function(name)
        if name == "multiplayer.lua" or name == "multiplayer_thread.lua" then
            return true
        end
    end
    smallFont = love.graphics.newFont("DejaVuSansMono.ttf", 15)
    bigFont = love.graphics.newFont("DejaVuSansMono.ttf", 25)
    font = love.graphics.setNewFont("DejaVuSansMono.ttf", 20)
    images.cash = love.graphics.newImage("cash.png")
    images.factory = love.graphics.newImage("factory.png")
    images.house = love.graphics.newImage("house.png")
    images.nuclear_plant = love.graphics.newImage("nuclear-plant.png")
    images.solar_power = love.graphics.newImage("solar-power.png")

    genGlobals()
    -- require("multiplayer"):start()
end

local function getWaveIntensityAt(waveState, position)
    local intensity = 0
    for _, pulse in ipairs(waveState.pulses) do
        local distance = math.abs(pulse.position - position)
        if distance < pulse.width then
            intensity = intensity + pulse.intensity * math.cos( (math.pi / 2) * (distance / pulse.width) )
        end
    end
    return intensity
end

local function spawnScoreEffect(radius, x, y, color, onComplete)
    table.insert(state.particles, {
        fromX = x,
        fromY = y,
        toX = x + math.random(-40, 40),
        toY = 30,
        color = color,
        radius = radius,
        x = x,
        y = y,
        midWayX = x + math.random(-100, 100),
        time = 0,
        duration = 0.5 + math.random(),
        onComplete = onComplete,
    })
end

local function waveY(waveConfig)
    return waveConfig.y * screenHeight
end

local function waveColorAt(waveConfig, position)
    -- -1 to 1
    -- -0.25 to 0.25
    local saturation = 0.75 + math.sin(
        waveConfig.saturationPulseOffset + position / 2) / 4
    return hsvToRgb(waveConfig.hue, saturation, 1, 1)
end

local function updateWave(wave, dt)
    wave.position = wave.position + wave.velocity * dt
    wave.affinity = wave.affinity - wave.affinity * 0.05 * dt

    local deltaVelocity = (constants.targetVelocity - wave.velocity)
    wave.velocity = wave.velocity + deltaVelocity * 0.05 * dt

    if wave.position > 4096 then
        wave.position = wave.position - 4096
        for _, pulse in ipairs(wave.pulses) do
            pulse.position = pulse.position - 4096
        end
    end

    local waveRightCorner = wave.position - screenWidth * constants.pixelSize
    local index = 1
    while index <= #wave.pulses do
        if wave.pulses[index].position < waveRightCorner then
            table.remove(wave.pulses, index)
        else
            index = index + 1
        end
    end

    -- Give points
    local points = getWaveIntensityAt(wave, wave.position) * wave.affinity * dt

    if math.abs(points) > 0.1 * dt then
        spawnScoreEffect(math.log(math.abs(points)),
            centerX,
            waveY(constants[wave.name]) + math.random(-8, 8),
            {waveColorAt(constants[wave.name], wave.position)},
            function()
                state.playerScore = state.playerScore + points
                state.pointsRecently = state.pointsRecently + points
            end)
    end
end

local function updateParticle(particle, dt)
    particle.time = particle.time + dt
    local percent = particle.time / particle.duration

    local otherPercent = percent * 2

    if percent < 0.5 then
        particle.x = -(particle.midWayX - particle.fromX)
                       * otherPercent * (otherPercent - 2) + particle.fromX
    else
        particle.x = (particle.toX - particle.midWayX)
                       * math.pow(otherPercent - 1, 2) + particle.midWayX
    end
    particle.y = particle.fromY + (particle.toY - particle.fromY) * percent
end

local function sendPulse(waveState, intensity, width)
    table.insert(waveState.pulses, {
        position = waveState.position + 4 * waveState.velocity,
        intensity = intensity,
        width = width,
    })
end

local function updateTextEffect(textEffect, dt)
    textEffect.time = textEffect.time + dt
    local percent = textEffect.time / textEffect.duration

    textEffect.x = textEffect.fromX + (textEffect.toX - textEffect.fromX) * percent
    textEffect.y = textEffect.fromY + (textEffect.toY - textEffect.fromY) * percent * (percent - 2)
    textEffect.color[4] = 255 * (1 - math.pow(percent, 2))
end

local function spawnTextEffect(text, x, y, color)
    table.insert(state.textEffects, {
        fromX = x,
        fromY = y,
        toX = x,
        toY = y + 30,
        color = color,
        x = x,
        y = y,
        time = 0,
        duration = 1.5,
        text = text,
        onComplete = function() end,
    })
end

local function updatePlayerScoreEffect(effect, dt)
    effect.time = effect.time + dt
    local percent = effect.time / effect.duration

    local otherPercent = percent * 2

    local alpha
    if percent < 0.5 then
        alpha = -effect.maxAlpha * otherPercent * (otherPercent - 2)
    else
        alpha = effect.maxAlpha * (1 - math.pow(otherPercent - 1, 2))
    end
    effect.color[4] = 255 * alpha
end

local function updateArray(array, dt, updateFunc)
    local index = 1
    while index <= #array do
        local item = array[index]
        if item.time < item.duration then
            updateFunc(item, dt)
            index = index + 1
        else
            table.remove(array, index)
            item.onComplete()
        end
    end
end

function love.update(dt)
    require("lurker").update()
    updateWave(state.alphaWave, dt)
    updateWave(state.betaWave, dt)
    updateArray(state.particles, dt, updateParticle)
    updateArray(state.textEffects, dt, updateTextEffect)
    updateArray(state.playerScoreEffects, dt, updatePlayerScoreEffect)

    if state.actionCooldownTimer > 0 then
        state.actionCooldownTimer = math.max(state.actionCooldownTimer - dt, 0)
    end

    state.pointsRecentlyTimer = state.pointsRecentlyTimer + dt
    if state.pointsRecentlyTimer > constants.pointsRecentlyInterval then
        if math.abs(state.pointsRecently) > 1 then
            local outbound = love.thread.getChannel("outbound")
            outbound:push(string.format("player_points %d", state.pointsRecently))
        end
        state.pointsRecently = 0
        state.pointsRecentlyTimer = 0
    end

    local inboundChannel = love.thread.getChannel("inbound")
    local command = inboundChannel:pop()
    if command then
        print("received command: '" .. command .. "'")
        local com, arg1, arg2 = command:match("^([%w_]+) ([%w%-]+) ?([%w%-]*)")
        print("Parsed:", com, arg1, arg2)
        if com == "num_players" then
            state.currentPlayers = arg1
        elseif com == "pulse_alpha" then
            sendPulse(state.alphaWave, tonumber(arg1), tonumber(arg2))
        elseif com == "pulse_beta" then
            sendPulse(state.betaWave, tonumber(arg1), tonumber(arg2))
        elseif com == "alpha_velocity" then
            state.alphaWave.velocity = state.alphaWave.velocity + tonumber(arg1)
            spawnTextEffect("+v", 40, waveY(constants.alphaWave) - 10,
                            {hsvToRgb(constants.alphaWave.hue, 1, 1, 1)})
        elseif com == "beta_velocity" then
            state.betaWave.velocity = state.betaWave.velocity + tonumber(arg1)
            spawnTextEffect("+v", 40, waveY(constants.betaWave) - 10,
                            {hsvToRgb(constants.betaWave.hue, 1, 1, 1)})
        elseif com == "player_points" then
            -- Can't think of anything that looks good
            -- spawnOtherPlayerScoreEffect(tonumber(arg1))
        end
    end
end

function love.keypressed(key)
    if key == "r" then
        love.event.quit("restart")
    end
end

local function renderWave(waveState, waveConfig)
    local pixelPosition = waveState.position + centerX * constants.pixelSize

    local y = waveY(waveConfig)

    love.graphics.setColor(waveColorAt(waveConfig, waveState.position))
    love.graphics.circle("fill", centerX, y, constants.centerCircleSize)

    for col = 0, screenWidth - 1 do
        love.graphics.setColor(waveColorAt(waveConfig, pixelPosition))

        local intensity = getWaveIntensityAt(waveState, pixelPosition)
        love.graphics.rectangle("fill",
            col,
            y - intensity,
            1,
            1)

        pixelPosition = pixelPosition - constants.pixelSize
    end
end

local function alignedRectangle(x, y, width, height, anchorX, anchorY)
    love.graphics.rectangle("fill",
        x - width * anchorX, y - height * anchorY,
        width, height)
end

local function sendCommandToBoth(command)
    local outboundChannel = love.thread.getChannel("outbound")
    local inboundChannel = love.thread.getChannel("inbound")
    outboundChannel:push(command)
    inboundChannel:push(command)
end

local function buildPulseArgs(signal)
    local intensity = math.random(constants.pulseMinIntesity,
                                  constants.pulseMaxIntesity)
    local width = math.random(constants.pulseMinWidth,
                              constants.pulseMaxWidth)

    return signal * intensity, width
end

function buttons.pulse_alpha_plus.onRelease()
    sendCommandToBoth(string.format("pulse_alpha %d %d", buildPulseArgs(1)))
end

function buttons.pulse_beta_plus.onRelease()
    sendCommandToBoth(string.format("pulse_beta %d %d", buildPulseArgs(1)))
end

function buttons.pulse_alpha_minus.onRelease()
    sendCommandToBoth(string.format("pulse_alpha %d %d", buildPulseArgs(-1)))
end

function buttons.pulse_beta_minus.onRelease()
    sendCommandToBoth(string.format("pulse_beta %d %d", buildPulseArgs(-1)))
end

function buttons.affinity_alpha.onRelease()
    state.alphaWave.affinity = state.alphaWave.affinity + 1
end

function buttons.velocity_alpha.onRelease()
    sendCommandToBoth(string.format("alpha_velocity %d", 5))
end

function buttons.affinity_beta.onRelease()
    state.betaWave.affinity = state.betaWave.affinity + 1
end

function buttons.velocity_beta.onRelease()
    sendCommandToBoth(string.format("beta_velocity %d", 5))
end

local function buttonX(button)
    return button.x * screenWidth
end

local function buttonY(button)
    return button.y * screenHeight
end

local function drawButton(button)
    local x = buttonX(button)
    local y = buttonY(button)
    local label = button.label
    local width = button.width
    local height = button.height
    local border = 4

    love.graphics.setColor(hsvToRgb(button.hue, button.saturation,
        button.pressing and 0.8 or 0.5, 1))
    alignedRectangle(x, y, width + border, height + border, 0.5, 0.5)

    love.graphics.setColor(hsvToRgb(button.hue, button.saturation,
        button.hover and 0.4 or 0.3, 1))
    alignedRectangle(x, y, width, height, 0.5, 0.5)

    love.graphics.setColor(hsvToRgb(button.hue, button.saturation * 0.5, 1, 1))
    if type(label) == "string" then
        alignedPrint(label, x, y, 0.5, 0.5)
    else
        label(x, y)
    end
end

local function drawParticle(particle)
    love.graphics.setColor(unpack(particle.color))
    love.graphics.circle("fill", particle.x, particle.y, particle.radius)
end

local function drawTextEffect(textEffect)
    love.graphics.setColor(unpack(textEffect.color))
    alignedPrint(textEffect.text, textEffect.x, textEffect.y, 0.5, 0.5)
end

local function drawPlayerScoreEffect(effect)
    local x, y = effect.x * screenWidth, effect.y * screenHeight
    love.graphics.setColor(unpack(effect.color))
    alignedRectangle(x, y, 4 * effect.score, 1, 0.5, 0.5)
end

local function isInsideRect(x, y, lx, rx, ly, ry)
    return lx <= x and x <= rx
       and ly <= y and y <= ry
end

local function isInsideButton(button, x, y)
    local bx = buttonX(button)
    local by = buttonY(button)
    local hWidth = button.width / 2
    local hHeight = button.height / 2
    return isInsideRect(x, y,
        bx - hWidth,  bx + hWidth,
        by - hHeight, by + hHeight
    )
    -- return bx - hWidth <= x and x <= bx + hWidth
    --    and by - hHeight <= y and y <= by + hHeight
end

function game.isInsideEntity(entity, mouseX, mouseY)
    local imageScale = constants.imageScale
    local drawable = images[entity.drawable]
    local width, height = drawable:getDimensions()

    return isInsideRect(
        mouseX - state.cameraPositionX, mouseY - state.cameraPositionY,
        entity.x - width * imageScale, entity.x,
        entity.y + height * imageScale * -1/2, entity.y + height * imageScale * 1/2
    )
end

function game.entityImageCenter(entity)
    local imageScale = constants.imageScale
    local drawable = images[entity.drawable]
    local width = drawable:getWidth()

    return
        entity.x + width * imageScale * -1/2,
        entity.y
end

function game.priceBetweenPoints(sourceX, sourceY, targetX, targetY)
    local distance = math.abs(sourceX - targetX)
                        + math.abs(sourceY - targetY)
    return distance / 50
end

function game.drawMapEntity(entity)
    love.graphics.push()
    love.graphics.translate(entity.x, entity.y)

    local drawable = images[entity.drawable]
    local width, height = drawable:getDimensions()
    local imageScale = constants.imageScale

    local texts = {}
    for _, statName in ipairs(constants.possibleStatsOrder) do
        if entity[statName] then
            table.insert(texts, string.format(constants.statsFormatting[statName], entity[statName]))
        end
    end

    love.graphics.draw(drawable,
        width * imageScale * -1,
        height * imageScale * -1/2,
        0, imageScale, imageScale)
    alignedPrint(table.concat(texts, "\n"), 5, 0, 0, 0.5, font)

    love.graphics.pop()
end

function game.isConnectedWith(entityA, entityB)
    return (state.connections[entityA] and state.connections[entityA][entityB])
           or (state.connections[entityB] and state.connections[entityB][entityA])
end

function game.addConnectionBetween(entityA, entityB)
    state.connections[entityA] = state.connections[entityA] or {}
    state.connections[entityA][entityB] = true

    local entityX, entityY = game.entityImageCenter(entityA)
    local price = game.priceBetweenPoints(entityX, entityY, game.entityImageCenter(entityB))
    state.currentMoney = state.currentMoney - price

    return price
end

function game.drawGame()
    love.graphics.push()
    love.graphics.translate(state.cameraPositionX, state.cameraPositionY)

    local mapEntities = state.mapEntities

    love.graphics.setColor(255, 255, 255, 256/4)
    for originEntity, targetEntities in pairs(state.connections) do
        for targetEntity in pairs(targetEntities) do
            local entityX, entityY = game.entityImageCenter(originEntity)
            love.graphics.line(entityX, entityY, game.entityImageCenter(targetEntity))
        end
    end
    love.graphics.setColor(255, 255, 255, 255)

    local toDraw = {}
    for i, entity in ipairs(mapEntities) do
        toDraw[i] = entity
    end
    table.sort(toDraw, function(entityA, entityB) return entityA.y < entityB.y end)

    for _, entity in ipairs(toDraw) do
        if state.currentlySelectedEntity == entity then
            love.graphics.setColor(0, 0, 255)
        else
            love.graphics.setColor(255, 255, 255)
        end
        game.drawMapEntity(entity)
    end

    if state.currentlySelectedEntity then
        love.graphics.setColor(0, 0, 255)
        local mouseX, mouseY = love.mouse.getPosition()
        mouseX = mouseX - state.cameraPositionX
        mouseY = mouseY - state.cameraPositionY

        local entityX, entityY = game.entityImageCenter(state.currentlySelectedEntity)
        love.graphics.line(entityX, entityY, mouseX, mouseY)

        alignedPrint(string.format("-%d $", game.priceBetweenPoints(mouseX, mouseY, entityX, entityY)),
                     mouseX + 10, mouseY + 10, 0, 0)
    end

    love.graphics.pop()
end

local function drawHud()
    -- Score
    love.graphics.setColor(255, 255, 255, 255)
    alignedPrint(string.format("Demand: %d MW -- Supply: %d MW -- Money: %d $",
                               state.playerScore, 0, state.currentMoney),
                 centerX, 5, 0.5, 0.0,
                 bigFont)

    -- Action buttons
    for _, button in pairs(buttons) do
        drawButton(button)
    end

    -- Player count
    if type(state.currentPlayers) == "boolean" then
        love.graphics.setColor(255, 0, 0, 255)
        alignedPrint("Offline", 5, screenHeight - 5, 0, 1, smallFont)
    else
        love.graphics.setColor(255, 255, 0, 255)
        alignedPrint(string.format("Current Players: %d", state.currentPlayers),
                     5, screenHeight - 5, 0, 1, smallFont)
    end
        alignedPrint(string.format("FPS: %d", love.timer.getFPS()),
                     screenWidth - 5, screenHeight - 5, 1, 1, smallFont)

    -- Particles
    for _, particle in ipairs(state.particles) do
        drawParticle(particle)
    end

    -- Text Effects
    for _, textEffect in ipairs(state.textEffects) do
        drawTextEffect(textEffect)
    end

    -- Text Effects
    for _, effect in ipairs(state.playerScoreEffects) do
        drawPlayerScoreEffect(effect)
    end
end

function love.draw()
    love.graphics.reset()
    love.graphics.setColor(255, 255, 255)
    game.drawGame()
    drawHud()
end

function love.mousemoved(x, y)
    if state.mouseDown and not state.clickedAButton then
        state.cameraPositionX = state.cameraPositionX + (x - state.lastMouseX)
        state.cameraPositionY = state.cameraPositionY + (y - state.lastMouseY)
        state.lastMouseX = x
        state.lastMouseY = y
    end
    for _, button in pairs(buttons) do
        local isInside = isInsideButton(button, x, y)
        if state.mouseDown then
            button.hover = button.hover and isInside
            button.pressing = button.pressing and isInside
        else
            button.hover = isInside
        end
    end
end

function love.mousepressed(x, y, mouseButton)
    if mouseButton == 1 then
        state.mouseDown = true
        state.lastMouseX = x
        state.lastMouseY = y

        local clickedAButton = false
        for _, button in pairs(buttons) do
            if isInsideButton(button, x, y) then
                button.pressing = true
                clickedAButton = true
                break
            end
        end
        if not state.currentlySelectedEntity then
            for _, entity in ipairs(state.mapEntities) do
                if game.isInsideEntity(entity, x, y) then
                    state.currentlySelectedEntity = entity
                    clickedAButton = true
                    break
                end
            end
        end
        state.clickedAButton = clickedAButton
    end
end

function love.mousereleased(x, y, mouseButton)
    if mouseButton == 1 then
        state.mouseDown = false
        for _, button in pairs(buttons) do
            if button.pressing and isInsideButton(button, x, y) then
                state.actionCooldownTimer = constants.actionCooldown
                button.onRelease()
            end
            button.pressing = false
        end
        if state.currentlySelectedEntity then
            for _, entity in ipairs(state.mapEntities) do
                if game.isInsideEntity(entity, x, y) then
                    if entity == state.currentlySelectedEntity then
                        state.currentlySelectedEntity = nil
                        break
                    end
                    if not game.isConnectedWith(state.currentlySelectedEntity, entity) then
                        local price = game.addConnectionBetween(state.currentlySelectedEntity, entity)
                        spawnTextEffect(string.format("%-.2f $", price), x, y, {255, 0, 0})
                    end
                    state.currentlySelectedEntity = nil
                    break
                end
            end
        end
    end
end

function love.quit()
    local messageChannel = love.thread.getChannel("outbound")
    messageChannel:push("close")
    -- require("multiplayer"):wait()
end