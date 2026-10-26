local services=game.ServerScriptService.Services
local race=require(services.RaceService);local cp=require(services.CheckpointService)
local p=game.Players:GetPlayers()[1]
race.ApplyStudioAction('RestartRace');task.wait(1);race.ApplyStudioAction('StartRace');task.wait(.5)
local map=workspace.RaceCourse;local origin=map.Bounds.CourseOrigin.CFrame
local records={}
for _,case in {{'X01 miss returns R2',2,Vector3.new(-60,4,-50),4},{'X02 miss returns R3',3,Vector3.new(55,4,-43),4},{'H01 actual hit returns R1',1,Vector3.new(-100,13.1,-6),10},{'H02 actual surge returns R4',4,Vector3.new(69,8.1,58),13}}do
local ok,err=pcall(function()
cp.SetInspectionCheckpointForStudio(p,case[2]);task.wait(1.6)
local c=p.Character;local r=c.HumanoidRootPart
r:SetNetworkOwner(nil);r.AssemblyLinearVelocity=Vector3.zero;c:SetAttribute('RecoveryUntil',0);c:PivotTo(origin*CFrame.new(case[3]))
local start=os.clock();repeat task.wait(.05)until (c:GetAttribute('RecoveryUntil')or 0)>workspace:GetServerTimeNow()or os.clock()-start>case[4]
assert((c:GetAttribute('RecoveryUntil')or 0)>workspace:GetServerTimeNow(),'no recovery')
assert(cp.GetLatestCheckpointIndex(p)==case[2],'progress changed')
local target=map.Checkpoints[string.format('Checkpoint_%03d',case[2])]
assert((r.Position-target.Position).Magnitude<12,'wrong recovery location')
end)
table.insert(records,{name=case[1],passed=ok,error=if ok then nil else tostring(err)});script:SetAttribute('Progress',#records)
end
script:SetAttribute('Result',game.HttpService:JSONEncode({build=map:GetAttribute('ShipwreckBuild'),records=records,method='Actual active-course hazards and fall zone with production recovery. Checkpoint progress and initial position set through Studio fixture; not full traversal.'}))