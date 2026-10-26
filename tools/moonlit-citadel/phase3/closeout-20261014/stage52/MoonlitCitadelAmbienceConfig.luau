--!strict
return table.freeze({
	CourseId = "moonlit_citadel", ActivationDistance = 750, UseCourseBounds = true,
	HideWorkspaceRoots = {"MoonlitCitadelPhase1_C01", "MoonlitCitadelPhase1_BL01", "MoonlitCitadelPhase1_BL02"}, RequiredCourseAttribute = "MoonlitNightAmbience",
	Lighting = {ClockTime = 19.2, GeographicLatitude = 20, Brightness = 2.2, ExposureCompensation = .65,
		GlobalShadows = true, ShadowSoftness = .3, EnvironmentDiffuseScale = .85, EnvironmentSpecularScale = .4,
		Ambient = Color3.fromRGB(145, 153, 171), OutdoorAmbient = Color3.fromRGB(132, 146, 169)},
	ColorCorrection = {Brightness = .035, Contrast = .015, Saturation = -.045, TintColor = Color3.fromRGB(232, 240, 255)},
		Atmosphere = {Density = .025, Offset = .10, Haze = .55, Glare = 0,
		Color = Color3.fromRGB(107, 123, 148), Decay = Color3.fromRGB(65, 78, 101)},
	Sky = {SkyboxBk = "rbxassetid://119591637361429", SkyboxDn = "rbxassetid://81233894808962",
		SkyboxFt = "rbxassetid://136920684348219", SkyboxLf = "rbxassetid://99622089516191",
		SkyboxRt = "rbxassetid://95853984087799", SkyboxUp = "rbxassetid://126102685877031",
		CelestialBodiesShown = true, StarCount = 1000, SunAngularSize = 0, MoonAngularSize = 11,
		MoonTextureId = "rbxasset://sky/moon.jpg"},
	Effects = {BloomEffect = {Enabled = true, Intensity = .10, Size = 20, Threshold = 1.4}, SunRaysEffect = {Enabled = false}},
})
