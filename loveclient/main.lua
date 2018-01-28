
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
        local xIndex = ((i - 1) % constants.levelsPerRow) / (constants.levelsPerRow - 1)
        local yIndex = math.floor((i - 1) / constants.levelsPerRow)
        buttons[i] = {
            x = xIndex * (1.0 - constants.levelSelectionHorizontalMargin * 2)
                + constants.levelSelectionHorizontalMargin,
            y = ((1 + yIndex) / constants.levelSelectionNumRows)
                * (1.0 - constants.levelSelectionVerticalMargin * 2)
                + constants.levelSelectionVerticalMargin,
            label = level.name,
            width = 140, height = 50,
            saturation = 0,
            hue = 0.5,
            onRelease = function()
                game.loadLevel(level.file)
            end,
        }
    end
end
createButtons()

function love.load()
    smallFont = love.graphics.newFont(15)
    bigFont = love.graphics.newFont(25)
    font = love.graphics.setNewFont(20)
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
    updateArray(state.particles, dt, updateParticle)
    updateArray(state.textEffects, dt, updateTextEffect)
end

function love.keypressed(key)
    if key == "r" then
        love.event.quit("restart")
    elseif key == "escape" then
        state.currentScreen = "levelSelect"
    end
end

local function drawParticle(particle)
    love.graphics.setColor(unpack(particle.color))
    love.graphics.circle("fill", particle.x, particle.y, particle.radius)
end

local function drawTextEffect(textEffect)
    love.graphics.setColor(255, 255, 255, textEffect.color[4])
    util.alignedPrint(textEffect.text, textEffect.x, textEffect.y, 0.5, 0.5)

    love.graphics.setColor(unpack(textEffect.color))
    util.alignedPrint(textEffect.text, textEffect.x, textEffect.y, 0.5, 0.5)
end


function love.draw()
    love.graphics.reset()
    love.graphics.setColor(255, 255, 255)

    if state.currentScreen == "levelSelect" then
        for _, button in pairs(buttons) do
            util.drawButton(button)
        end
    else
        game.drawGame()
        game.drawHud()
        util.drawButton(game.submitButton)
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
    for _, button in pairs(buttons) do
        util.checkMouseMovedButton(button, x, y)
    end
    util.checkMouseMovedButton(game.submitButton, x, y)
end

function love.mousepressed(x, y, mouseButton)
    if mouseButton == 1 then
        state.mouseDown = true
        state.lastMouseX = x
        state.lastMouseY = y

        local clickedAButton = false
        for _, button in pairs(buttons) do
            clickedAButton = clickedAButton or util.checkMousePressedButton(button, x, y)
        end
        clickedAButton = clickedAButton or util.checkMousePressedButton(game.submitButton, x, y)
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
            util.checkMouseReleasedButton(button, x, y)
        end
        util.checkMouseReleasedButton(game.submitButton, x, y)
        if state.currentlySelectedEntity then
            for _, entity in ipairs(state.mapEntities) do
                if game.isInsideEntity(entity, x, y) then
                    if entity == state.currentlySelectedEntity then
                        break
                    end
                    local price
                    if game.isConnectedWith(state.currentlySelectedEntity, entity) then
                        price = game.removeConnectionBetween(state.currentlySelectedEntity, entity)
                    else
                        price = game.addConnectionBetween(state.currentlySelectedEntity, entity)
                    end
                    if price > 0 then
                        util.spawnTextEffect(string.format("%-.2f $", price), x, y, {255, 0, 0})
                    end
                    break
                end
            end
        end
        state.currentlySelectedEntity = nil
    end
end

function love.quit()
end