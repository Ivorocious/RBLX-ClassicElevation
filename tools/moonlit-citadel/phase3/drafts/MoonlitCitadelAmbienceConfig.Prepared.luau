--!strict

return table.freeze({
	CourseId = "moonlit_citadel",
	ActivationDistance = 750,
	UseCourseBounds = true,
	HideWorkspaceRoots = {"MoonlitCitadelPhase1_BL02"},
	RequiredCourseAttribute = "MoonlitNightAmbience",
	Lighting = {
		ClockTime = .15, GeographicLatitude = 20, Brightness = 2,
		ExposureCompensation = .15, GlobalShadows = true, ShadowSoftness = .3,
		EnvironmentDiffuseScale = .55, EnvironmentSpecularScale = .3,
		Ambient = Color3.fromRGB(98, 110, 138),
		OutdoorAmbient = Color3.fromRGB(91, 106, 135),
	},
	ColorCorrection = {
		Brightness = .025, Contrast = .06, Saturation = -.06,
		TintColor = Color3.fromRGB(232, 240, 255),
	},
	Atmosphere = {
		Density = .22, Offset = .12, Haze = .8, Glare = 0,
		Color = Color3.fromRGB(161, 184, 219),
		Decay = Color3.fromRGB(77, 91, 122),
	},
	Sky = {
		SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex",
		SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex",
		SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex",
		SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex",
		SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex",
		SkyboxUp = "rbxasset://textures/sky/sky512_up.tex",
		CelestialBodiesShown = true, StarCount = 1800,
		SunAngularSize = 0, MoonAngularSize = 9,
	},
	Effects = {
		BloomEffect = {Enabled = true, Intensity = .12, Size = 20, Threshold = 1.4},
		SunRaysEffect = {Enabled = false},
	},
})
