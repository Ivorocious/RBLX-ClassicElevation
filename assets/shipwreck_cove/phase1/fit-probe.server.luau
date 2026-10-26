-- Temporary Studio-only probe; teleports establish starts, movement uses the live Humanoid.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
local originalCharacter = player.Character
local wasArchivable = originalCharacter.Archivable
originalCharacter.Archivable = true
local character = originalCharacter:Clone()
originalCharacter.Archivable = wasArchivable
character.Name = "__ShipwreckAvatarFit"
for _,object in character:GetDescendants() do
    if object:IsA("BaseScript") then object.Enabled = false end
    if object:IsA("BasePart") then object.Anchored = false end
end
character.Parent = workspace
local humanoid = character:FindFirstChildOfClass("Humanoid")
humanoid.PlatformStand = false
humanoid.Sit = false
humanoid.EvaluateStateMachine = true
humanoid:ChangeState(Enum.HumanoidStateType.Running)
local root = character.HumanoidRootPart
local study = workspace.__ShipwreckCove_Phase1
local controls = {Disable=function()end, Enable=function()end}
local saved = character:GetPivot()
local direction, jump = Vector3.zero, false
local records = {}
local binding
root:SetNetworkOwner(nil)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {study}
params.RespectCanCollide = true
local function floor()
    local h=workspace:Raycast(root.Position,Vector3.new(0,-4,0),params)
    return h and h.Instance
end
local function waitFor(fn,seconds,why)
    local deadline=os.clock()+seconds
    repeat RunService.Heartbeat:Wait() until fn() or os.clock()>deadline
    assert(fn(),why)
end
local function position(x,y,z)
    direction=Vector3.zero;jump=false
    assert(humanoid.Health>0,"Avatar must be alive before probe")
    character:PivotTo(CFrame.new(x,y+humanoid.HipHeight+root.Size.Y/2+.12,z))
    root.AssemblyLinearVelocity=Vector3.zero
    waitFor(function()
        local f=floor()
        return humanoid.FloorMaterial~=Enum.Material.Air and f and f:IsDescendantOf(study)
            and math.abs(root.Position.Y-(y+3))<.7
    end,2.5,"Start not grounded on the intended study surface")
    task.wait(.1)
end
local function parts(group,asset)
    local list={}
    for _,m in study[group]:GetChildren() do
        if m:GetAttribute("Asset")==asset then table.insert(list,m) end
    end
    table.sort(list,function(a,b)return a:GetAttribute("PlacementIndex")<b:GetAttribute("PlacementIndex")end)
    return list
end
local function probe(name,fn)
    local ok,result=xpcall(fn,debug.traceback)
    direction=Vector3.zero;jump=false
    table.insert(records,{name=name,passed=ok,result=tostring(result)})
end
local function jumpBetween(a,b)
    local p,q=a.Collider1,b.Collider1
    local isSpar=a:GetAttribute("Asset")=="SC_BrokenSpar"
    local target=if isSpar then q.Position-q.CFrame.RightVector*5 else q.Position
    local delta=target-p.Position
    local forward=Vector3.new(delta.X,0,delta.Z).Unit
    local start=if isSpar then p.Position+p.CFrame.RightVector*6.5 else p.Position+forward*1.1
    delta=target-start;forward=Vector3.new(delta.X,0,delta.Z).Unit
    position(start.X,p.Position.Y+p.Size.Y/2,start.Z)
    direction=forward;jump=true
    waitFor(function()return humanoid.FloorMaterial==Enum.Material.Air end,.5,"No takeoff")
    jump=false
    waitFor(function()
        if (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(target.X,0,target.Z)).Magnitude<.6 then direction=Vector3.zero end
        return humanoid.FloorMaterial~=Enum.Material.Air
    end,1.1,"No landing")
    direction=Vector3.zero
    task.wait(.12)
    local landed=floor()
    assert(landed and landed:IsDescendantOf(b),"Landed outside target: "..tostring(landed))
    return tostring(root.Position)
end
local function sphereHitsAvatar(center,radius)
    for _,p in character:GetChildren() do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
            local v=p.CFrame:PointToObjectSpace(center)
            local half=p.Size/2
            local closest=Vector3.new(math.clamp(v.X,-half.X,half.X),math.clamp(v.Y,-half.Y,half.Y),math.clamp(v.Z,-half.Z,half.Z))
            if (v-closest).Magnitude<radius then return true,p.Name end
        end
    end
    return false
