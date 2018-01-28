local entities = {
    {
        drawable = "solar_power",
        x = 0,
        y = 0,
        power = 2,
    },
    {
        drawable = "factory",
        x = -250,
        y = -100,
        power = -1,
        money = 15,
        people = -3,
    },
    {
        drawable = "house",
        x = 250,
        y = -100,
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
        x = 0,
        y = 100,
        text = "Factories requires workers, found in houses."
            .. "\nHouses does not have to be connected directly to the factory.",
    },
}