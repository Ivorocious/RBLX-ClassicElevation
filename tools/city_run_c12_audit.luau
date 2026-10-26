local Audit = {}

local function value(v)
	local kind = typeof(v)
	if kind == "Vector3" then return {v.X, v.Y, v.Z}
	elseif kind == "Vector2" then return {v.X, v.Y}
	elseif kind == "Color3" then return {v.R, v.G, v.B}
	elseif kind == "CFrame" then return {v:GetComponents()}
	elseif kind == "EnumItem" then return tostring(v)
	else return v end
end

function Audit.Snapshot(roots)
	local records = {}
	local function visit(object, path)
		local attrs = {}
		for key, attribute in object:GetAttributes() do
			attrs[key] = value(attribute)
		end
		local record = { path = path, class = object.ClassName, attrs = attrs }
		if object:IsA("BasePart") then
			record.cf = { object.CFrame:GetComponents() }
			record.size = { object.Size.X, object.Size.Y, object.Size.Z }
			record.color = { object.Color.R, object.Color.G, object.Color.B }
			for _, key in { "Transparency", "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow", "CollisionGroup", "Material" } do
				record[key] = if typeof(object[key]) == "EnumItem" then tostring(object[key]) else object[key]
			end
			if object:IsA("Part") then record.shape = tostring(object.Shape) end
			if object:IsA("MeshPart") then record.mesh = object.MeshId; record.texture = object.TextureID; record.DoubleSided = object.DoubleSided end
		elseif object:IsA("Model") then
			record.pivot = { object:GetPivot():GetComponents() }
		end
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			record.text = object.Text; record.textColor = value(object.TextColor3)
			record.textScaled = object.TextScaled; record.font = tostring(object.Font)
		elseif object:IsA("SurfaceGui") then
			record.face = tostring(object.Face); record.canvas = value(object.CanvasSize)
		end
		if object:IsA("LuaSourceContainer") then record.source = object.Source end
		table.insert(records, record)
		for _, child in object:GetChildren() do visit(child, path .. "/" .. child.Name) end
	end
	for _, root in roots do visit(root, root.Name) end
	return records
end

return Audit
