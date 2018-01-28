local entities = {
    {
        drawable = "solar_power",
        x = -200,
        y = -100,
        power = 2,
    },
    {
        drawable = "factory",
        x = 250,
        y = -100,
        power = -1,
        money = 8,
    },
    {
        drawable = "factory",
        x = 100,
        y = -200,
        power = -1,
        money = 5,
    },
}

local connections = {
}

return {
    entities = entities,
    connections = connections,
    tutorialMessage = {
        x = 25,
        y = 100,
        text = "Making connections costs money, based on distance.\nPrefer multiple small connections!"
            .. "\n\nTo remove a connection, perform the same action used to create it.",
    },
}