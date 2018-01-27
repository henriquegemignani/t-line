local entities = {
    {
        drawable = "solar_power",
        x = -200,
        y = 0,
        power = 1,
    },
    {
        drawable = "factory",
        x = 200,
        y = 0,
        power = -1,
        money = 10,
    },
}

local connections = {
}

return {
    entities = entities,
    connections = connections,
    tutorialMessage = {
        x = 0,
        y = 100,
        text = "Factories needs power to operate.\nConnect a solar station to provide power!" ..
                "\n\nWhen finished, press Submit.",
    },
}