--!nonstrict
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CheckWorld = {Revision="ER_P3_WORLD_CHECK_A04"}
local supersededArt={SortingShed=true,WorkshopBay=true,NurseryWallBay=true,MintPipeArch=true,MintArchWindow=true,PipeStraight=true}

local function point(value)
 return {value.X,value.Y,value.Z}
end

local function relative(object, root)
 if not object then return "nil" end
 if object == root then return "." end
 if not object:IsDescendantOf(root) then return object:GetFullName() end
 local names = {}
 while object ~= root do table.insert(names,1,object.Name); object=object.Parent end
 return table.concat(names,".")
end

local function bounds(part)
 local cf, half = part.CFrame, part.Size/2
 local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
 local extent=Vector3.new(
  math.abs(r.X)*half.X+math.abs(u.X)*half.Y+math.abs(l.X)*half.Z,
  math.abs(r.Y)*half.X+math.abs(u.Y)*half.Y+math.abs(l.Y)*half.Z,
  math.abs(r.Z)*half.X+math.abs(u.Z)*half.Y+math.abs(l.Z)*half.Z
 )
 return cf.Position-extent,cf.Position+extent
end

local function overlap(a,b,c,d)
 return a.X<d.X and b.X>c.X and a.Y<d.Y and b.Y>c.Y and a.Z<d.Z and b.Z>c.Z
end

local function closest(part, position, topOnly)
 local p=part.CFrame:PointToObjectSpace(position)
 local h=part.Size/2
 return part.CFrame:PointToWorldSpace(Vector3.new(
  math.clamp(p.X,-h.X,h.X),if topOnly then h.Y else math.clamp(p.Y,-h.Y,h.Y),math.clamp(p.Z,-h.Z,h.Z)
 ))
end

local function top(part)
 local value=part:GetAttribute("ERTop")
 return if typeof(value)=="Vector3" then value else part.CFrame:PointToWorldSpace(Vector3.new(0,part.Size.Y/2,0))
end

local function findPath(root,path)
 local matches={root}
 for name in path:gmatch("[^%.]+") do
  local nextMatches={}
  for _,parent in matches do for _,child in parent:GetChildren() do if child.Name==name then table.insert(nextMatches,child) end end end
  matches=nextMatches
 end
 return matches
end

-- The accepted BareRock is the closed three-ring primitive in world/build_environment.py.
local function rockSectionClearance(source,position)
 local p=source.CFrame:PointToObjectSpace(position)
 local t=p.Y/source.Size.Y+.5
 if t<=0 or t>=1 then return -1 end
 local function ring(width,depth,chamfer)
  local a,b,c=width/2,depth/2,math.min(width,depth)*chamfer
  local result={}
  for _,v in {{-a+c,-b},{a-c,-b},{a,-b+c},{a,b-c},{a-c,b},{-a+c,b},{-a,b-c},{-a,-b+c}} do
   table.insert(result,Vector2.new(v[1]/7*source.Size.X,v[2]/5.4*source.Size.Z))
  end
  return result
 end
 local lower,upper,alpha
 if t<=.52 then lower,upper,alpha=ring(7,5.4,.17),ring(7*.91,5.4*.94,.14),t/.52
 else lower,upper,alpha=ring(7*.91,5.4*.94,.14),ring(7*.82,5.4*.77,.12),(t-.52)/.48 end
 local section={}
 for index=1,8 do section[index]=lower[index]:Lerp(upper[index],alpha) end
 local clearance=math.min(t,1-t)*source.Size.Y
 local target=Vector2.new(p.X,p.Z)
 for index,a in section do
  local b=section[index%8+1]
  local edge,delta=b-a,target-a
  clearance=math.min(clearance,(edge.X*delta.Y-edge.Y*delta.X)/edge.Magnitude)
 end
 return clearance
end

