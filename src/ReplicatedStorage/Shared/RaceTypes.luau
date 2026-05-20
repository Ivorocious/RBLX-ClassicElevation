--!strict

export type RaceState =
	"WaitingForPlayers"
	| "Intermission"
	| "Countdown"
	| "Racing"
	| "RaceEnding"
	| "Results"
	| "Resetting"

export type PlayerRaceStatus =
	"Lobby"
	| "Queued"
	| "Racing"
	| "Finished"
	| "Spectating"
	| "LateRacing"
	| "GhostRacing"
	| "DNF"

export type RaceFormat = "PointToPoint" | "LapBased"

export type CheckpointSplit = {
	checkpointIndex: number,
	checkpointName: string,
	lap: number,
	elapsedTime: number,
	deltaFromPersonalBest: number?,
}

export type PlayerRaceResult = {
	userId: number,
	displayName: string,
	status: PlayerRaceStatus,
	official: boolean,
	placement: number?,
	finishTime: number?,
	falls: number,
	checkpointSplits: { CheckpointSplit },
	dnfReason: string?,
	isPersonalBest: boolean?,
	summaryNotes: { string }?,
}

export type RaceResult = {
	raceId: string,
	courseId: string,
	format: RaceFormat,
	startedAt: number?,
	duration: number?,
	placements: { PlayerRaceResult },
	dnfs: { PlayerRaceResult },
	unofficialRuns: { PlayerRaceResult },
}

export type PersonalRaceSummary = {
	raceId: string,
	courseId: string,
	userId: number,
	displayName: string,
	status: PlayerRaceStatus,
	official: boolean,
	placement: number?,
	finishTime: number?,
	falls: number,
	checkpointSplits: { CheckpointSplit },
	isPersonalBest: boolean,
	previousBestTime: number?,
	timeBehindPersonalBest: number?,
	summaryNotes: { string },
}

local RaceTypes = {}

return RaceTypes
