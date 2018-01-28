local entities = {
    {
        drawable = "nuclear_plant",
        x = 350,
        y = -300,
        power = 15.0,
        money = -30,
    },
    {
        drawable = "house",
        x = -100,
        y = 0,
        power = -0.2,
        people = 2,
    },
    {
        drawable = "house",
        x = 100,
        y = 0,
        power = -0.4,
        people = 3,
    },
    {
        drawable = "house",
        x = 0,
        y = 100,
        power = -0.2,
        people = 2,
    },
    {
        drawable = "house",
        x = 0,
        y = -100,
        power = -0.8,
        people = 4,
    },
    {
        drawable = "factory",
        x = -250,
        y = -200,
        power = -2,
        people = -4,
        money = 20,
    },
    {
        drawable = "factory",
        x = -200,
        y = -300,
        power = -3,
        people = -3,
        money = 30,
    },
    {
        drawable = "solar_power",
        x = 300,
        y = 100,
        power = 2.5,
    },
}

local connections = {
    [2] = { 4, 5 },
    [3] = { 4, 5 },
}

return {
    entities = entities,
    connections = connections,
}