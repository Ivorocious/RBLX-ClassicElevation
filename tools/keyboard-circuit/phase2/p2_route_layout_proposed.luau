--!strict
local Layout = {}
Layout.Revision = "KC_LAYOUT_P2_03"
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
	F00 = {-144, 0, 149, "Creamy"}, O01 = {-168, 0, 96.5, "Creamy"},
	H02 = {-168, 1, 19.5, "Creamy"}, O02 = {-169.5, 2, -36, "Creamy"},
	H03 = {-108, 4, -87, "Creamy"}, CP1 = {-54, 5, -120, "Creamy"},
	O03 = {0, 7, -126, "Thocky"}, H04 = {63, 9, -115.5, "Thocky"},
	H05 = {126, 15, -84, "Thocky"}, O04 = {177, 15, -40.5, "Thocky"},
	CP2 = {204, 15, 4.5, "Thocky"}, O05 = {201, 15, 54, "Clacky"},
	H06 = {163.5, 15, 102, "Clacky"}, H07 = {108, 15, 136.5, "Clacky"},
	O06 = {46.5, 13, 165, "Clacky"}, CP3 = {-9, 11, 162, "Clacky"},
	O07 = {-46.5, 10, 148.5, "Clicky"}, H08 = {-60, 7, 74.5, "Clicky"},
	H01 = {-83.5, 4, 2, "Clicky"}, O08 = {-128, 2, 60, "Clicky"},
	F01 = {-93, 0, 115.5, "Clicky"}, X01 = {70, 11, 0, "Thocky"}, X02 = {33, 13, 110, "Clacky"},
}
-- These headings keep adjacent decks apart and joins outside the H01 refuge.
Layout.ForwardDirections = {O03 = {2, 1}, H06 = {-1, 0}, CP3 = {-1, 0}, H01 = {-23.5, -72.5}, CP2 = {3, 4}}
Layout.CheckpointOrder = {"CP1", "CP2", "CP3", "F01"}
Layout.MovementBaseline = {walkSpeed = 16, jumpHeight = 7.2, useJumpPower = false, gravity = 196.2}
Layout.WorkingCapacity = 20
Layout.CapacityStatus = "Planning assumption; no crowd capacity proof"
Layout.TargetLaps = 3
Layout.TargetRaceSeconds = {240, 300}
Layout.PacingStatus = "Tuning target; no human full-race measurement"

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
