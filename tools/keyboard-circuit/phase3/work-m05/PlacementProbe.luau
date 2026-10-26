local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local env = {Vector3=roblox.Vector3, CFrame=roblox.CFrame, Instance=roblox.Instance, Enum=roblox.Enum}
local adapter = luau.load(fs.readFile("tools/keyboard-circuit/phase3/work-m05/sources/StandardCourse.luau"), {environment=env, injectGlobals=true})()
local input = "docs/artifacts/keyboard-circuit/phase3/m05-recovery/M04-before-basic-handoff.rbxm"
local original = roblox.deserializeModel(fs.readFile(input))[1]
local course = original:Clone()
local preserved = {}
for _, item in course:GetDescendants() do if item:IsA("BasePart") then preserved[item] = {item.CFrame, item.Size} end end
adapter.Apply(course)
local result = {passed=true, input=input, actualOrigin=tostring(course:GetAttribute("Origin")), safePoses={}}
for _, part in {course.Start, table.unpack(course.Checkpoints:GetChildren())} do
	if not part:IsA("BasePart") then continue end
	local spawn = assert(part:GetAttribute("RespawnCFrame"))
	local contact = course.Checkpoints.RecoveryPads[part:GetAttribute("RecoveryGate")].BankContact
	local point = contact.CFrame:PointToObjectSpace(spawn.Position)
	assert(math.abs(point.X) <= contact.Size.X/2 and math.abs(point.Z) <= contact.Size.Z/2, "Recovery outside bank: " .. part.Name)
	assert(point.Y > 2 and point.Y < 6, "Recovery height wrong: " .. part.Name)
	table.insert(result.safePoses, {name=part.Name, localPosition=tostring(point)})
end
assert(#result.safePoses == 9)
for item, props in preserved do
	assert(item.CFrame == props[1] and item.Size == props[2], "Physical geometry moved")
end
fs.writeFile("docs/artifacts/keyboard-circuit/phase3/P3-M05-placement-01.json", serde.encode("json",result,true))
print(serde.encode("json", result))
