
local constants = require("constants")
local state = require("state")
local images = require("images")
local util = require("util")
local game = require("game")

_G.state = state
_G.game = game

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

local function createButtons()
    for i, level in ipairs(require("levels")) do
        local xIndex = (i % constants.levelsPerRow) / (constants.levelsPerRow - 1)
        local yIndex = math.floor(i / constants.levelsPerRow)
        buttons[i] = {
            x = xIndex * (1.0 - constants.levelSelectionHorizontalMargin * 2)
                + constants.levelSelectionHorizontalMargin,
            y = ((1 + yIndex) / constants.levelSelectionNumRows)
                * (1.0 - constants.levelSelectionVerticalMargin * 2)
                + constants.levelSelectionVerticalMargin,
            label = level.name,
            width = 140, height = 50,
            saturation = 0.8,
            hue = 1,
            onRelease = function()
                game.loadLevel(level.file)
            end,
        }
    end
end
createButtons()

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

    love.graphics.setColor(util.hsvToRgb(button.hue, button.saturation,
        button.pressing and 0.8 or 0.5, 1))
    alignedRectangle(x, y, width + border, height + border, 0.5, 0.5)

    love.graphics.setColor(util.hsvToRgb(button.hue, button.saturation,
        button.hover and 0.4 or 0.3, 1))
    alignedRectangle(x, y, width, height, 0.5, 0.5)

    love.graphics.setColor(util.hsvToRgb(button.hue, button.saturation * 0.5, 1, 1))
    if type(label) == "string" then
        util.alignedPrint(label, x, y, 0.5, 0.5)
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
    util.alignedPrint(textEffect.text, textEffect.x, textEffect.y, 0.5, 0.5)
end

local function isInsideButton(button, x, y)
    local bx = buttonX(button)
    local by = buttonY(button)
    local hWidth = button.width / 2
    local hHeight = button.height / 2
    return util.isInsideRect(x, y,
        bx - hWidth,  bx + hWidth,
        by - hHeight, by + hHeight
    )
end


function love.draw()
    love.graphics.reset()
    love.graphics.setColor(255, 255, 255)

    if state.currentScreen == "levelSelect" then
        for _, button in pairs(buttons) do
            drawButton(button)
        end
    else
        game.drawGame()
        game.drawHud()
    end

    -- Action buttons
    util.alignedPrint(string.format("FPS: %d", love.timer.getFPS()),
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