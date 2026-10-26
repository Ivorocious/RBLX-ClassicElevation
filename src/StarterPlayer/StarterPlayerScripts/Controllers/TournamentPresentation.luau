--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local OnboardingConfig = require(game.ReplicatedStorage.Config.OnboardingConfig)
local DeliveryConfig = require(game.ReplicatedStorage.Config.GrandArcadeConfig)
local Assets = require(script.Parent.ArrivalAssets)
local Ownership = require(script.Parent.CameraOwnership)
local Theme = require(script.Parent.UiTheme)
local Kit = require(script.Parent.UiKit)
local View = require(script.Parent.NextCourseView)
local RacePresentation = require(script.Parent.RacePresentation)
local Controller = {}
local event: any = nil
local onAction: ((string) -> ())? = nil
-- Ticket looks must never break course delivery, so view errors are only logged.
local function show(name: string, ...: any): any
 if name~="Create" and name~="ShowFailed" and (...)==nil then return nil end
 local ok,result=pcall((View :: any)[name],...)
 if not ok then warn("[CourseDelivery] ticket: "..tostring(result)); return nil end
 return result
end
local player = Players.LocalPlayer
local active: any = nil
local sequence = 0
local seen: {[string]: boolean} = {}
local completed: {[string]: boolean} = {}
local function now() return workspace:GetServerTimeNow() end
local function matchesCourse(course: Instance,courseId: string): boolean
 local info=course:FindFirstChild("CourseInfo")
 return course:GetAttribute("CourseId")==courseId or course:GetAttribute("SourceCourseId")==courseId or (info~=nil and info:GetAttribute("CourseId")==courseId)
end
local function contentKey(value: string): string
 local id=value:match("^rbxassetid://(%d+)") or value:match("[?&]id=(%d+)")
 return if id then "asset:"..id else value
end
local function diagnose(owner: any,key: string,value: any)
 if RunService:IsStudio() and player:GetAttribute("CourseDeliveryToken")==owner.token then player:SetAttribute("CourseDelivery"..key,value) end
end
local function mark(owner: any,stage: string)
 owner.stage=stage
 diagnose(owner,"Stage",stage); diagnose(owner,"StageAt",now())
end

function Controller.Stop(reason: string?)
 sequence += 1
 local owner = active; active = nil
 if not owner then return end
 diagnose(owner,"StopReason",reason or "ExternalStop")
 diagnose(owner,"StopStage",owner.stage); diagnose(owner,"StoppedAt",now())
 diagnose(owner,"StopEnrolled",player:GetAttribute("RaceEnrolled"))
 diagnose(owner,"StopArrivalOpen",player:GetAttribute("ArrivalOpen"))
 diagnose(owner,"StopOnboardingReady",player:GetAttribute("OnboardingReady"))
 diagnose(owner,"StopSnapshot",tostring(owner.snapshot.state).."/"..tostring(owner.snapshot.status).."/entryOpen="..tostring(owner.snapshot.entryOpen))
 if RunService:IsStudio() and not owner.complete then
  warn("[CourseDelivery] stopped: "..tostring(reason or "ExternalStop").."; stage="..tostring(owner.stage).."; required request returned="..tostring(owner.geometryDone).."; failure="..tostring(owner.geometryReason))
 end
 RunService:UnbindFromRenderStep("GrandArcadeCamera")
 for _,connection in owner.connections do connection:Disconnect() end
 if owner.cue then owner.cue:Destroy() end
 if owner.glow then owner.glow:Destroy() end
 Ownership.Release(owner.lease)
 if owner.gui then owner.gui:Destroy() end
 player:SetAttribute("TournamentPresentation",false)
