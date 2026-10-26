--!nonstrict
-- Read-only candidates; mesh bounding boxes do not prove rendered surface overlap or support.
local started = os.clock()
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "Inspect one frozen world in Edit mode")
local course = assert(workspace:FindFirstChild("Course_EggRush"), "Course_EggRush missing")
assert(course:GetAttribute("Phase") == 3, "Expected the installed Phase3 course")
local world = assert(course.Decoration:FindFirstChild("HatcheryWorld"), "HatcheryWorld missing")
local pivot = course:GetPivot()
local EPS, CELL, DEPTH, LIMIT = .005, 32, 24, 1500
local operations, nextYield, exhausted = 0, 1000, false
local budget = 800000
local function step()
 operations += 1
 if operations >= nextYield then nextYield += 1000; task.wait() end
 if operations > budget then exhausted = true; return false end
 return true
end

local function path(object)
 local names = {}
 while object ~= course do table.insert(names, 1, object.Name); object = object.Parent end
 return table.concat(names, ".")
end
local function point(v) return {v.X, v.Y, v.Z} end
local function unitFor(part)
 local object = part.Parent
 while object and object ~= world do
  if object:GetAttribute("ERPhase3Archetype") then return object end
  if object.Name == "PerchFoundations" then return object end
  object = object.Parent
 end
 return part
end
local function record(part, index, isWorld)
 local frame, half = pivot:ToObjectSpace(part.CFrame), part.Size / 2
 local r, u, l = frame.RightVector, frame.UpVector, frame.LookVector
 local e = Vector3.new(math.abs(r.X)*half.X + math.abs(u.X)*half.Y + math.abs(l.X)*half.Z,
  math.abs(r.Y)*half.X + math.abs(u.Y)*half.Y + math.abs(l.Y)*half.Z,
  math.abs(r.Z)*half.X + math.abs(u.Z)*half.Y + math.abs(l.Z)*half.Z)
 local function aligned(v) return math.max(math.abs(v.X), math.abs(v.Y), math.abs(v.Z)) > .999999 end
 local block = part:IsA("Part") and part.Shape == Enum.PartType.Block and aligned(r) and aligned(u) and aligned(l)
 local unit = if isWorld then unitFor(part) else part
 return {object=part, index=index, world=isWorld, name=path(part), unit=path(unit), unitObject=unit,
  role=part:GetAttribute("ERWorldRole") or "AcceptedOriginal", min=point(frame.Position-e), max=point(frame.Position+e),
  center=point(frame.Position), block=block, shape=if block then "ExactAxisAlignedBox" else "BoundsOnly",
  transparency=part.Transparency}
end

local rows, supportRows, skippedBoxes, worldCount = {}, {}, 0, 0
for _, object in world:GetDescendants() do
 if not object:IsA("BasePart") then continue end
 worldCount += 1
 assert(worldCount <= LIMIT, "World exceeds the 1000-part bounded inspection")
 local row = record(object, worldCount, true)
 table.insert(rows, row); table.insert(supportRows, row)
 if not row.block then skippedBoxes += 1 end
 if worldCount % 100 == 0 then task.wait() end
