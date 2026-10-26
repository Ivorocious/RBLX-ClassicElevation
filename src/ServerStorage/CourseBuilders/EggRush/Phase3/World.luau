--!nonstrict
local Plan=require(script.Parent.WorldPlan)
local Kit=require(script.Parent.WorldKit)
local RestStops=require(script.Parent.RestStops)
local World={Candidate="ER_P3_W06_C03",MeshAssetId=80825818781490}
local supersededArt={SortingShed=true,WorkshopBay=true,NurseryWallBay=true,MintPipeArch=true,MintArchWindow=true,PipeStraight=true}
local wallTints={
 Nursery=Color3.fromRGB(255,240,202),Sorting=Color3.fromRGB(235,216,177),
 Shellworks=Color3.fromRGB(235,216,177),Incubation=Color3.fromRGB(196,217,190),
 Rookery=Color3.fromRGB(153,181,150),Return=Color3.fromRGB(255,240,202),
}

function World.MeshLibrary()
 local existing=game.ServerStorage:FindFirstChild("EggRushPhase3Meshes")
 if existing then return existing end
 local library=game:GetService("InsertService"):LoadAsset(World.MeshAssetId)
 library.Name="EggRushPhase3Meshes"
 for _,p in library:GetDescendants()do
  assert(not p:IsA("LuaSourceContainer"),"World mesh library must contain geometry only")
  if p:IsA("BasePart")then p.Anchored=true;p.CanCollide=false;p.CanTouch=false end
 end
 library.Parent=game.ServerStorage
 return library
end

local function lighting(world)
 for _,path in {
  {"Nursery","FinishIntakeGallery"},{"Sorting","LoadingHall2"},
  {"Incubation","MonumentalIncubator"},{"Incubation","TrayServiceHall"},
  {"Rookery","EasternRookeryHall"},{"Return","ReturnNursery"},
 }do
  local building=world[path[1]][path[2]]
  for _,p in building:GetDescendants()do
   if p:IsA("BasePart")and p.Material==Enum.Material.Glass then
    local light=Instance.new("PointLight");light.Name="HatcheryWindowGlow"
    light.Color=Color3.fromRGB(255,226,172);light.Brightness=.6;light.Range=18;light.Shadows=false
    light.Parent=p;break
   end
  end
 end
end

local function galleryBoundary(course,world)
 local gallery=world.Nursery.FinishIntakeGallery
 local fall=course.FallZones.FallZone_Main
 local fallTop=fall.CFrame:PointToWorldSpace(Vector3.new(0,fall.Size.Y/2,0)).Y
 for _,part in {gallery.FloorUnderside,world.Nursery.GalleryFoundation_Stem,world.Nursery.GalleryFoundation_Collar}do
  local frame,size=part.CFrame,part.Size
  local top=frame.Position.Y+(math.abs(frame.RightVector.Y)*size.X+math.abs(frame.UpVector.Y)*size.Y+math.abs(frame.LookVector.Y)*size.Z)/2
  assert(top<fallTop-1,"Gallery floors must remain below the fall boundary")
 end
 local walls={RearWall=true,FrontLeftWall=true,FrontRightWall=true,FrontLintel=true,DoorRecessBack=true,DoorArch=true,DoorSpandrels=true}
 local count=0
 -- The return-side wall is reachable during an off-course fall; its trims must not become catch platforms.
 for _,part in gallery:GetChildren()do
  if not part:IsA("BasePart")then continue end
  if walls[part.Name]or part.Name:match("^DoorJamb")or part.Name:match("^SidePier")or part.Name:match("^RecessedWindow")or part.Name:match("^WindowHead")or part.Name=="FloorUnderside"then
   part.CanCollide,part.CanQuery=true,true
   part:SetAttribute("ERWorldRole",if part.Name=="FloorUnderside"then "BelowFallBoundaryFloor"else "VisibleSolidBoundary")
   count+=1
  end
 end
 world:SetAttribute("SolidGalleryBoundaryParts",count)
end

local function integrateExistingArt(course,world)
 local models,parts=0,0
 local referenced={}
 for _,object in course:GetDescendants()do
  if object:IsA("ObjectValue")and object.Value then referenced[object.Value]=true end
 end
 for _,model in course.Decoration.RevisionR02:GetChildren()do
  if not model:IsA("Model")or not supersededArt[model:GetAttribute("ERAsset")]then continue end
  assert(model:GetAttribute("ERArt")==true and not referenced[model],"Retain functional course art")
  for _,part in model:GetDescendants()do
   if not part:IsA("BasePart")then continue end
   assert(not part.CanCollide and not part.CanTouch and not part.CanQuery and not referenced[part]and part:GetAttribute("ERLethal")~=true,"Retain functional course geometry")
   part.Transparency=1
   parts+=1
  end
  models+=1
 end
 world:SetAttribute("SupersededArtModels",models)
 world:SetAttribute("SupersededArtParts",parts)
end

local function native(parent,row,pivot)
 local part=Instance.new(if row.Type=="Wedge"then "WedgePart"else "Part")
 part.Name=row.Id
 if row.Type=="Cylinder"then part.Shape=Enum.PartType.Cylinder end
 part.Size=row.Size
 part.CFrame=pivot*row.Frame*CFrame.new(0,row.Size.Y/2,0)
 part.Color=assert(Plan.Palette[row.Color])
 part.Material=Enum.Material.SmoothPlastic
 part.Anchored,part.CanCollide,part.CanTouch,part.CanQuery=true,false,false,false
 part.TopSurface,part.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 part:SetAttribute("ERWorldRole",row.Role)
 part:SetAttribute("ERPhase3Build",Plan.Revision)
 part.Parent=parent
 return part
end

function World.Apply(course,library)
 assert(course:GetAttribute("CandidateId")=="ER_P2_R05_C01","Apply world only to accepted Phase2")
 assert(not course.Decoration:FindFirstChild("HatcheryWorld"),"Preserve the installed world")
 library=library or World.MeshLibrary()
 Kit.setMeshLibrary(library)
 local world=Instance.new("Model");world.Name="HatcheryWorld"
 local pivot=course:GetPivot();world.WorldPivot=pivot
 world:SetAttribute("ERPhase3Build",Plan.Revision)
 world:SetAttribute("ERPurpose","Complete creature hatchery surrounding the accepted race")
 world.Parent=course.Decoration
 local count=0
 for _,district in Plan.Districts do
  local group=Instance.new("Model");group.Name=district.Id;group.WorldPivot=pivot
  group:SetAttribute("ERDistrict",district.Name)
  for _,row in Plan.Placements do
   if row.District~=district.Id then continue end
   local size=Kit.getSize(row.Type)
   local options={Name=row.Id,Role=row.Role,WallTint=wallTints[district.Id]}
   if row.Color~="cream"then options.Accent=assert(Plan.Palette[row.Color])end
   Kit.build(group,row.Type,pivot*row.Frame,row.Size/size,options)
   count+=1
  end
  for _,row in Plan.Native do
   if row.District==district.Id then native(group,row,pivot);count+=1 end
  end
  group.Parent=world
  task.wait()
 end
 world:SetAttribute("PlacementCount",count)
 world:SetAttribute("PerchFoundationParts",0)
 RestStops.Apply(course,world)
 galleryBoundary(course,world)
 lighting(world)
 integrateExistingArt(course,world)
 course:SetAttribute("CandidateId",World.Candidate)
 course:SetAttribute("WorldRevision",Plan.Revision)
 course:SetAttribute("Phase",3)
 course:SetAttribute("OwnerAcceptance","Phase3 W06 appearance accepted; focused technical follow-ups")
 return world
end

return World
