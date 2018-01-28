local entities = {
    {
        drawable = "nuclear_plant",
        x = 0,
        y = 0,
        power = 15.0,
        money = -30,
    },
    {
        drawable = "factory",
        x = 500,
        y = 0,
        power = -2,
        people = -4,
        money = 30,
    },
    {
        drawable = "factory",
        x = -500,
        y = 0,
        power = -2,
        people = -3,
        money = 20,
    },
    {
        drawable = "solar_power",
        x = 0,
        y = -200,
        power = 3.0,
    },
    {
        drawable = "house",
        x = 0,
        y = 200,
        power = -0.5,
        people = 3,
    },
    {
        drawable = "house",
        x = 200,
        y = -200,
        power = -0.5,
        people = 3,
    },
}

local connections = {
}

return {
    entities = entities,
    connections = connections,
}