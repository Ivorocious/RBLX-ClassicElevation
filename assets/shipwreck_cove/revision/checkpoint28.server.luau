local RunService=game:GetService('RunService')
assert(RunService:IsStudio())
local map=workspace.RaceCourse
local player=game.Players:GetPlayers()[1]
local character=player.Character
local root=character.HumanoidRootPart
local humanoid=character:FindFirstChildOfClass('Humanoid')
local checkpoints=require(game.ServerScriptService.Services.CheckpointService)
local origin=map.Bounds.CourseOrigin.CFrame
local result={build=map:GetAttribute('ReviewBuild'),method='Studio inspection presets checkpoint 4. One initial placement outside checkpoint 5, then actual R15 walking into its trigger and off the refuge into production fall recovery.'}
local direction=Vector3.zero
root:SetNetworkOwner(nil)
local binding=RunService.PreSimulation:Connect(function()humanoid:Move(direction,false)end)
local ok,err=pcall(function()
    assert(checkpoints.GetLatestCheckpointIndex(player)==4,'Inspection checkpoint 4 required')
    character:PivotTo(origin*CFrame.new(-11.4,13.2,58));root.AssemblyLinearVelocity=Vector3.zero
    task.wait(.6)
    direction=Vector3.xAxis
    local deadline=os.clock()+2
    repeat RunService.Heartbeat:Wait() until checkpoints.GetLatestCheckpointIndex(player)==5 or os.clock()>deadline
    direction=Vector3.zero
    assert(checkpoints.GetLatestCheckpointIndex(player)==5,'Checkpoint 5 not reached by walking')
    result.checkpointReached=5
    local before=character:GetAttribute('RecoveryUntil') or 0
    direction=-Vector3.xAxis
    deadline=os.clock()+5
    repeat RunService.Heartbeat:Wait() until (character:GetAttribute('RecoveryUntil')or 0)~=before or os.clock()>deadline
    direction=Vector3.zero
    assert((character:GetAttribute('RecoveryUntil')or 0)~=before,'Production fall recovery did not occur')
    result.respawnDistance=(root.Position-map.Obstacles.WalkingSurfaces.SurgeWestRefuge.Position).Magnitude
    result.checkpointAfterFall=checkpoints.GetLatestCheckpointIndex(player)
    assert(result.respawnDistance<12 and result.checkpointAfterFall==5,'Did not return to checkpoint 5')
end)
direction=Vector3.zero;binding:Disconnect();humanoid:Move(Vector3.zero,false);root:SetNetworkOwnershipAuto()
result.passed=ok;result.error=if ok then nil else tostring(err)
script:SetAttribute('Result',game.HttpService:JSONEncode(result))
