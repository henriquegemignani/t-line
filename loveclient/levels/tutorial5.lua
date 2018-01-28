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
        drawable = "nuclear_plant",
        x = 500,
        y = 0,
        power = 8,
        money = -20,
    },
    {
        drawable = "house",
        x = 500,
        y = 150,
        power = -1.0,
        people = 2,
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
    [2] = { 7, },
    [5] = { 6, },
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