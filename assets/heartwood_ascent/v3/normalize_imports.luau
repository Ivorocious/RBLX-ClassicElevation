local manifest = loadstring(game.ServerStorage.CourseBuilders.HeartwoodAscent.ArtManifest.Source)()
local libraries=game.ServerStorage.AssetLibraries
assert(not libraries:FindFirstChild("HeartwoodV1HA04"),"Preserve existing library")
local library=Instance.new("Folder");library.Name="HeartwoodV1HA04";library.Parent=libraries
library:SetAttribute("State","Creating")
task.spawn(function()
 local made=0
 local ok,err=pcall(function()
  for name,data in manifest do
   local source
   for _,pack in {"HeartwoodStructureHA04FormsExact","HeartwoodFoliageHA04FullCrowns","HeartwoodStructureHA04Clearance","HeartwoodStructureHA04","HeartwoodFoliageHA04Attached","HeartwoodFlowersHA03GroundedEntrance"} do
    local found=game.ServerStorage.AssetImports[pack]:FindFirstChild(name,true)
    if found and found.MeshId==data.mesh then source=found;break end
   end
   if not source then source=libraries.HeartwoodV1:FindFirstChild(name) end
   assert(source and source:IsA("MeshPart"),"Missing owned mesh "..name)
   local solid=data.package=="flowers" or name:match("^HA_Forest") or data.package=="structure" and (name:match("^HA_Hollow") or name:match("^HA_Buttress") or name:match("^HA_Shelf") or name=="HA_RootSpan" or name=="HA_HeartwoodSocket" or name:match("^HA_Bough_0[0-3]$"))
   local p=if solid then game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(data.mesh),{CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition}) else source:Clone()
   p.Name=name;p.Size=data.size;p.CFrame=CFrame.new(data.center);p.PivotOffset=CFrame.identity
   p.TextureID=data.texture;p.Color=Color3.new(1,1,1);p.Material=Enum.Material.SmoothPlastic
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=library
   p:SetAttribute("ArtTriangles",data.triangles);made+=1;library:SetAttribute("Created",made)
  end
  local leaf=libraries.HeartwoodV1.HA_LeafCollisionChecked:Clone();leaf.Parent=library
 end)
 library:SetAttribute("State",if ok then "Complete" else "Failed");library:SetAttribute("Error",if ok then nil else tostring(err))
end)
return {library=library:GetFullName(),templates=61,asynchronous=true}
