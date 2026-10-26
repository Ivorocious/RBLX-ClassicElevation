--!nonstrict
local Foundations = {Revision="ER_P3_PERCH_FOUNDATIONS_A01"}
local V=Vector3.new
local importCorrection=CFrame.Angles(0,math.pi,0)

-- These broad runs remain below the lethal floor; upper extensions retain each original rock's footprint.
local beds={
 {id="NurseryBedrock",x=-75,z=84,width=170,depth=125,top=-38},
 {id="SortingBedrock",x=-128,z=-36,width=150,depth=170,top=-40},
 {id="ShellworksBedrock",x=-35,z=-115,width=220,depth=125,top=-40},
 {id="TrayBedrock",x=86,z=-58,width=180,depth=140,top=-42},
 {id="RookeryBedrock",x=124,z=35,width=145,depth=155,top=-38},
 {id="ReturnBedrock",x=86,z=124,width=150,depth=140,top=-40},
 {id="StartBedrock",x=-6,z=100,width=110,depth=96,top=-42},
}

local function vector(value) return {value.X,value.Y,value.Z} end

local function location(object,root)
 local path={}
 while object~=root do table.insert(path,1,object.Name);object=object.Parent end
 return table.concat(path,".")
end

local function collect(course,includeNormal)
 local revision=assert(course.Decoration:FindFirstChild("RevisionR02"),"Current R05 decoration required")
 local landing=assert(revision:FindFirstChild("LandingBases"),"Current static landing bases required")
 local world=course.Decoration:FindFirstChild("HatcheryWorld")
 local pivot=course:GetPivot()
 local rows={}
 local summary={major=0,ordinaryNormal=0,excludedExpert=0,selected=0,bedrock=7,rows={}}
 local selected={}
 for _,part in course.Decoration:GetDescendants() do
  if not part:IsA("MeshPart") or part.Name~="ER_BareRock__Rock" or (world and part:IsDescendantOf(world)) then continue end
  local model=part.Parent
  local isLanding=model and model.Parent==landing
  local expert=isLanding and model.Name:match("^E%d_")~=nil
  if expert then summary.excludedExpert+=1;continue end
  local ordinary=isLanding and model.Name:match("^S%d_")~=nil
  if ordinary then summary.ordinaryNormal+=1 else summary.major+=1 end
  if ordinary and not includeNormal then continue end
  local localFrame=pivot:ToObjectSpace(part.CFrame)
  assert(localFrame.UpVector.Y>.99,"Inspect tilted support before extension: "..part:GetFullName())
  local half=part.Size/2
  local axisY=math.abs(localFrame.RightVector.Y)*half.X+math.abs(localFrame.UpVector.Y)*half.Y+math.abs(localFrame.LookVector.Y)*half.Z
  local originalBottom=localFrame.Position.Y-axisY
  local row={
   original=part,path=location(part,course),ordinary=ordinary,
   frame=localFrame,x=localFrame.Position.X,z=localFrame.Position.Z,
   width=part.Size.X*.92,depth=part.Size.Z*.92,
   bottom=-58,top=originalBottom+1.5,originalBottom=originalBottom,
  }
  assert(row.top>row.bottom,"Support is already beneath the proposed bedrock")
  table.insert(selected,row)
 end
 table.sort(selected,function(a,b)
  if a.z~=b.z then return a.z<b.z end
  if a.x~=b.x then return a.x<b.x end
  return a.path<b.path
 end)
 for index,row in selected do
  row.id=string.format("PerchFoundation_%03d",index)
  table.insert(rows,row)
  table.insert(summary.rows,{
   id=row.id,source=row.path,kind=if row.ordinary then "OrdinaryNormal" else "MajorSupport",
   position={row.x,row.originalBottom,row.z},originalSize=vector(row.original.Size),
   extensionSize={row.width,row.top-row.bottom,row.depth},extensionBottom=row.bottom,extensionTop=row.top,
  })
 end
 summary.selected=#rows
 summary.plannedAddedParts=#rows+#beds
 summary.mode=if includeNormal then "MajorAndOrdinaryNormal" else "MajorOnly"
 summary.measurements="Actual supplied course MeshPart transforms and sizes; imported collision shape and visible undersides still need native inspection."
 return rows,summary
end

