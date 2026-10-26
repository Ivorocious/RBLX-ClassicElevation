assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177)
local H,E=game.HttpService,game.EncodingService
local recovery=game.ServerStorage.MoonlitP3ReworkRecovery
local library=game.ServerStorage.CourseLibrary
local oldLibrary,oldEditable=library.Course_MoonlitCitadel,workspace.Course_MoonlitCitadel
local oldHash='4f1f4a88263a7a2bcc59c5dbda9b570a3d02abe1f417c3d218803d0631611bfa' local hash='7c9e5532c3e6d6fb67c6a59af6c8ab50e33d3ef95a79e87d4fe776f9561f529c'
for _,m in {oldLibrary,oldEditable}do assert(m:GetAttribute('SourceRevision')==33 and m:GetAttribute('BuildRevision')==27 and m:GetAttribute('SourcePacketHash')==oldHash)end
local archive=recovery.BeforeAnimationCorrectionSource33Build27 assert(#archive:GetChildren()==0)
local course,editable,count
count=0
for _,m in recovery:GetChildren()do
 if m:IsA('Model') and m:GetAttribute('SourceRevision')==34 and m:GetAttribute('BuildRevision')==28 and m:GetAttribute('SourcePacketHash')==hash then
  count+=1 if m:GetAttribute('ManualEditing') then assert(not editable)editable=m else assert(not course)course=m end
 end
end
assert(count==2 and course and editable and #course:GetDescendants()==2572 and #editable:GetDescendants()==2572)
local protected={}for _,m in library:GetChildren()do if m~=oldLibrary then protected[m]=#m:GetDescendants()end end
local p1=workspace.MoonlitCitadelPhase1_BL02 local p1count=#p1:GetDescendants()
local camera=workspace.CurrentCamera local cf,focus,kind,fov=camera.CFrame,camera.Focus,camera.CameraType,camera.FieldOfView
local beforeHttp,day=H.HttpEnabled,game.Lighting.ClockTime
local swapped=false
local ok,failure=xpcall(function()
 H.HttpEnabled=true
 local response=H:RequestAsync({Url='http://127.0.0.1:56087/hardening_before_animation_source33_layout.json',Method='GET'})assert(response.Success)
 local owner=H:JSONDecode(response.Body) local origin=oldEditable:GetAttribute('Origin')
 for i,row in owner.parts do
  local part=oldEditable for name in row.path:gmatch('[^.]+')do part=assert(part:FindFirstChild(name))end
  local expected=CFrame.new(origin)*CFrame.new(table.unpack(row.cf))
  assert(part.ClassName==row.class and (part.Size-Vector3.new(table.unpack(row.size))).Magnitude<.001 and (part.CFrame.Position-expected.Position).Magnitude<.002 and part.CFrame.LookVector:Dot(expected.LookVector)>.999999 and part.CFrame.UpVector:Dot(expected.UpVector)>.999999)
  assert(part.CanCollide==row.collide and part.CanQuery==row.query and part.CanTouch==row.touch and part.Transparency==row.transparency and part.Material.Name==row.material)
  if part:IsA('MeshPart')then assert(part.MeshId==row.meshId and part.TextureID==row.textureId)end
  if i%300==0 then task.wait()end
 end
 oldLibrary.Name,oldEditable.Name='PriorLibraryCourse','PriorEditableCourse'
 oldLibrary.Parent,oldEditable.Parent=archive,archive swapped=true
 course.Parent,editable.Parent=library,workspace
 for m,n in protected do assert(m.Parent==library and #m:GetDescendants()==n)end
 assert(#library:GetChildren()==7 and #p1:GetDescendants()==p1count and game.Lighting.ClockTime==day)
end,debug.traceback)
if not ok and swapped then
 course.Parent,editable.Parent=recovery,recovery
 oldLibrary.Name,oldEditable.Name='Course_MoonlitCitadel','Course_MoonlitCitadel'
 oldLibrary.Parent,oldEditable.Parent=library,workspace
end
H.HttpEnabled=beforeHttp
return H:JSONEncode({ok=ok,failure=if ok then nil else failure,sourceHash=hash,sourceRevision=34,buildRevision=28,priorModelsPreserved=true,otherCoursesPreserved=true,phase1Preserved=true,httpRestored=H.HttpEnabled==beforeHttp,daylightPreserved=game.Lighting.ClockTime==day,cameraUnmodifiedByInstaller=true,cameraStayedAtSnapshot=camera.CFrame==cf and camera.Focus==focus and camera.CameraType==kind and camera.FieldOfView==fov,published=false,resources={instances=2572,parts=1617,meshes=1326,colliders=143,floors=131,redParts=55,arrows=15,signs=3,lights=13}})
