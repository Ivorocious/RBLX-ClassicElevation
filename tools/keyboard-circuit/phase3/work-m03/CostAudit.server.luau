--!strict
assert(game.PlaceId==85558151074819)
local old=game.ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses.KeyboardCircuit_P2_I09_Experience03
local current=workspace.KeyboardCircuit_P3_M03_01
local function count(root: Instance)
	local result={parts=0,meshParts=0,pressableCaps=0,surfaceGuis=0,textLabels=0,scripts=0,sourceBytes=0,descendants=#root:GetDescendants()}
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") then result.parts+=1 end
		if item:IsA("MeshPart") then result.meshParts+=1 end
		if item:GetAttribute("Pressable") then result.pressableCaps+=1 end
		if item:IsA("SurfaceGui") then result.surfaceGuis+=1 end
		if item:IsA("TextLabel") then result.textLabels+=1 end
		if item:IsA("LuaSourceContainer") then result.scripts+=1;result.sourceBytes+=#item.Source end
	end
	return result
end
local before, after = count(old), count(current)
local art={parts=0,meshParts=0,collision=0,touch=0,query=0,press=0}
for _, item in current.MapEnvironment:GetDescendants() do
	if item:IsA("BasePart") then
		art.parts+=1
		if item:IsA("MeshPart") then art.meshParts+=1 end
		if item.CanCollide then art.collision+=1 end
		if item.CanTouch then art.touch+=1 end
		if item.CanQuery then art.query+=1 end
		if item:GetAttribute("Pressable") then art.press+=1 end
	end
end
assert(art.collision==0 and art.touch==0 and art.query==0 and art.press==0 and before.pressableCaps==after.pressableCaps)
return game.HttpService:JSONEncode({passed=true,candidate=current.Name,revision=current:GetAttribute("PrototypeRevision"),before=before,after=after,artwork=art,partIncreasePercent=(after.parts/before.parts-1)*100,pressTargetsUnchanged=true,newPerFrameArtworkWork=0,
	boundary="Comparable hierarchy inventory in the same native session. Geometry/source counts; all new artwork is anchored with no collision/touch/query/press targets and construction-only source. Extra surfaces and mesh instances remain a rendering cost. Counts do not establish FPS, memory, startup latency, GPU batching or device gains. Archived baseline scripts are disabled; active candidate includes transient runtime controls."})