function Foundations.Inspect(course,options)
 local _,summary=collect(course,options and options.IncludeNormal==true)
 return summary
end

local function cloneRock(source,parent,name,size,frame,color,role)
 local part=source:Clone()
 part:ClearAllChildren()
 part.Name,part.Size,part.CFrame=name,size,frame*importCorrection
 part.Color,part.Material=color,Enum.Material.SmoothPlastic
 part.Anchored,part.CanCollide,part.CanTouch,part.CanQuery=true,false,false,false
 part.Transparency,part.CastShadow=0,true
 part.TopSurface,part.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 part:SetAttribute("ERWorldRole",role)
 part:SetAttribute("ERPhase3Build",Foundations.Revision)
 part.Parent=parent
 return part
end

-- Returns an unparented optional component so the controller can inspect it before installation.
function Foundations.Build(course,library,options)
 options=options or {}
 local rows,summary=collect(course,options.IncludeNormal==true)
 local rock=assert(library and library:FindFirstChild("ERW_RockLobe",true),"Use the verified Phase3 RockLobe import")
 assert(rock:IsA("MeshPart"),"ERW_RockLobe must be the imported MeshPart")
 local pivot=course:GetPivot()
 local model=Instance.new("Model")
 model.Name="PerchFoundations"
 model.WorldPivot=pivot
 model:SetAttribute("ERPhase3Build",Foundations.Revision)
 model:SetAttribute("ERWorldRole","BelowCourseFoundation")
 model:SetAttribute("FoundationMode",summary.mode)
 local lowerGroup=Instance.new("Folder");lowerGroup.Name="BelowLethalBedrock";lowerGroup.Parent=model
 local upperGroup=Instance.new("Folder");upperGroup.Name="ConfinedSupportExtensions";upperGroup.Parent=model
 for index,bed in beds do
  local bottom=-64
  local part=cloneRock(rock,lowerGroup,bed.id,V(bed.width,bed.top-bottom,bed.depth),
   pivot*CFrame.new(bed.x,(bed.top+bottom)/2,bed.z),
   Color3.fromRGB(105+index%3*3,111+index%3*3,123+index%3*3),"BelowLethalBedrock")
  part:SetAttribute("LethalFloorLocalTop",-18)
 end
 for _,row in rows do
  local rotation=row.frame.Rotation
  local part=cloneRock(rock,upperGroup,row.id,V(row.width,row.top-row.bottom,row.depth),
   pivot*CFrame.new(row.x,(row.top+row.bottom)/2,row.z)*rotation,
   row.original.Color:Lerp(Color3.fromRGB(101,108,120),.14),"ConfinedSupportContinuation")
  part:SetAttribute("FoundationSource",row.path)
  part:SetAttribute("FoundationSourceSize",row.original.Size)
  part:SetAttribute("FoundationSourceBottom",row.originalBottom)
  part:SetAttribute("FoundationTopOverlap",1.5)
 end
 local actualAdded=0
 for _,item in model:GetDescendants() do if item:IsA("BasePart") then actualAdded+=1 end end
 summary.actualAddedParts=actualAdded
 local existingWorld=course.Decoration:FindFirstChild("HatcheryWorld")
 local existingCount=0
 if existingWorld then for _,item in existingWorld:GetDescendants() do if item:IsA("BasePart") then existingCount+=1 end end end
 summary.existingWorldParts=existingCount
 summary.resultingWorldParts=existingCount+actualAdded
 summary.nativeMaximumBudget=1000
 summary.withinNativeMaximumBudget=summary.resultingWorldParts<=summary.nativeMaximumBudget
 model:SetAttribute("ActualAddedParts",actualAdded)
 model:SetAttribute("ExistingWorldParts",existingCount)
 model:SetAttribute("ResultingWorldParts",summary.resultingWorldParts)
 model:SetAttribute("NativeMaximumBudget",1000)
 summary.installation="Unparented optional model; nothing has been installed or accepted."
 summary.requiredNativeChecks={
  "Verify each confined top overlaps its original stone without an exposed new shelf.",
  "Verify every foot intersects the actual faceted lower bed, not only its bounding box.",
  "Inspect high tray/CP3 support proportions and the shell/roost undersides from player height and while falling.",
  "Run current scenery corridor and noncolliding-ledge checks after parenting inside HatcheryWorld.",
 }
 return model,summary
end

return Foundations
