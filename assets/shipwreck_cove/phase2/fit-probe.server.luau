local RunService=game:GetService("RunService")
local player=game.Players:GetPlayers()[1]
local original=player.Character;local archivable=original.Archivable;original.Archivable=true
local character=original:Clone();original.Archivable=archivable;character.Name="__ShipwreckRouteFit"
for _,v in character:GetDescendants() do
    if v:IsA("BaseScript") then v.Enabled=false end
    if v:IsA("BasePart") then v.Anchored=false end
end
character.Parent=workspace
local h=character:FindFirstChildOfClass("Humanoid");local root=character.HumanoidRootPart
root:SetNetworkOwner(nil);h.WalkSpeed=16;h.UseJumpPower=false;h.JumpHeight=7.2;h.EvaluateStateMachine=true
local map=workspace.RaceCourse;assert(map:GetAttribute("ShipwreckBuild"))
local surfaces=map.Obstacles.WalkingSurfaces
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={surfaces};params.RespectCanCollide=true
local direction=Vector3.zero;local jump=false
local binding=RunService.PreSimulation:Connect(function()h:Move(direction,false);h.Jump=jump end)
local function floor()local r=workspace:Raycast(root.Position,Vector3.new(0,-4.2,0),params);return r and r.Instance end
local function waitFor(fn,seconds)
    local deadline=os.clock()+seconds
    repeat RunService.Heartbeat:Wait() until fn() or os.clock()>deadline
    return fn()
end
local function top(p)return p.Position+p.CFrame.UpVector*p.Size.Y/2 end
local function floorHeight(p,position)
    local normal=p.CFrame.UpVector
    local center=top(p)
    return Vector3.new(position.X,center.Y-(normal.X*(position.X-center.X)+normal.Z*(position.Z-center.Z))/normal.Y,position.Z)
end
local function edge(p,d)
    return math.min(p.Size.X/2/math.max(.0001,math.abs(d:Dot(p.CFrame.RightVector))),p.Size.Z/2/math.max(.0001,math.abs(d:Dot(p.CFrame.LookVector))))
end
local pairsToTest={}
local function chain(names)for i=1,#names-1 do table.insert(pairsToTest,{names[i],names[i+1]})end end
chain({"HarborAssembly","S01_00","S01_01","S01_02","S01_03","R1_Refuge","BatteryDeck-6","BatteryDeck-18","BatteryDeck-30","R2_Boarding","BoardingRamp","S02_00"})
local names={"S02_00"};for i=1,9 do table.insert(names,string.format("S02_%02d",i))end;table.insert(names,"R3_Stern");chain(names)
names={"R2_Boarding"};for i=0,9 do table.insert(names,string.format("Rib%02d",i))end;table.insert(names,"R3_Stern");chain(names)
names={"R3_Stern"};for i=0,11 do table.insert(names,string.format("S03_%02d",i))end;table.insert(names,"R4_CaveEntry");chain(names)
names={"R3_Stern"};for i=0,4 do table.insert(names,string.format("Spar%02d",i))end;table.insert(names,"R4_CaveEntry");chain(names)
chain({"R4_CaveEntry","S04_Entry_00","S04_Entry_01","S04_Entry_02","S04_Entry_03","SurgeEastRefuge","SurgePassage","SurgeWestRefuge","S04_Shore_00"})
names={"S04_Shore_00"};for i=1,6 do table.insert(names,string.format("S04_Shore_%02d",i))end;table.insert(names,"HarborAssembly");chain(names)
local records={}
for _,pair in pairsToTest do
    local ok,err=pcall(function()
        local a,b=surfaces[pair[1]],surfaces[pair[2]]
        local ta,tb=top(a),top(b);local delta=tb-ta;local d=Vector3.new(delta.X,0,delta.Z).Unit
        local start=floorHeight(a,ta+d*math.max(0,edge(a,d)-3))
        local target=floorHeight(b,tb-d*math.max(0,edge(b,d)-1.3))
        if (Vector3.new(delta.X,0,delta.Z)).Magnitude<edge(a,d)+edge(b,d) then start=ta end
        direction=Vector3.zero;jump=false
        character:PivotTo(CFrame.new(start+Vector3.new(0,3.12,0)));root.AssemblyLinearVelocity=Vector3.zero
        h.PlatformStand=false;h.Sit=false;h:ChangeState(Enum.HumanoidStateType.Running)
        assert(waitFor(function()return h.FloorMaterial~=Enum.Material.Air and floor()==a end,1.2),"not grounded on start")
        local gap=(Vector3.new(target.X,0,target.Z)-Vector3.new(start.X,0,start.Z)).Magnitude
        local needsJump=(gap>2.5 or tb.Y-ta.Y>1) and a.Name~="BoardingRamp" and b.Name~="BoardingRamp"
        direction=d
        if needsJump then
            local launch=Vector3.new(ta.X,0,ta.Z)+d*math.max(0,edge(a,d)-.55)
            waitFor(function()return (Vector3.new(root.Position.X,0,root.Position.Z)-launch):Dot(d)>=0 end,.4)
        end
        jump=needsJump
        if needsJump then assert(waitFor(function()return h.FloorMaterial==Enum.Material.Air end,.4),"no takeoff");jump=false end
        local reached=waitFor(function()
            if floor()==b and h.FloorMaterial~=Enum.Material.Air then return true end
            local flat=Vector3.new(root.Position.X-tb.X,0,root.Position.Z-tb.Z)
            if flat:Dot(d)>0 then direction=Vector3.zero end
            return false
        end,1.5)
        assert(reached,"missed target; floor="..tostring(floor()))
    end)
    direction=Vector3.zero;jump=false
    table.insert(records,{from=pair[1],to=pair[2],passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute("Progress",#records)
end
binding:Disconnect();character:Destroy()
script:SetAttribute("Result",game.HttpService:JSONEncode({build=map:GetAttribute("ShipwreckBuild"),records=records,method="Server-owned live R15 clone, grounded takeoffs, normal movement; independent links, not a full race or human timing"}))
