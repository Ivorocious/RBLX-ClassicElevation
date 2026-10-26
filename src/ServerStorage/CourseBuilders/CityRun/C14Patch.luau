--!strict
local Patch = {}

local function folder(parent, name)
    local result = Instance.new("Folder")
    result.Name, result.Parent = name, parent
    return result
end

local function nativePart(parent, name, position, size, color, transparency, collide)
    local part = Instance.new("Part")
    part.Name, part.Position, part.Size = name, position, size
    part.Color, part.Transparency = color, transparency
    part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, collide, false, collide
    part.CastShadow = transparency == 0
    part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function newCheckpointSign(signs, trigger)
    local model = Instance.new("Model")
    model.Name, model.Parent = "Checkpoint_07_Sign", signs
    model.WorldPivot = trigger.CFrame
    local link = Instance.new("ObjectValue")
    link.Name, link.Value, link.Parent = "CheckpointTrigger", trigger, model
    local blue, navy, at = Color3.fromRGB(48,149,255), Color3.fromRGB(28,67,106), trigger.Position-Vector3.new(0,trigger.Size.Y/2,0)
    for _, offset in {-5.82, 5.82} do
        for _, alongX in {true, false} do
            local p = nativePart(model, "FloorBorder", at + (if alongX then Vector3.new(0,.15,offset) else Vector3.new(offset,.15,0)),
                if alongX then Vector3.new(12,.12,.3) else Vector3.new(.3,.12,12), blue, 0, false)
            p.Material = Enum.Material.Neon
        end
    end
    local base = at + Vector3.new(4.6,0,-4.6)
    nativePart(model, "Post", base+Vector3.new(0,1.8,0), Vector3.new(.2,3.6,.2), navy, 0, false)
    local beacon = nativePart(model, "NumberedBeacon", base+Vector3.new(0,4.9,0), Vector3.new(2.3,2.8,2.3), navy, 0, false)
    nativePart(model, "BeaconCap", base+Vector3.new(0,6.4,0), Vector3.new(2.5,.14,2.5), blue, 0, false).Material = Enum.Material.Neon
    for _, face in {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right} do
        local gui = Instance.new("SurfaceGui")
        gui.Name, gui.Face, gui.CanvasSize, gui.Parent = "CheckpointLabel", face, Vector2.new(230,280), beacon
        local label = Instance.new("TextLabel")
        label.Name, label.Text, label.Size, label.BackgroundTransparency = "Number", "07", UDim2.fromScale(1,1), 1
        label.Font, label.TextScaled, label.TextColor3, label.Parent = Enum.Font.GothamBold, true, Color3.new(1,1,1), gui
    end
end

local function motionAxis(frame, attrs)
    local axes = {X=Vector3.xAxis,Y=Vector3.yAxis,Z=Vector3.zAxis}
    local wanted = assert(axes[attrs.WorldMotionAxis], "Missing world motion axis")
    local localAxis = frame:VectorToObjectSpace(wanted)
    local axisName, signed = "X", localAxis.X
    for _, name in {"Y", "Z"} do
        if math.abs(localAxis[name]) > math.abs(signed) then axisName, signed = name, localAxis[name] end
    end
    assert(math.abs(signed) > .999, "Motion mesh axis is not calibrated")
    local phase = attrs.MotionPhase or 0
    if signed < 0 and (attrs.KitMotion == "Slide" or attrs.KitMotion == "Swing") then phase = (phase+180)%360 end
    return axisName, phase
end

local function setMotion(part, attrs)
    for key, value in attrs do
        if key ~= "WorldMotionAxis" then part:SetAttribute(key, value) end
    end
    if not attrs.KitMotion then return end
    -- Slide phases compensate for FBX axes pointing opposite to world travel.
    local axisName, phase = motionAxis(part.CFrame, attrs)
    part:SetAttribute("MotionAxis", axisName)
    part:SetAttribute("MotionPhase", phase)
    part:SetAttribute("WorldMotionAxis", attrs.WorldMotionAxis)
end

