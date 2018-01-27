
return {
    cameraPositionX = 0,
    cameraPositionY = 0,
    mapEntities = {
        {
            drawable = "solar_power",
            text = "+1MW",
            x = 150,
            y = 100,
            power = 1,
        },
        {
            drawable = "factory",
            text = "-2.5MW\n+$5",
            x = 400,
            y = 250,
            power = -2.5,
            money = 5,
        },
    },


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