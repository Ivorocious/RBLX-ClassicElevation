--!strict

-- Run in Studio Edit mode after C18Optimize has built both inspection templates.
-- This audit reports differences; it does not modify either template.
local ServerStorage = game:GetService("ServerStorage")

local sources = ServerStorage:FindFirstChild("CityRunInspectionSources")
assert(sources ~= nil and sources:IsA("Folder"), "CityRunInspectionSources folder is missing")
local original = sources:FindFirstChild("Original")
local optimized = sources:FindFirstChild("Optimized")
assert(original ~= nil and original:IsA("Model"), "Original inspection template is missing")
assert(optimized ~= nil and optimized:IsA("Model"), "Optimized inspection template is missing")

local differences = {}
local compared = 0
local allowed = 0
local missing = 0
local added = 0

local function report(kind: string, path: string, detail: string)
	table.insert(differences, string.format("[%s] %s: %s", kind, path, detail))
end

local function segmentFor(child: Instance): string
	local occurrence = 0
	for _, sibling in ipairs(child.Parent:GetChildren()) do
		if sibling.Name == child.Name and sibling.ClassName == child.ClassName then
			occurrence += 1
		end
		if sibling == child then break end
	end
	return string.format("%s:%s#%d", child.ClassName, child.Name, occurrence)
end

local function indexTree(root: Instance): { [string]: Instance }
	local indexed = { [""] = root }
	local function visit(parent: Instance, parentPath: string)
		for _, child in ipairs(parent:GetChildren()) do
			local path = if parentPath == "" then segmentFor(child) else parentPath .. "/" .. segmentFor(child)
			indexed[path] = child
			visit(child, path)
		end
	end
	visit(root, "")
	return indexed
end

local originalIndex = indexTree(original)
local optimizedIndex = indexTree(optimized)

local function under(path: string, name: string): boolean
	return string.find("/" .. path .. "/", "/" .. name .. "#", 1, true) ~= nil
end

local function isContext(path: string): boolean
	return under(path, "Model:Context")
end

local function directContextRoot(path: string): (string?, Instance?)
	local contextPrefix = "Model:Context#1/"
	if string.sub(path, 1, #contextPrefix) ~= contextPrefix then return nil, nil end
	local tail = string.sub(path, #contextPrefix + 1)
	local firstSegment = string.match(tail, "^[^/]+")
	if firstSegment == nil then return nil, nil end
	local rootPath = contextPrefix .. firstSegment
	return rootPath, originalIndex[rootPath]
end

local function isProtected(path: string, instance: Instance): boolean
	if string.find("/" .. path .. "/", ":OwnerEdits#", 1, true) ~= nil then return true end
	if under(path, "Model:RaceCourse") then
		if not under(path, "Folder:Decoration") and not under(path, "Model:Decoration") then return true end
	end
	return instance:IsA("BasePart") and (instance.CanCollide or instance.CanTouch)
end

local function isPermittedContextRemoval(path: string, instance: Instance): boolean
	local rootPath, root = directContextRoot(path)
	if rootPath == nil or root == nil then return false end
	if root.Name == "ObstacleKit_Palette" then return true end
	if root:IsA("BasePart") and (root.Position - Vector3.new(3500, 0, 0)).Magnitude > 5000 then
		return not isProtected(path, instance)
	end
	return false
end
local function same(a: any, b: any): boolean
	if typeof(a) == "number" and typeof(b) == "number" then return math.abs(a - b) <= 1e-5 end
	if typeof(a) == "Vector3" and typeof(b) == "Vector3" then return (a - b).Magnitude <= 1e-4 end
	if typeof(a) == "CFrame" and typeof(b) == "CFrame" then
		local delta = a:ToObjectSpace(b)
		local x, y, z = delta:ToOrientation()
		return delta.Position.Magnitude <= 1e-4 and math.abs(x) + math.abs(y) + math.abs(z) <= 1e-4
	end
	return a == b
end

local function compareProperty(path: string, left: Instance, right: Instance, property: string)
	local okLeft, leftValue = pcall(function() return (left :: any)[property] end)
	local okRight, rightValue = pcall(function() return (right :: any)[property] end)
	if not okLeft or not okRight then return end
	compared += 1
	if not same(leftValue, rightValue) then
		report("CHANGED", path, string.format("%s differs (%s -> %s)", property, tostring(leftValue), tostring(rightValue)))
	end
end

local function compareAttributes(path: string, left: Instance, right: Instance)
	local leftAttributes = left:GetAttributes()
	local rightAttributes = right:GetAttributes()
	for name, value in pairs(leftAttributes) do
		compared += 1
		if rightAttributes[name] == nil then
			report("ATTRIBUTE", path, name .. " removed")
		elseif not same(value, rightAttributes[name]) then
			report("ATTRIBUTE", path, string.format("%s differs (%s -> %s)", name, tostring(value), tostring(rightAttributes[name])))
		end
	end
	for name in pairs(rightAttributes) do
		if leftAttributes[name] == nil then report("ATTRIBUTE", path, name .. " added") end
	end
end

for path, left in pairs(originalIndex) do
	local right = optimizedIndex[path]
	if right == nil then
		if isPermittedContextRemoval(path, left) then
			allowed += 1
		else
			missing += 1
			report("MISSING", path, "removed from optimized template")
		end
	else
		if left.ClassName ~= right.ClassName then
			report("CLASS", path, left.ClassName .. " -> " .. right.ClassName)
		else
			local protected = isProtected(path, left)
			if protected then compareAttributes(path, left, right) end
			if left:IsA("BasePart") and right:IsA("BasePart") then
				for _, property in ipairs({
					"CFrame", "Size", "Material", "MaterialVariant", "Color", "Transparency", "Reflectance",
					"CastShadow", "Anchored", "CanCollide", "CanTouch", "CollisionGroup", "Massless",
				}) do
					compareProperty(path, left, right, property)
				end
				if protected then
					compareProperty(path, left, right, "CanQuery")
				elseif left.CanQuery ~= right.CanQuery then
					allowed += 1
				end
				if left:IsA("MeshPart") and right:IsA("MeshPart") then
					for _, property in ipairs({ "TextureID", "DoubleSided" }) do
						compareProperty(path, left, right, property)
					end
					if protected then
						compareProperty(path, left, right, "MeshId")
						compareProperty(path, left, right, "CollisionFidelity")
					else
						if left.MeshId ~= right.MeshId then allowed += 1 end
						if left.CollisionFidelity ~= right.CollisionFidelity then allowed += 1 end
					end
				end
			end
		end
	end
end
for path in pairs(optimizedIndex) do
	if originalIndex[path] == nil then
		added += 1
		report("ADDED", path, "exists only in optimized template")
	end
end

print(string.format(
	"[CityRunC18GeometryAudit] compared=%d allowedChanges=%d missingProtected=%d added=%d differences=%d",
	compared, allowed, missing, added, #differences
))
for _, difference in ipairs(differences) do warn("[CityRunC18GeometryAudit] " .. difference) end
return {
	compared = compared,
	allowedChanges = allowed,
	missingProtected = missing,
	added = added,
	differences = differences,
	passed = #differences == 0,
}
