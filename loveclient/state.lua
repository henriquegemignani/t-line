
return {
    cameraPositionX = 0,
    cameraPositionY = 0,
    mapEntities = {
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
            x = 480,
            y = 220,
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
    },
    connections = {
    },
    currentMoney = 0,
    groupForEntity = {},


    playerScore = 0,
    currentPlayers = false,
    actionCooldownTimer = 0,
    pointsRecently = 0,
    pointsRecentlyTimer = 0,

    alphaWave = {
        name = "alphaWave",
        position = 0,
        velocity = 10,
        affinity = 1,
        pulses = {},
    },
    betaWave = {
        name = "betaWave",
        position = 0,
        velocity = 10,
        affinity = 1,
        pulses = {},
    },
    particles = {},
    textEffects = {},
    playerScoreEffects = {},
}