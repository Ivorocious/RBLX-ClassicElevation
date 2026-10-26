--!strict
local Recover = {}

local TARGETS = {
 Original = "stud-garden-env01-before-install.rbxm",
 CandidateA = "stud-garden-env01-s02-native-b.rbxm",
}
local EXPECTED = "stud-garden-env01-s02-reviewed-b.rbxm"
local FIELDS = {"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","TopSurface","BottomSurface","Reflectance","CastShadow"}

function Recover.Run(backup: any, choice: string?, apply: boolean?): any
 assert(game.PlaceId == 85558151074819 and game:GetService("RunService"):IsStudio()
  and not game:GetService("RunService"):IsRunning(), "Intended Edit place required")
 local selected = choice or "Original"
 local filename = TARGETS[selected]
 assert(filename, "Unknown preserved recovery target")
 local live = workspace:FindFirstChild("Course_StudGarden") :: Model
 assert(live and live:GetAttribute("LayoutRevision") == "SG_LAYOUT_04"
  and live.Art:GetAttribute("EnvironmentRevision") == "SG_ENV_01_S02_B", "Reviewed native B required")
 local http = game:GetService("HttpService")
 local enabled = http.HttpEnabled
 local temporary = {}
 local okay, result = xpcall(function()
  http.HttpEnabled = true
  local function read(name: string): Model
   local data = http:GetAsync("http://127.0.0.1:8773/" .. name, true)
   local roots = game:GetService("SerializationService"):DeserializeInstancesAsync(buffer.fromstring(data))
   assert(#roots == 1 and roots[1]:IsA("Model"), "Recovery archive has unexpected roots")
   table.insert(temporary, roots[1])
   return roots[1] :: Model
  end
  local expected, target = read(EXPECTED), read(filename)
  local unchanged = backup.Compare({live}, {expected})
  local keep, pairsToRestore = {}, {}
  local function pair(original: Instance, current: Instance)
   assert(original.ClassName == current.ClassName and original.Name == current.Name,
    "Original art hierarchy is missing or changed")
   keep[current] = true
   table.insert(pairsToRestore, {original=original,current=current})
   local counts = {}
   for _, child in original:GetChildren() do
    counts[child.Name] = (counts[child.Name] or 0) + 1
    local matches = {}
    for _, candidate in current:GetChildren() do
     if candidate.Name == child.Name then table.insert(matches, candidate) end
    end
    local found = matches[counts[child.Name]]
    assert(found, "Original art instance is missing: " .. child:GetFullName())
    pair(child, found)
   end
  end
  pair(target.Art, live.Art)
  local additions, addedParts, removalRoots = 0,0,{}
  for _, object in live.Art:GetDescendants() do
   if not keep[object] then
    additions += 1
    if object:IsA("BasePart") then addedParts += 1 end
    if keep[object.Parent] then table.insert(removalRoots,object) end
   end
  end
  local report = {target=selected,source=filename,applied=apply == true,
   reviewedCandidateUnchanged=unchanged.verified,existingArtObjectsKept=#pairsToRestore,
   revisionAddedInstancesToRemove=additions,revisionAddedPartsToRemove=addedParts,
   originalInstancesDeleted=0,protectedObjectsEdited=0}
  if apply ~= true then return report end
  for _, item in pairsToRestore do
   local original, current = item.original,item.current
   if original:IsA("BasePart") then
    for _,field in FIELDS do (current :: any)[field] = (original :: any)[field] end
    if original:IsA("Part") then (current :: Part).Shape = original.Shape end
   end
   local attributes = original:GetAttributes()
   for key in current:GetAttributes() do if attributes[key] == nil then current:SetAttribute(key,nil) end end
   for key,value in attributes do current:SetAttribute(key,value) end
   if original:IsA("Model") then (current :: Model).WorldPivot = original.WorldPivot end
  end
  -- Only additions absent from the preserved target are removed after the live drift check.
  for _,object in removalRoots do object:Destroy() end
  report.verification = backup.Compare({live}, {target})
  return report
 end, debug.traceback)
 for _, root in temporary do root:Destroy() end
 http.HttpEnabled = enabled
 assert(okay,result)
 return result
end

return Recover
