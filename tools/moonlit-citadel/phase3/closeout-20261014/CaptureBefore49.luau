assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
local recovery=game.ServerStorage.MoonlitP3ReworkRecovery
assert(not recovery:FindFirstChild("Closeout20261014"),"Closeout recovery already exists")
local F=Instance.new("Folder");F.Name="Closeout20261014";F.Parent=recovery
local m=recovery.EnclosureRepair20261013.ProtectedCourse:Clone();m.Parent=F
local P=require(m)
local state={editable=P.Capture(workspace.Course_MoonlitCitadel),stored=P.Capture(game.ServerStorage.CourseLibrary.Course_MoonlitCitadel),phase1=P.CaptureFrozenPhase1Model(workspace.MoonlitCitadelPhase1_BL02),kit=P.CaptureAcceptedKit(game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library),arrows={},otherMaps={}}
for _,n in {"MC_P3_Rework_SolidArrow","MC_P3_Rework_ArrowMount"} do state.arrows[n]=P.CaptureArrowTemplate(game.ServerStorage.CourseAssetKits.MoonlitCitadel_P3Rework_RW01Library[n]) end
local E=game:GetService("EncodingService")
local function hash(bytes)local b=E:ComputeBufferHash(bytes,Enum.HashAlgorithm.Sha256);local p={};for i=0,buffer.len(b)-1 do p[#p+1]=string.format("%02x",buffer.readu8(b,i))end;return table.concat(p)end
for _,root in game.ServerStorage.CourseLibrary:GetChildren() do if root~=game.ServerStorage.CourseLibrary.Course_MoonlitCitadel then
 local bytes=game:GetService("SerializationService"):SerializeInstancesAsync({root});table.insert(state.otherMaps,{name=root.Name,descendants=#root:GetDescendants(),bytes=buffer.len(bytes),sha256=hash(bytes)});task.wait()
end end
local H=game:GetService("HttpService")
local encoded=H:JSONEncode(state);local chunks=Instance.new("Folder");chunks.Name="ProtectedBaseline49";chunks.Parent=F
for offset=1,#encoded,180000 do local c=Instance.new("StringValue");c.Name=tostring(math.floor((offset-1)/180000)+1);c.Value=encoded:sub(offset,offset+179999);c.Parent=chunks end
local old=H.HttpEnabled;local ok,r=pcall(function()H.HttpEnabled=true;return H:RequestAsync({Url="http://127.0.0.1:56118/closeout_protected_baseline49.json",Method="POST",Headers={["Content-Type"]="application/json"},Body=encoded})end);H.HttpEnabled=old;assert(ok,r);assert(r.Success,r.Body)
return H:JSONEncode({bytes=#encoded,otherMaps=state.otherMaps,httpRestored=H.HttpEnabled==old,receipt=H:JSONDecode(r.Body),recovery=F:GetFullName()})