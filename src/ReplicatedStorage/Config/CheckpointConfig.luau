--!strict

export type CheckpointConfig = {
	CourseModelName: string,
	StartPartName: string,
	CheckpointsFolderName: string,
	FinishPartName: string,
	CheckpointNamePrefix: string,
	CheckpointNumberPadding: number,
	CheckpointNamingConvention: string,
	StartingCheckpointIndex: number,
	DefaultLapNumber: number,
}

local CheckpointConfig: CheckpointConfig = {
	CourseModelName = "RaceCourse",
	StartPartName = "Start",
	CheckpointsFolderName = "Checkpoints",
	FinishPartName = "Finish",
	CheckpointNamePrefix = "Checkpoint",
	CheckpointNumberPadding = 3,
	CheckpointNamingConvention = "Checkpoint_###, for example Checkpoint_001, Checkpoint_002",
	StartingCheckpointIndex = 0,
	DefaultLapNumber = 1,
}

return CheckpointConfig
