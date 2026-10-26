local RunService=game:GetService('RunService')
assert(RunService:IsStudio())
local map=workspace.RaceCourse
assert(map:GetAttribute('ReviewBuild')=='SC27_FINAL_04')
local player=game.Players:GetPlayers()[1]
local character=player.Character
local root=character.HumanoidRootPart
local humanoid=character:FindFirstChildOfClass('Humanoid')
local before=root.Position
local recovery=character:GetAttribute('RecoveryUntil') or 0
local bounds=map.Obstacles.ShipwreckHazards.SurgeBounds
local water=map.Decoration.H02.SurgeWater
local start=os.clock()
local direction=Vector3.zero
root:SetNetworkOwner(nil)
local binding=RunService.PreSimulation:Connect(function()humanoid:Move(direction,false)end)
local result={build='SC27_FINAL_04',method='Walk from the west refuge reached by continuous cave traversal into active production tide; no teleport or recovery callback invocation.'}
local ok,err=pcall(function()
    assert((root.Position-map.Obstacles.WalkingSurfaces.SurgeWestRefuge.Position).Magnitude<20,'Not at traversed west refuge')
    repeat
        RunService.Heartbeat:Wait()
        assert(os.clock()-start<16,'No active tide window')
    until bounds:GetAttribute('Phase')=='Surge' and bounds.CFrame:PointToObjectSpace(water.Position).Z-water.Size.Z/2<0
    local began=os.clock()
    direction=Vector3.new(1,0,0)
    repeat RunService.Heartbeat:Wait() until (character:GetAttribute('RecoveryUntil') or 0)~=recovery or os.clock()-began>4
    direction=Vector3.zero
    assert((character:GetAttribute('RecoveryUntil') or 0)~=recovery,'No recovery from active tide')
    result.secondsWalkingUntilRecovery=os.clock()-began
    result.returnedPosition={root.Position.X,root.Position.Y,root.Position.Z}
    result.distanceToR4=(root.Position-map.Obstacles.WalkingSurfaces.R4_CaveEntry.Position).Magnitude
    assert(result.distanceToR4<12,'Did not return to R4')
end)
direction=Vector3.zero;binding:Disconnect();humanoid:Move(Vector3.zero,false);root:SetNetworkOwnershipAuto()
result.passed=ok;result.error=if ok then nil else tostring(err)
result.initialPosition={before.X,before.Y,before.Z}
script:SetAttribute('Result',game.HttpService:JSONEncode(result))
