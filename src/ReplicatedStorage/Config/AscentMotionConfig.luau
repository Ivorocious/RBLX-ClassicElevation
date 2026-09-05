--!strict

local AscentMotionConfig = {}

AscentMotionConfig.AttributeNames = {
	MotionKind = "MotionKind",
	MotionEnd = "MotionEnd",
	MotionDuration = "MotionDuration",
	PauseDuration = "PauseDuration",
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
}

AscentMotionConfig.Defaults = {
	MotionDuration = 2.5,
	PauseDuration = 1,
	WarningDuration = 1,
	SnowballDamage = 35,
}

AscentMotionConfig.ContactCooldown = 0.75
AscentMotionConfig.MaxRacersChecked = 20
AscentMotionConfig.GroundProbeExtraDistance = 1.5
AscentMotionConfig.ProjectileRadiusScale = 0.45
AscentMotionConfig.AvalancheRotationSpeed = math.rad(150)

return AscentMotionConfig
