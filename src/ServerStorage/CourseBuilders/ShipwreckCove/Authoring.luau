--!strict
local Authoring = {}

function Authoring.Organize(root: Instance)
	local pieces = root:FindFirstChild("EditablePlatforms")
	if not pieces then return end
	local labels = {S01="01_Docks", S02="02_Shipwreck", S03="03_Cliffs", S04="04_Cave", S05="05_PalmGrove", S04_Entry="04_Cave", S04_Shore="05_PalmGrove", H01="02_Cannons", H02="04_Waves", X01="Expert_WreckPiles", X02="Expert_CliffSpars"}
	for _, piece in pieces:GetDescendants() do
		if not piece:IsA("Model") then continue end
		local collider = piece.PrimaryPart
		local section = if collider then collider:GetAttribute("Section") else nil
		local label = labels[section] or "ConnectionsAndCheckpoints"
		local group = pieces:FindFirstChild(label)
		if not group then
			group = Instance.new("Folder"); group.Name = label; group.Parent = pieces
		end
		piece.Parent = group
	end
end

local function replaceRoot(source: Instance, className: string): Instance
	local target = Instance.new(className)
	target.Name = source.Name
	for name, value in source:GetAttributes() do target:SetAttribute(name, value) end
	for _, child in source:GetChildren() do child.Parent = target end
	target.Parent = source.Parent
	source:Destroy()
	return target
end

function Authoring.ToEditable(course: Model): Folder
	local root = replaceRoot(course, "Folder") :: Folder
	root:SetAttribute("EditablePiecesVersion", 1)
	local pieces = Instance.new("Folder")
	pieces.Name = "EditablePlatforms"
	pieces.Parent = root
	local decoration = root:FindFirstChild("Decoration") :: Folder
	local walking = (root:FindFirstChild("Obstacles") :: Folder):FindFirstChild("WalkingSurfaces") :: Folder
	for _, collider in walking:GetChildren() do
		if not collider:IsA("BasePart") then continue end
		local visual = decoration:FindFirstChild(collider.Name, true)
		if not visual or not visual:IsA("BasePart") then continue end
		local piece = Instance.new("Model")
		piece.Name = collider.Name
		piece:SetAttribute("EditingHint", "Move or delete this platform as one piece; Visual and Collision remain separate children.")
		piece.Parent = pieces
		visual:SetAttribute("AuthoringParent", "Decoration/" .. visual.Parent.Name)
		collider:SetAttribute("AuthoringParent", "Obstacles/WalkingSurfaces")
		visual.Parent = piece
		collider.Parent = piece
		collider.Locked = true
		piece.PrimaryPart = collider
		local markers = root:FindFirstChild("RouteMarkers")
		for _, marker in if markers then markers:GetChildren() else {} do
			if marker.Name == "RouteArrow_" .. piece.Name or marker.Name == "ExpertLanding_" .. piece.Name or marker.Name == "CliffLanding_" .. piece.Name then
				marker:SetAttribute("AuthoringParent", "RouteMarkers")
				marker.Parent = piece
			end
		end
	end
	-- Scenery folders do not select an entire island when clicking one rock.
	for _, group in decoration:GetChildren() do
		if group:IsA("Model") then
			local mode=group.ModelStreamingMode.Name
			local editableGroup=replaceRoot(group, "Folder")
			editableGroup:SetAttribute("AuthoringStreamingMode",mode)
		end
	end
	for _, section in decoration:GetChildren() do
		local groups: {[string]: Model} = {}
		for _, child in section:GetChildren() do
			local platformOwner = child:GetAttribute("PlatformOwner")
			local platform = if typeof(platformOwner)=="string" then pieces:FindFirstChild(platformOwner,true) else nil
			if platform then
				child:SetAttribute("AuthoringParent", "Decoration/" .. section.Name)
				child.Parent=platform
				continue
			end
			local name = child:GetAttribute("EditGroup")
			if typeof(name) ~= "string" then continue end
			local group = groups[name]
			if not group then
				group = Instance.new("Model")
				group.Name = name
				group.Parent = section
				groups[name] = group
			end
			child:SetAttribute("AuthoringParent", "Decoration/" .. section.Name)
			child.Parent = group
		end
	end
	Authoring.Organize(root)
	return root
end

function Authoring.ToRuntime(editable: Folder): Model
	assert(editable:GetAttribute("EditablePiecesVersion") == 1, "Unsupported Shipwreck authoring format")
	local model = replaceRoot(editable, "Model") :: Model
	for _, child in model:GetDescendants() do
		local path = child:GetAttribute("AuthoringParent")
		if typeof(path) ~= "string" then continue end
		local destination: Instance = model
		for segment in string.gmatch(path, "[^/]+") do
			local nextFolder = destination:FindFirstChild(segment)
			assert(nextFolder, "Missing authoring destination " .. path)
			destination = nextFolder
		end
		child.Parent = destination
		child:SetAttribute("AuthoringParent", nil)
	end
	local pieces = model:FindFirstChild("EditablePlatforms")
	if pieces then pieces:Destroy() end
	local decoration=model:FindFirstChild("Decoration")
	if decoration then
		for _,group in decoration:GetChildren() do
			local mode=group:GetAttribute("AuthoringStreamingMode")
			if typeof(mode)=="string" and group:IsA("Folder") then
				local runtimeGroup=replaceRoot(group,"Model") :: Model
				runtimeGroup.ModelStreamingMode=Enum.ModelStreamingMode[mode]
				runtimeGroup:SetAttribute("AuthoringStreamingMode",nil)
			end
		end
	end
	return model
end

return Authoring
