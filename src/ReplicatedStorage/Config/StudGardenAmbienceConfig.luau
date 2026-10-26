--!strict

return {
	CourseId = "stud_garden_v2",
	ActivationDistance = 500,
	ExcludeWorkspaceRoots = {"GrandArcade"},
	Lighting = {
		ClockTime = 11.4, Brightness = 2.1,
		Ambient = Color3.fromRGB(107, 116, 96),
		OutdoorAmbient = Color3.fromRGB(153, 161, 137),
	},
	Atmosphere = {
		Density = 0, Offset = 0, Haze = 0, Glare = 0,
		Color = Color3.fromRGB(235, 244, 218),
		Decay = Color3.fromRGB(157, 179, 144),
	},
	Sky = {
		SkyboxFt = "rbxassetid://97343629320684",
		SkyboxBk = "rbxassetid://79395151004282",
		SkyboxLf = "rbxassetid://115422036443018",
		SkyboxRt = "rbxassetid://82381969054955",
		SkyboxUp = "rbxassetid://117234001501139",
		SkyboxDn = "rbxassetid://90173932349875",
		SkyboxOrientation = Vector3.new(0, 0, 0),
		CelestialBodiesShown = false,
		StarCount = 0,
		SunAngularSize = 7,
	},
	ColorCorrection = {
		Brightness = 0.005, Contrast = 0.035, Saturation = 0.015,
		TintColor = Color3.fromRGB(255, 252, 242),
	},
}
