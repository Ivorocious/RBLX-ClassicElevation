local Audit = {}

function Audit.Snapshot(roots)
	local records = {}
	local function visit(object, path)
		local attrs = {}
		for key, value in object:GetAttributes() do
			attrs[key] = if typeof(value) == "Vector3" then { value.X, value.Y, value.Z } else value
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
			if object:IsA("MeshPart") then record.mesh = object.MeshId; record.texture = object.TextureID end
		elseif object:IsA("Model") then
			record.pivot = { object:GetPivot():GetComponents() }
		end
		if object:IsA("LuaSourceContainer") then record.source = object.Source end
		table.insert(records, record)
		for _, child in object:GetChildren() do visit(child, path .. "/" .. child.Name) end
	end
	for _, root in roots do visit(root, root.Name) end
	return records
end

return Audit
