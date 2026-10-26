--!strict
local Parts = require(script.Parent.Parts)
local Surroundings = {}

function Surroundings.Build(parent: Instance, origin: Vector3): Model
	local world = Parts.Model(parent, "RoughSurroundings")
	world:SetAttribute("FinishPhase", 3)
	world:SetAttribute("Purpose", "Space, sightline and ordinary-camera checks")
	for _, data in {
		{"KeyboardRackMass", Vector3.new(-220, 13, -40), Vector3.new(12, 28, 54), Parts.Palette.Creamy[3]},
		{"MagazineMass", Vector3.new(90, 17, -183), Vector3.new(45, 35, 12), Parts.Palette.Thocky[2]},
		{"SplitShellMass", Vector3.new(248, 21, 75), Vector3.new(15, 44, 58), Parts.Palette.Clacky[2]},
		{"RotaryDialMass", Vector3.new(-5, 13, 244), Vector3.new(42, 28, 18), Parts.Palette.Clicky[2]},
	} do
		local model = Parts.Model(world, data[1])
		local block = Parts.Block(model, "SpaceReservation", data[3], CFrame.new(origin + data[2]), data[4])
		block:SetAttribute("Role", "SolidBlocker")
		block:SetAttribute("Phase3RoughMass", true)
		model.PrimaryPart = block
	end
	return world
end

return Surroundings
