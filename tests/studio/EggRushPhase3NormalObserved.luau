--!nonstrict
local Test = {}
local RunService, Players, Workspace = game:GetService("RunService"), game:GetService("Players"), game:GetService("Workspace")
local BaseScript = assert(script.Parent:FindFirstChild("NormalBase"), "NormalBase module required")
local Base = require(BaseScript)

local function vector(value)
 return {value.X, value.Y, value.Z}
end

function Test.Run(expectedCandidate, laps)
 assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server required")
 local courseService = require(game.ServerScriptService.Services.CourseService)
 local eggRushService = require(game.ServerScriptService.Services.EggRushService)
 local resultsService = require(game.ServerScriptService.Services.ResultsService)
 local player = assert(Players:GetPlayers()[1], "Actual racer missing")
 assert(#Players:GetPlayers()==1, "One isolated actual client required")
 local course, character = assert(courseService.GetActiveCourse()), assert(player.Character)
 local root, humanoid = assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
 local mechanisms = assert(course.Obstacles:FindFirstChild("Mechanisms"))
 local trays = {}
 for _, name in {"SidewaysTray", "SidewaysTrayB"} do
  local model = assert(mechanisms:FindFirstChild(name), "Actual tray missing: "..name)
  local deck = assert(model:FindFirstChild("TrayContact"), "Actual tray support missing: "..name)
  assert(deck:IsA("BasePart") and deck.CanCollide and deck.CanQuery, "Queryable tray support required")
  table.insert(trays,{model=model,deck=deck})
 end
 local started, observerFailure = os.clock(), nil
 local observation = {
  method="Read-only PostSimulation samples near the two actual trays while NormalBase runs unchanged",
  nearRadius=36, nearHeight=18, trace={}, sampling={physicsFramesChecked=0,nearFrames=0,maxPhysicsDelta=0},
  limits="A scripted native run; samples describe observed frames, not human, crowd, device or performance proof",
  runtimeBefore=eggRushService.GetDiagnostics(),
 }
 local initial = assert(resultsService.GetPlayerResult(player))
 observation.initial={falls=initial.falls or 0,lap=initial.currentLap,nextCheckpoint=initial.nextCheckpointIndex}
 local ray = RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances={course}; ray.RespectCanCollide=true
 local observer = RunService.PostSimulation:Connect(function(dt)
  if observerFailure then return end
  local ok, failure = xpcall(function()
   observation.sampling.physicsFramesChecked+=1
   local nearby = {}
   for _, entry in trays do
    local delta=root.Position-entry.deck.Position
    if Vector3.new(delta.X,0,delta.Z).Magnitude<=observation.nearRadius and math.abs(delta.Y)<=observation.nearHeight then
     table.insert(nearby,entry)
    end
   end
   if #nearby==0 then return end
   observation.sampling.nearFrames+=1
   observation.sampling.maxPhysicsDelta=math.max(observation.sampling.maxPhysicsDelta,dt)
   local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),ray)
   local sample={seconds=os.clock()-started,dt=dt,progress=BaseScript:GetAttribute("Progress"),
    root=vector(root.Position),rootVelocity=vector(root.AssemblyLinearVelocity),moveDirection=vector(humanoid.MoveDirection),
    floor=humanoid.FloorMaterial.Name,support=hit and hit.Instance:GetFullName(),trays={}}
   for _, entry in nearby do
    local deck=entry.deck
    table.insert(sample.trays,{name=entry.model.Name,state=entry.model:GetAttribute("ERState"),deck=vector(deck.Position),
     deckVelocity=vector(deck.AssemblyLinearVelocity),deckLocal=vector(deck.CFrame:PointToObjectSpace(root.Position)),
     relativeVelocity=vector(deck.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity-deck.AssemblyLinearVelocity))})
   end
   table.insert(observation.trace,sample)
  end,debug.traceback)
  if not ok then observerFailure=tostring(failure) end
 end)
 local ran, value=xpcall(function() return Base.Run(expectedCandidate,laps) end,debug.traceback)
 observer:Disconnect()
 observation.seconds=os.clock()-started
 observation.failure=observerFailure
 observation.runtimeAfter=eggRushService.GetDiagnostics()
 local final=resultsService.GetPlayerResult(player)
 if final then observation.final={falls=final.falls or 0,lap=final.currentLap,nextCheckpoint=final.nextCheckpointIndex} end
 if observation.runtimeBefore.stats and observation.runtimeAfter.stats then
  observation.recoveryDelta={attempts=observation.runtimeAfter.stats.recoveryAttempts-observation.runtimeBefore.stats.recoveryAttempts,
   recoveries=observation.runtimeAfter.stats.recoveries-observation.runtimeBefore.stats.recoveries}
 end
 local report=if ran then value else {ok=false,failure=tostring(value)}
 report.trayObservation=observation
 if observerFailure then
  report.ok=false
  report.observationFailure=observerFailure
 end
 return report
end

return Test
