local F=game.ServerStorage.MoonlitP3ReworkRecovery.EnclosureRepair20261013
assert(not game.RunService:IsRunning() and workspace.Course_MoonlitCitadel:GetAttribute("SourceRevision")==48)
local original=game.ServerStorage.MoonlitP3ReworkRecovery.TowerLandscape20261013.ProtectedCourse
assert(not F:FindFirstChild("ProtectedCourse"));local m=original:Clone();m.Parent=F
local P=require(m)
local state={editable=P.Capture(workspace.Course_MoonlitCitadel),stored=P.Capture(game.ServerStorage.CourseLibrary.Course_MoonlitCitadel),phase1=P.CaptureFrozenPhase1Model(workspace.MoonlitCitadelPhase1_BL02),kit=P.CaptureAcceptedKit(game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library),arrows={},otherMaps={}}
for _,n in {"MC_P3_Rework_SolidArrow","MC_P3_Rework_ArrowMount"} do state.arrows[n]=P.CaptureArrowTemplate(game.ServerStorage.CourseAssetKits.MoonlitCitadel_P3Rework_RW01Library[n]) end
local E=game.EncodingService
local function hash(bytes)local b=E:ComputeBufferHash(bytes,Enum.HashAlgorithm.Sha256);local p={};for i=0,buffer.len(b)-1 do p[#p+1]=string.format("%02x",buffer.readu8(b,i))end;return table.concat(p)end
for _,root in game.ServerStorage.CourseLibrary:GetChildren() do if root~=game.ServerStorage.CourseLibrary.Course_MoonlitCitadel then
 local bytes=game.SerializationService:SerializeInstancesAsync({root});table.insert(state.otherMaps,{name=root.Name,descendants=#root:GetDescendants(),bytes=buffer.len(bytes),sha256=hash(bytes)});task.wait()
end end
local encoded=game.HttpService:JSONEncode(state);local chunks=Instance.new("Folder");chunks.Name,chunks.Parent="ProtectedBaseline48",F
for offset=1,#encoded,180000 do local c=Instance.new("StringValue");c.Name,c.Value,c.Parent=tostring(math.floor((offset-1)/180000)+1),encoded:sub(offset,offset+179999),chunks end
local H=game.HttpService;local old=H.HttpEnabled;local ok,r=pcall(function()H.HttpEnabled=true;return H:RequestAsync({Url="http://127.0.0.1:56117/enclosure_protected_baseline48.json",Method="POST",Headers={["Content-Type"]="application/json"},Body=encoded})end);H.HttpEnabled=old;assert(ok,r);assert(r.Success,r.Body)
local ambiguity={}for k,v in state do if k~="arrows" and k~="otherMaps" then ambiguity[k]=v.ambiguousDuplicateGroups end end
return H:JSONEncode({bytes=#encoded,ambiguity=ambiguity,otherMaps=state.otherMaps,httpRestored=H.HttpEnabled==old,receipt=H:JSONDecode(r.Body)})