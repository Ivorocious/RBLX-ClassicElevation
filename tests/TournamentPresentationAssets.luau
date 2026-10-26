local fs, luau = require("@lune/fs"), require("@lune/luau")
local Vector3 = require("@lune/roblox").Vector3
local Assets = require("../src/StarterPlayer/StarterPlayerScripts/Controllers/ArrivalAssets")
local source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Controllers/TournamentPresentation.luau")
local checks = 0
local function check(value, message) assert(value, message); checks += 1 end
local function signal()
 return {Connect=function() return {Disconnect=function() end} end, Wait=function() return .016 end}
end
local function run(options)
 options = options or {}
 local elapsed, acknowledgments, cameraAcks, warnings, requests = 0, {}, {}, {}, {}
 local controller
 local course = {}
 local function part(name, class, collide, attributes)
  local value = {Name=name, CanCollide=collide, Position=Vector3.zero, MeshId="rbxassetid://"..name}
  function value:IsA(wanted) return wanted==class or wanted=="BasePart" end
  function value:GetAttribute(key) return attributes and attributes[key] end
  function value:GetFullName() return "RaceCourse."..name end
  function value:IsDescendantOf(parent) return parent==course end
  return value
 end
 local floor = part("100", options.meshFloor and "MeshPart" or "Part", true)
 local lethal = part("200", "MeshPart", false, {ERLethal=true})
 local support = part("300", "MeshPart", false, {ERSupport=true})
 local wall = part("400", "MeshPart", true)
 local decoration = part("500", "MeshPart", false)
 local appearance = part("600", "MeshPart", false)
 local descendants = {floor, lethal, support, wall, decoration}
 function course:GetDescendants() return descendants end
 function course:GetAttribute(key) return if key=="CourseId" then (options.wrongCourse and "other" or "egg_rush_circuit") else nil end
 function course:FindFirstChild(name) return if name=="Start" and not options.missingStart then floor else nil end
 local root = part("Root", "Part", true)
 root.Position=Vector3.new(0,4,0)
 local humanoid = {Health=100, Died=signal()}
 local character = {}
 function character:GetDescendants() return {root, appearance} end
 function character:FindFirstChildOfClass(name) return if name=="Humanoid" then humanoid else nil end
 function character:FindFirstChild(name) return if name=="HumanoidRootPart" then root else nil end
 local attributes = {OnboardingReady=true, ReducedMotion=true, TournamentCourseReady=false}
 local player = {Character=character, CharacterRemoving=signal()}
 function player:GetAttribute(key) return attributes[key] end
 function player:SetAttribute(key,value) attributes[key]=value end
 function player:GetAttributeChangedSignal() return signal() end
 function player:WaitForChild() return {} end
 local workspace = {StreamingEnabled=false, CurrentCamera={CameraType=options.badCamera and "Scriptable" or "Custom"}}
 function workspace:GetServerTimeNow() return elapsed end
 function workspace:GetPropertyChangedSignal() return signal() end
 function workspace:FindFirstChild(name) return if name=="RaceCourse" then course else nil end
 function workspace:Raycast() return if options.noFloor then nil else {Instance=floor} end
 local provider = {}
 function provider:PreloadAsync(instances, callback)
  table.insert(requests, table.clone(instances))
  local mandatory = #requests>1
  if mandatory and options.requestError then error("Geometry request failed") end
  for _,item in instances do
   local failed = not mandatory or options.failedMesh==item.Name
   callback("https://assetdelivery.roblox.com/v1/asset?id="..item.Name, {Name=failed and "Failure" or "Success"})
   if mandatory and options.textureFailure then callback("rbxassetid://999", {Name="Failure"}) end
  end
  if mandatory and options.pendingGeometry then coroutine.yield() end
 end
 local runService = {IsStudio=function() return true end,RenderStepped=signal(), UnbindFromRenderStep=function() end}
 local modules = {
  OnboardingConfig={}, GrandArcadeConfig={DeliveryTimeout=.2,ReadyTimeout=.2,RenderTimeout=.2,OpeningSeconds=.2},
  ArrivalAssets=Assets, CameraOwnership={Release=function() end}, UiTheme={}, UiKit={Navy="navy"},
  RacePresentation={RaceNumber=function() return 1 end},
  NextCourseView=setmetatable({Create=function() return {} end},{__index=function() return function() end end}),
 }
 local game = {ReplicatedStorage={Config={OnboardingConfig="OnboardingConfig",GrandArcadeConfig="GrandArcadeConfig"}}}
 function game:GetService(name)
  return assert(({Players={LocalPlayer=player},RunService=runService,ContentProvider=provider,SoundService={}})[name])
 end
 controller = luau.load(source, {environment={
  game=game, workspace=workspace, script={Parent=setmetatable({},{__index=function(_,key) return key end})},
  require=function(key) return assert(modules[key],key) end,
  os={clock=function() return elapsed end},
  task={spawn=function(callback)
   local ok,reason=coroutine.resume(coroutine.create(callback)); assert(ok,reason)
  end,wait=function(seconds)
   elapsed+=seconds
   if options.cancelAt and elapsed>=options.cancelAt then controller.Stop() end
   return seconds
  end},
  Vector3=Vector3, UDim2={fromScale=function() return {} end},
  RaycastParams={new=function() return {} end},
  Enum={ScreenInsets={DeviceSafeInsets="Safe"},RaycastFilterType={Include="Include"},CameraType={Custom="Custom"}},
  Instance={new=function() return {Destroy=function() end} end},
  warn=function(message) table.insert(warnings,tostring(message)) end,
 }})()
 controller.Start({enrolled=true,status="Queued",entryOpen=true,state="Intermission",preparation={
  token="test-token",courseId="egg_rush_circuit",status="Preparing",delivery={modelName="RaceCourse",expectedParts=options.missingParts and 6 or 5},
 }},function(token,stage)
  check(token=="test-token", "Acknowledgments retain the actual preparation token")
  table.insert(acknowledgments,stage)
  if stage=="Ready" then attributes.TournamentCourseReady=true end
 end,function(token) table.insert(cameraAcks,token) end)
 return {acks=acknowledgments,cameras=cameraAcks,warnings=warnings,requests=requests,controller=controller,
  critical={lethal,support,wall},decoration=decoration,appearance=appearance,floor=floor,attributes=attributes}
