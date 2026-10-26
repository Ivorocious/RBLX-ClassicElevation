assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
local H,E,S = game.HttpService,game.EncodingService,game.SerializationService
local beforeHttp=H.HttpEnabled
local function hash(bytes)
 local value,pieces=E:ComputeBufferHash(bytes,Enum.HashAlgorithm.Sha256),{}
 for i=0,buffer.len(value)-1 do pieces[#pieces+1]=string.format("%02x",buffer.readu8(value,i)) end
 return table.concat(pieces)
end
local out={candidate="MC_P3_M01_R01",place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,sources={},files={}}
local function post(name,bytes)
 local r=H:RequestAsync({Url="http://127.0.0.1:56069/"..name,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=buffer.tostring(bytes)})
 assert(r.Success,r.StatusCode);local receipt=H:JSONDecode(r.Body);assert(receipt.sha256==hash(bytes));out.files[#out.files+1]=receipt
end
local ok,why=xpcall(function()
 H.HttpEnabled=true
 for _,p in game.ServerStorage.CourseBuilders.MoonlitCitadelCourse:GetChildren() do if p:IsA("ModuleScript") then out.sources[#out.sources+1]={instancePath="ServerStorage/CourseBuilders/MoonlitCitadelCourse/"..p.Name,source=p.Source,sha256=hash(buffer.fromstring(p.Source:gsub("\r\n","\n")))} end end
 for _,name in {"MoonlitCitadelCourseConfig","MoonlitCitadelAssemblyConfig","MoonlitCitadelConfig"} do local p=game.ReplicatedStorage.Config[name];out.sources[#out.sources+1]={instancePath="ReplicatedStorage/Config/"..name,source=p.Source,sha256=hash(buffer.fromstring(p.Source:gsub("\r\n","\n")))} end
 post("MC_P3_before_owner_oct12.rbxm",S:SerializeInstancesAsync({game.ServerStorage.CourseLibrary.Course_MoonlitCitadel,workspace.Course_MoonlitCitadel}))
 local camera=workspace.CurrentCamera
 out.camera={cf={camera.CFrame:GetComponents()},focus={camera.Focus:GetComponents()},type=camera.CameraType.Name,fov=camera.FieldOfView}
 out.clock=game.Lighting.ClockTime
 post("MC_P3_before_owner_oct12.json",buffer.fromstring(H:JSONEncode(out)))
end,debug.traceback)
H.HttpEnabled=beforeHttp
return H:JSONEncode({ok=ok,failure=why,files=out.files,sourceCount=#out.sources,httpRestored=H.HttpEnabled==beforeHttp})
