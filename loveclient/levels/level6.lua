local entities = {
    {
        drawable = "nuclear_plant",
        x = -300,
        y = -150,
        power = 15.0,
        money = -30,
    },
    {
        drawable = "nuclear_plant",
        x = -300,
        y = 150,
        power = 23.0,
        money = -40,
    },
    {
        drawable = "factory",
        x = -500,
        y = 100,
        power = -7,
        people = -5,
        money = 30,
    },
    {
        drawable = "factory",
        x = -200,
        y = 0,
        power = -11,
        people = -15,
        money = 80,
    },
    {
        drawable = "house",
        x = 420,
        y = 300,
        power = -2,
        people = 8,
    },
    {
        drawable = "house",
        x = 500,
        y = 200,
        power = -0.5,
        people = 3,
    },
    {
        drawable = "house",
        x = 600,
        y = 300,
        power = -1.9,
        people = 11,
    },
}

local connections = {
}

return {
    entities = entities,
    connections = connections,
}