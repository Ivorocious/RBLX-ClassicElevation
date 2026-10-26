local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local V, C = roblox.Vector3, roblox.CFrame
local base, parent = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/', {}
local function load(path, source)
 return luau.load(source or fs.readFile(path), {environment={Vector3=V,CFrame=C,script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig={Origin=V.new(4000,300,2600)}}}},require=function(value)return value end}})()
end
for _,name in {'ExpertRoutes','RouteHazardLayout','RouteHazardGoals','SupportingObstacles'} do parent[name]=load(base..name..'.luau') end
local source=fs.readFile(base..'Layout.luau')
local draft,n=source:gsub('v%(%-144, 28, %-131%)','v(-144, 28, -112)',1); assert(n==1)
local before,after=load(base..'Layout.luau',source),load(base..'Layout.luau',draft)
local function same(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in a do if not same(v,b[k]) then return false end end
 for k in b do if a[k]==nil then return false end end
 return true
end
local changed={}
for i,a in before.Surfaces do if not same(a,after.Surfaces[i]) then table.insert(changed,a.group..'/'..a.name) end end
assert(#changed==1 and changed[1]=='RecoveryPockets/CP01Pocket')
assert(same(before.GetCatchRoute('Arch'),after.GetCatchRoute('Arch')))
assert(same(before.GetCatchRoute('Upper'),after.GetCatchRoute('Upper')))
local wp=load(base..'WorldPlan.luau')
local worldBefore,countsBefore=wp.Get(before)
local worldAfter,countsAfter=wp.Get(after)
assert(same(worldBefore,worldAfter) and same(countsBefore,countsAfter))
local pocket,oldPocket,terrace
for _,s in after.Surfaces do
 if s.name=='CP01Pocket' then pocket=s elseif s.name=='CP01Terrace' then terrace=s end
end
for _,s in before.Surfaces do if s.name=='CP01Pocket' then oldPocket=s end end
assert(pocket.position==terrace.position and pocket.size==V.new(30,1,22) and terrace.size==V.new(32,2,24))
assert(pocket.size.X<=terrace.size.X and pocket.size.Y<=terrace.size.Y and pocket.size.Z<=terrace.size.Z)
local area=after.CP01.respawnArea
local columns,rows=1+math.floor((area.X-3)/4.5),1+math.floor((area.Z-3)/4.5)
assert(columns*rows==35)
for slot=0,columns*rows-1 do
 local x,z=(slot%columns-(columns-1)/2)*4.5,(math.floor(slot/columns)-(rows-1)/2)*4.5
 assert(math.abs(x)+1.5<=pocket.size.X/2 and math.abs(z)+1.5<=pocket.size.Z/2)
end
local function overlap(a,b)
 local axes={}
 for _,p in {a,b} do
  table.insert(axes,p.edges[1]:Cross(p.edges[2])); table.insert(axes,p.edges[1]:Cross(p.edges[3])); table.insert(axes,p.edges[2]:Cross(p.edges[3]))
 end
 for _,x in a.edges do for _,y in b.edges do table.insert(axes,x:Cross(y)) end end
 for _,axis in axes do
  if axis.Magnitude<.00001 then continue end
  local radius=0
  for _,p in {a,b} do for _,edge in p.edges do radius+=math.abs(axis:Dot(edge)) end end
  if math.abs((b.center-a.center):Dot(axis))>=radius-.001 then return false end
 end
 return true
end
local function floorBox(s)
 return {center=s.position-V.yAxis*s.size.Y/2,edges={V.xAxis*s.size.X/2,V.yAxis*s.size.Y/2,V.zAxis*s.size.Z/2}}
end
local oldFlags,newFlags,treads={}, {}, {}
for _,s in after.Surfaces do
 if s.group~='ArchCatchReturn' then continue end
 local frame=s.frame or C.new(s.position)
 local head={center=frame.Position+V.yAxis*4.5,edges={frame.RightVector*(s.size.X/2+2.25),V.yAxis*2.5,-frame.LookVector*(s.size.Z/2+2.25)}}
 if overlap(head,floorBox(oldPocket)) then table.insert(oldFlags,s.name) end
 if overlap(head,floorBox(pocket)) then table.insert(newFlags,s.name) end
 if s.name:find('Tread_5_',1,true) then table.insert(treads,{name=s.name,position={s.position.X,s.position.Y,s.position.Z},size={s.size.X,s.size.Y,s.size.Z}}) end
end
assert(#newFlags==0)
print(serde.encode('json',{ok=true,sourceOnly=true,sourceHash=serde.hash('sha256',source),draftHash=serde.hash('sha256',draft),changedSurfaces=changed,capacity=columns*rows,columns=columns,rows=rows,oldPocketCeilingFlags=oldFlags,newPocketCeilingFlags=newFlags,catchRoutesUnchanged=2,worldPlacementsUnchanged=#worldAfter,finalTreads=treads},true))
