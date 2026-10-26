--!strict
local Layout = {}
Layout.Revision = "KC_LAYOUT_P1_01"
Layout.Main = {"F00", "O01", "H02", "O02", "H03", "CP1", "O03", "H04", "H05", "O04", "CP2", "O05", "H06", "H07", "O06", "CP3", "O07", "H08", "H01", "O08", "F01"}
Layout.Branches = {{from = "H04", id = "X01", before = "CP2"}, {from = "H07", id = "X02", before = "CP3"}}
Layout.Nodes = {
	F00 = {-96, 0, 86, "Creamy"}, O01 = {-112, 0, 51, "Creamy"},
	H02 = {-112, 1, 13, "Creamy"}, O02 = {-103, 2, -24, "Creamy"},
	H03 = {-72, 4, -58, "Creamy"}, CP1 = {-36, 5, -80, "Creamy"},
	O03 = {0, 7, -84, "Thocky"}, H04 = {42, 9, -77, "Thocky"},
	H05 = {84, 15, -56, "Thocky"}, O04 = {118, 15, -27, "Thocky"},
	CP2 = {136, 15, 3, "Thocky"}, O05 = {134, 15, 36, "Clacky"},
	H06 = {109, 15, 68, "Clacky"}, H07 = {72, 15, 91, "Clacky"},
	O06 = {31, 13, 110, "Clacky"}, CP3 = {-6, 11, 108, "Clacky"},
	O07 = {-41, 10, 99, "Clicky"}, H08 = {-40, 7, 63, "Clicky"},
	H01 = {-52, 4, 26, "Clicky"}, O08 = {-72, 2, 51, "Clicky"},
	F01 = {-62, 0, 77, "Clicky"}, X01 = {62, 11, -27, "Thocky"},
	X02 = {22, 13, 78, "Clacky"},
}
Layout.MovementBaseline = {walkSpeed = 16, jumpHeight = 7.2, useJumpPower = false, gravity = 196.2}
Layout.WorkingCapacity = 20
Layout.TargetLaps = 3
return Layout
