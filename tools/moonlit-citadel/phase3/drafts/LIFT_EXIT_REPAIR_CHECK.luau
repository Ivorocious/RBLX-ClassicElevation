local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local V, C = roblox.Vector3, roblox.CFrame
local base = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local parent = {}
local function load(path, source)
 return luau.load(source or fs.readFile(path), {environment = {Vector3 = V, CFrame = C, script = {Parent = parent}, game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = {Origin = V.new(4000,300,2600)}}}}, require = function(value) return value end}})()
end
for _, name in {'ExpertRoutes','RouteHazardLayout','RouteHazardGoals','SupportingObstacles'} do parent[name] = load(base .. name .. '.luau') end
local original = fs.readFile(base .. 'Layout.luau')
local checkedSourceHash = serde.hash('sha256', original)
if original:find('local depth = if index == 4 then 14 else 22', 1, true) then
 local count
 original, count = original:gsub('local cp04 = checkpoint%("Lifts", "CP04", v%(112, 106, %-86%), v%(48, 2, 18%), 4, v%(112, 106, %-86%)%)', 'local cp04 = checkpoint("Lifts", "CP04", v(112, 106, -86), v(48, 2, 18), 4, v(112, 106, -66))', 1); assert(count == 1)
 original, count = original:gsub(' local depth = if index == 4 then 14 else 22\r?\n', '', 1); assert(count == 1)
 original, count = original:gsub('v%(30, 1, depth%)', 'v(30, 1, 22)', 1); assert(count == 1)
 original, count = original:gsub('v%(30, 0, depth%)', 'v(30, 0, 22)', 1); assert(count == 1)
end
local draft, n = original:gsub('v%(112, 106, %-66%)', 'v(112, 106, -86)', 1); assert(n == 1)
draft, n = draft:gsub('data%.pocketSupport = surface', 'local depth = if index == 4 then 14 else 22\n data.pocketSupport = surface', 1); assert(n == 1)
draft, n = draft:gsub('v%(30, 1, 22%)', 'v(30, 1, depth)', 1); assert(n == 1)
draft, n = draft:gsub('v%(30, 0, 22%)', 'v(30, 0, depth)', 1); assert(n == 1)
local before, after = load(base .. 'Layout.luau', original), load(base .. 'Layout.luau', draft)
local function same(a,b)
 if type(a) ~= type(b) then return false end
 if type(a) ~= 'table' then return a == b end
 for k,v in a do if not same(v,b[k]) then return false end end
 for k in b do if a[k] == nil then return false end end
 return true
end
assert(#before.Surfaces == #after.Surfaces)
local changed = {}
for i,a in before.Surfaces do if not same(a, after.Surfaces[i]) then table.insert(changed, a.group .. '/' .. a.name) end end
assert(#changed == 1 and changed[1] == 'RecoveryPockets/CP04Pocket')
for mask=0,7 do
 local choices={bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0}
 for _,bays in {{1,2},{2,1}} do assert(same(before.GetRoute(choices,bays), after.GetRoute(choices,bays)), 'Route changed') end
end
for _,name in {'Arch','Upper'} do assert(same(before.GetCatchRoute(name),after.GetCatchRoute(name)), 'Catch changed') end
local wp=load(base .. 'WorldPlan.luau')
local planBefore, countsBefore = wp.Get(before)
local planAfter, countsAfter = wp.Get(after)
assert(same(planBefore,planAfter) and same(countsBefore,countsAfter), 'WorldPlan changed')
local cp=after.CP04
local pocket
for _,s in after.Surfaces do if s.group=='RecoveryPockets' and s.name=='CP04Pocket' then pocket=s end end
local cols=1+math.floor((cp.respawnArea.X-3)/4.5)
local rows=1+math.floor((cp.respawnArea.Z-3)/4.5)
assert(cols*rows>=20 and cols==7 and rows==3)
assert(cp.point==V.new(112,106,-86) and cp.pocket==cp.point and pocket.size==V.new(30,1,14))
local span=2.25
local low, high=V.one*math.huge,V.one*-math.huge
for slot=0,cols*rows-1 do
 local p=cp.pocket+V.new((slot%cols-(cols-1)/2)*4.5,0,(math.floor(slot/cols)-(rows-1)/2)*4.5)
 assert(math.abs(p.X-cp.pocket.X)+1.5<=pocket.size.X/2 and math.abs(p.Z-cp.pocket.Z)+1.5<=pocket.size.Z/2)
 low,high=low:Min(p-V.new(span,0,span)),high:Max(p+V.new(span,7,span))
end
local function disjoint(a0,a1,b0,b1) return a1.X<=b0.X or a0.X>=b1.X or a1.Y<=b0.Y or a0.Y>=b1.Y or a1.Z<=b0.Z or a0.Z>=b1.Z end
local checks={}
local function check(name,b0,b1) assert(disjoint(low,high,b0,b1),name..' intersects recovery body slots'); table.insert(checks,name) end
check('UpperFrontWall', V.new(88,106,-96.25), V.new(136,116,-94.75))
for stage,origin in after.LiftOrigins do
 for bay,x in {-9,9} do
  check(stage..'Bay'..bay..'DeckBodySweep',origin+V.new(x-7,0,-6),origin+V.new(x+7,39,6))
  check(stage..'Bay'..bay..'WeightReserve',origin+V.new((if bay==1 then -27 else 27)-4,-1,-3.25),origin+V.new((if bay==1 then -27 else 27)+4,45,3.25))
 end
end
for _,s in after.Surfaces do
 if s.group=='UpperBrace' or s.group=='UpperBraceMirror' or s.group=='UpperExpertExit' or s.group=='UpperExpertExitMirror' then
  check(s.group..'/'..s.name, s.position-V.new(s.size.X/2,s.size.Y,s.size.Z/2),s.position+V.new(s.size.X/2,0,s.size.Z/2))
 end
end
print(serde.encode('json',{ok=true,sourceOnly=true,checkedSourceHash=checkedSourceHash,originalLayoutHash=serde.hash('sha256',original),draftLayoutHash=serde.hash('sha256',draft),changedSurfaces=changed,routeVariantsUnchanged=16,catchesUnchanged=2,worldPlacementsUnchanged=#planAfter,columns=cols,rows=rows,capacity=cols*rows,slotBodyMin={low.X,low.Y,low.Z},slotBodyMax={high.X,high.Y,high.Z},clearanceChecks=#checks},true))
