--!strict
assert(game.PlaceId==85558151074819,"Keyboard Circuit target must be Obby Tournament")
assert(not game:GetService("RunService"):IsRunning(),"Build in Edit mode")
local storage=game:GetService("ServerStorage")
assert(not workspace:FindFirstChild("KeyboardCircuit_P1_C06"),"C06 already exists; inspect it before rebuilding")
local archive=storage.DeveloperArchives.KeyboardCircuitP1_Archives
local old=workspace:FindFirstChild("KeyboardCircuit_P1_C05")
if old then
	assert(old:GetAttribute("NativeBackupSHA256"),"Export C05 before archiving")
	old.Parent=archive
end
local root=Instance.new("Model")
root.Name="KeyboardCircuit_P1_C06"
root:SetAttribute("CourseId","keyboard-circuit")
root:SetAttribute("CandidateRevision","KC_P1_C06")
root:SetAttribute("Phase1Only",true)
root:SetAttribute("KCSessionEnabled",true)
local function snapshot(parent)
	local originals=storage.CourseBuilders.KeyboardCircuit
	assert(#originals:GetChildren()==10,"Inspect duplicate or missing Rojo sources before building")
	local folder=Instance.new("Folder")
	folder.Name,folder.Parent="SourceSnapshot",parent
	local names={}
	for _,original in originals:GetChildren() do
		assert(original:IsA("LuaSourceContainer") and not names[original.Name],"Duplicate or unexpected source")
		names[original.Name]=true
		local copy=Instance.new(original.ClassName)
		copy.Name,copy.Source=original.Name,original.Source
		if copy:IsA("BaseScript") then copy.Disabled=true end
		copy.Parent=folder
	end
	local config=Instance.new("ModuleScript")
	config.Name="ConfigSnapshot"
	config.Source=game:GetService("ReplicatedStorage").Config.KeyboardCircuitConfig.Source
	config.Parent=folder
	return folder
end
local source=snapshot(root)
local garden=Instance.new("Folder")
garden.Name,garden.Parent="StudGardenV2",root
storage.CourseBuilders.StudGardenV2.HazardClock:Clone().Parent=garden
local template=storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey",true)
assert(template and template:IsA("MeshPart"),"Verified K02 key import required")
require(source.Sample).Build(root,Vector3.new(2300,330,-1300),template)
require(source.RouteStudy).Build(root,Vector3.new(2300,330,-1850))
source.Session.Disabled=false
root.Parent=workspace
local kits=storage:FindFirstChild("CourseAssetKits")
if not kits then kits=Instance.new("Folder"); kits.Name,kits.Parent="CourseAssetKits",storage end
local previousKit=kits:FindFirstChild("KeyboardCircuit_EditableKit_K01")
if previousKit then
	assert(previousKit:GetAttribute("NativeBackupSHA256"),"Export the previous kit before archiving")
	previousKit.Name,previousKit.Parent="KeyboardCircuit_EditableKit_K01_C05_sources",archive
end
local kit=require(source.Kit).Build(kits,template)
snapshot(kit)
return {candidate=root.Name,descendants=#root:GetDescendants(),kit=kit:GetFullName(),kitDescendants=#kit:GetDescendants(),mesh=template.MeshId}
