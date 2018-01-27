local entities = {
    {
        drawable = "solar_power",
        x = 150,
        y = 400,
        power = 1,
    },
    {
        drawable = "factory",
        x = 300,
        y = 150,
        power = -2.5,
        money = 50,
        people = -7,
    },
    {
        drawable = "house",
        x = 580,
        y = 120,
        power = -.3,
        people = 4,
    },
    {
        drawable = "house",
        x = 400,
        y = 230,
        power = -.6,
        people = 6,
    },
    {
        drawable = "nuclear_plant",
        x = 1200,
        y = 500,
        power = 8,
        money = -30,
    },
}

local connections = {
    [1] = { 4, }
}

return {
    entities = entities,
    connections = connections,
}