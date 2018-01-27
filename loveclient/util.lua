
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

return util