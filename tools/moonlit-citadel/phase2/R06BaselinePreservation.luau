assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177 and not game.RunService:IsRunning(),"Original Edit identity required")
local H=game.HttpService local S=game:GetService("SerializationService") local E=game:GetService("EncodingService") local beforeHttp=H.HttpEnabled
local library=game.ServerStorage.CourseLibrary local prior=library.Course_MoonlitCitadel
assert(prior:GetAttribute("CandidateId")=="MC_P2_C01_R05" and #library:GetChildren()==7)
local p1=workspace.MoonlitCitadelPhase1_BL02 local kit=game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library
local function hash(b) local h=E:ComputeBufferHash(b,Enum.HashAlgorithm.Sha256) local a={} for i=0,buffer.len(h)-1 do a[#a+1]=string.format("%02x",buffer.readu8(h,i)) end return table.concat(a) end
local camera=workspace.CurrentCamera local frame,focus,kind=camera.CFrame,camera.Focus,camera.CameraType
local out={candidate="MC_P2_C01_R06",baselineCandidate="MC_P2_C01_R05",place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,clock=game.Lighting.ClockTime,files={},httpBefore=beforeHttp}
local ok,err=xpcall(function()
 H.HttpEnabled=true
 for _,x in ipairs({{name="MC_P2_R06_original_before_library.rbxm",items={library}},{name="MC_P2_R06_original_before_P1.rbxm",items={p1,kit}},{name="MC_P2_R06_original_before_course.rbxm",items={prior}}}) do
  local b=S:SerializeInstancesAsync(x.items) local h=hash(b)
  local r=H:RequestAsync({Url="http://127.0.0.1:60259/"..x.name,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=buffer.tostring(b)}) assert(r.Success,r.StatusCode)
  local receipt=H:JSONDecode(r.Body) assert(receipt.sha256==h and receipt.bytes==buffer.len(b))
  out.files[#out.files+1]=receipt
 end
end,debug.traceback)
H.HttpEnabled=beforeHttp
out.httpAfter=H.HttpEnabled out.cameraPreserved=camera.CFrame==frame and camera.Focus==focus and camera.CameraType==kind out.previewEnabled=p1:GetAttribute("PreviewEnabled") out.ok=ok out.failure=if ok then nil else tostring(err)
out.wholeOriginalPlaceSaved=false out.published=false
return H:JSONEncode(out)
