--!strict
local Parts = require(script.Parent.Parts)
local Mechanisms = require(script.Parent.Mechanisms)
local Landmarks = require(script.Parent.Landmarks)
local Sample = {}

function Sample.Build(parent: Instance, origin: Vector3, template: MeshPart): Model
	local sample = Parts.Model(parent, "S02_ThockySwitchworks")
	sample:SetAttribute("CandidateRevision", "KC_P1_C08")
	sample:SetAttribute("CourseId", "keyboard-circuit")
	sample:SetAttribute("Phase1Only", true)
	local function cf(x: number, y: number, z: number): CFrame return CFrame.new(origin + Vector3.new(x, y, z)) end
	local function bank(name: string, x: number, y: number, z: number, cols: number, rows: number, legend: string?): Model
		local unit = Parts.Bank(sample, name, template, cf(x, y, z), cols, rows, "Thocky", legend)
		Parts.Support(unit, cf(x, y, z), 7, Parts.Palette.Thocky[2])
		return unit
	end
	local cp1 = bank("CP1_Recovery", 0, 0, 0, 12, 12, "CP1")
	cp1:SetAttribute("CheckpointIndex", 1)
	cp1:SetAttribute("RespawnOffset", Vector3.new(-3, 3, 3))
	Parts.CheckpointFlag(cp1, cf(-6, 0, 6), "CP1")
	for i,step in {Vector3.new(20, 2, 0), Vector3.new(37, 4, -3), Vector3.new(54, 6, 0)} do
		bank("O03_EscStep" .. i, step.X, step.Y, step.Z, 10, 8, "Esc")
	end
	bank("H04_Approach", 69, 6, 0, 8, 10, "↓")
	Mechanisms.Foundry(sample, template, cf(96, 6, 0))
	local exit = bank("H04_CommonExit", 127, 6, 0, 10, 12, "→")
	exit:SetAttribute("BranchAfter", "H04")
	local function routeSign(parent: Instance, name: string, position: CFrame, text: string, color: Color3)
		local sign = Parts.Block(parent, name, Vector3.new(8, 2.8, .3), position * CFrame.Angles(0, math.pi / 2, 0), color, false)
		for _,face in {Enum.NormalId.Front, Enum.NormalId.Back} do Parts.Legend(sign, text, face, Color3.new(1, 1, 1)) end
		for _,gui in sign:GetChildren() do if gui:IsA("SurfaceGui") then gui.CanvasSize = Vector2.new(768, 256) end end
	end
	routeSign(exit, "NormalRouteSign", cf(128, 9, -6), "NORMAL\nLIFT + ENTER", Parts.Palette.Thocky[2])
	bank("H05_Departure", 145, 6, 0, 10, 10, "↑")
	Mechanisms.Lift(sample, template, cf(161, 6, 0))
	bank("H05_FixedExit", 177, 14, 0, 10, 10, "→")
	local enter = Parts.Model(sample, "O04_EnterHairpin")
	local enterStem = Parts.SpecialKey(enter, "EnterStem", cf(194, 14, 0), Vector3.new(13, 1.25, 20.8), "Thocky", "ENTER")
	local enterReturn = Parts.SpecialKey(enter, "EnterReturn", cf(183.6, 14, 7.8), Vector3.new(7.8, 1.25, 5.2), "Thocky", "↵")
	Parts.JoinSpecialKeys(enterStem, enterReturn)
	Parts.Support(enter, cf(194, 14, 0), 11)
	bank("O04_OffsetExit", 190, 14, 22, 10, 8, "ENTER")
	bank("O04_ReturnLanding", 174, 14, 27, 10, 8, "→")
	local expert = Parts.Model(sample, "X01_SwitchSpine")
	routeSign(expert, "ExpertMarker", cf(130, 9, 7), "EXPERT X01\nHARD JUMPS", Parts.Palette.Thocky[3])
	for i,p in {Vector3.new(135, 8, 10), Vector3.new(143, 10, 16), Vector3.new(136, 9, 24), Vector3.new(144, 11.5, 29)} do
		local landing = Parts.Model(expert, "SwitchLanding" .. i)
		local top = Parts.Key(landing, template, CFrame.new(origin + p + Vector3.new(0, -.425, 0)), "Thocky", 2, ({"[", "]", ",", "."})[i])
		top.Name, top.Size = "SwitchCap", Vector3.new(2.4, .85, 2.4)
		landing.PrimaryPart = top
		local contact = Parts.Block(landing, "KeyContact", Vector3.new(2.4, .25, 2.4), cf(p.X, p.Y - Parts.PressDepth - .125, p.Z), Parts.Charcoal)
		contact.Transparency = 1
		local link = Instance.new("ObjectValue")
		link.Name, link.Value, link.Parent = "PressKey", top, contact
		Parts.Block(landing, "SwitchStem", Vector3.new(1.3, 2.4, 1.3), cf(p.X, p.Y - 2, p.Z), Parts.Charcoal, false)
		Parts.Block(landing, "SwitchFoot", Vector3.new(1.5, .4, 1.5), cf(p.X, p.Y - 4, p.Z), Parts.Charcoal, false)
	end
	local merge = bank("BeforeCP2_MergeApron", 156, 14, 36, 12, 10, "→")
	merge:SetAttribute("ExpertRejoin", "X01")
	local cp2 = bank("CP2_Recovery", 156, 14, 54, 12, 12, "CP2")
	cp2:SetAttribute("CheckpointIndex", 2)
	cp2:SetAttribute("RespawnOffset", Vector3.new(-3, 3, 3))
	Parts.CheckpointFlag(cp2, cf(150, 14, 60), "CP2")
	Landmarks.Magazine(sample, cf(176, 1, -24), template)
	Landmarks.Rack(sample, cf(50, -5, -29), template)
	local proof = Parts.Model(parent, "H06_EarlyProof")
	Parts.Bank(proof, "CP2_DepartureDock", template, cf(0, 0, 100), 12, 12, "Clacky", "CP2")
	Mechanisms.Shuttle(proof, template, cf(16, 0, 100))
	Parts.Bank(proof, "ReceivingDock", template, cf(56, 0, 100), 12, 12, "Clacky", "→")
	proof:SetAttribute("Phase1Only", true)
	proof:SetAttribute("RecoveryCheckpoint", "CP2")
	local comparisons = Parts.Model(parent, "FourFamilyAudioAudition")
	comparisons:SetAttribute("AudioStatus", "Actual recording candidates; final family selection pending")
	for i,family in {"Creamy", "Thocky", "Clacky", "Clicky"} do
		local strip = Parts.Bank(comparisons, family, template, cf((i - 1) * 13, 0, 130), 8, 6, family, family)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name, prompt.ActionText, prompt.ObjectText = "Audition", "Listen", family .. " candidate"
		prompt.MaxActivationDistance, prompt.HoldDuration = 10, 0
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("AuditionFamily", family)
		prompt.Parent = strip.PrimaryPart
	end
	return sample
end

return Sample
