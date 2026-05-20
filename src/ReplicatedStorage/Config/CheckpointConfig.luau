--!strict

export type CheckpointConfig = {
	CourseModelName: string,
	StartPartName: string,
	CheckpointsFolderName: string,
	FinishPartName: string,
	CheckpointNamePrefix: string,
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
	CheckpointNamingConvention = "Checkpoint<number>, for example Checkpoint1, Checkpoint2",
	StartingCheckpointIndex = 0,
	DefaultLapNumber = 1,
}

return CheckpointConfig