-- Reconstructs the verified RockLobe's rendered cap and side planes, including the measured import rotation.
local function extensionGeometry(part)
 local rings={}
 local minX,minZ,maxX,maxZ=math.huge,math.huge,-math.huge,-math.huge
 for index=0,9 do
  local a=2*math.pi*index/10
  local factor=1+.075*math.sin(index*2.2)+.035*math.cos(index*4.4)
  local x,z=math.cos(a)*factor,math.sin(a)*factor
  minX,minZ,maxX,maxZ=math.min(minX,x),math.min(minZ,z),math.max(maxX,x),math.max(maxZ,z)
 end
 local renderFrame=part.CFrame*CFrame.Angles(0,math.pi,0)
 for _,profile in {{1,0},{.96,.38},{.80,1}} do
  local ring={}
  for index=0,9 do
   local a=2*math.pi*index/10
   local factor=1+.075*math.sin(index*2.2)+.035*math.cos(index*4.4)
   local x=profile[1]*math.cos(a)*factor
   local z=profile[1]*math.sin(a)*factor
   local normalized=Vector3.new((x-(minX+maxX)/2)/(maxX-minX),profile[2]-.5,(z-(minZ+maxZ)/2)/(maxZ-minZ))
   table.insert(ring,renderFrame:PointToWorldSpace(normalized*part.Size))
  end
  table.insert(rings,ring)
 end
 local maximumSideUpNormal=0
 for level=1,2 do for index=1,10 do
  local following=index%10+1
  local a,b,c=rings[level][index],rings[level][following],rings[level+1][index]
  local normal=(b-a):Cross(c-a).Unit
  maximumSideUpNormal=math.max(maximumSideUpNormal,math.abs(normal.Y))
 end end
 local samples,center={},Vector3.zero
 for _,vertex in rings[3] do table.insert(samples,vertex);center+=vertex end
 center/=10
 for index,a in rings[3] do table.insert(samples,a:Lerp(rings[3][index%10+1],.5)) end
 table.insert(samples,center)
 return samples,maximumSideUpNormal
end

local function jsonValue(value)
 local kind=typeof(value)
 if kind=="Vector3" then return point(value) end
 if kind=="CFrame" then return {value:GetComponents()} end
 if kind=="Color3" then return {value.R,value.G,value.B} end
 if kind=="EnumItem" then return tostring(value) end
 if kind=="number" or kind=="string" or kind=="boolean" or kind=="nil" then return value end
 return tostring(value)
end

