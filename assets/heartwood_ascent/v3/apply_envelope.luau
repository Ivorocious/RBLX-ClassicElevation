local library=game.ServerStorage.AssetLibraries.HeartwoodV1HA04
assert(library:GetAttribute('State')=='Complete')
local manifest=loadstring(game.ServerStorage.CourseBuilders.HeartwoodAscent.ArtManifest.Source)()
local archive=Instance.new('Folder');archive.Name='HA04HollowBeforeEnvelopeFitPlaced';archive.Parent=game.ServerStorage.HeartwoodBuildHistory
local course=workspace.Course_HeartwoodAscent
local count=0
for _,old in course.Decoration.HeartwoodArt.HollowTrunk:GetDescendants() do
 if old:IsA('MeshPart') then
  local name=old:GetAttribute('ArtAsset')
  if name and name:match('^HA_Hollow') then
   local data=manifest[name];local p=library[name]:Clone();local offset=old:GetAttribute('AssemblyOffset') or Vector3.zero
   p.Name=old.Name;p.Size=data.size;p.CFrame=CFrame.new(Vector3.new(4200,80,0)+offset+data.center)*CFrame.Angles(0,math.pi,0)
   p.PivotOffset=CFrame.identity;p.TextureID=data.texture;p.CanCollide=old.CanCollide;p.CanQuery=old.CanQuery;p.CanTouch=false
   p.CustomPhysicalProperties=old.CurrentPhysicalProperties;p.Material=Enum.Material.Wood
   for k,v in old:GetAttributes() do p:SetAttribute(k,v) end
   p:SetAttribute('ArtTriangles',data.triangles);p.Parent=old.Parent
   if old.Parent.PrimaryPart==old then old.Parent.PrimaryPart=p end
   old.Parent=archive;count+=1
  end
 end
end
return {updatedHollowMeshes=count,triangles=course:GetAttribute('ArtTriangles'),build=course:GetAttribute('HeartwoodBuild')}
