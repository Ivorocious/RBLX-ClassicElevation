local roblox=require("@lune/roblox")
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local Vector3,CFrame=roblox.Vector3,roblox.CFrame
local source=fs.readFile("src/ServerStorage/CourseBuilders/StudGarden/FruitMotion.luau")
local module=luau.load(source,{environment={Vector3=Vector3}})()
local cube=Vector3.new(2,2,2)
local frame=CFrame.identity
assert(module.SweepTouchesBody(Vector3.new(-5,0,0),Vector3.new(5,0,0),.5,frame,cube),"Crossing must hit")
assert(not module.SweepTouchesBody(Vector3.new(-5,2,0),Vector3.new(5,2,0),.5,frame,cube),"Clearance must miss")
assert(not module.SweepTouchesBody(Vector3.new(1.45,1.45,0),Vector3.new(1.45,1.45,0),.5,frame,cube),"Box-corner near miss must remain safe")
assert(module.SweepTouchesBody(Vector3.new(-5,1.3,1.3),Vector3.new(5,1.3,1.3),.5,frame,cube),"Rounded corner contact must hit")
assert(not module.SweepTouchesBody(Vector3.new(-5,1.4,1.4),Vector3.new(5,1.4,1.4),.5,frame,cube),"Rounded corner clearance must miss")
assert(module.SweepTouchesBody(Vector3.zero,Vector3.zero,.1,frame,cube),"Stationary overlap must hit")
local rotation=CFrame.new(13,7,-9)*CFrame.Angles(.2,1.1,-.3)
assert(module.SweepTouchesBody(rotation*Vector3.new(-5,0,0),rotation*Vector3.new(5,0,0),.5,rotation,cube),"Transform must preserve hit")
assert(not module.SweepTouchesBody(rotation*Vector3.new(-5,2,0),rotation*Vector3.new(5,2,0),.5,rotation,cube),"Transform must preserve miss")
for i=1,3 do
	assert((module.Position(0,i)-Vector3.new(-17,2.8,(i-2)*8)).Magnitude<.001)
	assert((module.Position(1,i)-Vector3.new(21,2.8,(i-2)*8)).Magnitude<.001)
end
local corner=.76*(13.6+17)/38
local drop=10.6
assert((module.Position(corner,1,drop)-Vector3.new(13.6,2.8,-8)).Magnitude<.001,"Fruit leaves the root at crown height")
assert((module.Position(1,1,drop)-Vector3.new(21,-7.8,-8)).Magnitude<.001,"Fruit rests above the lowered catch trough")
local split=module.Segments(corner-.02,corner+.02,1,drop)
assert(#split==3 and (split[2]-Vector3.new(13.6,2.8,-8)).Magnitude<.001,"Contact must split at the falling-path corner")
assert(#module.Segments(0,.3,1,drop)==2,"Straight travel needs one sweep")
assert(#module.Segments(.9,1,1,drop)==2,"Stationary end remains safe to sweep")
local nearCorner=CFrame.new(13.6,4.9,-8)
local touches=false
for i=1,#split-1 do touches=touches or module.SweepTouchesBody(split[i],split[i+1],2.4,nearCorner,Vector3.one) end
assert(touches,"Corner contact must survive the route split")
print("FruitMotion: 20 focused crossing, near-miss, transform, falling-path and endpoint checks passed")
