--!strict

local RaceConstants = require(script.Parent.Parent.Shared.RaceConstants)
local RaceTypes = require(script.Parent.Parent.Shared.RaceTypes)

export type RaceConfig = {
	RaceFormat: RaceTypes.RaceFormat,
	MinPlayers: number,
	IntermissionDuration: number,
	CountdownDuration: number,
	RaceDuration: number,
	RaceEndingDuration: number,
	ResultsDuration: number,
	ResettingDuration: number,
	FallYThreshold: number,
	DefaultCourseId: string,
	LobbyModelName: string,
	LobbySpawnMarkerName: string,
	LobbyFallbackPartName: string,
	RaceCourseModelName: string,
	RaceStartPartName: string,
	RacerStartVerticalOffset: number,
	LobbyResetVerticalOffset: number,
	StagingTeleportEnabled: boolean,
}

local RaceConfig: RaceConfig = {
	RaceFormat = RaceConstants.RaceFormat.PointToPoint,
	MinPlayers = 1,
	IntermissionDuration = RaceConstants.DefaultDurations.Intermission,
	CountdownDuration = RaceConstants.DefaultDurations.Countdown,
	RaceDuration = RaceConstants.DefaultDurations.Race,
	RaceEndingDuration = RaceConstants.DefaultDurations.RaceEnding,
	ResultsDuration = RaceConstants.DefaultDurations.Results,
	ResettingDuration = RaceConstants.DefaultDurations.Resetting,
	FallYThreshold = 4,
	DefaultCourseId = "MVP_PointToPoint_01",
	LobbyModelName = "Lobby",
	LobbySpawnMarkerName = "LobbySpawnPadMarker",
	LobbyFallbackPartName = "LobbyPlatform",
	RaceCourseModelName = "RaceCourse",
	RaceStartPartName = "Start",
	RacerStartVerticalOffset = 5,
	LobbyResetVerticalOffset = 5,
	StagingTeleportEnabled = true,
}

return RaceConfig
