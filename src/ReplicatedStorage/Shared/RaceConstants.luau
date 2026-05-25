--!strict

local RaceTypes = require(script.Parent.RaceTypes)

type RaceState = RaceTypes.RaceState
type PlayerRaceStatus = RaceTypes.PlayerRaceStatus
type RaceFormat = RaceTypes.RaceFormat

local RaceConstants = {}

RaceConstants.RaceState = {
	WaitingForPlayers = "WaitingForPlayers" :: RaceState,
	Intermission = "Intermission" :: RaceState,
	Countdown = "Countdown" :: RaceState,
	Racing = "Racing" :: RaceState,
	RaceEnding = "RaceEnding" :: RaceState,
	Results = "Results" :: RaceState,
	Resetting = "Resetting" :: RaceState,
}

RaceConstants.PlayerRaceStatus = {
	Lobby = "Lobby" :: PlayerRaceStatus,
	Queued = "Queued" :: PlayerRaceStatus,
	Racing = "Racing" :: PlayerRaceStatus,
	Finished = "Finished" :: PlayerRaceStatus,
	Spectating = "Spectating" :: PlayerRaceStatus,
	LateRacing = "LateRacing" :: PlayerRaceStatus,
	GhostRacing = "GhostRacing" :: PlayerRaceStatus,
	DNF = "DNF" :: PlayerRaceStatus,
}

RaceConstants.RaceFormat = {
	PointToPoint = "PointToPoint" :: RaceFormat,
	LapBased = "LapBased" :: RaceFormat,
}

RaceConstants.RemoteNames = {
	RaceStateChanged = "RaceStateChanged",
	PlayerRaceStatusChanged = "PlayerRaceStatusChanged",
	RaceTimerUpdated = "RaceTimerUpdated",
	RaceResultsUpdated = "RaceResultsUpdated",
	PersonalRaceSummary = "PersonalRaceSummary",
	RequestSpectate = "RequestSpectate",
	RequestRaceLate = "RequestRaceLate",
	RequestGhostRace = "RequestGhostRace",
	RequestDevRaceState = "RequestDevRaceState",
}

RaceConstants.CollisionGroups = {
	Default = "Default",
	RaceCharacter = "RaceCharacter",
	GhostCharacter = "GhostCharacter",
	Racers = "Racers",
	GhostRacers = "GhostRacers",
}

RaceConstants.DefaultDurations = {
	Intermission = 20,
	Countdown = 5,
	Race = 180,
	RaceEnding = 5,
	Results = 12,
	Resetting = 3,
}

return RaceConstants
