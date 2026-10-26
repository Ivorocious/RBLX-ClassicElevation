local fs, luau, roblox = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local environment = {}
for key, value in roblox do environment[key] = value end
local nativeCFrame = table.clone(roblox.CFrame)
-- Lune's lookAt reverses Z; match Roblox's forward/right/up basis for this geometry check.
function nativeCFrame.lookAt(origin,target,up)
	local look = (target-origin).Unit
	local right = look:Cross(up or roblox.Vector3.yAxis).Unit
	return roblox.CFrame.fromMatrix(origin,right,right:Cross(look),-look)
end
environment.CFrame = nativeCFrame
local peck = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/GuardianPeck.luau"),{environment=environment})()
local V, CF = roblox.Vector3.new, nativeCFrame
local checks = 0
local function check(value,message)
	checks += 1
	assert(value,message)
end
local settings = {rest=2.2,warning=1.8,strike=.55,impact=.3,recover=.9}
local duration = settings.rest+settings.warning+settings.strike+settings.impact+settings.recover
local expected = {
	{0,"Rest",false}, {2.3,"Warning",false}, {4.1,"Pecking",true},
	{4.6,"Impact",true}, {4.9,"Recovering",false},
}
for target=1,3 do
	for _, row in expected do
		local sample = peck.Sample(settings,(target-1)*duration+row[1],3)
		check(sample.target==target and sample.state==row[2] and sample.lethal==row[3],"warn/strike/recovery target policy")
	end
end
check(peck.Sample(settings,duration*3+.1,3).target==1,"fixed three-target order repeats")
check(peck.Sample(settings,4.001,3).state=="Pecking","warning ends before strike")
local anchor, tip, neck = V(94,36,40), V(0,-1,-10), V(0,-3,2.5)
local home = CF.new(112,55,40)*CF.Angles(0,-math.pi/2,0)
for _, point in {V(135,28.5,40),V(121.5,29.5,26),V(87,23.5,85)} do
	local strike = peck.StrikeFrame(anchor,point,tip)
	local aim = strike + V(0,12,0)
	check((strike:PointToWorldSpace(tip)-point).Magnitude<1e-5,"visible beak tip reaches target")
	for _, pair in {{home,aim},{aim,strike},{strike,home}} do
		for sample=0,200 do
			local frame = pair[1]:Lerp(pair[2],sample/200)
			local endpoint = frame:PointToWorldSpace(neck)
			local elbow = peck.Elbow(anchor,endpoint,24,V(0,1,0))
			check(math.abs((elbow-anchor).Magnitude-24)<1e-4,"fixed lower neck length")
			check(math.abs((endpoint-elbow).Magnitude-24)<1e-4,"fixed upper neck length")
		end
	end
end
print(string.format("GuardianPeck: %d timing, target order, visible-tip and fixed-link reach checks passed; native contact and animation appearance are not simulated",checks))
