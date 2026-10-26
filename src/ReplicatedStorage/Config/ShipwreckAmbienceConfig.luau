--!strict
return {
    CourseId = "shipwreck_cove",
    ActivationDistance = 750,
    HideWorkspaceRoots = {"Lobby", "ObstacleKit_Palette"},
    Lighting = {
        ClockTime = 11.3, GeographicLatitude = 18, Brightness = 2.6,
        ExposureCompensation = 0,
        GlobalShadows = true, ShadowSoftness = 0.25,
        EnvironmentDiffuseScale = 0.65, EnvironmentSpecularScale = 0.4,
        Ambient = Color3.fromRGB(100, 121, 143),
        OutdoorAmbient = Color3.fromRGB(143, 163, 177),
    },
    ColorCorrection = {
        Brightness = 0.015, Contrast = 0.08, Saturation = 0.12,
        TintColor = Color3.fromRGB(255, 253, 244),
    },
    Atmosphere = {
        Density = 0.19, Offset = 0.1, Haze = 0.65, Glare = 0.08,
        Color = Color3.fromRGB(190, 225, 244),
        Decay = Color3.fromRGB(116, 160, 188),
    },
    Sky = {
        SkyboxBk = "rbxassetid://103718808452831",
        SkyboxDn = "rbxassetid://77833892063182",
        SkyboxFt = "rbxassetid://73772573619883",
        SkyboxLf = "rbxassetid://126618357332854",
        SkyboxRt = "rbxassetid://131381458066433",
        SkyboxUp = "rbxassetid://108618245347156",
        SkyboxOrientation = Vector3.zero,
        CelestialBodiesShown = true, StarCount = 0, SunAngularSize = 7,
    },
    Effects = {
        BloomEffect = {Enabled=true, Intensity=0.12, Size=20, Threshold=1.2},
        SunRaysEffect = {Enabled=true, Intensity=0.035, Spread=0.75},
    },
}

