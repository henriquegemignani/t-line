
local constants = require("constants")
local state = require("state")
local images = require("images")
local util = require("util")

_G.state = state

local game = {}
_G.game = game

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

local buttons = {}

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

function game.loadLevel(levelName)
    local levelTable = require(levelName)

    state.mapEntities = {}
    state.connections = {}
    for i, entity in ipairs(levelTable.entities) do
        state.mapEntities[i] = util.tableDeepCopy(entity)
        state.connections[state.mapEntities[i]] = {}
    end

    for i, connections in pairs(levelTable.connections) do
        local sourceEntity = state.mapEntities[i]
        for _, j in ipairs(connections) do
            local targetEntity = state.mapEntities[j]
            state.connections[sourceEntity][targetEntity] = "original"
            state.connections[targetEntity][sourceEntity] = "original"
        end
    end

    for _, sourceEntity in ipairs(state.mapEntities) do
        for _, targetEntity in ipairs(state.mapEntities) do
            if sourceEntity ~= targetEntity and not state.connections[sourceEntity][targetEntity] then
                state.connections[sourceEntity][targetEntity] = "never"
            end
        end
    end
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

    game.loadLevel("level1")
    game.calculateReach()

    genGlobals()
    -- require("multiplayer"):start()
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
    require("lovebird").update()
    updateArray(state.particles, dt, updateParticle)
    updateArray(state.textEffects, dt, updateTextEffect)
end

function love.keypressed(key)
    if key == "r" then
        love.event.quit("restart")
    end
end

local function alignedRectangle(x, y, width, height, anchorX, anchorY)
    love.graphics.rectangle("fill",
        x - width * anchorX, y - height * anchorY,
        width, height)
end

function game.hasUnsatisfiedRequirement(entity)
    local group = state.groupForEntity[entity]
    for _, statName in ipairs(constants.possibleStatsOrder) do
        if entity[statName] and entity[statName] < 0 and group[statName] < 0 then
            return true
        end
    end
    return false
end

function game.calculateProfit()
    local profit = 0

    local mapEntities = state.mapEntities
    for i = 1, #mapEntities do
        for j = i + 1, #mapEntities do
            local originEntity = mapEntities[i]
            local targetEntity = mapEntities[j]
            local connectionType = state.connections[originEntity][targetEntity]

            if connectionType == "added" then
                profit = profit - game.priceBetweenEntities(originEntity, targetEntity)
            elseif connectionType == "removed" then
                profit = profit - game.priceBetweenEntities(originEntity, targetEntity)
                                  * constants.connectionRemovalModifier
            end
        end
    end

    return profit
end

function game.calculateReach()
    state.groupForEntity = {}

    local mapEntities = state.mapEntities
    local groupForEntity = state.groupForEntity
    local queue = {}

    local nextGroup = 0
    local function genGroup()
        nextGroup = nextGroup + 1
        return { name = tostring(nextGroup), }
    end

    for _, initialEntity in ipairs(mapEntities) do
        local currentGroup
        if not groupForEntity[initialEntity] then
            queue[1] = initialEntity
            currentGroup = genGroup()
        end
        while queue[1] do
            local entity = table.remove(queue, 1)
            groupForEntity[entity] = currentGroup
            for targetEntity in pairs(state.connections[entity] or {}) do
                if game.isConnectedWith(entity, targetEntity) and not groupForEntity[targetEntity] then
                    table.insert(queue, targetEntity)
                end
            end
        end
    end

    for _, entity in ipairs(mapEntities) do
        local group = groupForEntity[entity]
        for _, statName in ipairs(constants.possibleStatsOrder) do
            if entity[statName] then
                group[statName] = group[statName] or 0
                group[statName] = group[statName] + entity[statName]
            end
        end
    end
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
    local distance = math.abs(sourceX - targetX) + math.abs(sourceY - targetY)
    return distance * constants.connectionPriceDistanceModifier
end

function game.priceBetweenEntities(entityA, entityB)
    local entityX, entityY = game.entityImageCenter(entityA)
    return game.priceBetweenPoints(entityX, entityY, game.entityImageCenter(entityB))
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
    -- alignedPrint(state.groupForEntity[entity].name, 0, 50, 0.5, 0, font)


    love.graphics.pop()
end

function game.isConnectedWith(entityA, entityB)
    local connectionState = state.connections[entityA][entityB]
    return connectionState == "original" or connectionState == "added"
end

function game.addConnectionBetween(entityA, entityB)
    local price = game.priceBetweenEntities(entityA, entityB)

    local newState
    if state.connections[entityA][entityB] == "never" then
        newState = "added"
    else
        newState = "original"
        price = price * -constants.connectionRemovalModifier
    end
    state.connections[entityA][entityB] = newState
    state.connections[entityB][entityA] = newState
    game.calculateReach()

    state.currentMoney = state.currentMoney - price
    return price
end

function game.removeConnectionBetween(entityA, entityB)
    local price = game.priceBetweenEntities(entityA, entityB)

    local newState
    if state.connections[entityA][entityB] == "original" then
        newState = "removed"
        price = price * constants.connectionRemovalModifier
    else
        newState = "never"
        price = -price
    end

    state.connections[entityA][entityB] = newState
    state.connections[entityB][entityA] = newState
    game.calculateReach()

    state.currentMoney = state.currentMoney - price
    return price
end

function game.drawGame()
    love.graphics.push()
    love.graphics.translate(state.cameraPositionX, state.cameraPositionY)

    local mapEntities = state.mapEntities

    for i = 1, #mapEntities do
        for j = i + 1, #mapEntities do
            local originEntity = mapEntities[i]
            local targetEntity = mapEntities[j]
            if game.isConnectedWith(originEntity, targetEntity) then
                if state.connections[originEntity][targetEntity] == "added" then
                    love.graphics.setColor(127, 127, 255, 256/2)
                else
                    love.graphics.setColor(255, 255, 255, 256/4)
                end
                local entityX, entityY = game.entityImageCenter(originEntity)
                love.graphics.line(entityX, entityY, game.entityImageCenter(targetEntity))
            end
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
        elseif game.hasUnsatisfiedRequirement(entity) then
            love.graphics.setColor(255, 0, 0)
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
    alignedPrint(string.format("Projected Profit: %d $",
                               state.currentMoney),
                 centerX, 5, 0.5, 0.0,
                 bigFont)

    -- Action buttons
    for _, button in pairs(buttons) do
        drawButton(button)
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
                    local price
                    if game.isConnectedWith(state.currentlySelectedEntity, entity) then
                        price = game.removeConnectionBetween(state.currentlySelectedEntity, entity)
                    else
                        price = game.addConnectionBetween(state.currentlySelectedEntity, entity)
                    end
                    if price > 0 then
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
end