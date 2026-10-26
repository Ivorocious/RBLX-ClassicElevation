--!strict
local Layout = {}
Layout.Revision = "KC_LAYOUT_P2_I09_03"
Layout.SourcePlan = "Owner October 8 Expert experience and checkpoint review"
Layout.Main = {"F00", "O01", "H02", "O02", "H03", "CP1", "O03", "H04", "H05", "O04", "CP2", "O05", "H06", "H07", "O06", "CP3", "O07", "H08", "H01", "O08", "F01"}
Layout.Sequences = {"O01", "H02", "O02", "H03", "O03", "H04", "H05", "O04", "O05", "H06", "H07", "O06", "O07", "H08", "H01", "O08"}
Layout.Branches = {
 {from = "H02", id = "X03", before = "CP1", skips = {"O02", "H03"}, family = "Creamy", recovery = "R1", name = "Stagger Cut", rejoins = "DISTRICT CHECKPOINT"},
 {from = "H06", id = "X02", before = "CP3", skips = {"H07", "O06"}, family = "Clacky", recovery = "R3", name = "Bracket Spine", rejoins = "DISTRICT CHECKPOINT"},
}
Layout.Districts = {
 {id = "S01", name = "CreamyCloudbank", family = "Creamy", recovery = "F00", checkpoint = "CP1", sequences = {"O01", "H02", "O02", "H03"}},
 {id = "S02", name = "ThockySwitchworks", family = "Thocky", recovery = "CP1", checkpoint = "CP2", sequences = {"O03", "H04", "H05", "O04"}},
 {id = "S03", name = "ClackyCarriage", family = "Clacky", recovery = "CP2", checkpoint = "CP3", sequences = {"O05", "H06", "H07", "O06"}},
 {id = "S04", name = "ClickyRelay", family = "Clicky", recovery = "CP3", checkpoint = "F01", sequences = {"O07", "H08", "H01", "O08"}},
}
Layout.Nodes = {
 F00 = {-54, 0, -54, "Creamy"}, O01 = {-8, 0, -54, "Creamy"},
 H02 = {12.25, 2, -103, "Creamy"}, O02 = {48.3, 2, -136, "Creamy"},
 H03 = {83, 2, -93, "Creamy"}, CP1 = {54, 2, -54, "Creamy"},
 O03 = {54, 2, -8, "Thocky"}, H04 = {101, 8, 12.25, "Thocky"},
 H05 = {142.3, 8, 44.75, "Thocky"}, O04 = {101.7, 16, 60.75, "Thocky"},
 CP2 = {54, 16, 54, "Thocky"}, O05 = {8, 16, 54, "Clacky"},
 H06 = {-12.25, 16, 87, "Clacky"}, H07 = {-53.25, 16, 127, "Clacky"},
 O06 = {-78.5, 16, 88.4, "Clacky"}, CP3 = {-54, 13, 54, "Clacky"},
 O07 = {-54, 13, 8, "Clicky"}, H08 = {-98, 9, -12.25, "Clicky"},
 H01 = {-128, 9, -57.25, "Clicky"}, O08 = {-109, 14.5, -99, "Clicky"},
 F01 = {-91, 23.5, -54, "Clicky"},
 X03 = {39, 2.4, -93, "Creamy"},
 X02 = {-43, 15.5, 87, "Clacky"},
}
Layout.ForwardDirections = {
 F00 = {1, 0}, O01 = {1, 0}, H02 = {0, -1}, O02 = {1, 0}, H03 = {0, 1},
 CP1 = {0, 1}, O03 = {0, 1}, H04 = {1, 0}, H05 = {0, 1}, O04 = {-1, 0},
 CP2 = {-1, 0}, O05 = {-1, 0}, H06 = {0, 1}, H07 = {-1, 0}, O06 = {0, -1},
 CP3 = {0, -1}, O07 = {0, -1}, H08 = {-1, 0}, H01 = {0, -1}, O08 = {1, 0}, F01 = {1, 0},
}
Layout.BranchGeometry = {
 X03 = {landings = 13, edgeInset = 1.25, mergeLocalX = -13.25, mergeLocalZ = 8,
  capLength = 1.7, capWidth = 1.7, offsets = {-1.3, 1.3, -.6, 1.8, -1.8, .4}, heights = {.15, .7, .2, 1, .3, .9}, legends = {"{", "}", "[", "]"}},
 X02 = {landings = 12, edgeInset = 1.25, mergeLocalX = -13.25, mergeLocalZ = -8,
  capLength = 2.2, capWidth = 1.45, offsets = {-.45, .65, .2, -.75}, heights = {.2, 1, .3, .65}, legends = {"[", "]"}},
}
Layout.RetryCheckpoints = {
 {id = "R1", after = "H02", requiresNextGate = "CP1", ordinal = 1, family = "Creamy"},
 {id = "R2", after = "H04", requiresNextGate = "CP2", ordinal = 3, family = "Thocky"},
 {id = "R3", after = "H06", requiresNextGate = "CP3", ordinal = 5, family = "Clacky"},
 {id = "R4", after = "H08", requiresNextGate = "F01", ordinal = 7, family = "Clicky"},
}
Layout.CheckpointCount = 7
Layout.CheckpointOrdinals = {CP1 = 2, CP2 = 4, CP3 = 6}
Layout.CheckpointOrder = {"CP1", "CP2", "CP3", "F01"}
Layout.MovementBaseline = {walkSpeed = 16, jumpHeight = 7.2, useJumpPower = false, gravity = 196.2}
Layout.ConnectorGapLimits = {levelOrDownhill = 6.25, uphill = 4.5}
Layout.WorkingCapacity = 20
Layout.CapacityStatus = "Planning assumption; no crowd capacity proof"
Layout.TargetLaps = 2
Layout.TargetRaceSeconds = {240, 360}
Layout.PreviousExpertRaceSeconds = {120, 180}
Layout.ExpertPacingPriority = "Owner chose experience preservation over the previous 2-3 minute target; clean Expert must save time against Normal"
Layout.PacingStatus = "Two optional Expert cuts preserve twelve encounters and six mechanisms; fresh measurement pending"
Layout.HorizontalScale = 1.5

function Layout.NodePosition(id: string, origin: Vector3): Vector3
 local node = assert(Layout.Nodes[id], "Unknown route node " .. id)
 return origin + Vector3.new(node[1] * Layout.HorizontalScale, node[2], node[3] * Layout.HorizontalScale)
end
function Layout.NodeFrame(id: string, origin: Vector3): CFrame
 local heading = assert(Layout.ForwardDirections[id])
 local delta = Vector3.new(heading[1], 0, heading[2])
 return CFrame.fromMatrix(Layout.NodePosition(id, origin), delta, Vector3.yAxis, delta:Cross(Vector3.yAxis))
end
return Layout

