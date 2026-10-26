--!strict
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local c=workspace.KeyboardCircuit_P3_M01_01
local encoding=game:GetService("EncodingService")
local function hex(value) return (value:gsub(".",function(char)return string.format("%02x",string.byte(char))end)) end
local sources={}
local function add(item)
 local data=buffer.fromstring(item.Source)
 table.insert(sources,{path=item:GetFullName():gsub("^game%.",""),name=item.Name,class=item.ClassName,bytes=buffer.len(data),sha256=hex(buffer.tostring(encoding:ComputeBufferHash(data,Enum.HashAlgorithm.Sha256)))})
end
for _, item in c.SourceSnapshot:GetChildren() do add(item) end
add(game.ServerScriptService.Services.StudioDevService)
add(game.StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController)
add(game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview)
table.sort(sources,function(a,b)return a.path<b.path end)
local active, archived, disabled={}, {}, true
for _,item in workspace:GetChildren() do if item.Name:match("^KeyboardCircuit") then table.insert(active,item.Name) end end
local older=game.ServerStorage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses
for _,item in older:GetChildren() do
 table.insert(archived,item.Name)
 for _,script in item:GetDescendants() do if script:IsA("BaseScript") and not script.Disabled then disabled=false end end
end
table.sort(archived)
local unrelated={}
for _,name in {"Lobby","GrandArcade","SGV2_Phase3_F04","ObstacleKit_Palette"} do
 local item=assert(workspace:FindFirstChild(name));local parts=0
 for _,part in item:GetDescendants() do if part:IsA("BasePart") then parts+=1 end end
 unrelated[name]={descendants=#item:GetDescendants(),parts=parts}
end
local origin=c:GetAttribute("Origin")
local function relative(model, item) return item:GetFullName():sub(#model:GetFullName() + 2) end
local function numbers(...)
 local values = {...}
 for i, v in values do values[i] = string.format("%.3f", if math.abs(v) < .0005 then 0 else v) end
 return table.concat(values, ",")
end
local function geometry(model)
 local rows = {}
 for _, item in model:GetDescendants() do
  local row = item.ClassName .. "|" .. relative(model, item)
  if item:IsA("BasePart") then
   row ..= "|" .. numbers(item.CFrame:GetComponents()) .. "|" .. numbers(item.Size.X, item.Size.Y, item.Size.Z)
   row ..= "|" .. numbers(item.Color.R, item.Color.G, item.Color.B) .. "|" .. item.Material.Name
   row ..= "|Alpha|" .. numbers(item.Transparency,item.Reflectance) .. "|" .. tostring(item.Anchored)
   if item:IsA("Part") then row ..= "|" .. item.Shape.Name end
   row ..= "|" .. tostring(item.CanCollide) .. "|" .. tostring(item.CanTouch) .. "|" .. tostring(item.CanQuery) .. "|" .. tostring(item.CastShadow) .. "|" .. item.CollisionGroup
   if item:IsA("MeshPart") then row ..= "|" .. item.MeshId .. "|" .. item.TextureID .. "|" .. item.CollisionFidelity.Name end
  elseif item:IsA("TextLabel") then
   row ..= "|" .. item.Text .. "|" .. item.Font.Name .. "|" .. tostring(item.Visible)
   row ..= "|" .. numbers(item.TextColor3.R,item.TextColor3.G,item.TextColor3.B,item.TextTransparency,item.TextStrokeTransparency) .. "|" .. tostring(item.TextScaled)
  elseif item:IsA("SurfaceGui") then row ..= "|" .. tostring(item.Enabled)
  elseif item:IsA("ObjectValue") then row ..= "|" .. (if item.Value and item.Value:IsDescendantOf(model) then relative(model, item.Value) else tostring(item.Value))
  elseif item:IsA("Vector3Value") then row ..= "|" .. numbers(item.Value.X, item.Value.Y, item.Value.Z)
  end
  local attributes, names = item:GetAttributes(), {}
  for name in attributes do table.insert(names,name) end
  table.sort(names)
  for _,name in names do
   local value, encoded = attributes[name], nil
   if typeof(value)=="CFrame" then encoded=numbers(value:GetComponents())
   elseif typeof(value)=="Vector3" then encoded=numbers(value.X,value.Y,value.Z)
   elseif typeof(value)=="Color3" then encoded=numbers(value.R,value.G,value.B)
   elseif typeof(value)=="number" then encoded=numbers(value)
   else encoded=tostring(value) end
   row ..= "|A:"..name..":"..typeof(value)..":"..encoded
  end
  table.insert(rows, row)
 end
 table.sort(rows)
 return rows
end

local result=({candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),mapRevision=c:GetAttribute("MapRevision"),baseCourseRevision=c:GetAttribute("BaseCourseRevision"),layout=require(c.SourceSnapshot.Layout).Revision,origin={origin.X,origin.Y,origin.Z},descendants=#c:GetDescendants(),rows=sources,active=active,archived=archived,archivedScriptsDisabled=disabled,unrelated=unrelated,datamodel="Edit",boundary="Read-only intended experience identity, preserved owner placement, exact source bytes, one active course, scoped inert archives and unrelated map counts. No camera or computer control, publication, stored data, human pacing or FPS proof."})
local restored=game.ServerStorage.KCP3M01NativeRecovery01.KeyboardCircuit_P3_M01_01
local a,b=geometry(c),geometry(restored)
local differences={}
for index=1,math.max(#a,#b) do if a[index]~=b[index] and #differences<12 then table.insert(differences,{index=index,active=a[index],reopened=b[index]}) end end
result.geometry={passed=#a==#b and #differences==0,activeRows=#a,reopenedRows=#b,differences=differences,boundary="Read-only comparison against the retained engine reopening: all descendant classes/names, typed attrs, .001 geometry and color precision, physical/query flags, transparency/reflectance, anchored state, Part shapes, text ink, internal ObjectValues and exact source hashes. Active Session remains enabled; inert reopened scripts remain disabled. No transforms or instances changed."}
result.passed=result.geometry.passed and #result.rows==23 and #result.active==1 and #result.archived==13 and result.archivedScriptsDisabled
assert(result.passed,game.HttpService:JSONEncode(result.geometry))
return game.HttpService:JSONEncode(result)

