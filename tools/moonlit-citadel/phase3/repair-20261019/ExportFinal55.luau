local ss=game:GetService("ServerStorage")
local rec=ss.MoonlitP3ReworkRecovery.Repair20261019
local H=game:GetService("HttpService")
assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
local snapshot=require(ss.MoonlitP3ReworkRecovery.DetailPass20261014.CaptureSnapshot53)
local before=snapshot.ReadChunks(rec.BeforeSnapshot54)
local cam=before.camera.records[""].props
workspace.CurrentCamera.CameraType=Enum.CameraType.Fixed
workspace.CurrentCamera.CFrame=CFrame.new(table.unpack(cam.CFrame.value))
workspace.CurrentCamera.Focus=CFrame.new(table.unpack(cam.Focus.value))
workspace.CurrentCamera.FieldOfView=cam.FieldOfView
local enc=game:GetService("EncodingService")
local function hash(b)
 local digest=enc:ComputeBufferHash(b,Enum.HashAlgorithm.Sha256) local t={}
 for i=0,buffer.len(digest)-1 do t[#t+1]=string.format("%02x",buffer.readu8(digest,i)) end return table.concat(t)
end
local oldHttp=H.HttpEnabled
local ok,result=xpcall(function()
 H.HttpEnabled=true
 local function post(name,body,contentType)
  local b=if typeof(body)=="buffer" then body else buffer.fromstring(body)
  local response=H:RequestAsync({Url="http://127.0.0.1:56150/"..name,Method="POST",Headers={["Content-Type"]=contentType or "application/octet-stream"},Body=buffer.tostring(b)})
  assert(response.Success,name..":"..response.StatusCode..":"..response.Body)
  local receipt=H:JSONDecode(response.Body) assert(receipt.bytes==buffer.len(b) and receipt.sha256==hash(b),name.." SHA")
  return receipt
 end
 local files={}
 local S=game:GetService("SerializationService")
 table.insert(files,post("repair_final55_models.rbxm",S:SerializeInstancesAsync({workspace.Course_MoonlitCitadel,ss.CourseLibrary.Course_MoonlitCitadel})))
 table.insert(files,post("repair_final55_modules.rbxm",S:SerializeInstancesAsync({ss.CourseBuilders.MoonlitCitadelCourse,game.ReplicatedStorage.Config.MoonlitCitadelAmbienceConfig,game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig,game.ServerScriptService.Services.CheckpointService,game.ReplicatedStorage.Shared.ForwardGate})))
 table.insert(files,post("repair_final55_depth_library.rbxm",S:SerializeInstancesAsync({ss.CourseAssetKits.MoonlitCitadel_Depth_DP01Library})))
 local beforeGuard=H:JSONDecode(rec.SourceGuardBefore.Value)
 local allowed={Layout=true,EnvironmentPlan=true,VisualAssembly=true,WorldAssembly=true,WorldPlan=true}
 local unchanged,changed=0,{}
 for i,row in beforeGuard do
  local item=game for segment in row.path:gmatch("[^%.]+") do item=assert(item:FindFirstChild(segment),row.path) end
  local h=hash(buffer.fromstring((item.Source:gsub("\r\n","\n"))))
  if h==row.sha256 then unchanged+=1 else
   assert(row.path:sub(1,53)=="ServerStorage.CourseBuilders.MoonlitCitadelCourse." or row.path:find("^ServerStorage.CourseBuilders.MoonlitCitadelCourse%."))
   assert(allowed[item.Name],row.path) table.insert(changed,{path=row.path,sha256=h,beforeSHA256=row.sha256})
  end
  if i%50==0 then task.wait() end
 end
 assert(#changed==5 and unchanged==269)
 local packet=H:JSONDecode(H:GetAsync("http://127.0.0.1:56150/repair_source55_packet_final.json"))
 for _,row in packet.records do
  local item=if row.name=="MoonlitCitadelAmbienceConfig" then game.ReplicatedStorage.Config[row.name] else ss.CourseBuilders.MoonlitCitadelCourse[row.name]
  assert(item.Source:gsub("\r\n","\n")==row.source and hash(buffer.fromstring(row.source))==row.sha256)
 end
 table.insert(files,post("repair_final55_source_guard.json",H:JSONEncode({pass=true,beforeCount=#beforeGuard,unchanged=unchanged,changed=changed,newModules={"ArtRepairPlan","DepthPlan","SurfaceSeparation"},packetRecords=#packet.records,packetSHA256=rec:GetAttribute("FinalSource55PacketSHA256")}),"application/json"))
 table.insert(files,post("repair_final55_detail_append.json",rec.DetailAppendProof55.Value,"application/json"))
 table.insert(files,post("repair_final55_cleanup_manifest.json",rec.CleanupAfterManifest.Value,"application/json"))
 H.HttpEnabled=oldHttp
 local state=snapshot.CaptureSession({editable=workspace.Course_MoonlitCitadel,stored=ss.CourseLibrary.Course_MoonlitCitadel})
 local snapReceipt,raw=snapshot.SaveChunks(rec,"AfterSnapshot55",state)
 H.HttpEnabled=true
 for offset=1,#raw,1000000 do
  local index=math.ceil(offset/1000000)
  table.insert(files,post(string.format("repair_final55_snapshot_part%02d.json",index),raw:sub(offset,offset+999999),"application/json"))
 end
 local result={source=55,build=49,candidate="MC_P3_REPAIR_20261019",snapshot=snapReceipt,files=files,
  packetSHA256=rec:GetAttribute("FinalSource55PacketSHA256"),noPublish=true,noWholePlaceSave=true}
 local receipt=post("repair_final55_receipt.json",H:JSONEncode(result),"application/json")
 local v=Instance.new("StringValue") v.Name,v.Value,v.Parent="FinalReceipt55",H:JSONEncode(result),rec
 return {snapshot=snapReceipt,files=#files,receipt=receipt,packetSHA256=result.packetSHA256}
end,debug.traceback)
H.HttpEnabled=oldHttp
assert(ok,result)
return result