function Patch.Apply(imported: Model)
    assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Intended place in Edit mode required")
    local course = workspace.Course_CityRun
    assert(course:GetAttribute("CityRunRevision") == "C13", "Inspect expected C13 course before C14")
    assert(not game.ServerStorage:FindFirstChild("CityRun_C14_Archive"), "C14 already started")
    assert(not course.Obstacles:FindFirstChild("C14Routes"), "C14 routes already exist")
    local manifest = script.Parent.C14Manifest:Clone()
    local data = require(manifest)
    manifest:Destroy()
    assert(string.match(data.revision, "^C14_"), "Wrong manifest")
    local walking = course.Obstacles.WalkingSurfaces
    for _, name in data.replacements do assert(walking:FindFirstChild(name), "Missing replaced route " .. name) end
    local signs = course.RouteMarkers.CheckpointSigns
    local expert = course.Checkpoints.Checkpoint_003.AlternateTriggers.ExpertRoute
    local landing = walking.C11CheckpointLandings.ExpertRoute
    assert(landing:IsA("BasePart") and landing.CanCollide, "Expert checkpoint pad missing")
    assert(course.Checkpoints:FindFirstChild("Checkpoint_007") and not course.Checkpoints:FindFirstChild("Checkpoint_008"))
    assert(signs:FindFirstChild("Checkpoint_07_Sign"))
    local markers, names, count, expected = {}, {}, 0, 0
    for _ in data.meshes do expected += 1 end
    for _, part in imported:GetDescendants() do
        assert(not part:IsA("LuaSourceContainer"), "Unexpected imported script")
        if not part:IsA("BasePart") then continue end
        assert(data.meshes[part.Name] and not names[part.Name], "Unexpected or duplicate C14 mesh " .. part.Name)
        names[part.Name], count = true, count+1
        for _, key in {"Origin","Right","Up","Forward"} do
            if string.find(part.Name,"Marker"..key.."__",1,true) then markers[key] = part end
        end
    end
    assert(count == expected, "Incomplete C14 asset")
    for _, key in {"Origin","Right","Up","Forward"} do assert(markers[key], "Missing calibration marker") end
    imported:ScaleTo(imported:GetScale()*10/(markers.Right.Position-markers.Origin.Position).Magnitude)
    local frame = CFrame.fromMatrix(markers.Origin.Position,
        (markers.Right.Position-markers.Origin.Position).Unit,
        (markers.Up.Position-markers.Origin.Position).Unit,
        (markers.Origin.Position-markers.Forward.Position).Unit)
    for _, part in imported:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        local definition = data.components[data.meshes[part.Name].component]
        if definition.attrs and definition.attrs.KitMotion then
            motionAxis(CFrame.new(3500,0,0)*frame:ToObjectSpace(part.CFrame),definition.attrs)
        end
    end
    local archive = folder(game.ServerStorage,"CityRun_C14_Archive")
    local oldRoutes, oldVisuals = folder(archive,"ReplacedRoutes"), folder(archive,"ReplacedVisuals")
    local scenery = folder(course.Decoration,"C14Scenery")
    local supports, parked = folder(scenery,"RetainedBuildingSupports"), folder(scenery,"ParkedTrains")
    local function preserve(object, destination)
        object:SetAttribute("C14OriginalPath",object:GetFullName())
        object.Parent = destination or oldVisuals
    end
    for _, name in data.replacements do
        local model = walking[name]
        local keepBodies = string.match(name,"^DistrictRoofs_") or string.match(name,"^RoofGarden_")
        local keepPier=string.match(name,"^RoofMainEntry_")
        local bodyModel
        for _, child in model:GetChildren() do
            if child:IsA("MeshPart") and ((keepPier and string.find(child.Name,"__Stone__",1,true)) or (keepBodies and (string.find(child.Name,"__Brick__",1,true)
                or string.find(child.Name,"__Plaster__",1,true) or string.find(child.Name,"__Glass__",1,true)))) then
                assert(not child.CanCollide, "Unexpected body collider")
                if not bodyModel then
                    bodyModel = Instance.new("Model")
                    bodyModel.Name, bodyModel.Parent = name, supports
                    bodyModel:SetAttribute("EditableUnit",true)
                end
                child.Parent = bodyModel
            elseif string.match(name,"^StationaryTrains_") and child:IsA("Model") and string.match(child.Name,"^Depot_Parked") then
                child:SetAttribute("C14OriginalPath",child:GetFullName())
                child.Parent = parked
                child:PivotTo(child:GetPivot()+Vector3.new(0,-1.2,0))
                child:SetAttribute("C14LoweredBy",1.2)
            end
        end
        if bodyModel then bodyModel.WorldPivot = model:GetPivot() end
        preserve(model,oldRoutes)
    end
    local replaced = {}
    for _, name in data.replacements do replaced[name] = true end
    for _, model in course.Obstacles.C10Obstacles:GetChildren() do
        local matches = false
        for name in replaced do if string.find(model.Name,name,1,true) then matches = true break end end
        if matches then preserve(model) end
    end
    preserve(course.Decoration.RenovationCourtyardHouse)
    for _, object in course.Decoration.C13Terminal:GetDescendants() do
        if object:IsA("Model") and string.match(object.Name,"^C13_DepotCanopy") then preserve(object) end
    end
    local walls = course.OwnerEdits:FindFirstChild("C11InvisibleWalls")
    if walls and walls:FindFirstChild("CrossingWestFacade") then preserve(walls.CrossingWestFacade) end
    local legacyWall=workspace:FindFirstChild("DepotEast")
    if legacyWall and legacyWall:GetAttribute("InvisibleBoundary")==true then preserve(legacyWall) end
    local corner = course.Decoration.C10Streets:FindFirstChild("CityC10_Depot_CrossingCorner")
    local clearedCorner = 0
    if corner then
        clearedCorner = #corner:GetDescendants()
        preserve(corner)
    end
    local routes, groups, sections = folder(course.Obstacles,"C14Routes"), {}, {}
    for name, definition in data.components do
        if definition.section == "Calibration" then continue end
        if not sections[definition.section] then sections[definition.section] = folder(routes,definition.section) end
        local model = Instance.new("Model")
        model.Name, model.Parent = name, sections[definition.section]
        model:SetAttribute("EditableUnit",true)
        model:SetAttribute("Section",definition.section)
        model:SetAttribute("C14Role",definition.role)
        groups[name] = model
        if definition.role == "Surface" or definition.role == "Solid" then
            local pos, size = definition.position, definition.size
            local collider = nativePart(model,"Collider",Vector3.new(pos[1],pos[2],pos[3]),Vector3.new(size[1],size[2],size[3]),Color3.new(),1,true)
            collider:SetAttribute("Section",definition.section)
            collider:SetAttribute("C14Role",definition.role)
        end
    end
    for _, part in imported:GetDescendants() do
        if not part:IsA("BasePart") then continue end
        local mesh = data.meshes[part.Name]
        local definition, color = data.components[mesh.component], data.colors[mesh.material]
        part.CFrame = CFrame.new(3500,0,0)*frame:ToObjectSpace(part.CFrame)
        part.Color = Color3.new(color[1],color[2],color[3])
        part.Material = if mesh.material == "Danger" then Enum.Material.Neon
            elseif mesh.material == "Brick" or mesh.material == "Terracotta" then Enum.Material.Brick
            elseif mesh.material == "Roof" then Enum.Material.Asphalt
            elseif mesh.material == "Iron" or mesh.material == "Ink" or mesh.material == "Copper" then Enum.Material.Metal
            elseif mesh.material == "Plaster" or mesh.material == "Stone" or mesh.material == "Pale" then Enum.Material.Concrete
            else Enum.Material.SmoothPlastic
        part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true,false,false,false
        if part:IsA("MeshPart") then part.TextureID = ""; part.DoubleSided = true end
        part:SetAttribute("SourceTriangles",mesh.triangles)
        part.Parent = groups[mesh.component] or oldVisuals
        if definition.role == "Hazard" then
            if definition.position and definition.size then
                part.CFrame=CFrame.new(unpack(definition.position))
                part.Size=Vector3.new(unpack(definition.size))
            end
            part.CanTouch, part.CanQuery = true,true
            setMotion(part,definition.attrs)
        end
    end
    for _, model in groups do model.WorldPivot = model:GetBoundingBox() end
    local savedCheckpoints = folder(archive,"PreviousCheckpoints")
    expert:Clone().Parent = savedCheckpoints
    expert.CFrame = landing.CFrame*CFrame.new(0,landing.Size.Y/2+.5,0)
    expert.Size = Vector3.new(landing.Size.X,1,landing.Size.Z)
    expert.Anchored, expert.CanCollide, expert.CanTouch, expert.Transparency = true,false,true,1
    local oldLast = course.Checkpoints.Checkpoint_007
    oldLast:Clone().Parent = savedCheckpoints
    oldLast.Name = "Checkpoint_008"
    local oldSign = signs.Checkpoint_07_Sign
    oldSign:Clone().Parent = savedCheckpoints
    oldSign.Name = "Checkpoint_08_Sign"
    for _, label in oldSign:GetDescendants() do
        if label:IsA("TextLabel") and label.Name == "Number" then label.Text = "08" end
    end
    local cp = nativePart(course.Checkpoints,"Checkpoint_007",Vector3.new(3665,82.5,-90),Vector3.new(12,1,12),Color3.fromRGB(48,149,255),1,false)
    cp.CanTouch, cp.CanQuery = true,true
    cp:SetAttribute("PlanningId","C14DepotCheckpoint")
    newCheckpointSign(signs,cp)
    course.CourseInfo:SetAttribute("CheckpointCount",8)
    local fade = Instance.new("Model")
    fade.Name, fade.Parent = "ActiveTrainFloorFade", scenery
    fade.WorldPivot = CFrame.new(3545,58,-12)
    fade:SetAttribute("EditableUnit",true)
    fade:SetAttribute("FadeDirection","Clear top to opaque bottom")
    for index = 1, 12 do
        local fraction = (index-1)/11
        local p = nativePart(fade,string.format("Layer_%02d",index),Vector3.new(3545,58-44*fraction,-12),Vector3.new(350,.05,72),Color3.fromRGB(100,128,151),1-fraction*fraction,false)
        p.CastShadow, p.Material = false,Enum.Material.SmoothPlastic
    end
    imported.Parent = archive
    course:SetAttribute("C14CheckpointMigration",true)
    course:SetAttribute("ReviewBuildId",data.revision)
    course:SetAttribute("CityRunRevision","C14")
    course:SetAttribute("VisualReviewPassed",false)
    for _, key in {"GroundingScore","ReadabilityScore","VariationScore","CompositionScore","RewardScore"} do course:SetAttribute(key,nil) end
    return {build=data.revision,meshes=count-4,archivedRoutes=#data.replacements,archivedCornerDescendants=clearedCorner,
        checkpointCount=8,fadeLayers=12,descendants=#course:GetDescendants()}
end
return Patch
