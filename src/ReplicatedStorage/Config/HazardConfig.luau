--!strict

local HazardConfig = {}

HazardConfig.AttributeNames = {
	HazardType = "HazardType",
	FallDistance = "FallDistance",
	CycleOffset = "CycleOffset",
	HazardPhase = "HazardPhase",
	NextPhaseAt = "NextPhaseAt",
}

HazardConfig.HazardTypes = {
	Kill = "Kill",
	FallingRock = "FallingRock",
	Crumble = "Crumble",
}

HazardConfig.Phases = {
	Idle = "Idle",
	Solid = "Solid",
	Warning = "Warning",
	Falling = "Falling",
	Cooldown = "Cooldown",
	Resetting = "Resetting",
	Gone = "Gone",
}

HazardConfig.OverlapScanInterval = 0.1

HazardConfig.FallingRock = {
	DefaultFallDistance = 40,
	WarningDuration = 1.3,
	FallDuration = 0.7,
	CooldownDuration = 2.5,
	ResetDuration = 0.1,
	WarningColor = Color3.fromRGB(255, 174, 48),
	WarningMaterial = Enum.Material.Neon,
	WarningTransparency = 0.2,
}

HazardConfig.Crumble = {
	WarningDuration = 1.25,
	GoneDuration = 2,
	WarningColor = Color3.fromRGB(255, 170, 54),
	WarningMaterial = Enum.Material.Neon,
	GoneTransparency = 1,
}

return HazardConfig
