assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177 and not game.RunService:IsRunning())
local H=game.HttpService local oldHttp=H.HttpEnabled local S=game:GetService("SerializationService") local E=game:GetService("EncodingService")
local lib=assert(game.ServerStorage.CourseLibrary)
assert(#lib:GetChildren()==7 and lib.Course_MoonlitCitadel:GetAttribute("CandidateId")=="MC_P2_C01_R04")
local p1=assert(workspace.MoonlitCitadelPhase1_BL02) local kit=assert(game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library)
local function hash(b) local h=E:ComputeBufferHash(b,Enum.HashAlgorithm.Sha256) local a={} for i=0,buffer.len(h)-1 do a[#a+1]=string.format("%02x",buffer.readu8(h,i)) end return table.concat(a) end
local out={place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,mode="Edit",clock=game.Lighting.ClockTime,httpBefore=oldHttp,camera={workspace.CurrentCamera.CFrame:GetComponents()},focus={workspace.CurrentCamera.Focus:GetComponents()},cameraType=workspace.CurrentCamera.CameraType.Name,backups={},p1Desc=#p1:GetDescendants(),kitDesc=#kit:GetDescendants(),previewEnabled=p1:GetAttribute("PreviewEnabled")}
local ok,err=xpcall(function()
 local buffers={
  {name="MC_P2_original_R05_preinstall_library_20261011.rbxm",data=S:SerializeInstancesAsync({lib}),expected="9a0ae81ee73216043257294fd35c0c73bf055ab377272a49909ac79a2090bcf2"},
  {name="MC_P2_original_R05_preinstall_P1_20261011.rbxm",data=S:SerializeInstancesAsync({p1,kit}),expected="7019c52ff336186830c20905eb561dd613b395bdc0e9ea798de7ae437cac9837"}
 }
 H.HttpEnabled=true
 for _,x in ipairs(buffers) do
  local h=hash(x.data)
  assert(h==x.expected,"Current original geometry differs from sealed original: "..x.name.." "..h)
  local reply=H:RequestAsync({Url="http://127.0.0.1:53494/"..x.name,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=buffer.tostring(x.data)})
  assert(reply.Success,reply.StatusCode)
  local row=H:JSONDecode(reply.Body)
  assert(row.sha256==h and row.bytes==buffer.len(x.data))
  out.backups[#out.backups+1]=row
 end
end,debug.traceback)
H.HttpEnabled=oldHttp
out.httpAfter=H.HttpEnabled
assert(ok,err)
return H:JSONEncode(out)
