-- This construction function is invoked in Studio Edit mode with manifest_M02.json.
return function(manifest, assetId: string, origin: Vector3)
	assert(game.PlaceId == 85558151074819, "Wrong place")
	local rootName = "MedievalStudShowcase_" .. manifest.revision
	assert(not workspace:FindFirstChild(rootName), "Showcase already exists")
	local source = game.ServerStorage:FindFirstChild(rootName)
	assert(source and source:IsA("Model"), "Load the uploaded asset into ServerStorage first")
	local imported = {}
	local count = 0
	for _, item in source:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Unexpected imported script")
		if item:IsA("BasePart") then
			assert(item:IsA("MeshPart") and manifest.meshes[item.Name], "Unexpected mesh: " .. item.Name)
			assert(not imported[item.Name], "Duplicate mesh: " .. item.Name)
			imported[item.Name] = item
			count += 1
		end
	end
	assert(count == manifest.geometryCount, "Imported mesh count does not match manifest")
	for name in manifest.meshes do assert(imported[name], "Missing " .. name) end
	local root = Instance.new("Model")
	root.Name = rootName
	root:SetAttribute("SourceAssetId", assetId)
	root:SetAttribute("SourceFile", "assets/medieval_stud_showcase/MedievalStudShowcase_" .. manifest.revision .. ".blend")
	root:SetAttribute("Reference", "User supplied medieval stud-style prop collection screenshot")
	root:SetAttribute("Revision", manifest.revision)
	root:SetAttribute("Triangles", manifest.triangles)
	local props = Instance.new("Folder")
	props.Name, props.Parent = "Props", root
	local groups = {}
	local function convert(v)
		return Vector3.new(v[1], v[3], -v[2])
	end
	for name, definition in manifest.props do
		local group = Instance.new("Model")
		group.Name = name
		group:SetAttribute("SourceProp", name)
		group.Parent = props
		groups[name] = group
		for index, definitionBox in definition.colliders do
			local collider = Instance.new("Part")
			collider.Name = "Collision" .. index
			local size = definitionBox.size
			collider.Size = Vector3.new(size[1], size[3], size[2])
			collider.CFrame = CFrame.new(origin + convert(definition.position))
				* CFrame.Angles(0, math.rad(definition.angle), 0)
				* CFrame.new(convert(definitionBox.center))
			collider.Transparency, collider.Anchored = 1, true
			collider.CanCollide, collider.CanTouch = true, false
			collider.TopSurface, collider.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			collider.Parent = group
		end
	end
	-- FBX import expands these unitless Blender exports 100x and reverses X/Z.
	local rotation = CFrame.Angles(0, math.pi, 0)
	for name, definition in manifest.meshes do
		local mesh = imported[name]:Clone()
		mesh.Name = definition.material
		mesh.Size /= 100
		mesh.CFrame = CFrame.new(origin) * rotation * (CFrame.new(mesh.Position / 100) * mesh.CFrame.Rotation)
		local rgb = manifest.palette[definition.material]
		mesh.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
		mesh.Material = Enum.Material.SmoothPlastic
		mesh.Anchored, mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = true, false, false, false
		mesh:SetAttribute("SourceMesh", name)
		mesh:SetAttribute("Triangles", definition.triangles)
		mesh.Parent = groups[definition.prop]
	end
	for name, group in groups do
		local definition = manifest.props[name]
		group.WorldPivot = CFrame.new(origin + convert(definition.position)) * CFrame.Angles(0, math.rad(definition.angle), 0)
	end
	local ground = Instance.new("Part")
	ground.Name = "StuddedDisplayGround"
	ground.Size = Vector3.new(76, 1, 38)
	ground.CFrame = CFrame.new(origin + Vector3.new(2, -.5, 1))
	ground.Color, ground.Material = Color3.fromRGB(70, 170, 112), Enum.Material.Plastic
	ground.TopSurface, ground.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth
	ground.Anchored, ground.CanTouch, ground.Parent = true, false, root
	root.WorldPivot = CFrame.new(origin)
	root.Parent = workspace
	game:GetService("Selection"):Set({})
	workspace.CurrentCamera.FieldOfView = 50
	workspace.CurrentCamera.CFrame = CFrame.lookAt(origin + Vector3.new(10, 21, 48), origin + Vector3.new(3, 3.8, -1))
	return {root = root:GetFullName(), props = manifest.propCount, meshes = count, triangles = manifest.triangles}
end
