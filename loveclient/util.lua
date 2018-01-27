
local util = {}

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

return util