end
local ok,errorMessage=xpcall(function()
    assert(RunService:IsStudio() and RunService:IsServer())
    assert(humanoid.RigType==Enum.HumanoidRigType.R15)
    assert(humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01)
    assert(math.abs(workspace.Gravity-196.2)<.01)
    local flight=nil
    if flight then require(flight).SetFlying(false) end
    controls:Disable()
    binding=RunService.Heartbeat:Connect(function()
        humanoid:Move(direction,false);humanoid.Jump=jump
    end)
    probe("BoardingRampRun",function()
        position(-620,54.23,-44)
        direction=Vector3.new(1,0,0)
        waitFor(function()return root.Position.X>-604 end,1.8,"Blocked on ramp")
        direction=Vector3.zero
        assert(root.Position.Y>61.8,"Did not reach raised hull floor: "..tostring(root.Position))
        return tostring(root.Position)
    end)
    local ribs=parts("ribs_spars","SC_PlayableRib")
    probe("InteriorGapAndHeadroom",function()
        local m=parts("ribs_spars","SC_BrokenDeck")[1]
        local p,q=m.Collider1,m.Collider2
        position(p.Position.X+1,p.Position.Y+.6,p.Position.Z)
        local startY=root.Position.Y
        direction=Vector3.new(1,0,0);jump=true
        waitFor(function()return humanoid.FloorMaterial==Enum.Material.Air end,.5,"No gap takeoff")
        jump=false
        local peak=startY
        waitFor(function()
            peak=math.max(peak,root.Position.Y)
            if root.Position.X>=q.Position.X-.4 then direction=Vector3.zero end
            return humanoid.FloorMaterial~=Enum.Material.Air
        end,1.2,"No interior landing")
        direction=Vector3.zero
        assert(peak-startY>6.4,"Ceiling restricted normal jump")
        assert(floor()==q,"Did not land across real plank gap")
        return "Five-stud open gap; jump rise="..(peak-startY)..";14.2-stud roof clearance"
    end)
    local function caveJump(name,x,y,targetPart)
        probe(name,function()
            position(x,y,0);direction=Vector3.new(-1,0,0);jump=true
            waitFor(function()return humanoid.FloorMaterial==Enum.Material.Air end,.5,"No cave takeoff")
            jump=false
            waitFor(function()return humanoid.FloorMaterial~=Enum.Material.Air end,1.3,"No cave landing")
            direction=Vector3.zero;task.wait(.08)
            assert(floor()==targetPart,"Wrong cave landing")
            return tostring(root.Position)
        end)
    end
    caveJump("CaveEntryDrop",-405.4,57,parts("cave","SC_SurgeCrossing")[1].Collider1)
    caveJump("CaveExitRise",-426.4,54,parts("cave","SC_RefugeShelf")[1].Collider1)
    for i=1,#ribs-1 do probe("RibJump"..i,function()return jumpBetween(ribs[i],ribs[i+1])end) end
    local spars=parts("ribs_spars","SC_BrokenSpar")
    for i=1,#spars-1 do probe("SparJump"..i,function()return jumpBetween(spars[i],spars[i+1])end) end
    probe("CannonJump",function()
        position(-622,54.23,0)
        local hits=0
        local start=os.clock()
        direction=Vector3.new(0,0,-1);jump=true
        waitFor(function()return humanoid.FloorMaterial==Enum.Material.Air end,.5,"No cannon jump takeoff")
        jump=false
        local peak=0
        repeat
            RunService.Heartbeat:Wait()
            local t=os.clock()-start
            local center=Vector3.new(-612.9-48*t,57.33,-4)
            if sphereHitsAvatar(center,.8) then hits+=1 end
            peak=math.max(peak,root.Position.Y)
        until os.clock()-start>.7
        assert(hits==0,"Cannon contacted jumping avatar")
        assert(peak>61,"Jump did not occur at intended fixture height")
        assert(root.Position.Z<-7,"Did not cross firing lane")
        assert(humanoid.FloorMaterial~=Enum.Material.Air,"No post-shot landing")
        return "No body contact; peak rootY="..peak.."; shot48 studs/s, diameter1.6"
    end)
    probe("CannonStandingPositiveControl",function()
        position(-622,54.23,-4)
        assert(sphereHitsAvatar(Vector3.new(-622,57.33,-4),.8),"Standing control did not hit")
        return "Standing avatar intersects low ball, jump clearance is meaningful"
    end)
    probe("CannonWaitingPocket",function()
        position(-623,54.23,6)
        for i=0,80 do
            assert(not sphereHitsAvatar(Vector3.new(-612.9-i*.5,57.33,-4),.8),"Unsafe waiting pocket")
        end
        return "Whole body outside complete ball corridor; impact ends at x=-652.9 in water"
    end)
    for i,m in parts("cave","SC_RefugeShelf") do
        probe("DryRefuge"..i,function()
            local p=m.Collider1
            position(p.Position.X,p.Position.Y+.5,p.Position.Z)
            for _,body in character:GetChildren() do
                if body:IsA("BasePart") then
                    local v=body.Position
                    assert(v.X+body.Size.X/2 < -426 or v.X-body.Size.X/2 > -414,"Refuge enters surge footprint")
                end
            end
            return "Safe outside surge x[-426,-414], z[-3,19], maximum y56"
        end)
    end
end,debug.traceback)
if binding then binding:Disconnect() end
direction=Vector3.zero;humanoid:Move(Vector3.zero,false);humanoid.Jump=false
root.AssemblyLinearVelocity=Vector3.zero;controls:Enable()
script:SetAttribute("Result",game.HttpService:JSONEncode({build=study:GetAttribute("Build"),setupPassed=ok,error=if ok then nil else errorMessage,records=records,avatar={rig="R15",hipHeight=humanoid.HipHeight,rootSize=tostring(root.Size),walkSpeed=humanoid.WalkSpeed,jumpHeight=humanoid.JumpHeight},limits="Server-owned live avatar clone driven by real Humanoid physics to isolate unrelated race recovery teleports. Sampled mathematical ball/body clearance. Not final hazard controller, 20-player, touch-input or full-route proof."}))
character:Destroy()

