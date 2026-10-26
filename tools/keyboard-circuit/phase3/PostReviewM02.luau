--!strict
assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and not game.RunService:IsRunning())
local c=workspace.KeyboardCircuit_P3_M02_01
local old=game.ServerStorage.KeyboardCircuitPhase2Archive
local reference=old.Phase3M02Work20261009.KCP3M02NativeRecovery04.KeyboardCircuit_P3_M02_01
local function relative(root,item)return item:GetFullName():sub(#root:GetFullName()+2)end
local function n(...)local values={...}for i,v in values do values[i]=string.format("%.3f",if math.abs(v)<.0005 then 0 else v)end return table.concat(values,",")end
local function row(root,item)
 local value=item.ClassName.."|"..relative(root,item)
 if item:IsA("BasePart") then
  value..="|"..n(item.CFrame:GetComponents()).."|"..n(item.Size.X,item.Size.Y,item.Size.Z,item.Color.R,item.Color.G,item.Color.B,item.Transparency,item.Reflectance)
  value..="|"..tostring(item.Anchored).."|"..tostring(item.CanCollide).."|"..tostring(item.CanTouch).."|"..tostring(item.CanQuery).."|"..item.Material.Name.."|"..item.CollisionGroup.."|"..tostring(item.CastShadow)
  if item:IsA("Part")then value..="|"..item.Shape.Name end
  if item:IsA("MeshPart")then value..="|"..item.MeshId.."|"..item.TextureID.."|"..item.CollisionFidelity.Name end
 elseif item:IsA("TextLabel")then
  value..="|"..item.Text.."|"..item.Font.Name.."|"..n(item.TextColor3.R,item.TextColor3.G,item.TextColor3.B,item.TextTransparency,item.TextStrokeTransparency).."|"..tostring(item.Visible)
 elseif item:IsA("SurfaceGui")then value..="|"..tostring(item.Enabled) end
 return value
end
local function rows(root)local result={}for _,v in root:GetDescendants()do table.insert(result,row(root,v))end table.sort(result)return result end
local a,b=rows(c),rows(reference)
assert(#a==#b)
for i=1,#a do assert(a[i]==b[i],"Post-review native geometry changed at "..i)end
local sources={}
for _,s in c.SourceSnapshot:GetChildren()do assert(s.Source==reference.SourceSnapshot[s.Name].Source,"Post-review source changed "..s.Name)table.insert(sources,s.Name)end
assert(#sources==23 and not c.SourceSnapshot.Session.Disabled)
local active={}
for _,v in workspace:GetChildren()do if v:IsA("Model")and v.Name:find("KeyboardCircuit",1,true)then table.insert(active,v.Name)end end
assert(#active==1 and active[1]==c.Name)
local older=0
for _,v in old.TwoLapCleanup20261008.OlderCourses:GetChildren()do older+=1 for _,s in v:GetDescendants()do if s:IsA("BaseScript")then assert(s.Disabled)end end end
assert(older==14)
for _,v in old.Phase3M02Work20261009:GetDescendants()do if v:IsA("BaseScript")then assert(v.Disabled)end end
local unchanged={}
for name,expected in {Lobby={2356,1243},GrandArcade={424,281},SGV2_Phase3_F04={8795,8015},ObstacleKit_Palette={499,369}}do
 local m=assert(workspace:FindFirstChild(name))local all=m:GetDescendants()local parts=0 for _,v in all do if v:IsA("BasePart")then parts+=1 end end
 assert(#all==expected[1]and parts==expected[2],name.." changed")
 unchanged[name]={descendants=#all,parts=parts}
end
local result={candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),passed=true,geometryRows=#a,sources=#sources,activeCourses=active,inertOlderCourses=older,inertWorkFolders=#old.Phase3M02Work20261009:GetChildren(),unrelated=unchanged,origin=tostring(c:GetAttribute("Origin")),editRunning=false,
 boundary="Post-review Edit comparison against the frozen native reopening includes transforms, sizes, colors, transparency, reflectance, anchored/collision/query/touch/shadow states, shapes, mesh identity/fidelity, visible legends and source bytes. No scene/camera/input changes."}
shared.KCP3M02PostReview01=result
return game.HttpService:JSONEncode(result)

