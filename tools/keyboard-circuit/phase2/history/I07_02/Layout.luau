--!strict
local Layout = {}
Layout.Revision = "KC_LAYOUT_P2_I07_02"
Layout.SourcePlan = "Owner October 8 final timing and redundant-bank pass"
Layout.Main = {"F00", "O01", "H02", "O02", "H03", "CP1", "O03", "H04", "H05", "O04", "CP2", "O05", "H06", "H07", "O06", "CP3", "O07", "H08", "H01", "O08", "F01"}
Layout.Sequences = {"O01", "H02", "O02", "H03", "O03", "H04", "H05", "O04", "O05", "H06", "H07", "O06", "O07", "H08", "H01", "O08"}
Layout.Branches = {
 {from = "O01", id = "X03", before = "CP1", skips = {"H02", "O02", "H03"}, family = "Creamy", recovery = "F00"},
 {from = "O03", id = "X01", before = "CP2", skips = {"H04", "H05", "O04"}, family = "Thocky", recovery = "CP1"},
 {from = "O05", id = "X02", before = "CP3", skips = {"H06", "H07", "O06"}, family = "Clacky", recovery = "CP2"},
 {from = "O07", id = "X04", before = "F01", skips = {"H08", "H01", "O08"}, family = "Clicky", recovery = "CP3"},
}
Layout.Districts = {
 {id = "S01", name = "CreamyCloudbank", family = "Creamy", recovery = "F00", checkpoint = "CP1", sequences = {"O01", "H02", "O02", "H03"}},
 {id = "S02", name = "ThockySwitchworks", family = "Thocky", recovery = "CP1", checkpoint = "CP2", sequences = {"O03", "H04", "H05", "O04"}},
 {id = "S03", name = "ClackyCarriage", family = "Clacky", recovery = "CP2", checkpoint = "CP3", sequences = {"O05", "H06", "H07", "O06"}},
 {id = "S04", name = "ClickyRelay", family = "Clicky", recovery = "CP3", checkpoint = "F01", sequences = {"O07", "H08", "H01", "O08"}},
}
Layout.Nodes = {
 F00 = {-54, 0, -54, "Creamy"}, O01 = {-8, 0, -54, "Creamy"},
 H02 = {12.25, 2, -103, "Creamy"}, O02 = {51.5, 2, -136, "Creamy"},
 H03 = {95, 2, -89, "Creamy"}, CP1 = {54, 2, -54, "Creamy"},
 O03 = {54, 2, -8, "Thocky"}, H04 = {109, 8, 12.25, "Thocky"},
 H05 = {157, 8, 44, "Thocky"}, O04 = {108, 16, 60, "Thocky"},
 CP2 = {54, 16, 54, "Thocky"}, O05 = {8, 16, 54, "Clacky"},
 H06 = {-12.25, 16, 100, "Clacky"}, H07 = {-63, 16, 140, "Clacky"},
 O06 = {-87, 16, 99, "Clacky"}, CP3 = {-54, 13, 54, "Clacky"},
 O07 = {-54, 13, 8, "Clicky"}, H08 = {-109, 9, -12.25, "Clicky"},
 H01 = {-139, 9, -58, "Clicky"}, O08 = {-92, 9, -86, "Clicky"},
 F01 = {-91, 0, -54, "Clicky"},
 X03 = {31, 1, -33, "Creamy"}, X01 = {33, 12, 31, "Thocky"},
 X02 = {-31, 14, 33, "Clacky"}, X04 = {-78, 6, -31, "Clicky"},
}
Layout.ForwardDirections = {
 F00 = {1, 0}, O01 = {1, 0}, H02 = {0, -1}, O02 = {1, 0}, H03 = {0, 1},
 CP1 = {0, 1}, O03 = {0, 1}, H04 = {1, 0}, H05 = {0, 1}, O04 = {-1, 0},
 CP2 = {-1, 0}, O05 = {-1, 0}, H06 = {0, 1}, H07 = {-1, 0}, O06 = {0, -1},
 CP3 = {0, -1}, O07 = {0, -1}, H08 = {-1, 0}, H01 = {0, -1}, O08 = {1, 0}, F01 = {1, 0},
}
Layout.BranchGeometry = {
 X03 = {landings = 5, lateralOffset = 1.2, edgeInset = 1.25, mergeLocalX = -8, mergeLocalZ = 14.25},
 X01 = {landings = 5, lateralOffset = 1.2, edgeInset = 1.25, mergeLocalX = -8, mergeLocalZ = 14.25},
 X02 = {landings = 5, lateralOffset = 1.2, edgeInset = 1.25, mergeLocalX = -8, mergeLocalZ = 14.25},
 X04 = {landings = 7, lateralOffset = 1.2, edgeInset = 1.25, mergeLocalX = -8, mergeLocalZ = 14.25},
}
Layout.CheckpointOrder = {"CP1", "CP2", "CP3", "F01"}
Layout.MovementBaseline = {walkSpeed = 16, jumpHeight = 7.2, useJumpPower = false, gravity = 196.2}
Layout.WorkingCapacity = 20
Layout.CapacityStatus = "Planning assumption; no crowd capacity proof"
Layout.TargetLaps = 3
Layout.TargetRaceSeconds = {240, 360}
Layout.TargetExpertRaceSeconds = {120, 180}
Layout.PacingStatus = "Separate I07 pass; continuous timing pending"

function Layout.NodePosition(id: string, origin: Vector3): Vector3
 local node = assert(Layout.Nodes[id], "Unknown route node " .. id)
 return origin + Vector3.new(node[1], node[2], node[3])
end
function Layout.NodeFrame(id: string, origin: Vector3): CFrame
 local heading = assert(Layout.ForwardDirections[id])
 local delta = Vector3.new(heading[1], 0, heading[2])
 return CFrame.fromMatrix(Layout.NodePosition(id, origin), delta, Vector3.yAxis, delta:Cross(Vector3.yAxis))
end
return Layout
