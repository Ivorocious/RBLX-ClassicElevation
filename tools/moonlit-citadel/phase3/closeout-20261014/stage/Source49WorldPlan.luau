--!nonstrict
local Previous=require(script.Parent.Source48WorldPlan)
local Geometry=require(script.Parent.FortressGeometry)
local AR=require(script.Parent.AssetGeometry)
local Tower=require(script.Parent.TowerGeometry)
local Baseline=require(script.Parent.BaselineWorldPlan)
local World={Limits=Previous.Limits,BaseY=-94,LibraryName="MoonlitCitadel_Enclosure_ER01Library"}
local v=Vector3.new
local function cf(point,yaw)return CFrame.new(point)*CFrame.Angles(0,yaw or 0,0) end
local shellNames={GrandKeepSouthWall=true,GrandKeepWestWall=true,GrandKeepNorthWall=true,GrandKeepEastWall=true,GrandRearApseFoundation=true}
local crownNames={RoofDrumWestReturn=true,RoofDrumSouthReturn=true,RoofDrumNorthWestReturn=true,EastApproachLowSill=true,RoofDrumEastSouthReturn=true,EastApproachPortalFoot=true,CrownUnderfloorSeat=true,SouthScreenSeatedCurb=true,WestScreenSeatedCurb=true}
local function retained(data)
 if crownNames[data.name] then return false end
 if shellNames[data.name] then return false end
 if data.name=="ContactFascia5_-1" or data.name=="ContactFascia28_-1" then return false end
 if data.district=="GrandKeep" or data.district=="KeepRoof" or data.district=="CrownArrival"
  or data.district=="TerraceFoundations" or data.district=="GalleryKeepJunction" or data.district=="Keep" then return true end
 if data.district=="LanternPendulums" then
  return data.name:match("^Gallery%dFoundation$") or data.name:match("^Gallery%dEnclosedBody$")
   or data.name:match("^Gallery%dSeatedRoof$") or data.name:match("^Gallery%dPlanterShelf")
   or data.name:match("^GalleryMoonBanner") or data.name:match("^GalleryInteriorQuietLancet")
 end
 return false