end
for _, object in course:GetDescendants() do
 if object:IsA("BasePart") and not object:IsDescendantOf(world) and object.Transparency < .95 then
  table.insert(supportRows, record(object, #supportRows+1, false))
  if #supportRows % 100 == 0 then task.wait() end
 end
end

local function key(x,y,z) return x..":"..y..":"..z end
local function gridFor(items)
 local grid = {}
 for i, row in items do
  for x=math.floor(row.min[1]/CELL),math.floor(row.max[1]/CELL) do
   for y=math.floor(row.min[2]/CELL),math.floor(row.max[2]/CELL) do
    for z=math.floor(row.min[3]/CELL),math.floor(row.max[3]/CELL) do
     local k=key(x,y,z); local bucket=grid[k]
     if not bucket then bucket={};grid[k]=bucket end
     table.insert(bucket,row)
    end
   end
  end
  if i % 100 == 0 then task.wait() end
 end
 return grid
end
local grid, supportGrid = gridFor(rows), gridFor(supportRows)
local function contains(row,p)
 return p[1] > row.min[1]+EPS and p[1] < row.max[1]-EPS
  and p[2] > row.min[2]+EPS and p[2] < row.max[2]-EPS
  and p[3] > row.min[3]+EPS and p[3] < row.max[3]-EPS
end
local function exposedSamples(a,b,axis,plane,sign,lo,hi)
 local other = {}; for i=1,3 do if i~=axis then table.insert(other,i) end end
 local visible, meshPossible = 0, false
 for _, s in {.25,.75} do for _,t in {.25,.75} do
  local p={0,0,0};p[axis]=plane+sign*.02
  p[other[1]]=lo[other[1]]+(hi[other[1]]-lo[other[1]])*s
  p[other[2]]=lo[other[2]]+(hi[other[2]]-lo[other[2]])*t
  local hidden=false
  local bucket=grid[key(math.floor(p[1]/CELL),math.floor(p[2]/CELL),math.floor(p[3]/CELL))] or {}
  for _,row in bucket do
   if not step() then break end
   if row~=a and row~=b and row.transparency<.05 and contains(row,p) then
    if row.block then hidden=true else meshPossible=true end
   end
  end
  if not hidden then visible+=1 end
 end end
 return visible,meshPossible
end

local cofaces, overlaps, seen = {}, {}, {}
local cofaceCount, hiddenCofaceCount, overlapCount, foundationPairs = 0,0,0,0
local function foundation(row)
 return row.role == "BelowCourseFoundation" or row.role == "BelowLethalBedrock" or row.role == "ConfinedSupportContinuation"
end
local function examine(a,b)
 local lo,hi,d={},{},{}
 for axis=1,3 do lo[axis]=math.max(a.min[axis],b.min[axis]);hi[axis]=math.min(a.max[axis],b.max[axis]);d[axis]=hi[axis]-lo[axis] end
 if d[1]<-EPS or d[2]<-EPS or d[3]<-EPS then return end
 if a.block and b.block and a.transparency<.95 and b.transparency<.95 then
  for axis=1,3 do
   local other={};for j=1,3 do if j~=axis then table.insert(other,j) end end
   local area=d[other[1]]*d[other[2]]
   if d[other[1]]<=EPS or d[other[2]]<=EPS or area<.05 then continue end
   for _,face in {{"min",-1},{"max",1}} do
    local plane=a[face[1]][axis]
    if math.abs(plane-b[face[1]][axis])>EPS then continue end
    local visible,meshPossible=exposedSamples(a,b,axis,plane,face[2],lo,hi)
    if visible==0 then hiddenCofaceCount+=1;continue end
    cofaceCount+=1
    table.insert(cofaces,{a=a.name,b=b.name,sameUnit=a.unit==b.unit,axis=({"X","Y","Z"})[axis],
     outward=face[2],plane=plane,area=area,visibleBoxSamples=visible,totalSamples=4,
     sameAppearance=a.object.Color==b.object.Color and a.object.Material==b.object.Material,
     meshMayOcclude=meshPossible,classification="SameFacingBoxFaceCandidate"})
   end
  end
 end
 if a.unit~=b.unit and d[1]>EPS and d[2]>EPS and d[3]>EPS then
  overlapCount+=1
  if foundation(a) or foundation(b) then foundationPairs+=1;return end
  local first,second=a,b;if first.unit>second.unit then first,second=second,first end
  local groupKey=first.unit.."|"..second.unit
  local volume=d[1]*d[2]*d[3]
  local group=overlaps[groupKey]
  if not group then group={a=first.unit,b=second.unit,partPairs=0,maxBoundsVolume=0};overlaps[groupKey]=group end
  group.partPairs+=1
  if volume>group.maxBoundsVolume then
   group.maxBoundsVolume=volume;group.exampleA=first.name;group.exampleB=second.name
   group.depth=d;group.shapeA=first.shape;group.shapeB=second.shape
  end
 end
end
for _,bucket in grid do
 for i=1,#bucket-1 do for j=i+1,#bucket do
  if not step() then break end
  local a,b=bucket[i],bucket[j];if a.index>b.index then a,b=b,a end
  local pair=a.index..":"..b.index
  if not seen[pair] then seen[pair]=true;examine(a,b) end
 end if exhausted then break end end
 if exhausted then break end
end

local unitBases={}
for _,row in rows do
 local archetype=row.unitObject:GetAttribute("ERPhase3Archetype")
 local nativeTarget=row.unitObject==row.object and (row.object.Name:match("Column") or row.object.Name:match("Pilaster") or row.object.Name:match("Buttress") or row.object.Name:match("Planter"))
 if archetype or nativeTarget then
  local old=unitBases[row.unit]
  local area=(row.max[1]-row.min[1])*(row.max[3]-row.min[3])
  if not old or row.min[2]<old.min[2]-EPS or (math.abs(row.min[2]-old.min[2])<=EPS and area>old.baseArea) then
   row.baseArea=area;unitBases[row.unit]=row
  end
 end
end
local supportGaps, meshSupportChecks, belowIslandBase, inspectedBases = {},{},0,0
for unit,base in unitBases do
 if exhausted then break end
 if base.min[2]<-43.01 then belowIslandBase+=1;continue end
 inspectedBases+=1
 local samples={{base.center[1],base.min[2],base.center[3]}}
 if base.block then
  for _,sx in {.15,.85} do for _,sz in {.15,.85} do
   table.insert(samples,{base.min[1]+(base.max[1]-base.min[1])*sx,base.min[2],base.min[3]+(base.max[3]-base.min[3])*sz})
  end end
 end
 local misses,bestGap,examples,meshBounded=0,0,{},false
 for _,p in samples do
  local best,top=nil,-math.huge;local candidates={}
  for y=math.floor((p[2]-DEPTH)/CELL),math.floor((p[2]+EPS)/CELL) do
   for _,row in supportGrid[key(math.floor(p[1]/CELL),y,math.floor(p[3]/CELL))] or {} do candidates[row]=true end
  end
  for row in candidates do
   if not step() then break end
   if row.unit==unit or row.transparency>=.95 or p[1]<row.min[1]-EPS or p[1]>row.max[1]+EPS or p[3]<row.min[3]-EPS or p[3]>row.max[3]+EPS then continue end
   if row.min[2]<=p[2]+EPS and row.max[2]>=p[2]-DEPTH then
    local contactTop=math.min(row.max[2],p[2])
    if contactTop>top then best,top=row,contactTop end
   end
  end
  local gap=if best then p[2]-top else DEPTH
  if best and not best.block then meshBounded=true end
  if gap>.08 then
   misses+=1;bestGap=math.max(bestGap,gap)
   if #examples<2 then table.insert(examples,{sample=p,nearest=if best then best.name else "NoneWithin24",gap=gap,shape=if best then best.shape else "Unknown"}) end
  end
 end
 if misses>0 then table.insert(supportGaps,{unit=unit,base=base.name,baseY=base.min[2],samples=#samples,unsupportedBoundsSamples=misses,
  maximumGap=bestGap,examples=examples,baseShape=base.shape,classification="SupportGapCandidate"}) end
 if meshBounded and #meshSupportChecks<30 then table.insert(meshSupportChecks,{unit=unit,base=base.name,classification="BoundsSupportNeedsRenderedMeshCheck"}) end
end

local overlapList={};for _,row in overlaps do table.insert(overlapList,row) end
local cofaceGroupMap={}
local function faceKind(name)
 local leaf=name:match("[^%.]+$")
 for _,kind in {"_Footing","_Stem","_Collar","SidePier","DoorJamb","ArchJamb","WindowSill","WindowHead"} do
  if name:find(kind,1,true) then return kind end
 end
 return leaf
end
for _,row in cofaces do
 local a,b=faceKind(row.a),faceKind(row.b);if a>b then a,b=b,a end
 local region=if row.axis=="Y" and row.plane < -43 then "LowerBase" else "Other"
 local k=table.concat({a,b,row.axis,tostring(row.sameUnit),tostring(row.sameAppearance),region},"|")
 local group=cofaceGroupMap[k]
 if not group then
  group={kindA=a,kindB=b,axis=row.axis,sameUnit=row.sameUnit,sameAppearance=row.sameAppearance,region=region,
   count=0,maxArea=0,meshMayOccludeCount=0,examples={}}
  cofaceGroupMap[k]=group
 end
 group.count+=1;group.maxArea=math.max(group.maxArea,row.area)
 if row.meshMayOcclude then group.meshMayOccludeCount+=1 end
 if #group.examples<2 then table.insert(group.examples,{a=row.a,b=row.b,plane=row.plane,outward=row.outward}) end
end
local cofaceGroups={};for _,row in cofaceGroupMap do table.insert(cofaceGroups,row) end
table.sort(cofaceGroups,function(a,b)
 if a.sameAppearance~=b.sameAppearance then return not a.sameAppearance end
 if a.count~=b.count then return a.count>b.count end
 return a.maxArea>b.maxArea
end)
table.sort(cofaces,function(a,b)return a.area>b.area end)
table.sort(overlapList,function(a,b)return a.maxBoundsVolume>b.maxBoundsVolume end)
table.sort(supportGaps,function(a,b)return a.maximumGap>b.maximumGap end)
local function limited(rows,n)
 local result={};for i=1,math.min(#rows,n) do table.insert(result,rows[i]) end
 return result
end
return {inspector="ER_WORLD_JOINS_READONLY_A02",candidate=course:GetAttribute("CandidateId"),build=world:GetAttribute("ERPhase3Build"),
 worldParts=worldCount,exactBoxes=worldCount-skippedBoxes,meshOrRotatedBounds=skippedBoxes,operations=operations,budgetExhausted=exhausted,
 complete=not exhausted,seconds=os.clock()-started,cofaceCount=cofaceCount,boxOccludedCofaceCount=hiddenCofaceCount,
 sameFacingBoxFaceCandidates=limited(cofaces,800),cofaceListTruncated=#cofaces>800,
 cofaceGroups=limited(cofaceGroups,50),cofaceGroupCount=#cofaceGroups,cofaceGroupListTruncated=#cofaceGroups>50,
 interUnitOverlapPartPairs=overlapCount,foundationOverlapPairsKeptAsExpectedCandidates=foundationPairs,
 interUnitAabbGroups=limited(overlapList,40),overlapGroupCount=#overlapList,overlapListTruncated=#overlapList>40,
 supportBasesInspected=inspectedBases,belowIslandBasesSkipped=belowIslandBase,supportGapCount=#supportGaps,
 supportGapCandidates=limited(supportGaps,35),supportListTruncated=#supportGaps>35,meshSupportChecks=meshSupportChecks,
 limits={"All rows are candidates, not automatic defects or clearance.",
 "Same-facing cofaces use exact axis-aligned box faces and four outside samples; other meshes may hide them.",
 "Opposite-facing contact, such as a roof seated on a wall, is not reported as a duplicate exposed face.",
 "Inter-unit AABB overlap does not establish rendered mesh overlap; buried foundation pairs are counted separately.",
 "Support scans use one lowest part per unit and a24-stud downward bounds search; curved supports require actual rendered-shape inspection.",
 "Support inside another box may be intentional buried contact; partial overhang may be an intentional slab, not a floating object.",
 "Below-Y-43 island bases are intentionally excluded from ground-support requirements.",
 "No instances, properties, scripts, camera, gameplay, collision or source were changed."}}
