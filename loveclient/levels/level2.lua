local entities = {
    -- Row 1
    {
        drawable = "house",
        x = -400,
        y = -125,
        power = -0.2,
        people = 1,
    },
    {
        drawable = "solar_power",
        x = -200,
        y = -150,
        power = 2,
    },
    {
        drawable = "house",
        x = 0,
        y = -175,
        power = -0.7,
        people = 2,
    },
    {
        drawable = "house",
        x = 200,
        y = -150,
        power = -1,
        people = 2,
    },
    {
        drawable = "factory",
        x = 400,
        y = -125,
        power = -1.5,
        people = -4,
        money = 12,
    },
    -- Row 2
    {
        drawable = "house",
        x = -400,
        y = 125,
        power = -1,
        people = 1,
    },
    {
        drawable = "factory",
        x = -200,
        y = 150,
        power = -2.5,
        people = -3,
        money = 15,
    },
    {
        drawable = "house",
        x = 0,
        y = 175,
        power = -0.5,
        people = 1,
    },
    {
        drawable = "house",
        x = 200,
        y = 150,
        power = -0.8,
        people = 2,
    },
    {
        drawable = "solar_power",
        x = 400,
        y = 125,
        power = 2.5,
    },
    -- Middle
    {
        drawable = "solar_power",
        x = -450,
        y = 0,
        power = 2,
    },
    {
        drawable = "solar_power",
        x = 450,
        y = 0,
        power = 2,
    },
}

local connections = {
    [1] = { 7, 9, },
    [3] = { 8, },
}

return {
    entities = entities,
    connections = connections,
}