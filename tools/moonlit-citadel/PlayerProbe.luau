local Probe={}
local player=game.Players.LocalPlayer
local character=player.Character
local humanoid=character.Humanoid
local body=character.HumanoidRootPart
local config=require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local sample=workspace[config.BlenderRootName].UpperSample
local offset=config.BlenderOffset
local steps={}
local function record(name)
	table.insert(steps,{name=name,position={body.Position.X,body.Position.Y,body.Position.Z},ground=humanoid.FloorMaterial.Name,state=humanoid:GetState().Name})
end
local function move(x,z,seconds)
	x+=offset.X;z+=offset.Z
	shared.MCGoal=Vector3.new(x,body.Position.Y,z)
	local start=os.clock()
	repeat task.wait(.02)until Vector3.new(body.Position.X-x,0,body.Position.Z-z).Magnitude<1.2 or os.clock()-start>(seconds or 3)
	shared.MCGoal=nil;humanoid:Move(Vector3.zero,false)
	assert(Vector3.new(body.Position.X-x,0,body.Position.Z-z).Magnitude<1.4,"Movement goal not reached: "..x..", "..z)
end
local function jump(x,z,name)
	record(name.."Takeoff")
	assert(humanoid.FloorMaterial~=Enum.Material.Air,"Ungrounded takeoff: "..name)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping);humanoid.Jump=true
	move(x,z,2)
	task.wait(.55)
	record(name.."Contact")
end
local function await(test,seconds)
	local deadline=os.clock()+seconds
	local passed=false
	repeat task.wait(.03);passed=test()until passed or os.clock()>deadline
	assert(passed,"Arrival window unavailable")
end
function Probe.Debug() return steps end
function Probe.CatchReturn()
	move(4318,1023)
	move(4318,1029.5)
	await(function()return body.Position.Y<347 and humanoid.FloorMaterial~=Enum.Material.Air end,3)
	record("CatchShelfLanding")
	move(4275,1024,4)
	move(4269,1024)
	move(4269,1018)
	record("CatchReturnMiddle")
	move(4269,1012)
	move(4277,1012)
	record("CatchReturnApproach")
	move(4282,1021)
	record("CatchReturnCP04")
	return {route="CatchReturn",steps=steps,speed=humanoid.WalkSpeed,jumpHeight=humanoid.JumpHeight}
end
function Probe.Normal()
	local deck=sample.MovingCars.Upper_Bay1.PrimaryPart
	move(4291,1011)
	await(function()return deck.Position.Y<350 end,16)
	jump(4291,1000,"NormalBoard")
	await(function()return deck.Position.Y>383.2 end,16)
	record("NormalRideTop")
	move(4291,996,1)
	jump(4291,987,"NormalExit")
	move(4300,981)
	record("NormalMerge")
	return {route="Normal",steps=steps,speed=humanoid.WalkSpeed,jumpHeight=humanoid.JumpHeight}
end
function Probe.BlockedCarry()
	local deck=sample.MovingCars.Upper_Bay1.PrimaryPart
	move(4291,1011)
	await(function()return deck.Position.Y<350 end,16)
	jump(4291,1000,"ObstructedBoard")
	await(function()
		local encoded=workspace[config.BlenderRootName]:GetAttribute("PreviewReport")
		if not encoded then return false end
		for _,row in game.HttpService:JSONDecode(encoded).players do
			if row.userId==player.UserId then return row.lastRecovery=="BlockedCarCarry" end
		end
		return false
	end,10)
	record("BlockedCarryRecovery")
	return {route="BlockedCarry",steps=steps}
end
function Probe.Expert()
	local deck=sample.MovingCars.Upper_Bay2.PrimaryPart
	move(4323,1021)
	for i,p in {{4331,1019},{4325,1014},{4317,1012},{4309,1010.5}}do jump(p[1],p[2],"Brace"..i)end
	local previous=deck.Position.Y
	await(function()local top=deck.Position.Y+.375;local rising=deck.Position.Y>previous;previous=deck.Position.Y;return top>359 and top<361 and rising end,16)
	jump(4309,1000,"ExpertBoard")
	await(function()return deck.Position.Y>375.4 end,16)
	move(4309,1004,1)
	jump(4309,1010.5,"ExpertEarlyExit")
	for _,p in {{4318,1014},{4326,1015},{4334,1007},{4334,986},{4321,979},{4300,981}}do move(p[1],p[2],3)end
	record("ExpertMerge")
	return {route="Expert",steps=steps,speed=humanoid.WalkSpeed,jumpHeight=humanoid.JumpHeight}
end
return Probe
