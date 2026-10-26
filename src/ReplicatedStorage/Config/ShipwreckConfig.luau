--!strict
return {
    CannonCycle=8.5, CannonWarning=1.8, CannonSpeed=48, CannonRadius=.8,
    CannonArcHeight=8.1, CannonArcCollisionStep=.05,
    CannonFireParticles=9, CannonSmokeParticles=12, CannonSplashParticles=16,
    CrumbleWarning=.65, ExpertSparWarning=.65, CrumbleFall=.55, CrumbleReset=3, CrumbleCheck=.1, CrumbleDrop=24,
    TideCycle=10, TideDry=4.5, TideWarning=2, TideActive=2.5, TideDrain=1,
    -- The flood pool ends below the refuge decks; the crest rises from the authored floor.
    TideWaterBottom=1.5, TideWaterHeight=7,
    TideCrestHeight=14, TideCrestDepth=9,
    MaxFallingHazards=32, FallingCoconutMaxDelay=1.4,
    FallingStalactiteImpactTime=.35, FallingStalactitePassDepth=8,
    TideWaterActiveTransparency=0, TideFoamActiveTransparency=1, TideWaveActiveTransparency=0,
    ObstacleSweepPeriod=3.5, ObstacleSweepAmplitude=4,
    Audio={Fuse="rbxassetid://87684423785818",Blast="rbxassetid://88893898468893",
        TideWarning="rbxassetid://139938185841803",TideSurge="rbxassetid://120461637148584"},
}