end
function World.Get(layout,options)
 options=options or {}
 local prior,previous=Previous.Get(layout)
 local plan,rows={},{}
 local counts={units=0,meshParts=0,triangles=0,districts={},retired={},retained={},plantingMounts=previous.plantingMounts,
  assemblies={},proposalRows=rows,groundSeats={},joinedGroups={},fullMapPending=false,newLibrary=World.LibraryName,
  retiredSource43=previous.retired,approachPortal=previous.approachPortal,mainPeakY=previous.mainPeakY,representative=options.representative==true}
 for _,r in previous.assemblies do if r.name:match("^Gallery[123]$") then local copy=table.clone(r);copy.foundationBase=-38;table.insert(counts.assemblies,copy) end end
 local function metadata(asset)
  if Geometry[asset] then return Geometry[asset] end
  if Tower[asset] then return Tower[asset] end
  if AR[asset] then return AR[asset] end
  local old=assert(Baseline.Assets[asset],"Unknown fortress asset "..asset)
  return {parts=old[1],triangles=old[2],center=old[3],size=old[4]}
 end
 local function add(data,isRetained)
  local meta=metadata(data.asset)
  if data.asset=="MC_AR_MasonryMass" or data.asset=="MC_AR_FoundationBay46" then data.library="ER01" end
  table.insert(plan,data);counts.units+=1;counts.meshParts+=meta.parts;counts.triangles+=meta.triangles
  counts.districts[data.district]=(counts.districts[data.district] or 0)+1
  if isRetained then table.insert(counts.retained,data.name) end
  if isRetained and (data.asset=="MC_AR_FoundationBay46" or data.name=="JunctionWestReturn" or data.name=="JunctionEastReturn") then
   local lo,hi=meta.center-meta.size/2,meta.center+meta.size/2
   table.insert(counts.groundSeats,{name=data.name,frame={data.localCF:GetComponents()},footprint={lo.X,lo.Z,hi.X,hi.Z},scale={data.scale.X,data.scale.Y,data.scale.Z},bottomY=-38,burialStuds=4})
  end
  local boxes=meta.occupied or {{low=meta.center-meta.size/2,high=meta.center+meta.size/2}}
  for index,box in boxes do
   local frame=data.localCF*CFrame.new((box.low+box.high)/2*data.scale)
   local size=(box.high-box.low)*data.scale
   table.insert(rows,{path=data.name.."/Occupied"..index,frame={frame:GetComponents()},size={size.X,size.Y,size.Z},
    anchored=true,collide=false,query=false,touch=false,transparency=0,retained=isRetained==true})
  end
 end
 for _,data in prior do
  if retained(data) then
   if data.asset=="MC_AR_FoundationBay46" or data.name=="JunctionWestReturn" or data.name=="JunctionEastReturn" then
    data=table.clone(data);data.localCF+=v(0,-8,0);data.scale+=v(0,8/(if data.asset=="MC_AR_FoundationBay46" then 40 else 24),0)
   end
   if not options.representative or data.district=="GrandKeep" or data.district=="KeepRoof" or data.district=="CrownArrival" then add(data,true) end
  else table.insert(counts.retired,{name=data.name,district=data.district,asset=data.asset,source="Source48",reason=if crownNames[data.name] then "Replaced by coherent MC_ER_CrownBaseShell at identity frame" elseif shellNames[data.name] then "Replaced by coherent MC_ER_MainKeepShell" elseif data.name=="ContactFascia5_-1" or data.name=="ContactFascia28_-1" then "Legacy Phase3 trim crosses accepted movement/headroom/camera reserve" else "Replaced repeated outer facade or behind-start arrival by connected fortress composition"}) end
 end
 local function unit(district,name,asset,point,yaw,scale,root)
  local data={district=district,name=name,asset=asset,localCF=cf(point,yaw),scale=scale or Vector3.one,library="ER01",materialRole="FortressStone"}
  add(data,false)
  if root then
   local meta=metadata(asset);local lo,hi=meta.center-meta.size/2,meta.center+meta.size/2
   table.insert(counts.groundSeats,{name=name,frame={data.localCF:GetComponents()},footprint={lo.X,lo.Z,hi.X,hi.Z},scale={data.scale.X,data.scale.Y,data.scale.Z},bottomY=point.Y,burialStuds=4})
  end
 end
 local function bastion(name,x,z,sy,sx,sz)unit("FortressBastions",name,"MC_ER_Bastion",v(x,-94,z),0,v(sx or 1,sy,sz or 1),true) end
 local function wing(name,x,z,yaw,sx,sy,sz,rootY)unit("SteppedFortressWings",name,"MC_ER_SteppedWing",v(x,rootY or -94,z),yaw,v(sx,sy,sz),true) end
 local function rampart(name,x,z,yaw,sx,sy)unit("FortressRamparts",name,"MC_ER_Rampart",v(x,-94,z),yaw,v(sx,sy,1),true) end
 unit("CrownArrival","CrownBaseUnifiedShell","MC_ER_CrownBaseShell",Vector3.zero,0,Vector3.one)
 unit("GrandKeep","GrandKeepUnifiedShell","MC_ER_MainKeepShell",v(layout.FinishPoint.X,-38,layout.FinishPoint.Z),0,Vector3.one,true)
 -- The upper representative includes the complete machinery/crown composition, then the full map adds arrival and lower wings.
 bastion("NorthWestArchBastion",-282,-154,1.42,1.05,1)
 bastion("NorthMiddleBastion",-69,-204,1.30,1.05,.85)
 bastion("NorthEastMachineBastion",225,-197,1.42,1,1.05)
 wing("KeepNorthWestDeepWing",-70,-110,0,.65,1.70,1.20)
 wing("NorthWestSteppedHall",-130,-207,0,1.10,1.95,1)
 wing("NorthMiddleSteppedHall",-22,-207,0,1,1.85,1)
 wing("RearMachineSteppedHall",111,-221,0,1.10,1.80,.85,-38)
 wing("EastUpperDeepWing",241,-100,-math.pi/2,1.45,1.80,1.4,-38)
 unit("MachineryHouse","JoinedDoubleLiftHall","MC_ER_LiftHood",v(112,-94,-115),0,v(1.12,1,2),true)
 -- These reused brackets seat behind the visible wheel faces and rise into the hood beam.
 unit("MachineryHouse","UpperWheelSupportLeft","MC_ER_LanternBracket",v(80.3,172,-161),0,Vector3.one)
 unit("MachineryHouse","UpperWheelSupportRight","MC_ER_LanternBracket",v(135.4,172,-161),0,Vector3.one)
 unit("MachineryHouse","LowerWheelSupportLeft","MC_ER_LanternBracket",v(88.4,174,-85),0,v(1,2.65,1))
 unit("MachineryHouse","LowerWheelSupportRight","MC_ER_LanternBracket",v(135.6,174,-85),0,v(1,2.65,1))
 unit("RaisedFortressCourts","NorthWestRaisedCourt","MC_ER_RaisedCourt",v(-234,-94,-212),0,v(1.25,2.3,1),true)
 unit("RaisedFortressCourts","NorthEastRaisedCourt","MC_ER_RaisedCourt",v(248,-94,-216),0,v(1.1,2.2,1),true)
 rampart("NorthWestCurtain",-166,-197,0,1.35,4.8)
 rampart("NorthMiddleCurtain",2,-197,0,1.15,4.8)
 rampart("NorthEastCurtain",169,-226,0,1.05,4.0)
 if not options.representative then
  bastion("SouthWestArrivalBastion",-229,104,1.05,.90,.9)
  bastion("SouthArrivalRightBastion",-77,116,1.1,.75,.75)
  bastion("EastGalleryBastion",233,43,1.10,.95,.95)
  bastion("SouthEastPanoramaBastion",130,140,.85,1.2,1.05)
  unit("ForwardArrival","MonumentalForwardGate","MC_ER_ForwardGate",v(layout.StartPoint.X,-94,106),0,v(1,2,1),true)
  wing("WestArchHighWing",-267,-103,math.pi/2,1.05,1.7,1.1)
  wing("WestArchMiddleWing",-267,-18,math.pi/2,1.05,1.5,1.1)
  wing("WestArrivalWing",-267,63,math.pi/2,1.05,1.3,1.1)
  wing("EastGalleryDeepWing",241,11,-math.pi/2,1.10,1.30,1.4)
  wing("GalleryRearGreatHall",18,122,math.pi,1.70,1.25,1.4,-38)
  wing("SouthEastServiceWing",133,125,math.pi,1.10,1.30,1.2)
  for i,z in {-147,-48,51,150} do rampart("WestSteppedCurtain"..i,-267,z,math.pi/2,1.05,({3.2,3.0,2.6,2.45})[i]) end
  rampart("EastLowerCurtain",236,114,-math.pi/2,1,2.7)
  rampart("SouthGalleryCurtain",29,173,0,1.8,2.4)
  rampart("GateEastConnection",-83,142,math.pi/2,.55,2.1)
  for i,lantern in layout.Lanterns do unit("LanternMachineMounts","LanternWallBracket"..i,"MC_ER_LanternBracket",v(lantern.pivot.X,lantern.pivot.Y,39.8),0,Vector3.one) end
 end
 counts.joinedGroups={{name="WestFortress",members={"NorthWestArchBastion","WestArchHighWing","WestArchMiddleWing","WestArrivalWing","SouthWestArrivalBastion"}},
  {name="NorthFortress",members={"NorthWestSteppedHall","NorthMiddleSteppedHall","RearMachineSteppedHall","NorthMiddleBastion","NorthEastMachineBastion"}},
  {name="MachineFortress",members={"JoinedDoubleLiftHall","EastUpperDeepWing","EastGalleryDeepWing","RearMachineSteppedHall"}},
  {name="ForwardEntrance",members={"MonumentalForwardGate","SouthWestArrivalBastion","SouthArrivalRightBastion"}}}
 counts.openings={forwardEntrance={center=v(layout.StartPoint.X,0,106),clearWidth=84,minimumHeadY=50,faces="-Z journey"},
  machinery={low=v(34,0,-156),high=v(190,166,-56)},crownPanorama="East/southeast low saddle framed by lower service wing and bastion"}
 if options.clearance and options.config then counts.clearance=options.clearance.CheckParts(rows,options.clearance.Prepare(layout,options.config)) end
 assert(counts.units<=210 and counts.meshParts<640 and counts.triangles<=280000,"Fortress architecture budget exceeded")
 return plan,counts
end
World.AssetGeometry=Geometry
return World
