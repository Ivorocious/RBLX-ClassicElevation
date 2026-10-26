--!strict
return {
	DataStoreName = "ArrivalProfiles_v1",
	CreationBonus = 100,
	AmbientSoundId = "rbxassetid://83623533219361",
	AmbientVolume = 0.12,
	Entrance = {TitleMoveSeconds = 0.9, LogoHoldSeconds = 1.6, RevealSeconds = 1.1, ApproachSeconds=3, LandingSeconds=.7, ReturningHoldSeconds=.35},
	Hair = {
		{name = "Bare", assetId = 0},
		{name = "Tousled", assetId = 63690008},
		{name = "Classic", assetId = 16630147},
		{name = "Spiked", assetId = 376524487},
	},
	Skin = {{245, 205, 135}, {255, 224, 189}, {205, 155, 112}, {142, 92, 62}, {86, 56, 43}, {235, 188, 156}},
	Colors = {{37, 198, 153}, {53, 130, 240}, {242, 114, 73}, {170, 116, 238}, {245, 204, 75}, {239, 244, 249}, {43, 51, 67}, {234, 114, 173}},
	DefaultLook = {hair = 1, skin = 1, top = 2, legs = 7},
	StudioPresets = {"First visit", "Returning avatar", "Returning racer", "Bonus available", "Bonus claimed", "Slow loading", "Load failure", "Save failure", "Lobby entrance", "Slow lobby delivery", "Lobby delivery failure"},
}
