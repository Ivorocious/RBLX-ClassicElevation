local fs, luau, roblox = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local source = fs.readFile("src/ServerScriptService/Services/EggRushService.luau")
local assertions, cases = 0, 0
local bodyNames = {Head=true, Torso=true, UpperTorso=true, LowerTorso=true}
local V, C = roblox.Vector3, roblox.CFrame
local expectedPadding = .5
local expectedForwardClearance = 1.25

local function check(value, message)
 assertions += 1
 assert(value, message)
end

local function near(actual, expected, message)
 check(math.abs(actual-expected) < 1e-4, message)
end

local function frameNear(actual, expected, message)
 check((actual.Position-expected.Position).Magnitude < 1e-4
  and (actual.RightVector-expected.RightVector).Magnitude < 1e-4
  and (actual.UpVector-expected.UpVector).Magnitude < 1e-4, message)
end

local function character(workspace, rig, originals, movement, rootFirst, colliderSize)
 local model = roblox.Instance.new("Model")
 model.Name, model.Parent = rig.."TestCharacter", workspace
 local humanoid = roblox.Instance.new("Humanoid")
 humanoid.Parent, humanoid.Health = model, 100
 humanoid.WalkSpeed, humanoid.UseJumpPower = movement[1], movement[2]
 humanoid.JumpHeight, humanoid.JumpPower = movement[3], movement[4]
 local parts = {}
 local names = if rig == "R6" then {"Head", "Torso", "Left Arm", "Right Leg", "HumanoidRootPart", "CollisionPart"}
  else {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightFoot", "HumanoidRootPart", "CollisionPart"}
 for _, name in names do
  local part = roblox.Instance.new("Part")
  part.Name, part.Parent, part.CanCollide = name, model, originals[name] == true
  parts[name] = part
 end
 local root, collider = parts.HumanoidRootPart, parts.CollisionPart
 root.Size = V.new(2.12, 2.12, 1.06)
 root.CFrame = C.new(17, 8, -11)*C.Angles(.2, .6, -.1)
 collider.Size = colliderSize or V.new(2, 3, 1)
 collider.CFrame = root.CFrame*C.new(.35, -.2, .1)*C.Angles(.05, .13, -.04)
 local poses = {
  Head={V.new(2, 1.3, 1.4), C.new(.2, 2.2, .3)*C.Angles(.1, .15, -.12)},
  UpperTorso={V.new(2.1, 1.4, 1), C.new(-.1, .7, .15)*C.Angles(.07, 0, .05)},
  LowerTorso={V.new(1.8, 1, 1.2), C.new(.1, -.5, -.1)*C.Angles(-.04, .08, 0)},
  Torso={V.new(2, 2.2, 1.2), C.new(0, .3, .1)*C.Angles(.02, .1, .04)},
 }
 for name, part in parts do
  local pose = poses[name]
  if pose then part.Size, part.CFrame = pose[1], root.CFrame*pose[2]
  elseif part ~= root and part ~= collider then
   part.Size, part.CFrame = V.new(2, 2, 2), root.CFrame*C.new(-12, -8, 7)
  end
 end
 local joint = roblox.Instance.new("Weld")
 joint.Name, joint.Parent = "ExistingCharacterWeld", collider
 local jointOffset = C.new(.1, -.05, .2)*C.Angles(.01, .03, 0)
 local relative = root.CFrame:ToObjectSpace(collider.CFrame)
 if rootFirst then
  joint.Part0, joint.Part1, joint.C1, joint.C0 = root, collider, jointOffset, relative*jointOffset
 else
  joint.Part0, joint.Part1, joint.C0, joint.C1 = collider, root, jointOffset, relative*jointOffset
 end
 local accessory = roblox.Instance.new("Folder")
 accessory.Name, accessory.Parent = "AccessorySubstitute", model
 local nestedHead = roblox.Instance.new("Part")
 nestedHead.Name, nestedHead.Parent, nestedHead.CanCollide = "Head", accessory, false
 nestedHead.Size, nestedHead.CFrame = V.new(20, 20, 20), root.CFrame*C.new(50, 50, 50)
 return {model=model, humanoid=humanoid, parts=parts, root=root, collider=collider, joint=joint,
  nestedHead=nestedHead, originals=originals, movement=movement,
  savedSize=collider.Size, savedFrame=collider.CFrame, savedC0=joint.C0, savedC1=joint.C1,
  descendants=#model:GetDescendants()}
end

local function movementRestored(rig, label)
 near(rig.humanoid.WalkSpeed, rig.movement[1], label.." speed")
 check(rig.humanoid.UseJumpPower == rig.movement[2], label.." jump mode")
 near(rig.humanoid.JumpHeight, rig.movement[3], label.." jump height")
 near(rig.humanoid.JumpPower, rig.movement[4], label.." jump power")
end

local function flagsUnchanged(rig, label)
 for name, part in rig.parts do
  check(part.CanCollide == (rig.originals[name] == true), label.." original collision "..name)
 end
 check(not rig.nestedHead.CanCollide, label.." nested accessory untouched")
end

local function colliderRestored(rig, label)
 check(rig.collider.Size == rig.savedSize, label.." exact original collider size")
 check(rig.joint.C0 == rig.savedC0, label.." exact original Weld C0")
 check(rig.joint.C1 == rig.savedC1, label.." exact original Weld C1")
end

local function weldedFrame(rig)
 -- Lune preserves joint properties but does not solve the welded part's world pose.
 if rig.joint.Part0 == rig.collider then return rig.root.CFrame*rig.joint.C1*rig.joint.C0:Inverse() end
 return rig.root.CFrame*rig.joint.C0*rig.joint.C1:Inverse()
end

local function colliderEnclosesBody(rig, label, bounded)
 local fitted = weldedFrame(rig)
 local relative = rig.root.CFrame:ToObjectSpace(fitted)
 frameNear(C.fromMatrix(V.zero, relative.RightVector, relative.UpVector), C.identity, label.." collider axes align with root")
 local half = rig.collider.Size/2
 local bodyCount = 0
 local requiredLowZ, requiredHighZ = math.huge, -math.huge
 local function enclosed(part, padding, forwardClearance, frame, size)
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local worldPoint = frame*(size*V.new(x,y,z)/2)
   local point = fitted:PointToObjectSpace(worldPoint)
   local rootPoint = rig.root.CFrame:PointToObjectSpace(worldPoint)
   requiredLowZ = math.min(requiredLowZ, rootPoint.Z-padding-forwardClearance)
   requiredHighZ = math.max(requiredHighZ, rootPoint.Z+padding)
   check(math.abs(point.X)+padding <= half.X+1e-4
    and math.abs(point.Y)+padding <= half.Y+1e-4
    and point.Z-padding-forwardClearance >= -half.Z-1e-4
    and point.Z+padding <= half.Z+1e-4, label.." encloses "..part.Name.." corner with directional clearance")
  end end end
 end
 for name, part in rig.parts do
  if bodyNames[name] then enclosed(part, expectedPadding, expectedForwardClearance, part.CFrame, part.Size); bodyCount+=1 end
 end
 enclosed(rig.collider, 0, 0, rig.savedFrame, rig.savedSize)
 near(relative.Position.Z-half.Z, requiredLowZ, label.." exact forward body clearance or original box bound")
 near(relative.Position.Z+half.Z, requiredHighZ, label.." rear bound has padding without forward clearance")
 check(bodyCount == (if rig.parts.Torso then 2 else 3), label.." expected rig body parts tested")
 if bounded then
  check(rig.collider.Size.X < 4 and rig.collider.Size.Y < 6.5 and rig.collider.Size.Z < 4.75,
   label.." excludes distant limbs and nested accessory from fit")
 end
 check(#rig.model:GetDescendants() == rig.descendants, label.." reuses existing collider and weld without new instances")
 flagsUnchanged(rig, label)
end

local function fixture(flag, rigType, originals, movement, rootFirst, colliderSize)
 local workspace = roblox.Instance.new("Workspace")
 workspace.Gravity = 196.2
 local callbacks, players = {}, {}
 local state = {active=true, raceId="body-test-A", official=true, status="Racing", starts=0, stops=0}
 local rig = character(workspace, rigType or "R15", originals, movement, rootFirst, colliderSize)
 local player = {Parent=players, Character=rig.model}
 function players:GetPlayers() return {player} end
 local heartbeat = {}
 function heartbeat:Connect(callback)
  local connection = {Connected=true, callback=callback}
  function connection:Disconnect() self.Connected=false end
  table.insert(callbacks, connection)
  return connection
 end
 local runService = {Heartbeat=heartbeat, IsServer=function() return true end}
 local runtimeToken, constantsToken = {}, {}
 local runtime = {}
 function runtime.Start(course, eligible, recover)
  check(course == state.course and typeof(course) == "Instance", "runtime receives actual selected model")
  check(type(eligible) == "function" and type(recover) == "function", "actual service passes eligibility/recovery")
  state.starts += 1
  local stopped = false
  return {
   Stop=function() if not stopped then stopped=true; state.stops+=1 end end,
   Resume=function() end, Hold=function() end,
   Diagnostics=function() return {bound=not stopped} end,
  }
 end
 local game = {
  ServerStorage={CourseBuilders={EggRush={Runtime=runtimeToken}}},
  ReplicatedStorage={Shared={RaceConstants=constantsToken}},
 }
 function game:GetService(name)
  return assert(({Players=players, RunService=runService, Workspace=workspace})[name])
 end
 local function course(fullBodyContacts)
  local model = roblox.Instance.new("Model")
  model.Name, model.Parent = "OwnedEggRushContactCourse", workspace
  model:SetAttribute("CourseId", "egg_rush_circuit")
  model:SetAttribute("EROwned", true)
  if fullBodyContacts ~= nil then model:SetAttribute("FullBodyContacts", fullBodyContacts) end
  return model
 end
 state.course = course(flag)
 local now = 0
 local service = luau.load(source, {environment={game=game, Vector3=V, CFrame=C, os={clock=function() return now end},
  require=function(token)
   if token == runtimeToken then return runtime end
   assert(token == constantsToken, "Unexpected service dependency")
   return {PlayerRaceStatus={Racing="Racing"}}
  end,
  warn=function(message) error("Unexpected runtime start warning: "..message) end,
 }})()
 service.Init({Services={
  CourseService={GetActiveCourse=function() return state.course end},
  RaceService={IsRaceActive=function() return state.active end, GetCurrentRaceId=function() return state.raceId end},
  PlayerRaceService={IsOfficialRacer=function() return state.official end, GetPlayerStatus=function() return state.status end},
  RespawnService={RecoverPlayer=function() return true end},
 }})
 service.Start()
 local function tick()
  now += .05
  for _, connection in table.clone(callbacks) do
   if connection.Connected then connection.callback(.05) end
  end
 end
 return {workspace=workspace, state=state, rig=rig, player=player, service=service, tick=tick, course=course,
  cleanup=function() service.Stop(); workspace:Destroy() end}
end

local originals = {Head=false, UpperTorso=true, LowerTorso=false, LeftUpperArm=false, RightFoot=true,
 HumanoidRootPart=false, CollisionPart=true}
local movement = {23, true, 5.25, 61}
local function run(name, callback)
 callback()
 cases += 1
 print("PASS "..name)
end

run("absent flag preserves existing collider and collision flags", function()
 local f = fixture(nil, "R15", originals, movement)
 f.tick()
 check(f.service.GetDiagnostics().movementProfiles == 1, "absent flag still profiles eligible movement")
 colliderRestored(f.rig, "absent flag")
 flagsUnchanged(f.rig, "absent flag")
 near(f.rig.humanoid.WalkSpeed, 16, "absent flag standard race speed")
 f.service.Stop()
 movementRestored(f.rig, "absent flag Stop")
 f.cleanup()
end)

run("true flag fits existing collider once around rotated body and original box", function()
 local f = fixture(true, "R15", originals, movement)
 f.tick()
 colliderEnclosesBody(f.rig, "flag true", true)
 local size, c0, c1 = f.rig.collider.Size, f.rig.joint.C0, f.rig.joint.C1
 f.rig.parts.Head.CFrame *= C.new(100, 0, 0)
 f.tick()
 check(f.rig.collider.Size == size, "second tick does not resize for animated body")
 frameNear(f.rig.joint.C0, c0, "second tick retains fitted C0")
 frameNear(f.rig.joint.C1, c1, "second tick retains fitted C1")
 flagsUnchanged(f.rig, "second tick")
 check(f.state.starts == 1, "ordinary tick retains the same binding")
 f.cleanup()
end)

run("ineligible restores oversized original collider and both weld offsets", function()
 local f = fixture(true, "R15", originals, movement, true, V.new(6, 8, 5))
 f.tick(); f.tick()
 colliderEnclosesBody(f.rig, "oversized original is never shrunk", false)
 f.state.status = "Spectating"
 f.tick()
 colliderRestored(f.rig, "ineligible")
 flagsUnchanged(f.rig, "ineligible")
 movementRestored(f.rig, "ineligible")
 check(f.service.GetDiagnostics().movementProfiles == 0, "ineligible profile released")
 f.cleanup()
end)

run("Stop restores movement collider and weld without rewriting body flags", function()
 local f = fixture(true, "R15", originals, movement)
 f.tick()
 f.rig.humanoid.JumpPower = 73
 f.rig.parts.UpperTorso.CanCollide = false
 f.service.Stop()
 colliderRestored(f.rig, "Stop")
 check(not f.rig.parts.UpperTorso.CanCollide, "Stop leaves an external Humanoid collision-flag change alone")
 movementRestored(f.rig, "Stop")
 check(f.state.stops == 1 and not f.service.GetDiagnostics().bound, "Stop ends runtime binding")
 check(f.service.GetDiagnostics().movementProfiles == 0, "Stop clears profile")
 f.tick()
 colliderRestored(f.rig, "tick after Stop")
 check(f.state.starts == 1, "disconnected heartbeat cannot bind again")
 f.cleanup()
end)

run("respawn restores old character and profiles replacement", function()
 local f = fixture(true, "R15", originals, movement)
 f.tick()
 local nextOriginals = {Head=true, UpperTorso=false, LowerTorso=true, LeftUpperArm=true,
  RightFoot=false, HumanoidRootPart=true, CollisionPart=false}
 local replacement = character(f.workspace, "R15", nextOriginals, {11, false, 3.75, 42})
 f.player.Character = replacement.model
 f.tick()
 colliderRestored(f.rig, "respawn old")
 flagsUnchanged(f.rig, "respawn old")
 movementRestored(f.rig, "respawn old")
 colliderEnclosesBody(replacement, "respawn replacement", true)
 check(f.service.GetDiagnostics().movementProfiles == 1, "only replacement profile remains")
 near(replacement.humanoid.WalkSpeed, 16, "replacement receives race movement")
 f.service.Stop()
 colliderRestored(replacement, "replacement Stop")
 flagsUnchanged(replacement, "replacement Stop")
 movementRestored(replacement, "replacement Stop")
 f.cleanup()
end)

run("binding change restores root-first R6 weld before unflagged course", function()
 local r6Originals = {Head=true, Torso=false, ["Left Arm"]=false, ["Right Leg"]=true,
  HumanoidRootPart=false, CollisionPart=true}
 local f = fixture(true, "R6", r6Originals, {19, true, 6, 57}, true)
 f.tick()
 colliderEnclosesBody(f.rig, "R6 flagged", true)
 f.state.course, f.state.raceId = f.course(nil), "body-test-B"
 f.tick()
 colliderRestored(f.rig, "rebind unflagged")
 flagsUnchanged(f.rig, "rebind unflagged")
 check(f.state.starts == 2 and f.state.stops == 1, "course/race change replaced binding")
 check(f.service.GetDiagnostics().movementProfiles == 1, "unflagged binding still profiles movement")
 near(f.rig.humanoid.WalkSpeed, 16, "unflagged new binding retains race movement")
 f.service.Stop()
 movementRestored(f.rig, "rebind Stop")
 colliderRestored(f.rig, "rebind Stop")
 flagsUnchanged(f.rig, "rebind Stop")
 f.cleanup()
end)

assert(cases == 6)
print(string.format("EGG_RUSH_BODY_CONTACTS_CLEAR: %d cases, %d assertions; actual service source compiled and loaded", cases, assertions))
print("LIMITS: Real Lune Roblox Model/Humanoid/Part/Weld instances with substitute game/heartbeat/race/Runtime. Weld equations infer the fitted pose because Lune does not solve character joints; no native collision or clipping physics proof.")