end
function Controller.Forget(token: string) completed[token]=nil end
-- Latest tournament snapshot, for the ticket's race number only.
function Controller.SetEvent(snapshot: any) event=snapshot end
-- Race options actions, for the failed ticket's Watch racers button.
function Controller.SetActions(activate: (string) -> ()) onAction=activate end
local failedShown: {[string]: boolean} = {}
-- Pink ticket with the server's message when an enrolled player's preparation fails (once per token).
function Controller.ShowFailure(snapshot: any)
 local prep=snapshot and snapshot.preparation
 if not prep or prep.status~="Failed" or typeof(prep.token)~="string" or failedShown[prep.token] or snapshot.enrolled~=true then return end
 failedShown[prep.token]=true
 show("ShowFailed",player:WaitForChild("PlayerGui"),tostring(snapshot.courseDisplayName or prep.courseId or "the course"),
  tostring(prep.message or "This course couldn't be prepared."),#(snapshot.watchTargets or {})>0,onAction)
end
function Controller.IsActive(): boolean return active ~= nil end
function Controller.HasSession(token: string): boolean return completed[token] == true or (active ~= nil and active.token == token) end
function Controller.Update(snapshot: any)
 if active and snapshot.preparation and active.token == snapshot.preparation.token then active.snapshot = snapshot end
end
function Controller.Start(snapshot: any, acknowledge: (string,string) -> (), cameraReady: ((string) -> ())?)
 local prep = snapshot.preparation
 if not prep or typeof(prep.token) ~= "string" or completed[prep.token] then return end
 Controller.Stop("Superseded")
 local owner: any = {token=prep.token,snapshot=snapshot,connections={},skip=false,loaded=false}
 active = owner
 if RunService:IsStudio() then
  player:SetAttribute("CourseDeliveryToken",prep.token)
  for _,key in {"Error","StopReason","StopStage","StoppedAt","RequiredFirstFailure","RequiredRequestError","RequiredRequestReturned","RequiredRequestSucceeded","RequiredCallbacks","RequiredFailures","RequiredCount","RequiredMeshList","Floor","CourseParts","ExpectedParts"} do diagnose(owner,key,nil) end
  for index=1,16 do diagnose(owner,"Asset"..index,nil) end
 end
 mark(owner,"Starting")
 local epoch = sequence
 local function valid(): boolean
  return active == owner and sequence == epoch and player:GetAttribute("ArrivalOpen") ~= true
   and player:GetAttribute("OnboardingReady") == true
   and owner.snapshot.enrolled == true and owner.snapshot.status ~= "Racing"
   and owner.snapshot.entryOpen==true and owner.snapshot.state=="Intermission"
 end
 task.spawn(function()
  local ok,reason = pcall(function()
   local deadline = os.clock()+DeliveryConfig.DeliveryTimeout+DeliveryConfig.ReadyTimeout+DeliveryConfig.RenderTimeout+DeliveryConfig.OpeningSeconds
   diagnose(owner,"DeadlineAt",now()+deadline-os.clock())
   mark(owner,"WaitingArrival")
   while player:GetAttribute("ArrivalOpen")==true or player:GetAttribute("OnboardingReady")~=true do
    assert(active==owner and os.clock()<deadline,"Arrival still preparing"); task.wait(.1)
   end
   assert(valid(),"Not participating")
   local character = player.Character
   local humanoid = character and character:FindFirstChildOfClass("Humanoid")
   assert(humanoid and humanoid.Health>0,"Character unavailable")
   table.insert(owner.connections,humanoid.Died:Connect(function() Controller.Stop("HumanoidDied") end))
   table.insert(owner.connections,player.CharacterRemoving:Connect(function() Controller.Stop("CharacterRemoving") end))
   table.insert(owner.connections,workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Controller.Stop("CurrentCameraChanged") end))
   table.insert(owner.connections,player:GetAttributeChangedSignal("ArrivalOpen"):Connect(function() if player:GetAttribute("ArrivalOpen")==true then Controller.Stop("ArrivalOpened") end end))
   owner.gui = Instance.new("ScreenGui")
   owner.gui.Name,owner.gui.ResetOnSpawn,owner.gui.DisplayOrder = "CourseDelivery",false,70
   owner.gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
   owner.gui.Parent = player:WaitForChild("PlayerGui")
   local ticket = show("Create",owner.gui,{skip=function() owner.skip=true end,
    reduce=function() player:SetAttribute("ReducedMotion",player:GetAttribute("ReducedMotion")~=true) end})
   show("SetHeader",ticket,RacePresentation.RaceNumber(event,prep.courseId),tostring(snapshot.courseDisplayName or prep.courseId))
   show("SetStep",ticket,2,"Loading the course…",true)
   local loadingSince = os.clock()
   -- Slow loading keeps the ticket and reassures the player; it never changes the delivery itself.
   local function loadingNote() show("SetStep",ticket,2,if os.clock()-loadingSince>5 then "Still loading. Hang tight, your spot is saved" else "Loading the course…",true) end
   local curtain = Instance.new("Frame")
   curtain.Name,curtain.Size,curtain.BackgroundColor3,curtain.BackgroundTransparency,curtain.BorderSizePixel = "MatchFade",UDim2.fromScale(1,1),Kit.Navy,1,0
   curtain.ZIndex,curtain.Parent = 0,owner.gui
   RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
   assert(valid(),"Cancelled")
   acknowledge(prep.token,"Rendered")
   mark(owner,"WaitingCourse")
   local course,startPart = nil,nil
   while valid() and os.clock()<deadline do
    local current = owner.snapshot.preparation
    assert(current and current.token==prep.token and current.status~="Failed","Preparation cancelled")
    local delivery = current.delivery or current
    local candidate = workspace:FindFirstChild(delivery.modelName or "RaceCourse")
    if candidate and matchesCourse(candidate,prep.courseId) then
     local start = candidate:FindFirstChild("Start",true)
     if start and start:IsA("BasePart") then
      if workspace.StreamingEnabled then player:RequestStreamAroundAsync(start.Position,5) end
      local parts = 0
      for _,part in candidate:GetDescendants() do if part:IsA("BasePart") then parts+=1 end end
      diagnose(owner,"CourseParts",parts); diagnose(owner,"ExpectedParts",delivery.expectedParts)
      if not delivery.expectedParts or parts>=delivery.expectedParts then course,startPart=candidate,start; break end
     end
    end
    loadingNote()
    task.wait(.1)
   end
   assert(valid() and course and startPart,"Course delivery timed out")
   mark(owner,"CourseReplicated")
   local function reportOptional(id: string,status: string)
    if valid() then warn("[CourseDelivery] Optional visual "..id..": "..status) end
   end
   local assets = Assets.LobbyVisuals(course)
   for _,item in Assets.CharacterVisuals(character) do table.insert(assets,item) end
   task.spawn(function()
    Assets.WarmOptional(ContentProvider,assets,reportOptional)
   end)
   show("SetStep",ticket,2,"Course loaded · waiting for safe delivery",true)
   mark(owner,"WaitingSpawn")
   local function delivered(): (boolean,BasePart?)
    local root=character:FindFirstChild("HumanoidRootPart")
    if player.Character~=character or humanoid.Health<=0 or not root or not root:IsA("BasePart") then return false end
    local current=owner.snapshot.preparation
    local delivery=current.delivery or current
    local spawn=delivery.startPosition or startPart.Position
    if (root.Position-spawn).Magnitude>80 then return false end
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={course}; params.RespectCanCollide=true
    local floor=workspace:Raycast(root.Position,Vector3.new(0,-12,0),params)
    if floor and floor.Instance:IsA("BasePart") and floor.Instance.CanCollide and floor.Instance:IsDescendantOf(course) then return true,floor.Instance end
    return false,nil
   end
   while valid() and not delivered() and os.clock()<deadline do task.wait(.05) end
   local safe,floor=delivered()
   assert(valid() and safe and floor,"Safe spawn not delivered")
   mark(owner,"SpawnDelivered"); diagnose(owner,"Floor",floor:GetFullName())
   local geometry,meshKeys,meshList={},{},{}
   for _,part in course:GetDescendants() do
    if part:IsA("MeshPart") and part.MeshId~="" and (part.CanCollide or part==floor or part:GetAttribute("ERSupport")==true or part:GetAttribute("ERLethal")==true) then
     table.insert(geometry,part)
     meshKeys[contentKey(part.MeshId)]=true
     table.insert(meshList,part:GetFullName().."="..part.MeshId)
    end
   end
   local geometryDone,geometryReady=false,false
   local geometryReason: string?=nil
   owner.geometryDone=false
   diagnose(owner,"RequiredCount",#geometry); diagnose(owner,"RequiredMeshList",table.concat(meshList,";"))
   diagnose(owner,"RequiredRequestReturned",false)
   local samples,requiredCallbacks,requiredFailures=0,0,0
   mark(owner,"RequiredGeometry")
   task.spawn(function()
    local success,reason=pcall(function()
     if #geometry==0 then return end
     ContentProvider:PreloadAsync(geometry,function(id,status)
      local required=meshKeys[contentKey(tostring(id))]==true
      if required then requiredCallbacks+=1; diagnose(owner,"RequiredCallbacks",requiredCallbacks) end
      samples+=1
      if samples<=16 then diagnose(owner,"Asset"..samples,tostring(id).." | "..tostring(status).." | "..status.Name.." | required="..tostring(required).." | at="..tostring(now())) end
      if status.Name=="Success" then return end
      if required then
       geometryReason="Required course mesh unavailable: "..tostring(id).." ("..status.Name..")"
       requiredFailures+=1; diagnose(owner,"RequiredFailures",requiredFailures)
       if requiredFailures==1 then diagnose(owner,"RequiredFirstFailure",geometryReason) end
       owner.geometryReason=geometryReason
       if RunService:IsStudio() then warn("[CourseDelivery] "..geometryReason) end
      else reportOptional(tostring(id),status.Name) end
     end)
    end)
    if not success then geometryReason="Required course geometry preload failed: "..tostring(reason); diagnose(owner,"RequiredRequestError",tostring(reason)) end
    geometryReady=success and geometryReason==nil
    geometryDone=true
    owner.geometryDone,owner.geometryReason=true,geometryReason
    diagnose(owner,"RequiredRequestReturned",true); diagnose(owner,"RequiredRequestSucceeded",geometryReady)
   end)
   while valid() and not geometryDone and os.clock()<deadline do loadingNote(); task.wait(.05) end
   assert(valid() and geometryDone and geometryReady and delivered(),geometryReason or "Course geometry unavailable")
   owner.loaded=true
   acknowledge(prep.token,"Ready")
   mark(owner,"WaitingServerReady")
   local gateDeadline=math.min(deadline,os.clock()+6)
   while valid() and player:GetAttribute("TournamentCourseReady")~=true and os.clock()<gateDeadline do task.wait(.05) end
   assert(valid() and player:GetAttribute("TournamentCourseReady")==true,"Course readiness not confirmed")
   mark(owner,"Preview")
   local firstCheckpoint=course:FindFirstChild("Checkpoint_001",true) or course:FindFirstChild("Checkpoint_01",true)
   if firstCheckpoint and firstCheckpoint:IsA("BasePart") then
    owner.cue=Instance.new("Highlight")
    owner.cue.Adornee,owner.cue.FillColor,owner.cue.OutlineColor=firstCheckpoint,Theme.Mint,Theme.Cream
    owner.cue.FillTransparency,owner.cue.OutlineTransparency,owner.cue.Parent=.75,0,course
   end
   local known=seen[prep.courseId]==true
   local function releaseCamera()
    RunService:UnbindFromRenderStep("GrandArcadeCamera")
    Ownership.Release(owner.lease); owner.lease=nil
    player:SetAttribute("TournamentPresentation",false)
    curtain.BackgroundTransparency=1
   end
   local began,initial=nil,nil
   while valid() and os.clock()<deadline do
    local current=owner.snapshot.preparation
    assert(current and current.token==prep.token and current.status~="Failed","Preparation cancelled")
    local previewAt=current.previewAt or now()
    local handoffAt=current.handoffAt or previewAt+3
    local motion=player:GetAttribute("ReducedMotion")~=true
    show("SetPills",ticket,motion,owner.skip)
    if owner.skip or not motion or now()>=handoffAt-.15 or (known and began and os.clock()-began>=1) then break end
    if now()>=previewAt and not owner.lease then
     owner.lease=Ownership.Acquire("Course",Controller.Stop,true)
     assert(owner.lease,"Camera busy")
     player:SetAttribute("TournamentPresentation",true)
     began,initial=os.clock(),owner.lease.camera.CFrame
     if player:GetAttribute("SoundMuted")~=true then
      local cue=Instance.new("Sound")
      cue.SoundId,cue.Volume,cue.Parent=OnboardingConfig.AmbientSoundId,.12,owner.gui
      SoundService:PlayLocalSound(cue)
      task.delay(.5,function() if cue.Parent then cue:Stop(); cue:Destroy() end end)
     end
     RunService:BindToRenderStep("GrandArcadeCamera",Enum.RenderPriority.Camera.Value+2,function()
      if not valid() or not Ownership.IsOwner(owner.lease) then return end
      local camera=owner.lease.camera
      local root=character:FindFirstChild("HumanoidRootPart")
      if not root or not root:IsA("BasePart") then return end
      local age=os.clock()-began
      local behind=CFrame.lookAt(root.Position-root.CFrame.LookVector*12+Vector3.new(0,5,0),root.Position+Vector3.new(0,2,0))
      local target=behind
      local stage=workspace:FindFirstChild("GrandArcade")
      local displays=stage and stage:FindFirstChild("Displays")
      local bay=displays and displays:FindFirstChild("Bay"..tostring(prep.index or 1))
      local miniature=bay and bay:FindFirstChild("MapPanel")
      if miniature and not owner.glow then
       owner.glow=Instance.new("Highlight"); owner.glow.Adornee=miniature
       owner.glow.FillColor,owner.glow.OutlineColor,owner.glow.FillTransparency,owner.glow.Parent=Theme.Mint,Theme.Cream,.8,miniature
      end
      if age<.7 and miniature and miniature:IsA("BasePart") then target=CFrame.lookAt(miniature.Position+Vector3.new(0,2,18),miniature.Position) end
      curtain.BackgroundTransparency=if age>.65 and age<1 then 1-math.sin((age-.65)/.35*math.pi) else 1
      camera.CameraType=Enum.CameraType.Scriptable
      camera.CFrame=initial:Lerp(target,math.clamp(age/.65,0,1))
      camera.FieldOfView=owner.lease.fov
     end)
    end
    show("SetStep",ticket,3,if began then tostring(current.courseCue or (if firstCheckpoint then "Aim for the highlighted first checkpoint" else "Follow the numbered checkpoints in order")) else "Course ready · preview starts shortly",not began)
    show("SetCheckpoint",ticket,began~=nil and firstCheckpoint~=nil)
    task.wait(.05)
   end
   assert(valid() and delivered(),"Delivery changed")
   releaseCamera()
   mark(owner,"RestoringCamera")
   RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
   assert(valid() and delivered() and workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"Camera not restored")
   seen[prep.courseId],completed[prep.token]=true,true
   if cameraReady then cameraReady(prep.token) end
   owner.complete=true
   mark(owner,"CameraReadySent")
  end)
  if active==owner then
   if not ok then completed[prep.token]=true; diagnose(owner,"Error",tostring(reason)); warn("[CourseDelivery] "..tostring(reason)) end
   Controller.Stop(if ok then "Completed" else "Failed")
  end
 end)
end
return Controller
