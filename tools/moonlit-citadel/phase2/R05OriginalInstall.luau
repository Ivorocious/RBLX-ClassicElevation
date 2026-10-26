assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177 and not game.RunService:IsRunning())
local E=game:GetService('EncodingService') local H=game.HttpService local guards={{path="game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig",className="ModuleScript",sha256="e5b8bbfad631f7626e82031fe0058ee621ee9fb61d1d714d247cc4c9a5e5424f",bytes=439},{path="game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Layout",className="ModuleScript",sha256="d285dd0145062af7c4d040d1a4b17465a05f8c1d99f4a6eabd0fb96aa6c776bb",bytes=19730},{path="game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.RouteBuilder",className="ModuleScript",sha256="4eb97e9104acf7c270891b871e81d82dd128b421cf4c057b788781af5177ef99",bytes=13274},{path="game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Runtime",className="ModuleScript",sha256="b8ae2514c69cdf125b8728219714dbd291abca256ef0190919821c187dac1bc9",bytes=24235},{path="game.ServerScriptService.Services.MoonlitCitadelService",className="ModuleScript",sha256="6f7fb8d7e0ff3822ea875e5e434a27556c249465e5ef76830e8439d36e80fbdb",bytes=2172},{path="game.ServerScriptService.Services.RespawnService",className="ModuleScript",sha256="8775379d47ea08f92453e1733882a12ce0efe51bfb143c77133c56f211117b0b",bytes=10582},{path="game.ServerScriptService.Main",className="Script",sha256="0985ce66ccb7173c0a11b66dd90e144f663bea07644d38c999c62b47ad28ec39",bytes=2573},{path="game.StarterPlayer.StarterPlayerScripts.Onboarding",className="LocalScript",sha256="d0fe112166ad5df28b139d260b248536c0712a2e4b74a797d6d05f398739e4b4",bytes=137},{path="game.StarterPlayer.StarterPlayerScripts.Tournament",className="LocalScript",sha256="1870f47af9c16536b6bd156eb9b67e0a8b8434416f725410db42eb6c4d88a0b3",bytes=137},{path="game.StarterPlayer.StarterPlayerScripts.StudioFlight",className="LocalScript",sha256="37cc08175b89d8b89eeef16e18eb76ace34b12110818f45b4d8c7f2420a7203a",bytes=195},{path="game.ReplicatedStorage.Config.MoonlitCitadelAssemblyConfig",className="ModuleScript",sha256="5057536c1013994b10a699312d0d23fc4022922f60ed969fa834901f7d9ecb7e",bytes=4917},{path="game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.VisualAssembly",className="ModuleScript",sha256="ab76f14c9282bd9fb42d7160f7c4673906359e958e01b6ac835804fbf60ad93f",bytes=2373}} local out={place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,sources={}} for _,x in ipairs(guards) do local inst=game for n in x.path:gmatch('[^%.]+') do if n~='game' then inst=inst and inst:FindFirstChild(n) end end local row={path=x.path,present=inst~=nil,class=inst and inst.ClassName,expected=x.sha256} if inst and inst:IsA('LuaSourceContainer') then local source=inst.Source:gsub('^\239\187\191',''):gsub('\r\n','\n') local b=E:ComputeBufferHash(buffer.fromstring(source),Enum.HashAlgorithm.Sha256) local hex={} for i=0,buffer.len(b)-1 do hex[#hex+1]=string.format('%02x',buffer.readu8(b,i)) end row.bytes=#source row.sha256=table.concat(hex) row.agrees=row.sha256==x.sha256 and row.bytes==x.bytes and row.class==x.className end out.sources[#out.sources+1]=row end for _,x in ipairs(out.sources) do assert(x.agrees,'Production source agreement required: '..x.path) end
local H=game.HttpService local oldHttp=H.HttpEnabled local E=game:GetService("EncodingService") local S=game:GetService("SerializationService")
local lib=game.ServerStorage.CourseLibrary local prior=lib.Course_MoonlitCitadel
assert(#lib:GetChildren()==7 and prior:GetAttribute("CandidateId")=="MC_P2_C01_R04" and #prior:GetDescendants()==2856)
assert(not game.ServerStorage:FindFirstChild("MoonlitR05OriginalRecovery"))
local p1=workspace.MoonlitCitadelPhase1_BL02 local kit=game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library
assert(p1:GetAttribute("PreviewEnabled")==false)
local function hash(b) local h=E:ComputeBufferHash(b,Enum.HashAlgorithm.Sha256) local a={} for i=0,buffer.len(h)-1 do a[#a+1]=string.format("%02x",buffer.readu8(h,i)) end return table.concat(a) end
local six={} for _,x in ipairs(lib:GetChildren()) do if x~=prior then six[#six+1]=x end end
local sixBefore=hash(S:SerializeInstancesAsync(six))
local priorBefore=hash(S:SerializeInstancesAsync({prior}))
local cam=workspace.CurrentCamera local beforeCamera, beforeFocus=cam.CFrame,cam.Focus local beforeType=cam.CameraType
local result={candidate="MC_P2_C01_R05",sources=out.sources,place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,sixBefore=sixBefore,archivedNativeBefore=priorBefore,httpBefore=oldHttp,cameraPreserved=false,clock=game.Lighting.ClockTime,recovery={}}
local archive,newCourse
local ok,err=xpcall(function()
 H.HttpEnabled=true
 local reply=H:RequestAsync({Url="http://127.0.0.1:53494/MC_P2_C01_R05_native_final.rbxm",Method="GET"})
 assert(reply.Success)
 local input=buffer.fromstring(reply.Body)
 assert(buffer.len(input)==205064 and hash(input)=="e4b6fd6521fc5e3021c1ca322772c05f2fa8b4b87ec310cd09f79c1f43d4c6e4")
 local roots=S:DeserializeInstancesAsync(input)
 assert(#roots==1)
 newCourse=roots[1]
 assert(newCourse:IsA("Model") and newCourse.Name=="Course_MoonlitCitadel" and newCourse:GetAttribute("CandidateId")=="MC_P2_C01_R05" and newCourse:GetAttribute("VisualAssemblyApplied")==true and #newCourse:GetDescendants()==2870)
 assert(hash(S:SerializeInstancesAsync({newCourse}))==hash(input))
 archive=Instance.new("Folder") archive.Name="MoonlitR05OriginalRecovery" archive.Parent=game.ServerStorage
 local finalB=Instance.new("Folder") finalB.Name="MC_P2_C01_R04_FinalB" finalB.Parent=archive
 prior.Parent=finalB
 newCourse.Parent=lib
 assert(#lib:GetChildren()==7 and lib.Course_MoonlitCitadel==newCourse)
 result.sixAfter=hash(S:SerializeInstancesAsync(six))
 result.archivedNativeAfter=hash(S:SerializeInstancesAsync({prior}))
 result.installedNativeSha256=hash(S:SerializeInstancesAsync({newCourse}))
 assert(result.sixAfter==sixBefore and result.archivedNativeAfter==priorBefore and result.installedNativeSha256==hash(input))
 local buffers={
  {name="MC_P2_original_R05_postinstall_library_20261011.rbxm",data=S:SerializeInstancesAsync({lib})},
  {name="MC_P2_original_R05_postinstall_P1_20261011.rbxm",data=S:SerializeInstancesAsync({p1,kit})},
  {name="MC_P2_original_R05_archived_FinalB_20261011.rbxm",data=S:SerializeInstancesAsync({prior})}
 }
 for _,x in ipairs(buffers) do
  local h=hash(x.data)
  if x.name:find("postinstall_P1",1,true) then assert(h=="7019c52ff336186830c20905eb561dd613b395bdc0e9ea798de7ae437cac9837") end
  local reply=H:RequestAsync({Url="http://127.0.0.1:53494/"..x.name,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=buffer.tostring(x.data)})
  assert(reply.Success,reply.StatusCode)
  local row=H:JSONDecode(reply.Body)
  assert(row.sha256==h and row.bytes==buffer.len(x.data))
  result.recovery[#result.recovery+1]=row
 end
 result.coursePath=newCourse:GetFullName()
 result.archivePath=prior:GetFullName()
 result.libraryEntries=#lib:GetChildren()
 result.p1Desc=#p1:GetDescendants() result.kitDesc=#kit:GetDescendants()
 result.previewEnabled=p1:GetAttribute("PreviewEnabled")
 result.wholeOriginalPlaceSaved=false result.published=false
end,debug.traceback)
H.HttpEnabled=oldHttp
result.httpAfter=H.HttpEnabled
result.cameraPreserved=cam.CFrame==beforeCamera and cam.Focus==beforeFocus and cam.CameraType==beforeType
result.ok,result.failure=ok,if ok then nil else tostring(err)
return H:JSONEncode(result)
