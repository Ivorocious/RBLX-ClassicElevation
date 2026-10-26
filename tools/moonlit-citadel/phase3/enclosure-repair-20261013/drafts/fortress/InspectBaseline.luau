local fs, luau, roblox, serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local base="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local own="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/fortress/"
local parent={}
local config=luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"),{environment={Vector3=roblox.Vector3}})()
local function load(path) return luau.load(fs.readFile(path),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(value)return value end}})() end
for _,name in {"ExpertRoutes","RouteHazardGoals","SupportingObstacles","RouteHazardLayout","BaselineWorldPlan","AssetGeometry","TowerGeometry","Source43WorldPlan"} do parent[name]=load(base..name..".luau") end
local layout=load(base.."Layout.luau")
local previous=load(own.."PreviousWorldPlan.luau")
local plan,counts=previous.Get(layout)
local saved={counts={units=counts.units,meshParts=counts.meshParts,triangles=counts.triangles},plan={},surfaces={},lanterns={},lifts={}}
for _,r in plan do table.insert(saved.plan,{name=r.name,district=r.district,asset=r.asset,library=r.library,frame={r.localCF:GetComponents()},scale={r.scale.X,r.scale.Y,r.scale.Z}}) end
for _,r in layout.Surfaces do table.insert(saved.surfaces,{name=r.name,group=r.group,position={r.position.X,r.position.Y,r.position.Z},size={r.size.X,r.size.Y,r.size.Z},frame={(r.frame or roblox.CFrame.new(r.position)):GetComponents()}}) end
for _,r in layout.Lanterns do table.insert(saved.lanterns,{name=r.name,pivot={r.pivot.X,r.pivot.Y,r.pivot.Z},point={r.point.X,r.point.Y,r.point.Z}}) end
for k,r in layout.LiftOrigins do saved.lifts[k]={r.X,r.Y,r.Z} end
saved.start={layout.StartPoint.X,layout.StartPoint.Y,layout.StartPoint.Z};saved.finish={layout.FinishPoint.X,layout.FinishPoint.Y,layout.FinishPoint.Z}
local clearance=load("tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/ArchitectureClearance.luau")
saved.volumes={}
for _,r in clearance.Prepare(layout,config) do table.insert(saved.volumes,{frame={r.frame:GetComponents()},size={r.size.X,r.size.Y,r.size.Z},reason=r.reason,kind=r.kind,low={r.low.X,r.low.Y,r.low.Z},high={r.high.X,r.high.Y,r.high.Z}}) end
fs.writeFile(own.."source48-plan.json",serde.encode("json",saved,true))
print(serde.encode("json",{counts=saved.counts,start=saved.start,finish=saved.finish,lanterns=saved.lanterns,lifts=saved.lifts,volumes=#saved.volumes}))
