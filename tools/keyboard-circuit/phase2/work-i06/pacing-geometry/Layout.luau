--!strict
local Layout = {}
Layout.Revision = "KC_LAYOUT_P2_I06_COMPACT_01"
Layout.SourcePlan = "keyboard-circuit.drawio R02"
Layout.Main = {"F00", "O01", "H02", "O02", "H03", "CP1", "O03", "H04", "H05", "O04", "CP2", "O05", "H06", "H07", "O06", "CP3", "O07", "H08", "H01", "O08", "F01"}
Layout.Sequences = {"O01", "H02", "O02", "H03", "O03", "H04", "H05", "O04", "O05", "H06", "H07", "O06", "O07", "H08", "H01", "O08"}
Layout.Branches = {{from = "H04", id = "X01", before = "CP2", skips = {"H05", "O04"}, family = "Thocky", recovery = "CP1"}, {from = "H07", id = "X02", before = "CP3", skips = {"O06"}, family = "Clacky", recovery = "CP2"}}
Layout.Districts = {
	{id = "S01", name = "CreamyCloudbank", family = "Creamy", recovery = "F00", checkpoint = "CP1", sequences = {"O01", "H02", "O02", "H03"}},
	{id = "S02", name = "ThockySwitchworks", family = "Thocky", recovery = "CP1", checkpoint = "CP2", sequences = {"O03", "H04", "H05", "O04"}},
	{id = "S03", name = "ClackyCarriage", family = "Clacky", recovery = "CP2", checkpoint = "CP3", sequences = {"O05", "H06", "H07", "O06"}},
	{id = "S04", name = "ClickyRelay", family = "Clicky", recovery = "CP3", checkpoint = "F01", sequences = {"O07", "H08", "H01", "O08"}},
}
-- These are editable schematic centers; constructor endpoints govern real joins.
Layout.Nodes = {
 F00 = {-185, 0, -135, "Creamy"}, O01 = {-127.9, 0, -135, "Creamy"},
 H02 = {-50.8, 1, -135, "Creamy"}, O02 = {26.3, 2, -135, "Creamy"},
 H03 = {98.4, 4, -135, "Creamy"}, CP1 = {151.3, 5, -135, "Creamy"},
 O03 = {151.3, 7, -81.8, "Thocky"}, H04 = {151.3, 9, -6.7, "Thocky"},
 H05 = {204, 15, 24.3, "Thocky"}, O04 = {220, 15, 70.4, "Thocky"},
 CP2 = {167, 15, 99.4, "Thocky"}, O05 = {113.8, 15, 99.4, "Clacky"},
 H06 = {52.4, 15, 99.4, "Clacky"}, H07 = {-28.7, 15, 99.4, "Clacky"},
 O06 = {-52.7, 13, 145.5, "Clacky"}, CP3 = {-111.2, 11, 129.4, "Clacky"},
 O07 = {-111.2, 10, 76.2, "Clicky"}, H08 = {-111.2, 7, 5.1, "Clicky"},
 H01 = {-111.2, 4, -68.7, "Clicky"}, O08 = {-195, 2, -95, "Clicky"},
 F01 = {-246, 0, -119, "Clicky"}, X01 = {185, 12, 65, "Thocky"}, X02 = {-74, 13, 88, "Clacky"},
}
Layout.ForwardDirections = {
 F00 = {1, 0}, O01 = {1, 0}, H02 = {1, 0}, O02 = {1, 0}, H03 = {1, 0},
 CP1 = {0, 1}, O03 = {0, 1}, H04 = {0, 1}, H05 = {1, 0}, O04 = {0, 1},
 CP2 = {-1, 0}, O05 = {-1, 0}, H06 = {-1, 0}, H07 = {-1, 0}, O06 = {0, 1},
 CP3 = {-1, 0}, O07 = {0, -1}, H08 = {0, -1}, H01 = {0, -1}, O08 = {-1, 0}, F01 = {-1, 0},
}
Layout.RecoveryOffsets = {
 F00 = Vector3.new(0, 0, -31), CP1 = Vector3.new(0, 0, -28.8),
 CP2 = Vector3.new(0, 0, -31), CP3 = Vector3.new(31.4, 0, 0),
}
Layout.BranchGeometry = {
 X01 = {spacing = 6.25, lateralOffset = 2.1, edgeInset = 1.25, mergeInset = 2.5, mergeLocalZ = 13},
 X02 = {spacing = 6.25, lateralOffset = 2.1, edgeInset = 1.25, mergeInset = 2.5, mergeLocalZ = 13},
}
Layout.CheckpointOrder = {"CP1", "CP2", "CP3", "F01"}
Layout.MovementBaseline = {walkSpeed = 16, jumpHeight = 7.2, useJumpPower = false, gravity = 196.2}
Layout.WorkingCapacity = 20
Layout.CapacityStatus = "Planning assumption; no crowd capacity proof"
Layout.TargetLaps = 3
Layout.TargetRaceSeconds = {240, 360}
Layout.TargetExpertRaceSeconds = {120, 180}
Layout.PacingStatus = "Offline compact candidate; target fit and human timing unproved"

function Layout.NodePosition(id: string, origin: Vector3): Vector3
	local node = assert(Layout.Nodes[id], "Unknown route node " .. id)
	return origin + Vector3.new(node[1], node[2], node[3])
end

function Layout.NodeFrame(id: string, origin: Vector3): CFrame
	local index = assert(table.find(Layout.Main, id), "Normal route node required")
	local from = Layout.NodePosition(id, origin)
	local to = Layout.NodePosition(Layout.Main[index % #Layout.Main + 1], origin)
	local override = Layout.ForwardDirections[id]
	local direction = if override then Vector3.new(override[1], 0, override[2]) else to - from
	local delta = Vector3.new(direction.X, 0, direction.Z).Unit
	return CFrame.fromMatrix(from, delta, Vector3.yAxis, delta:Cross(Vector3.yAxis))
end

return Layout
