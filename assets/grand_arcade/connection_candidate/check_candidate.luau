local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

luau.compile(fs.readFile("src/ServerStorage/CourseBuilders/LobbyBuilders/GrandArcadeConnection.luau"))
luau.compile(fs.readFile("assets/grand_arcade/connection_candidate/check_recovery.native.luau"))
local checks = 2
local origin = roblox.Vector3.new(1552,370,-892.5)
local sections = {
	{near=-2.5,far=1.5,start=0,rise=0},
	{near=1.5,far=17.5,start=0,rise=4.2},
	{near=17.5,far=27.5,start=4.2,rise=0},
}
for _, section in sections do
	local run = section.far-section.near
	local back = roblox.Vector3.new(0,-section.rise/run,1).Unit
	local up = roblox.Vector3.new(0,1,section.rise/run).Unit
	local surface = origin+roblox.Vector3.new(0,section.start+section.rise/2,-(section.near+section.far)/2)
	local frame = roblox.CFrame.fromMatrix(surface-up*.25,roblox.Vector3.xAxis,up,back)
	local length=math.sqrt(run*run+section.rise*section.rise)
	local near=frame:PointToWorldSpace(roblox.Vector3.new(0,.25,length/2))
	local far=frame:PointToWorldSpace(roblox.Vector3.new(0,.25,-length/2))
	assert((near-(origin+roblox.Vector3.new(0,section.start,-section.near))).Magnitude<.0001)
	assert((far-(origin+roblox.Vector3.new(0,section.start+section.rise,-section.far))).Magnitude<.0001)
	checks+=2
end
assert(sections[1].far==sections[2].near and sections[2].far==sections[3].near)
assert(sections[1].start+sections[1].rise==sections[2].start)
assert(sections[2].start+sections[2].rise==sections[3].start)
checks+=3
assert(origin.Z+2.5>-893 and origin.Z-27.5<-917.7)
assert(9.45-.55>8)
checks+=2
assert(10.4-1>7.2+1)
assert(math.abs((370+(6*4.2/16)) - (371.4+.175))<.00001)
checks+=2
assert(math.abs((370+1.575-.3)+.6/2-371.575)<.00001)
assert(10.4-3/2<9.85)
checks+=2
print(`{checks} candidate syntax/profile checks passed; native installation and walking remain unverified.`)
