local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local serde = require("@lune/serde")

local directory = "backups/shared-obstacle-kit-v5-2026-10-11/"
local sources = {"ManualObstacleKit", "ManualObstacleCreative", "ManualObstacleInventive", "ManualObstacleMotion", "ManualObstaclePhases"}
for _, name in sources do
	luau.load(fs.readFile("src/ServerStorage/CourseBuilders/" .. name .. ".luau"), {debugName=name})
end

local function snapshot(root)
	local rows = {}
	local function visit(item, key)
		local row = {class=item.ClassName, attributes=item:GetAttributes()}
		if item:IsA("BasePart") then
			row.frame, row.size = item.CFrame, item.Size
			row.properties = {item.Color, item.Material, item.Transparency, item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery, item.TopSurface, item.BottomSurface}
		end
		if item:IsA("Model") then
			local ok, pivot = pcall(function() return item.WorldPivot end)
			if ok then row.pivot = pivot end
		end
		if item:IsA("TextLabel") then row.text = item.Text end
		rows[key] = row
		local counts = {}
		for _, child in item:GetChildren() do
			local name = child.Name .. ":" .. child.ClassName
			counts[name] = (counts[name] or 0) + 1
			visit(child, key .. "/" .. name .. "#" .. counts[name])
		end
	end
	visit(root, root.Name)
	return rows
end
local function equal(a, b)
	if typeof(a) ~= typeof(b) then return false end
	if typeof(a) == "table" then
		for k,v in a do if not equal(v,b[k]) then return false end end
		for k in b do if a[k] == nil then return false end end
		return true
	elseif typeof(a) == "CFrame" then return equal({a:GetComponents()},{b:GetComponents()})
	elseif typeof(a) == "Vector3" then return (a-b).Magnitude < .0001
	elseif typeof(a) == "Color3" then return math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B) < .0001
	elseif typeof(a) == "number" then return math.abs(a-b) < .0001 end
	return a==b
end
local before = roblox.deserializeModel(fs.readFile(directory .. "palette-before-v5.rbxm"))[1]
assert(#before.CopyThese:GetChildren() == 42)
local initial = snapshot(before)
local restored = snapshot(roblox.deserializeModel(roblox.serializeModel({before}))[1])
local count = 0
for key,row in initial do assert(equal(row,restored[key]), "Backup roundtrip changed " .. key); count+=1 end
local result = {compiledSources=#sources, backupRoundtripInstances=count, beforePieces=42}
if fs.isFile(directory .. "palette-v5.rbxm") then
	local after = roblox.deserializeModel(fs.readFile(directory .. "palette-v5.rbxm"))[1]
	local final = snapshot(after)
	for key,row in initial do
		if key==before.Name then
			local version=final[key].attributes.KitVersion
			final[key].attributes.KitVersion=row.attributes.KitVersion
			assert(version==5)
		end
		assert(equal(row,final[key]),"Existing palette changed: " .. key)
	end
	assert(#after.CopyThese:GetChildren()==66)
	local parts, phases, hinges, moving, crumbles = 0,0,0,0,0
	local sets={}
	for _, model in after.CopyThese:GetChildren() do
		local index=tonumber(model.Name:sub(1,2))
		if index < 43 then continue end
		assert(model:GetAttribute("Instructions") and model:GetAttribute("Category"))
		local n=0
		for _, part in model:GetDescendants() do
			assert(not part:IsA("LuaSourceContainer"),"Embedded script")
			if not part:IsA("BasePart") then continue end
			assert(part.Anchored)
			n+=1; parts+=1
			if part:GetAttribute("KitPhase") then phases+=1; assert(part.CanCollide and part:GetAttribute("HazardType")==nil) end
			if part:GetAttribute("MotionPivotOffset") then hinges+=1 end
			if part:GetAttribute("KitMotion") then moving+=1; assert(not part.CanCollide and part.CanTouch and part.CanQuery) end
			if part:GetAttribute("HazardType")=="Crumble" then crumbles+=1 end
		end
		table.insert(sets,{name=model.Name,parts=n})
	end
	result.afterPieces, result.preservedInstances = 66,count
	result.additions={parts=parts,phases=phases,hinges=hinges,moving=moving,crumbles=crumbles,sets=sets}
	local nativeRoundtrip = snapshot(roblox.deserializeModel(roblox.serializeModel({after}))[1])
	local authored = snapshot(after)
	for key,row in authored do assert(equal(row,nativeRoundtrip[key]),"V5 restore mismatch: " .. key) end
end
fs.writeFile("docs/artifacts/shared-obstacle-kit-v5-static.json",serde.encode("json",result,true))
print(serde.encode("json",result,true))