local function compare(accepted,candidate,world)
 local output={ok=true,instances=0,parts=0,differences={},differenceCount=0,sourceUnreadable=0,allowedArtVisibilityChanges={},allowedPresentationChanges={}}
 local ignoredAttributes={CandidateId=true,Phase=true,WorldRevision=true,OwnerAcceptance=true}
 local function difference(path,property,a,b)
  output.ok=false
  output.differenceCount+=1
  if #output.differences<120 then table.insert(output.differences,{path=path,property=property,accepted=jsonValue(a),candidate=jsonValue(b)}) end
 end
 local function property(a,b,path,key)
  local oka,va=pcall(function() return a[key] end)
  local okb,vb=pcall(function() return b[key] end)
  local stopPad=a==accepted.Start
  for index=1,4 do stopPad=stopPad or a==accepted.Obstacles["CP"..index.."_Pocket"]end
  local post=a:IsA("BasePart")and a.Parent==accepted.StartPen.GateSupports and a.Name=="GatePost"
  local trigger=a:IsA("BasePart")and a.Parent==accepted.Checkpoints and a.Name:match("^Checkpoint_00[1-4]$")~=nil
  local oldLabel=a:IsA("SurfaceGui")and a.Parent and a.Parent.Parent==accepted.Checkpoints
  local allowed=key=="Color"and ((stopPad and vb==Color3.fromRGB(255,240,202))or(post and vb==Color3.fromRGB(104,205,176)))
   or key=="Transparency"and trigger and vb==1
   or key=="Enabled"and oldLabel and vb==false
  if oka and okb and va~=vb and allowed then
   table.insert(output.allowedPresentationChanges,{path=path,property=key,accepted=jsonValue(va),candidate=jsonValue(vb)})
   return
  end
  if key=="Transparency"and oka and okb and va~=vb and vb==1 and a:IsA("BasePart")then
   local model=a.Parent
   local art=accepted.Decoration:FindFirstChild("RevisionR02")
   while model and model.Parent~=art and model~=accepted do model=model.Parent end
   if model and model:IsA("Model")and model.Parent==art and model:GetAttribute("ERArt")==true and supersededArt[model:GetAttribute("ERAsset")]
    and not a.CanCollide and not a.CanTouch and not a.CanQuery and not b.CanCollide and not b.CanTouch and not b.CanQuery and a:GetAttribute("ERLethal")~=true then
    table.insert(output.allowedArtVisibilityChanges,{path=path,asset=model:GetAttribute("ERAsset"),accepted=va,candidate=vb})
    return
   end
  end
  if oka~=okb or (oka and va~=vb) then difference(path,key,if oka then va else "unreadable",if okb then vb else "unreadable") end
 end
 local function children(root)
  local result,counts={},{}
  for _,child in root:GetChildren() do
   if child==world then continue end
   local base=child.Name..":"..child.ClassName
   counts[base]=(counts[base] or 0)+1
   result[base.."#"..counts[base]]=child
  end
  return result
 end
 local visit
 visit=function(a,b,path)
  output.instances+=1
  if a.ClassName~=b.ClassName then difference(path,"ClassName",a.ClassName,b.ClassName);return end
  local aa,ba=a:GetAttributes(),b:GetAttributes()
  for key,value in aa do
   if not (a==accepted and ignoredAttributes[key]) and ba[key]~=value then difference(path,"Attribute:"..key,value,ba[key]) end
  end
  for key,value in ba do
   if aa[key]==nil and not (a==accepted and ignoredAttributes[key]) then difference(path,"Attribute:"..key,nil,value) end
  end
  if a:IsA("BasePart") then
   output.parts+=1
   for _,key in {"CFrame","Size","Color","Material","MaterialVariant","Transparency","Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","CastShadow","TopSurface","BottomSurface"} do property(a,b,path,key) end
   if a:IsA("Part") then property(a,b,path,"Shape") end
   if a:IsA("MeshPart") then
    for _,key in {"MeshId","TextureID","CollisionFidelity","DoubleSided"} do property(a,b,path,key) end
   end
  elseif a:IsA("SurfaceGui")then
   for _,key in {"Enabled","Face","CanvasSize","LightInfluence","SizingMode","ZOffset"}do property(a,b,path,key)end
  elseif a:IsA("TextLabel")then
   for _,key in {"Text","TextColor3","Font","TextScaled","BackgroundTransparency"}do property(a,b,path,key)end
  elseif a:IsA("Model") then
   if a:GetPivot()~=b:GetPivot() then difference(path,"Pivot",a:GetPivot(),b:GetPivot()) end
  elseif a:IsA("ObjectValue") then
   local av,bv=relative(a.Value,accepted),relative(b.Value,candidate)
   if av~=bv then difference(path,"ValueReference",av,bv) end
  elseif a:IsA("ValueBase") then property(a,b,path,"Value")
  elseif a:IsA("Attachment") then property(a,b,path,"CFrame")
  elseif a:IsA("LuaSourceContainer") then
   local oka,sa=pcall(function() return a.Source end)
   local okb,sb=pcall(function() return b.Source end)
   if oka and okb then
    if sa~=sb then difference(path,"Source","content differs; "..#sa.." characters","content differs; "..#sb.." characters") end
   else output.sourceUnreadable+=1 end
  end
  local ac,bc=children(a),children(b)
  for key,child in ac do
   if bc[key] then visit(child,bc[key],path.."/"..key) else difference(path.."/"..key,"Instance","present","missing") end
  end
  for key in bc do if not ac[key] then difference(path.."/"..key,"Instance","missing","present") end end
 end
 visit(accepted,candidate,"Course")
 output.allowedArtVisibilityChangeCount=#output.allowedArtVisibilityChanges
 output.allowedPresentationChangeCount=#output.allowedPresentationChanges
 output.allOriginalAppearanceUnchanged=output.allowedArtVisibilityChangeCount+output.allowedPresentationChangeCount==0
 return output
end

local function route(course,name)
 local folder=assert(course.Routes:FindFirstChild(name),"Missing current route "..name)
 local refs=folder:GetChildren()
 table.sort(refs,function(a,b) return a.Name<b.Name end)
 local result={}
 for _,ref in refs do
  assert(ref:IsA("ObjectValue") and ref.Value and ref.Value:IsA("BasePart"),"Invalid route reference "..ref:GetFullName())
  table.insert(result,{part=ref.Value,top=top(ref.Value),waitKind=ref:GetAttribute("WaitKind"),reference=ref.Name})
 end
 return result
end

-- Run in Edit against the preserved Phase2 model and the assembled candidate.
function CheckWorld.Run(accepted,candidate,neighbors,options)
 assert(RunService:IsStudio() and not RunService:IsRunning(),"CheckWorld requires stable Edit geometry")
 assert(accepted and accepted:IsA("Model") and candidate and candidate:IsA("Model") and accepted~=candidate,"Pass distinct accepted and candidate Models")
 assert(typeof(neighbors)=="table" and #neighbors>0,"Pass the actual unrelated neighbor Models explicitly")
 options=options or {}
 local world=assert(candidate.Decoration:FindFirstChild("HatcheryWorld"),"Assemble HatcheryWorld first")
 local report={
  complete=false,ok=false,checker=CheckWorld.Revision,build=world:GetAttribute("ERPhase3Build"),
  candidate=candidate:GetAttribute("CandidateId"),worldParts=0,queries=0,
  maximumQueries=math.clamp(options.MaximumQueries or 6500,2000,10000),
  hits={},hitCounts={},nearestScenery={},reachableLedges={},neighborBounds={},ledgeClassifications={},unresolvedReachableLedges={},
  limits={
   "Mesh overlap and ray results use the imported collision shape, which may differ from the visible triangles.",
   "Sampled body, jump and camera envelopes are conservative scenery checks; they are not human gameplay or full mechanism animation proof.",
   "A reachable-ledge warning needs visual judgment; role labels never clear a geometric warning.",
   "Source equality is checked only where Studio permits reading Source; sourceUnreadable reports every omitted script.",
   "Analytic cap containment uses the checked BareRock/RockLobe generator shapes and measured Y180 import correction; unknown mesh identities or failed source rays remain unresolved.",
   "Cloned-source rays use collision geometry. They supplement full rendered-cap containment; collision rays alone never prove an opaque mesh hides a cap.",
  },
 }
 report.preservation=compare(accepted,candidate,world)
 local fixture,probe,sourceFixture
 local success,failure=xpcall(function()
  fixture=world:Clone()
  fixture.Name="EggRushWorldQA_"..HttpService:GenerateGUID(false)
  local cloneParts,originalParts={},{}
  for _,part in world:GetDescendants() do
   if part:IsA("BasePart") then
    local path=relative(part,world)
    assert(not originalParts[path],"Ambiguous world part path "..path)
    originalParts[path]=part
   end
  end
  for _,item in fixture:GetDescendants() do
   if item:IsA("BasePart") then
    item.Anchored=true;item.CanCollide=false;item.CanTouch=false;item.CanQuery=true;item.Transparency=1
    table.insert(cloneParts,item)
   elseif item:IsA("BaseScript") then item.Disabled=true
   elseif item:IsA("LayerCollector")then item.Enabled=false end
  end
  local originalOf={}
  for _,part in cloneParts do originalOf[part]=assert(originalParts[relative(part,fixture)],"World fixture clone mismatch") end
  fixture.Parent=Workspace
  probe=Instance.new("Part");probe.Name="EggRushWorldQAProbe";probe.Anchored=true
  probe.CanCollide=false;probe.CanTouch=false;probe.CanQuery=false;probe.Transparency=1;probe.Parent=Workspace
  report.worldParts=#cloneParts
  local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={fixture};params.MaxParts=0;params.RespectCanCollide=false
  local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={fixture};rays.IgnoreWater=true;rays.RespectCanCollide=false
  local singleRay=RaycastParams.new();singleRay.FilterType=Enum.RaycastFilterType.Include;singleRay.IgnoreWater=true;singleRay.RespectCanCollide=false
  local budget=false
  local function allowance()
   if report.queries>=report.maximumQueries then budget=true;return false end
   report.queries+=1;return true
  end
  local function record(category,part,context,position,detail)
   report.hitCounts[category]=(report.hitCounts[category] or 0)+1
   if #report.hits>=180 then return end
   local original=originalOf[part]
   table.insert(report.hits,{category=category,scenery=relative(original or part,candidate),role=(original or part):GetAttribute("ERWorldRole"),context=context,position=point(position),detail=detail})
  end
  local function box(category,cf,size,context)
   if not allowance() then return end
   local broad=Workspace:GetPartBoundsInBox(cf,size,params)
   if #broad==0 then return end
   probe.CFrame,probe.Size=cf,size
   if not allowance() then return end
   local precise=Workspace:GetPartsInPart(probe,params)
   for _,part in precise do record(category,part,context,cf.Position,"Collision-shape overlap after bounding-box broad phase") end
  end
  local function ray(category,origin,direction,context)
   if not allowance() then return end
   local hit=Workspace:Raycast(origin,direction,rays)
   if hit then record(category,hit.Instance,context,hit.Position,"Camera line interrupted by scenery collision shape") end
  end

  local worldMin,worldMax=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
  for _,part in cloneParts do local lo,hi=bounds(part);worldMin=worldMin:Min(lo);worldMax=worldMax:Max(hi) end
  report.worldBounds={min=point(worldMin),max=point(worldMax)}
  for _,neighbor in neighbors do
   assert(neighbor:IsA("Model") and neighbor~=candidate and neighbor~=accepted and not neighbor:IsDescendantOf(candidate),"Neighbors must be unrelated actual Models")
   local row={name=neighbor:GetFullName(),parts=0,boundingCandidates=0,collisionHits=0}
   table.insert(report.neighborBounds,row)
   for _,part in neighbor:GetDescendants() do
    if not part:IsA("BasePart") then continue end
    row.parts+=1
    local lo,hi=bounds(part)
    if not overlap(lo,hi,worldMin,worldMax) then continue end
    if not allowance() then break end
    for _,scenery in Workspace:GetPartBoundsInBox(part.CFrame,part.Size,params) do
     row.boundingCandidates+=1
     record("NeighborBounds",scenery,neighbor:GetFullName()..":"..relative(part,neighbor),part.Position,"Actual rotated-part bounding boxes overlap; inspect visible mesh bounds")
    end
    probe.CFrame,probe.Size=part.CFrame,part.Size
    if not allowance() then break end
    for _,scenery in Workspace:GetPartsInPart(probe,params) do
     row.collisionHits+=1;record("NeighborShape",scenery,neighbor:GetFullName()..":"..relative(part,neighbor),part.Position,"Neighbor box intersects scenery collision shape")
    end
   end
  end

  local nearest,ledgeSeen,routeContexts={},{},{}
  local fallTop=options.FallTopY or (candidate:GetPivot().Position.Y-18)
  report.routeSamples={}
  for _,routeName in {"RevisionNormal","RevisionExpert"} do
   local nodes=route(candidate,routeName)
   report.routeSamples[routeName]=#nodes
   for index,node in nodes do
    if budget then break end
    local context=routeName..":"..node.reference..":"..relative(node.part,candidate)
    routeContexts[context]=node
    local p=node.top
    box("Standing",CFrame.new(p+Vector3.new(0,3,0)),Vector3.new(3.5,6,3.5),context)
    local nextNode=nodes[index+1]
    if nextNode then
     for step=1,7 do
      local t=step/8
      local jump=p:Lerp(nextNode.top,t)+Vector3.new(0,3+7*4*t*(1-t),0)
      box("Jump",CFrame.new(jump),Vector3.new(3.5,6,3.5),context.."->"..nextNode.reference)
     end
    end
    if node.waitKind=="Tray" then
     local mechanism=node.part:FindFirstAncestorOfClass("Model")
     local travel=mechanism and mechanism:GetAttribute("Travel")
     if typeof(travel)=="Vector3" then
      local worldTravel=mechanism:GetPivot():VectorToWorldSpace(travel)
      for step=0,8 do box("TraySweep",CFrame.new(p+worldTravel*(step/8)+Vector3.new(0,3,0)),Vector3.new(node.part.Size.X+2,6,node.part.Size.Z+2),context) end
     end
    end
    local previous=nodes[math.max(1,index-1)].top
    local forward=Vector3.new(p.X-previous.X,0,p.Z-previous.Z)
    if forward.Magnitude<.1 and nextNode then forward=Vector3.new(nextNode.top.X-p.X,0,nextNode.top.Z-p.Z) end
    forward=if forward.Magnitude>.1 then forward.Unit else candidate:GetPivot().LookVector
    local right=forward:Cross(Vector3.yAxis)
    local eye=p+Vector3.new(0,4.5,0)
    for _,offset in {-forward*12,forward*12,right*12,-right*12} do
     local camera=eye+offset+Vector3.new(0,4,0)
     box("CameraPosition",CFrame.new(camera),Vector3.new(2,2,2),context)
     ray("CameraLine",eye,camera-eye,context)
    end
    for _,drop in {7,14} do box("Falling",CFrame.new(p-Vector3.new(0,drop,0)),Vector3.new(4,6,4),context) end
    for _,part in cloneParts do
     local near=closest(part,p+Vector3.new(0,3,0),false)
     local distance=(near-(p+Vector3.new(0,3,0))).Magnitude
     local original=originalOf[part]
     local path=relative(original,candidate)
     if not nearest[path] or distance<nearest[path].distance then nearest[path]={scenery=path,distance=distance,route=context,role=original:GetAttribute("ERWorldRole"),nearest=point(near)} end
     if original.CanCollide or ledgeSeen[part] or part.CFrame.UpVector.Y<.85 or part.Size.X<2.5 or part.Size.Z<2.5 then continue end
     local surface=closest(part,p,true)
     local gap=Vector3.new(surface.X-p.X,0,surface.Z-p.Z).Magnitude
     local height=surface.Y-p.Y
     if gap>16 or height>8 or height< -18 or surface.Y<=fallTop then continue end
     if not allowance() then break end
     singleRay.FilterDescendantsInstances={part}
     local hit=Workspace:Raycast(surface+Vector3.new(0,3,0),Vector3.new(0,-6,0),singleRay)
     if hit and hit.Normal.Y>.65 and hit.Position.Y>fallTop then
      ledgeSeen[part]=true
      if #report.reachableLedges<100 then table.insert(report.reachableLedges,{scenery=path,route=context,gap=gap,height=hit.Position.Y-p.Y,surface=point(hit.Position),normal=point(hit.Normal),role=original:GetAttribute("ERWorldRole"),collide=original.CanCollide}) end
     end
    end
   end
  end
  for _,row in nearest do table.insert(report.nearestScenery,row) end
  table.sort(report.nearestScenery,function(a,b) return a.distance<b.distance end)
  while #report.nearestScenery>30 do table.remove(report.nearestScenery) end
  local sceneryByPath={}
  for _,part in cloneParts do local original=originalOf[part];sceneryByPath[relative(original,candidate)]=original end
  local library=game:GetService("ServerStorage"):FindFirstChild("EggRushPhase3Meshes")
  local verifiedLobe=library and library:FindFirstChild("ERW_RockLobe",true)
  local sourceClones={}
  sourceFixture=Instance.new("Folder");sourceFixture.Name="EggRushWorldQASources_"..HttpService:GenerateGUID(false);sourceFixture.Parent=Workspace
  local sourceRays=RaycastParams.new();sourceRays.FilterType=Enum.RaycastFilterType.Include;sourceRays.RespectCanCollide=false;sourceRays.IgnoreWater=true
  local function containedDeckTrim(extension,evidence)
   if not extension or not extension:IsA("Part")or extension.Shape~=Enum.PartType.Block
    or not world:FindFirstChild("RestStops")or not extension:IsDescendantOf(world.RestStops)
    or (extension.Name~="MintApron"and extension.Name~="HoneyReveal")then return false end
   local marking=extension.Parent:FindFirstChild("DeckMarking")
   local name=marking and marking:GetAttribute("TargetPad")
   local deck=if name=="Start"then candidate.Start else name and candidate.Obstacles:FindFirstChild(name)
   if not deck or not deck:IsA("Part")or deck.Shape~=Enum.PartType.Block or not deck.CanCollide or deck.Transparency~=0
    or deck.CFrame.UpVector.Y<.99 or extension.CFrame.UpVector.Y<.99 then return false end
   local cap,margin,gap={},math.huge,-math.huge
   for _,offset in {Vector3.new(-.5,.5,-.5),Vector3.new(.5,.5,-.5),Vector3.new(.5,.5,.5),Vector3.new(-.5,.5,.5),Vector3.new(0,.5,0)}do
    local p=extension.CFrame:PointToWorldSpace(offset*extension.Size)
    local localPoint=deck.CFrame:PointToObjectSpace(p)
    margin=math.min(margin,deck.Size.X/2-math.abs(localPoint.X),deck.Size.Z/2-math.abs(localPoint.Z))
    gap=math.max(gap,-deck.Size.Y/2-localPoint.Y)
    if localPoint.Y>deck.Size.Y/2-1 or localPoint.Y< -deck.Size.Y/2-.55 then return false end
    table.insert(cap,p)
   end
   if margin<.04 or gap>.55 then return false end
   local cloned=sourceClones[deck]
   if not cloned then
    cloned=deck:Clone();cloned:ClearAllChildren();cloned.Anchored=true;cloned.CanCollide=false;cloned.CanTouch=false;cloned.CanQuery=true;cloned.Transparency=1;cloned.Parent=sourceFixture;sourceClones[deck]=cloned
   end
   sourceRays.FilterDescendantsInstances={cloned}
   local raysChecked=0
   for _,p in cap do
    if not allowance()then return false end
    local hit=Workspace:Raycast(p+Vector3.yAxis*(deck.Size.Y+2),-Vector3.yAxis*(deck.Size.Y+4),sourceRays)
    if not hit or hit.Normal.Y<.99 or hit.Position.Y-p.Y<1 then return false end
    raysChecked+=1
   end
   evidence.classification="BlockedByOriginalSolidDeck";evidence.cleared=true
   evidence.source=relative(deck,candidate);evidence.sourceCandidates=1
   evidence.minimumFootprintInset=margin;evidence.maximumUndersideHeadroom=gap;evidence.sourceRays=raysChecked
   evidence.reason="The complete rectangular cap is contained in the existing solid deck footprint, inside its body or at most0.55stud below its underside; exact box geometry and five cloned-deck rays leave no standing space above the trim"
   return true
  end
  local function classify(raw)
   local evidence={scenery=raw.scenery,classification="Unresolved",cleared=false,sourceCandidates=0}
   local extension=sceneryByPath[raw.scenery]
   if containedDeckTrim(extension,evidence)then return evidence end
   if not extension or not extension:IsA("MeshPart") or not verifiedLobe or extension.MeshId~=verifiedLobe.MeshId then evidence.reason="Extension does not match the verified RockLobe import";return evidence end
   local sourcePath=extension:GetAttribute("FoundationSource")
   local sourceSize=extension:GetAttribute("FoundationSourceSize")
   local sourceBottom=extension:GetAttribute("FoundationSourceBottom")
   if typeof(sourcePath)~="string" or typeof(sourceSize)~="Vector3" or typeof(sourceBottom)~="number" then evidence.reason="No measured source binding";return evidence end
   local source
   local pivot=candidate:GetPivot()
   local extensionPosition=pivot:PointToObjectSpace(extension.Position)
   for _,match in findPath(candidate,sourcePath) do
    if not match:IsA("MeshPart") or (match.Size-sourceSize).Magnitude>.001 then continue end
    local localFrame=pivot:ToObjectSpace(match.CFrame)
    local bottom=localFrame.Position.Y-match.Size.Y/2
    if math.abs(bottom-sourceBottom)>.01 or math.abs(localFrame.Position.X-extensionPosition.X)>.01 or math.abs(localFrame.Position.Z-extensionPosition.Z)>.01 then continue end
    evidence.sourceCandidates+=1;source=match
   end
   if evidence.sourceCandidates~=1 then evidence.reason="Measured source path is missing or ambiguous";return evidence end
   evidence.source=relative(source,candidate);evidence.sourceMesh=source.MeshId
   if source.MeshId:match("(%d+)$")~="81247992552083" or source.Transparency~=0 or source.TextureID~="" or source:FindFirstChildOfClass("SurfaceAppearance") or source.Material==Enum.Material.Glass or source.Material==Enum.Material.ForceField then
    evidence.reason="Source is not the known opaque untextured BareRock primitive";return evidence
   end
   if source.CFrame.UpVector.Y<.99 or extension.CFrame.UpVector.Y<.99 then evidence.reason="Cap is tilted beyond the verified horizontal shape contract";return evidence end
   local samples,sideNormal=extensionGeometry(extension)
   evidence.maximumRenderedSideUpNormal=sideNormal
   if sideNormal>=.65 then evidence.reason="An exposed rendered side may itself be a plausible ledge";return evidence end
   evidence.capSamples={};evidence.minimumContainmentClearance=math.huge
   for _,sample in samples do
    local clearance=rockSectionClearance(source,sample)
    evidence.minimumContainmentClearance=math.min(evidence.minimumContainmentClearance,clearance)
    table.insert(evidence.capSamples,{position=point(sample),primitiveClearance=clearance})
   end
   if evidence.minimumContainmentClearance<.03 then evidence.reason="Rendered cap reaches an original source corner or exterior";return evidence end
   local cloned=sourceClones[source]
   if not cloned then
    cloned=source:Clone();cloned:ClearAllChildren();cloned.Anchored=true;cloned.CanCollide=false;cloned.CanTouch=false;cloned.CanQuery=true;cloned.Transparency=1;cloned.Parent=sourceFixture;sourceClones[source]=cloned
   end
   sourceRays.FilterDescendantsInstances={cloned}
   local reach=source.Size.Magnitude*2+3
   evidence.minimumRayEntryMargin=math.huge
   for index,sample in samples do
    local margins={};evidence.capSamples[index].sourceRayEntryMargins=margins
    for _,direction in {Vector3.xAxis,-Vector3.xAxis,Vector3.yAxis,-Vector3.yAxis,Vector3.zAxis,-Vector3.zAxis} do
     if not allowance() then evidence.reason="Query budget ended before containment verification";return evidence end
     local hit=Workspace:Raycast(sample+direction*reach,-direction*reach*2,sourceRays)
     local margin=if hit then reach-hit.Distance else -reach
     table.insert(margins,margin);evidence.minimumRayEntryMargin=math.min(evidence.minimumRayEntryMargin,margin)
     if margin<.02 then evidence.reason="A cloned-source visibility ray does not enclose the rendered cap";return evidence end
    end
   end
   evidence.classification="OccludedRenderedCap";evidence.cleared=true
   evidence.reason="The entire convex rendered cap lies inside the original opaque closed frustum; exposed rendered sides are steep, and all cloned-source enclosure rays agree"
   evidence.shapeSources={"assets/egg_rush_circuit/world/build_environment.py:support", "assets/egg_rush_circuit/phase1/build_kit.py:square_loop", "assets/egg_rush_circuit/phase3/current/build_world_kit.py:RockLobe"}
   return evidence
  end
  for _,raw in report.reachableLedges do
   local evidence=classify(raw)
   table.insert(report.ledgeClassifications,evidence)
   if not evidence.cleared then table.insert(report.unresolvedReachableLedges,raw) end
  end
  report.rawReachableLedgeCount=#report.reachableLedges
  report.geometryClearedLedgeCount=#report.reachableLedges-#report.unresolvedReachableLedges
  report.fallingInterpretation={observations=report.hitCounts.Falling or 0,blockedCenterline=0,otherCenterline=0,
   note="Falling boxes sample vertically beneath route centers. A line starting on a solid accepted pad cannot pass through that pad; these observations do not by themselves show a reachable new ledge. Sideways falls and visible undersides still require native views."}
  for _,hit in report.hits do
   if hit.category~="Falling" then continue end
   local node=routeContexts[hit.context]
   local support=node and node.part
   local blocked=false
   if support and support:IsA("Part") and support.Shape==Enum.PartType.Block and support.CanCollide then
    local localTop=support.CFrame:PointToObjectSpace(node.top)
    blocked=math.abs(localTop.X)<=support.Size.X/2 and math.abs(localTop.Z)<=support.Size.Z/2 and math.abs(localTop.Y-support.Size.Y/2)<.02
   end
   if blocked then report.fallingInterpretation.blockedCenterline+=1 else report.fallingInterpretation.otherCenterline+=1 end
  end
  report.viewSuggestions={
   "At each nearestScenery route node, inspect the normal follow camera, both shoulders and the reverse approach.",
   "Fall beside Shellworks lips and both tray receive banks; inspect foundations and roof undersides while descending toward the lethal floor.",
   "Inspect the chicken's three pecks from Normal and Expert, then reverse from target 3 toward the roost; the static query does not sweep the moving creature.",
   "From original Start and the last return pads, look toward the south gallery roof and both nursery wings; confirm the arcade is screened and no false landing is offered.",
   "Preserved reachableLedges rows are raw collision warnings. Inspect every unresolvedReachableLedges row; review ledgeClassifications separately for full-cap containment and cloned-source enclosure evidence.",
  }
  report.budgetExhausted=budget
  report.complete=not budget
  report.ok=report.complete and report.preservation.ok and report.preservation.sourceUnreadable==0 and #report.unresolvedReachableLedges==0
   and (report.hitCounts.Standing or 0)==0 and (report.hitCounts.Jump or 0)==0 and (report.hitCounts.TraySweep or 0)==0
   and (report.hitCounts.NeighborBounds or 0)==0 and (report.hitCounts.CameraPosition or 0)==0 and (report.hitCounts.CameraLine or 0)==0
 end,debug.traceback)
 if probe then probe:Destroy() end
 if fixture then fixture:Destroy() end
 if sourceFixture then sourceFixture:Destroy() end
 report.fixtureRemoved=not fixture or fixture.Parent==nil
 report.probeRemoved=not probe or probe.Parent==nil
 report.sourceFixtureRemoved=not sourceFixture or sourceFixture.Parent==nil
 if not success then report.failure=tostring(failure);report.ok=false;report.complete=false end
 return report
end

return CheckWorld
