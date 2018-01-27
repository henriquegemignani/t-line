local constants = require("constants")
local state = require("state")
local images = require("images")
local util = require("util")


local game = {}

game.submitButton = {
    x = 0.5,
    y = 0.9,
    label = "Submit",
    width = 140,
    height = 50,
    saturation = 0.8,
    hue = 1,
    onRelease = function()
        game.submitSolution()
    end,
}


function game.loadLevel(levelName)
    local levelTable = love.filesystem.load("levels/" .. levelName)()

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    local function doMinMax(t)
        minX = math.min(minX, t.x)
        minY = math.min(minY, t.y)
        maxX = math.max(maxX, t.x)
        maxY = math.max(maxY, t.y)
    end

    state.mapEntities = {}
    state.connections = {}
    for i, entity in ipairs(levelTable.entities) do
        doMinMax(entity)
        state.mapEntities[i] = util.tableDeepCopy(entity)
        state.connections[state.mapEntities[i]] = {}
    end

    if levelTable.tutorialMessage then
        doMinMax(levelTable.tutorialMessage)
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
    game.calculateReach()

    state.currentTutorialMessage = levelTable.tutorialMessage
    state.cameraPositionX = centerX - (maxX + minX) / 2
    state.cameraPositionY = centerY - (maxY + minY) / 2

    state.currentScreen = "game"
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

    for _, group in ipairs(state.entityGroups) do
        local unsatisfiedGroup = false
        for _, statName in ipairs(constants.possibleStatsOrder) do
            if group[statName] and group[statName] < 0 then
                unsatisfiedGroup = true
            end
        end
        if group.money and group.money > 0 and not unsatisfiedGroup then
            profit = profit + group.money
        end
    end

    return profit
end

function game.calculateReach()
    state.groupForEntity = {}
    state.entityGroups = {}

    local mapEntities = state.mapEntities
    local groupForEntity = state.groupForEntity
    local queue = {}

    local nextGroup = 0
    local function genGroup()
        nextGroup = nextGroup + 1
        local group = { name = tostring(nextGroup), }
        table.insert(state.entityGroups, group)
        return group
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
    state.currentMoney = game.calculateProfit()
end

function game.isInsideEntity(entity, mouseX, mouseY)
    local imageScale = constants.imageScale
    local drawable = images[entity.drawable]
    local width, height = drawable:getDimensions()

    return util.isInsideRect(
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
    util.alignedPrint(table.concat(texts, "\n"), 5, 0, 0, 0.5, font)
    -- util.alignedPrint(state.groupForEntity[entity].name, 0, 50, 0.5, 0, font)


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
            love.graphics.setColor(100, 100, 255)
        elseif entity.power and entity.power > 0 then
            love.graphics.setColor(255, 255, 100)
        elseif game.hasUnsatisfiedRequirement(entity) then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(200, 255, 200)
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

        util.alignedPrint(string.format("-%d $", game.priceBetweenPoints(mouseX, mouseY, entityX, entityY)),
                     mouseX + 10, mouseY + 10, 0, 0)
    end


    if state.currentTutorialMessage then
        local message = state.currentTutorialMessage
        local width = font:getWidth(message.text)

        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.printf(message.text, message.x - width / 2, message.y, width, "center")
    end

    love.graphics.pop()
end

function game.drawHud()
    -- Score
    love.graphics.setColor(255, 255, 255, 255)
    util.alignedPrint(string.format("Projected Profit: %d $", state.currentMoney),
                      centerX, 15, 0.5, 0.0,
                      bigFont)
end

function game.submitSolution()
    if state.currentMoney > 0 then
        state.currentScreen = "levelSelect"
    else
        local x, y = love.mouse.getPosition()
        util.spawnTextEffect("Invalid Solution!", x, y, {255, 255, 255})
    end
end

return game