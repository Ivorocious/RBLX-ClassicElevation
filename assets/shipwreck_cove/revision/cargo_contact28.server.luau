local RunService=game:GetService('RunService')
assert(RunService:IsStudio())
local map=workspace.RaceCourse
local layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local checkpoints=require(game.ServerScriptService.Services.CheckpointService)
local player=game.Players:GetPlayers()[1]
local character=player.Character
local root=character.HumanoidRootPart
local humanoid=character:FindFirstChildOfClass('Humanoid')
local origin=map.Bounds.CourseOrigin.CFrame
local oldPivot=character:GetPivot()
local oldOwner=root:GetNetworkOwner()
local result={build=map:GetAttribute('ReviewBuild'),rows={},method='Production RaceCourse runtime, actual unanchored R15. One test placement onto each moving-cargo row, then observe normal full-period motion and actual checkpoint recovery. Not traversal.'}
local binding=RunService.PreSimulation:Connect(function()humanoid:Move(Vector3.zero,false);humanoid.Jump=false end)
root:SetNetworkOwner(nil)
local ok,err=pcall(function()
    for _,d in layout.hazards do
        if not d.name:match('^RedCargo') then continue end
        local rowIndex=tonumber(d.name:match('^RedCargo(%d+)_'))
        local surfaceName=string.format('S01_%02d',rowIndex)
        local pad=map.Obstacles.WalkingSurfaces[surfaceName]
        local visual=map.Decoration.Obstacles[d.name]
        local lo,hi=math.huge,-math.huge
        local pads=0
        for _,s in layout.surfaces do
            if s.name==surfaceName or s.name:match('^DockCluster'..rowIndex..'_') then
                lo=math.min(lo,s.p[1]-s.size[1]/2);hi=math.max(hi,s.p[1]+s.size[1]/2);pads+=1
            end
        end
        local beforeCheckpoint=checkpoints.GetLatestCheckpointIndex(player)
        local bounding,size=character:GetBoundingBox()
        local feetOffset=root.Position.Y-(bounding.Position.Y-size.Y/2)
        local start=pad.Position+Vector3.new(0,pad.Size.Y/2+feetOffset+.08,0)
        character:PivotTo(character:GetPivot()+(start-root.Position))
        root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        character:SetAttribute('RecoveryUntil',0)
        local minX,maxX=math.huge,-math.huge
        local recovered=false
        local recoveryDistance
        local deadline=os.clock()+d.period+.5
        repeat
            RunService.Heartbeat:Wait()
            local x=origin:PointToObjectSpace(visual.Position).X
            minX=math.min(minX,x);maxX=math.max(maxX,x)
            if (character:GetAttribute('RecoveryUntil')or 0)>0 then
                recovered=true
                recoveryDistance=(root.Position-start).Magnitude
            end
        until os.clock()>deadline
        local covered=minX-visual.Size.X/2<=lo+.12 and maxX+visual.Size.X/2>=hi-.12
        local afterCheckpoint=checkpoints.GetLatestCheckpointIndex(player)
        local row={name=d.name,pads=pads,rowEdges={lo,hi},actualSweptEdges={minX-visual.Size.X/2,maxX+visual.Size.X/2},fullRow=covered,recovered=recovered,recoveryDistance=recoveryDistance,checkpointBefore=beforeCheckpoint,checkpointAfter=afterCheckpoint}
        row.passed=covered and recovered and recoveryDistance>15 and beforeCheckpoint==afterCheckpoint
        table.insert(result.rows,row)
        assert(row.passed,d.name..' motion/contact/recovery failed')
        script:SetAttribute('Progress',#result.rows)
    end
    assert(#result.rows==3)
end)
binding:Disconnect();humanoid:Move(Vector3.zero,false)
character:PivotTo(oldPivot);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
if oldOwner then root:SetNetworkOwner(oldOwner)else root:SetNetworkOwnershipAuto()end
result.passed=ok;result.error=if ok then nil else tostring(err)
script:SetAttribute('Result',game.HttpService:JSONEncode(result))
