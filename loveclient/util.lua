
local util = {}

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
function util.hsvToRgb(h, s, v, a)
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

function util.tableDeepCopy(t1)
    local r = {}
    for k, v in pairs(t1) do
        if type(v) == "table" then
            r[k] = util.tableDeepCopy(v)
        else
            r[k] = v
        end
    end
    return r
end

function util.printConnections()
    local state = require("state")

    for _, sourceEntity in ipairs(state.mapEntities) do
        for _, targetEntity in ipairs(state.mapEntities) do
            print(sourceEntity.drawable, targetEntity.drawable, state.connections[sourceEntity][targetEntity])
        end
    end
end

function util.isInsideRect(x, y, lx, rx, ly, ry)
    return lx <= x and x <= rx
       and ly <= y and y <= ry
end


function util.alignedPrint(msg, x, y, anchorX, anchorY, theFont)
    theFont = theFont or font
    local numLines = select(2, msg:gsub("\n", ""))
    local w = theFont:getWidth(msg)
    local h = theFont:getHeight() * (numLines + 1)
    love.graphics.setFont(theFont)
    love.graphics.print(msg, x - w * anchorX, y - h * anchorY)
end

local function buttonX(button)
    return button.x * screenWidth
end

local function buttonY(button)
    return button.y * screenHeight
end

function util.alignedRectangle(x, y, width, height, anchorX, anchorY)
    love.graphics.rectangle("fill",
        x - width * anchorX, y - height * anchorY,
        width, height)
end

function util.isInsideButton(button, x, y)
    local bx = buttonX(button)
    local by = buttonY(button)
    local hWidth = button.width / 2
    local hHeight = button.height / 2
    return util.isInsideRect(x, y,
        bx - hWidth,  bx + hWidth,
        by - hHeight, by + hHeight
    )
end

function util.drawButton(button)
    local x = buttonX(button)
    local y = buttonY(button)
    local label = button.label
    local width = button.width
    local height = button.height
    local border = 4

    love.graphics.setColor(util.hsvToRgb(button.hue, button.saturation,
        button.pressing and 0.8 or 0.5, 1))
    util.alignedRectangle(x, y, width + border, height + border, 0.5, 0.5)

    love.graphics.setColor(util.hsvToRgb(button.hue, button.saturation,
        button.hover and 0.4 or 0.3, 1))
    util.alignedRectangle(x, y, width, height, 0.5, 0.5)

    love.graphics.setColor(util.hsvToRgb(button.hue, button.saturation * 0.5, 1, 1))
    if type(label) == "string" then
        util.alignedPrint(label, x, y, 0.5, 0.5)
    else
        label(x, y)
    end
end

return util