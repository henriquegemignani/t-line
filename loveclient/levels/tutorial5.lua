local entities = {
    {
        drawable = "solar_power",
        x = 0,
        y = 100,
        power = 2.0,
    },
    {
        drawable = "factory",
        x = -250,
        y = -100,
        power = -1,
        money = 30,
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
    {
        drawable = "factory",
        x = 0,
        y = -100,
        power = -4.0,
        people = -3,
        money = 5,
    },
}

local connections = {
    [1] = { 3, },
    [2] = { 5, },
}

return {
    entities = entities,
    connections = connections,
    tutorialMessage = {
        x = 100,
        y = 200,
        text = "Sometimes, there's already some connections.\nYou can remove these connections, for a fee.",
    },
}