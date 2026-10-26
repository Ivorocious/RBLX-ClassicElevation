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
	LobbyAmbiencePadding: Vector3,
	RaceCourseModelName: string,
	RaceStartPartName: string,
	RacerStartVerticalOffset: number,
	LobbyResetVerticalOffset: number,
	StagingTeleportEnabled: boolean,
	StudioLobbyPreview: boolean,
}

local RaceConfig = {
	RaceFormat = RaceConstants.RaceFormat.PointToPoint,
	MinPlayers = 1,
	IntermissionDuration = RaceConstants.DefaultDurations.Intermission,
	CountdownDuration = 3,
	RaceDuration = 540,
	RaceEndingDuration = 0,
	ResultsDuration = 2,
	ResettingDuration = 0,
	FallYThreshold = 4,
	DefaultCourseId = "city_run",
	LobbyModelName = "Lobby",
	LobbySpawnMarkerName = "LobbySpawnPadMarker",
	LobbyFallbackPartName = "LobbyPlatform",
	LobbyAmbiencePadding = Vector3.new(8, 12, 8),
	RaceCourseModelName = "RaceCourse",
	RaceStartPartName = "Start",
	RacerStartVerticalOffset = 5,
	LobbyResetVerticalOffset = 5,
	StagingTeleportEnabled = true,
	StudioLobbyPreview = true,
 FinishReturnSeconds = 1.2,
 CameraReadyTimeout = 15,
 SpectateLoadSeconds = 6,
 InactivityWarningSeconds = 120,
 InactivityBreakSeconds = 150,
 MinimumRaceDuration = 300,
 MaximumRaceDuration = 900,
 AuthoredDeadlineMultiplier = 1.5,
 DeadlineRecoverySeconds = 60,
 -- Conservative floors until beginner sessions establish measured deadlines.
 CourseTimeLimits = {
  city_run = {seconds=540,evidence="Authored target; beginner timing pending"},
  heartwood_ascent = {seconds=540,evidence="Authored target; beginner timing pending"},
  shipwreck_cove = {seconds=540,evidence="Authored target; beginner timing pending"},
  stud_garden_v2 = {seconds=660,evidence="Authored 5–6 minute target; beginner timing pending"},
  moonlit_citadel = {seconds=720,evidence="Course under revision; beginner timing pending"},
 },
}

return RaceConfig
