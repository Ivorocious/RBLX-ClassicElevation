--!strict

return {
	CourseId = "city_run",
	ActivationDistance = 1250,
	Lighting = {
		ClockTime = 17.2, Brightness = 2.2,
		Ambient = Color3.fromRGB(99, 91, 111),
		OutdoorAmbient = Color3.fromRGB(147, 132, 128),
	},
	Atmosphere = {
		Density = 0.20, Offset = 0, Haze = 0.7, Glare = 0,
		Color = Color3.fromRGB(255, 220, 175),
		Decay = Color3.fromRGB(145, 155, 180),
	},
	Sky = {
		SkyboxFt = "rbxassetid://101590100389932",
		SkyboxBk = "rbxassetid://103969206026906",
		SkyboxLf = "rbxassetid://112078473274944",
		SkyboxRt = "rbxassetid://100023227808303",
		SkyboxUp = "rbxassetid://93036780813806",
		SkyboxDn = "rbxassetid://77265981493578",
		SkyboxOrientation = Vector3.new(0, 0, 0),
		CelestialBodiesShown = false,
		StarCount = 0,
		SunAngularSize = 7,
	},
	ColorCorrection = {
		Brightness = 0.01, Contrast = 0.05, Saturation = 0.03,
		TintColor = Color3.fromRGB(255, 246, 232),
	},
}
