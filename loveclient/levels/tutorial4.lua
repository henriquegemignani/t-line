local entities = {
    {
        drawable = "solar_power",
        x = 0,
        y = 0,
        power = 2.5,
    },
    {
        drawable = "factory",
        x = -250,
        y = -100,
        power = -1,
        money = 15,
        people = -2,
    },
    {
        drawable = "factory",
        x = 450,
        y = -180,
        power = -1,
        money = 8,
        people = -1,
    },
    {
        drawable = "house",
        x = -250,
        y = 100,
        power = -0.5,
        people = 3,
    },
}

local connections = {
}

return {
    entities = entities,
    connections = connections,
    tutorialMessage = {
        x = 100,
        y = 200,
        text = "It's not always profitable to connect everything.",
    },
}