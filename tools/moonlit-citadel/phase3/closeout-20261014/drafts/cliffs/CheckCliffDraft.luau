local fs,luau,roblox,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local source="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local own="tools/moonlit-citadel/phase3/closeout-20261014/drafts/cliffs/"
local parent={}
local config=luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"),{environment={Vector3=roblox.Vector3}})()
local function load(path)
 local text=fs.readFile(path);luau.compile(text)
 return luau.load(text,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,
 script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(value)return value end}})()
end
for _,name in {"ExpertRoutes","RouteHazardGoals","SupportingObstacles","RouteHazardLayout"} do parent[name]=load(source..name..".luau") end
local layout=load(source.."Layout.luau")
local clearance=load("tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/ArchitectureClearance.luau")
local volumes,seen={},{ }
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
assert(#volumes==1581,"Accepted clearance envelope count changed; inspect before using prior proof")
local finishing=load(own.."CliffFinishingPlan.luau")
local plan,counts=finishing.Get()
local report=clearance.CheckParts(counts.proposalRows,volumes)
local failures={}
for _,key in {"blocking","headroom","camera","visibility","invalidContactFlags"} do
 if #report[key]>0 then table.insert(failures,key.." "..#report[key]) end
end
local preserved49=serde.decode("json",fs.readFile("tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/combined-stage-check.json")).totals
local combined={units=preserved49.units+counts.units,meshParts=preserved49.meshParts+counts.meshParts,triangles=preserved49.triangles+counts.triangles}
local limits={units=350,meshParts=900,triangles=420000}
for key,limit in limits do if combined[key]>limit then table.insert(failures,key.." exceeds existing world cap") end end
local result={pass=#failures==0,failures=failures,plannedOnly=true,nativeVisualVerified=false,protectedCourseMutated=false,
 routeCombinations=32,uniqueVolumes=#volumes,proposalRows=#counts.proposalRows,totals={units=counts.units,meshParts=counts.meshParts,triangles=counts.triangles},
 existing49PlusDraft=combined,limits=limits,blocking=report.blocking,headroom=report.headroom,camera=report.camera,visibility=report.visibility,invalidFlags=report.invalidContactFlags,
 planSHA256=serde.hash("sha256",fs.readFile(own.."CliffFinishingPlan.luau")),configSHA256=serde.hash("sha256",fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau")),
 layoutSHA256=serde.hash("sha256",fs.readFile(source.."Layout.luau"))}
fs.writeFile(own.."cliff-clearance-check.json",serde.encode("json",result,true))
print(serde.encode("json",{pass=result.pass,failures=failures,units=counts.units,meshParts=counts.meshParts,triangles=counts.triangles,uniqueVolumes=#volumes,combined=combined}))
assert(result.pass,"Inspect focused cliff findings before integration")