end

local accepted=run({textureFailure=true})
check(table.concat(accepted.acks,",")=="Rendered,Ready" and #accepted.cameras==1,"Missing cosmetic assets and required-mesh textures do not block valid delivery")
check(#accepted.requests==2 and #accepted.requests[2]==3,"Only the three actual critical mesh instances enter the mandatory request")
for _,part in accepted.critical do check(table.find(accepted.requests[2],part),"Lethal, support and collidable mesh geometry stays mandatory") end
check(not table.find(accepted.requests[2],accepted.decoration) and not table.find(accepted.requests[2],accepted.appearance),"Decorative course and avatar meshes remain optional")
check(not accepted.controller.IsActive(),"Successful delivery releases the presentation session")
for _,scenario in {
 {failedMesh="200"},{failedMesh="300"},{failedMesh="400"},{meshFloor=true,failedMesh="100"},
 {requestError=true},{noFloor=true},{wrongCourse=true},{missingStart=true},{missingParts=true},
} do
 local result=run(scenario)
 check(table.concat(result.acks,",")=="Rendered" and #result.cameras==0,"Invalid geometry, replication or delivery cannot acknowledge readiness")
 check(not result.controller.IsActive(),"Failed delivery releases the presentation session")
end
local cameraFailure=run({badCamera=true})
check(table.concat(cameraFailure.acks,",")=="Rendered,Ready" and #cameraFailure.cameras==0,"A camera that is not restored never sends CameraReady")
local pending=run({pendingGeometry=true,cancelAt=.3,failedMesh="200"})
check(pending.attributes.CourseDeliveryStopStage=="RequiredGeometry" and pending.attributes.CourseDeliveryStopReason=="ExternalStop","External cancellation preserves the exact blocking stage")
check(pending.attributes.CourseDeliveryRequiredRequestReturned==false and pending.attributes.CourseDeliveryRequiredFailures==1,"A canceled pending request retains its actual required callback failure")
check(pending.attributes.CourseDeliveryRequiredFirstFailure:find("200",1,true) and pending.attributes.CourseDeliveryAsset1:find("Failure",1,true),"Required mesh failure identity and callback status survive cancellation")
print(string.format("TournamentPresentationAssets: %d checks passed",checks))
