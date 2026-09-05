--!strict

local AscentMotionConfig = {}

AscentMotionConfig.AttributeNames = {
	MotionKind = "MotionKind",
	MotionStart = "MotionStart",
	MotionEnd = "MotionEnd",
	InitialProgress = "InitialProgress",
	MotionDuration = "MotionDuration",
	PauseDuration = "PauseDuration",
	PauseMin = "PauseMin",
	PauseMax = "PauseMax",
	WarningDuration = "WarningDuration",
	CycleOffset = "CycleOffset",
	Damage = "Damage",
	ActiveTransparency = "ActiveTransparency",
	MotionPhase = "MotionPhase",
	MotionNextPhaseAt = "MotionNextPhaseAt",
}

AscentMotionConfig.MotionKinds = {
	MovingLog = "MovingLog",
	LavaSpurt = "LavaSpurt",
	Snowball = "Snowball",
	Avalanche = "Avalanche",
	RollingLog = "RollingLog",
	RollingBoulder = "RollingBoulder",
}

AscentMotionConfig.Defaults = {
	MotionDuration = 2.5,
	PauseDuration = 1,
	WarningDuration = 1,
	SnowballDamage = 35,
	MovingLogPauseDuration = 0.6,
	SnowballPauseMin = 2.5,
	SnowballPauseMax = 4.5,
	RollingBoulderPauseMin = 4,
	RollingBoulderPauseMax = 8,
}

AscentMotionConfig.ContactCooldown = 0.75
AscentMotionConfig.MaxRacersChecked = 20
AscentMotionConfig.GroundProbeExtraDistance = 1.5
AscentMotionConfig.ProjectileRadiusScale = 0.45
AscentMotionConfig.AvalancheRotationSpeed = math.rad(150)
AscentMotionConfig.RollingRotationSpeed = math.rad(210)
AscentMotionConfig.RollingBoulderMinWarningDuration = 1.2

return AscentMotionConfig
