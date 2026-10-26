local fs,luau,roblox,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local base="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local own="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/fortress/"
local parent={}
local config=luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"),{environment={Vector3=roblox.Vector3}})()
local function load(path)return luau.load(fs.readFile(path),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(value)return value end}})() end
for _,name in {"ExpertRoutes","RouteHazardGoals","SupportingObstacles","RouteHazardLayout","BaselineWorldPlan","AssetGeometry","TowerGeometry","Source43WorldPlan"} do parent[name]=load(base..name..".luau") end
parent.PreviousWorldPlan=load(own.."PreviousWorldPlan.luau");parent.FortressGeometry=load(own.."FortressGeometry.luau")
local layout=load(base.."Layout.luau");local world=load(own.."WorldPlan.luau")
local clearance=load("tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/ArchitectureClearance.luau")
local volumes,seen={},{}
local function reserve(volume)
 local key=volume.kind..volume.reason
 for _,n in {volume.frame:GetComponents()} do key..=string.format("/%.5f",n) end
 for _,n in {volume.size.X,volume.size.Y,volume.size.Z} do key..=string.format("/%.5f",n) end
 if not seen[key] then seen[key]=true;table.insert(volumes,volume) end
end
for mask=0,7 do for lower=1,2 do for upper=1,2 do
 local choices={bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0}
 local proxy=table.clone(layout)
 proxy.GetRoute=function()return layout.GetRoute(choices,{lower,upper}) end
 for _,volume in clearance.Prepare(proxy,config) do reserve(volume) end
end end end
local weightCenter=layout.LiftOrigins.Upper+roblox.Vector3.new(-46,22,-1)
reserve({frame=roblox.CFrame.new(weightCenter),size=roblox.Vector3.new(8,44,6.5),half={4,22,3.25},
 axes={roblox.Vector3.xAxis,roblox.Vector3.yAxis,roblox.Vector3.zAxis},low=weightCenter-roblox.Vector3.new(4,22,3.25),
 high=weightCenter+roblox.Vector3.new(4,22,3.25),kind="Mechanism",reason="Actual Upper west counterweight at -46"})
local results={plannedOnly=true,protectedCourseMutated=false,nativeVisualVerified=false,stages={},routeCombinations=32,uniqueVolumes=#volumes}
for _,representative in {true,false} do
 local plan,counts=world.Get(layout,{representative=representative})
 local checked=clearance.CheckParts(counts.proposalRows,volumes)
 local stage={representative=representative,units=counts.units,meshParts=counts.meshParts,triangles=counts.triangles,rows=#counts.proposalRows,
  blocking=checked.blocking,headroom=checked.headroom,camera=checked.camera,visibility=checked.visibility,invalidFlags=checked.invalidContactFlags}
 table.insert(results.stages,stage)
 if not representative then
  local placements={}
  for _,r in plan do table.insert(placements,{name=r.name,district=r.district,asset=r.asset,library=r.library,frame={r.localCF:GetComponents()},scale={r.scale.X,r.scale.Y,r.scale.Z}}) end
  fs.writeFile(own.."placement-plan.json",serde.encode("json",placements,true))
  fs.writeFile(own.."ground-seats.json",serde.encode("json",counts.groundSeats,true))
  fs.writeFile(own.."retire-map.json",serde.encode("json",{source48=counts.retired,source43Earlier=counts.retiredSource43,retained=counts.retained},true))
  fs.writeFile(own.."occupied-plan.json",serde.encode("json",counts.proposalRows,true))
 end
 print(serde.encode("json",{representative=representative,units=counts.units,meshParts=counts.meshParts,triangles=counts.triangles,blocking=#checked.blocking,headroom=#checked.headroom,camera=#checked.camera,visibility=#checked.visibility}))
end
fs.writeFile(own.."focused-checks.json",serde.encode("json",results,true))
