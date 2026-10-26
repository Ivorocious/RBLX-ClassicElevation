return function(port)
local Run,H,E,S=game:GetService("RunService"),game.HttpService,game:GetService("EncodingService"),game:GetService("SerializationService")
assert(Run:IsStudio() and Run:IsRunning() and Run:IsServer() and game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177)
assert(#game.Players:GetPlayers()==1 and game.Players:GetPlayerByUserId(86069177) and H.HttpEnabled==false)
assert(type(port)=="number" and port%1==0 and port>0 and port<65536)
local specs={{"MC_P2_C01_R06_NoJump_fa1a36ba6de443258802916f1aeaf33e","setup_failure02","Failed"},{"MC_P2_C01_R06_NoJump_8d8d95b3fd7344469c0da7c2f35960fb","normal02","Complete"},{"MC_P2_C01_R06_NoJump_412575e093434470b683d2ade8288faa","expert01","Complete"}}
local function hex(b) local t={} for i=0,buffer.len(b)-1 do t[#t+1]=string.format("%02x",buffer.readu8(b,i)) end return table.concat(t) end
local function hash(b) return hex(E:ComputeBufferHash(b,Enum.HashAlgorithm.Sha256)) end
local reports={}
local before=H.HttpEnabled
local ok,err=xpcall(function()
H.HttpEnabled=true
for _,spec in specs do
 local name,label,state=table.unpack(spec)
 local f=assert(game.ServerStorage.MoonlitPhase2Evidence:FindFirstChild(name)) assert(f:IsA("Folder"))
 local remote=assert(game.ReplicatedStorage.Remotes:FindFirstChild(name))
 assert(remote:GetAttribute("OwnedNoJump")==name and remote:GetAttribute("DriverActive")==false)
 local chunks={} local count=math.ceil(assert(f:GetAttribute("JSONBytes"))/140000)
 assert(count>=1 and count<=64)
 for i=1,count do local v=assert(f:FindFirstChild(string.format("JSON_%03d",i))) assert(v:IsA("StringValue")) chunks[i]=v.Value end
 local raw=table.concat(chunks) assert(#raw==f:GetAttribute("JSONBytes") and #f:GetChildren()==count)
 local data=H:JSONDecode(raw)
 assert(data.state==state and data.packet.owner==name and data.packet.userId==86069177 and data.packet.candidate=="MC_P2_C01_R06")
 local native=S:SerializeInstancesAsync({f}) local sha=hash(native)
 assert(buffer.len(native)>=32 and buffer.len(native)<=4194304 and hex(buffer.fromstring(buffer.tostring(native):sub(1,32))):sub(1,28)=="3c726f626c6f782189ff0d0a1a0a")
 local file="MC_P2_R06_nojump_"..label.."_server.rbxm"
 local url="http://127.0.0.1:"..port.."/"..file
 local posted=H:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=buffer.tostring(native)})
 assert(posted.Success and posted.StatusCode==200)
 local receipt=H:JSONDecode(posted.Body)
 assert(receipt.bytes==buffer.len(native) and receipt.sha256==sha and receipt.path:gsub("\\","/"):lower()=="c:/users/ivorr/robloxdevelopment/projectclassicelevation/docs/artifacts/moonlit-citadel/phase2/"..file:lower())
 local fetched=H:RequestAsync({Url=url,Method="GET"})
 assert(fetched.Success and fetched.StatusCode==200 and fetched.Body==buffer.tostring(native))
 assert(remote:GetAttribute("DriverActive")==false)
 for i,v in chunks do assert(f:FindFirstChild(string.format("JSON_%03d",i)).Value==v) end
 reports[#reports+1]={actualServerMCP=true,serializationOrigin="privileged-MCP-actual-server",sourcePath=f:GetFullName(),sourceClass=f.ClassName,sourceAttributes=f:GetAttributes(),ownershipMarker={remotePath=remote:GetFullName(),ownedNoJump=name,driverActive=false},name=data.packet.name,raceId=data.packet.raceId,state=data.state,nativeBytes=buffer.len(native),nativeSha256=sha,rawJsonSha256=hash(buffer.fromstring(raw)),postReceipt=receipt,exactNativeReadback=true,at=workspace:GetServerTimeNow(),nativeProof=false}
 task.wait()
end
end,debug.traceback)
H.HttpEnabled=before
assert(H.HttpEnabled==false)
return H:JSONEncode({ok=ok,failure=not ok and tostring(err) or nil,reports=reports,httpEnabledRestored=true,actualServerMCP=true})
end