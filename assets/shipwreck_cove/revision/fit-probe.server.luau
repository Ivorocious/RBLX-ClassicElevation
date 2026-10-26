local RunService=game:GetService("RunService")
local layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local map=workspace.RaceCourse
assert(map:GetAttribute("ShipwreckBuild")==layout.build,"layout and installed build differ")
local player=game.Players:GetPlayers()[1]
local original=player.Character;local archivable=original.Archivable;original.Archivable=true
local character=original:Clone();original.Archivable=archivable;character.Name="__ShipwreckRouteFit"
for _,v in character:GetDescendants() do
    if v:IsA("BaseScript") then v.Enabled=false end
    if v:IsA("BasePart") then v.Anchored=false end
end
character.Parent=workspace
local h=character:FindFirstChildOfClass("Humanoid");local root=character.HumanoidRootPart
assert(h and h.RigType==Enum.HumanoidRigType.R15,"Probe requires an R15 test player")
root:SetNetworkOwner(nil);h.WalkSpeed=16;h.UseJumpPower=false;h.JumpHeight=7.2;h.EvaluateStateMachine=true
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
for _,pair in layout.links do
    if not script:GetAttribute("OnlyFirstRib") or (pair[1]=="R2_Boarding" and pair[2]=="Rib00") then table.insert(pairsToTest,pair) end
end
assert(pairsToTest and #pairsToTest>0,"layout has no authored links")
local ribLinks,sparLinks=0,0
for _,pair in pairsToTest do
    if string.find(pair[1],"Rib") or string.find(pair[2],"Rib") then ribLinks+=1 end
    if string.find(pair[1],"Spar") or string.find(pair[2],"Spar") then sparLinks+=1 end
end
assert(script:GetAttribute("OnlyFirstRib") or (ribLinks>1 and sparLinks>1),"both expert shortcuts must be tested")
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
            if flat:Dot(d)>-.85 then direction=Vector3.zero end
            return false
        end,1.5)
        assert(reached,"missed target; floor="..tostring(floor()))
    end)
    direction=Vector3.zero;jump=false
    table.insert(records,{from=pair[1],to=pair[2],passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute("Progress",#records)
end
binding:Disconnect();character:Destroy()
script:SetAttribute("Result",game.HttpService:JSONEncode({build=map:GetAttribute("ShipwreckBuild"),links=#pairsToTest,ribLinks=ribLinks,sparLinks=sparLinks,records=records,method="Server-owned live R15 clone, grounded takeoffs, normal movement; independently reset for each authored link, including both shortcuts; not a full race or human timing"}))
