local config=require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local area=workspace[config.BlenderRootName].LanternStudy
local origin=config.LanternOrigin+config.BlenderOffset
local player=game.Players.LocalPlayer
local humanoid=player.Character.Humanoid
local body=player.Character.HumanoidRootPart
local steps={}
local function record(name)
	table.insert(steps,{name=name,position={body.Position.X,body.Position.Y,body.Position.Z},ground=humanoid.FloorMaterial.Name,state=humanoid:GetState().Name})
end
local function move(x,z,seconds)
	local target=origin+Vector3.new(x,0,z)
	shared.MCGoal=target
	local deadline=os.clock()+(seconds or 3)
	repeat task.wait(.02)until Vector3.new(body.Position.X-target.X,0,body.Position.Z-target.Z).Magnitude<1.1 or os.clock()>deadline
	shared.MCGoal=nil;humanoid:Move(Vector3.zero,false)
	assert(Vector3.new(body.Position.X-target.X,0,body.Position.Z-target.Z).Magnitude<1.4,"Lantern movement goal not reached")
end
local function jump(x,z,name)
	assert(humanoid.FloorMaterial~=Enum.Material.Air,"Ungrounded lantern takeoff")
	record(name.."Takeoff")
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping);humanoid.Jump=true
	move(x,z,2)
	task.wait(.45);record(name.."Contact")
	assert(humanoid.FloorMaterial~=Enum.Material.Air,"Lantern landing unavailable")
end
local function away(band,left)
	local cage=area.SwingLanterns["SwingBand"..band].PrimaryPart
	local previous=cage.Position.X
	local deadline=os.clock()+7
	local passed=false
	repeat
		task.wait(.02)
		local x=cage.Position.X-origin.X
		local rising=cage.Position.X>previous
		previous=cage.Position.X
		passed=if left then x>2 and rising else x< -2 and not rising
	until passed or os.clock()>deadline
	assert(passed,"Lantern away phase unavailable")
end
local Probe={}
function Probe.Debug() return steps end
function Probe.Normal()
	move(-8,-6)
	away(1,true)
	jump(-8,-14,"Band1Entry")
	move(-8,-24)
	jump(-8,-31,"Band1Wait")
	move(-3,-34.5)
	jump(5,-35,"Band2Entry")
	move(8,-35)
	away(2,false)
	move(8,-46)
	jump(8,-53,"Band2Wait")
	move(3,-56.5)
	jump(-5,-57,"Band3Entry")
	move(-8,-57)
	away(3,true)
	move(-8,-68)
	jump(-8,-75,"Band3Wait")
	move(0,-80)
	record("LanternMerge")
	return {route="LanternNormal",steps=steps}
end
function Probe.Expert()
	move(0,-6)
	jump(0,-13,"CentralApproach1")
	for band=1,3 do
		local before=-13-(band-1)*22
		local after=before-14
		move(0,before-3.6)
		local cage=area.SwingLanterns["SwingBand"..band].PrimaryPart
		local previous=cage.Position.X-origin.X
		local deadline=os.clock()+7
		local clear=false
		repeat
			task.wait(.02)
			local x=cage.Position.X-origin.X
			clear=math.abs(x)>6.5 and math.abs(x)>math.abs(previous)
			previous=x
		until clear or os.clock()>deadline
		assert(clear,"Central crossing phase unavailable")
		jump(0,after+1.7,"CentralGap"..band)
		if band<3 then
			move(0,after-2.8)
			jump(0,before-21,"CentralApproach"..(band+1))
		end
	end
	jump(0,-80,"CentralExit")
	record("LanternExpertMerge")
	return {route="LanternExpert",steps=steps}
end
return Probe
