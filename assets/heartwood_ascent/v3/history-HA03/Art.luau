--!strict
local Config = require(game.ReplicatedStorage.Config.HeartwoodConfig)
local Manifest = require(script.Parent.ArtManifest)
local Art = {}

local meshRotation = CFrame.Angles(0, math.pi, 0)
local sectionNames = {"S01_AncientRoots", "S02_LivingHeartwood", "S03_HangingGardens", "S04_SanctuaryBough"}
local boughOffsets = {
    Vector3.new(0, -16, 0), Vector3.new(0, -12, 0), Vector3.new(0, -16, 0), Vector3.new(-18, -12, 0),
    Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero,
}

type Surface = {model: Model, prototype: BasePart, section: string, frame: CFrame, size: Vector3}
type Greenery = {point: Vector3, size: Vector3}
type FamilyGreenery = {family: number, point: Vector3, size: Vector3}
type ScenicBough = {asset: string, root: Vector3, yaw: number, scale: Vector3}

local function child(parent: Instance, name: string): Instance
    return assert(parent:FindFirstChild(name), parent:GetFullName() .. " is missing " .. name)
end

local function modelChild(parent: Instance, name: string): Model
    local result = child(parent, name)
    assert(result:IsA("Model"), name .. " must be a Model")
    return result
end

local function partChild(parent: Instance, name: string): BasePart
    local result = child(parent, name)
    assert(result:IsA("BasePart"), name .. " must be a BasePart")
    return result
end

local function group(parent: Instance, name: string, className: string?): Instance
    local result = Instance.new(className or "Folder")
    result.Name = name
    result.Parent = parent
    return result
end

local function disablePrototype(part: BasePart, name: string)
    part.Name = name
    part.Transparency = 1
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part:SetAttribute("ArtPrototype", true)
end

function Art.Assemble(course: Model, library: Folder): number
    local decoration = child(course, "Decoration")
    assert(not decoration:FindFirstChild("HeartwoodArt"), "Preserve the existing assembled art")
    local art = group(decoration, "HeartwoodArt")
    art:SetAttribute("AssetLibrary", library.Name)
    art:SetAttribute("RouteCoordinates", "HA02")
    local triangles = 0

    local function clone(name: string, parent: Instance, frame: CFrame, scale: Vector3?, collide: boolean?): MeshPart
        local metadata = assert(Manifest[name], "Missing Heartwood art metadata: " .. name)
        local source = child(library, name)
        assert(source:IsA("MeshPart"), name .. " must be a MeshPart")
        local mesh = source:Clone() :: MeshPart
        local sizeScale = scale or Vector3.one
        mesh.Size = metadata.size * sizeScale
        mesh.CFrame = frame * CFrame.new(metadata.center * sizeScale) * meshRotation
        mesh.PivotOffset = CFrame.identity
        mesh.Anchored = true
        mesh.CanCollide = collide == true
        mesh.CanTouch = false
        mesh.CanQuery = collide == true
        mesh.Color = Color3.new(1, 1, 1)
        if metadata.package == "structure" or metadata.package == "pod" then
            mesh.CustomPhysicalProperties = mesh.CurrentPhysicalProperties
            mesh.Material = Enum.Material.Wood
        elseif metadata.package == "foliage" then
            mesh.CustomPhysicalProperties = mesh.CurrentPhysicalProperties
            mesh.Material = Enum.Material.Grass
        else
            mesh.Material = Enum.Material.SmoothPlastic
        end
        mesh:SetAttribute("ArtAsset", name)
        mesh:SetAttribute("ArtTriangles", metadata.triangles)
        mesh.Parent = parent
        triangles += metadata.triangles
        return mesh
    end

    local function centered(name: string, parent: Instance, frame: CFrame, size: Vector3, collide: boolean?): MeshPart
        local metadata = Manifest[name]
        local scale = size / metadata.size
        return clone(name, parent, frame * CFrame.new(-metadata.center * scale), scale, collide)
    end

    local function foliage(name: string, parent: Instance, point: Vector3, size: Vector3, yaw: number?): MeshPart
        return centered(name, parent, CFrame.new(Config.Origin + point) * CFrame.Angles(0, yaw or 0, 0), size)
    end

    local trunk = group(art, "HollowTrunk")
    local sectors: {[string]: Model} = {}
    for name, metadata in Manifest do
        local sectorId = string.match(name, "^HA_Hollow_(%d%d)_%d%d$")
        if sectorId then
            local sector = sectors[sectorId]
            if not sector then
                sector = group(trunk, "ShellSector_" .. sectorId, "Model") :: Model
                sector:SetAttribute("SectorId", sectorId)
                sectors[sectorId] = sector
            end
            local offset = if name == "HA_Hollow_05_00" then Vector3.new(0, -20, 0)
                elseif name == "HA_Hollow_05_01" or name == "HA_Hollow_06_01" or name == "HA_Hollow_07_01" then Vector3.new(0, 8, 0)
                else Vector3.zero
            local nearRoute = metadata.center.Y - metadata.size.Y / 2 + offset.Y <= 195
            local mesh = clone(name, sector, CFrame.new(Config.Origin + offset), nil, nearRoute)
            mesh:SetAttribute("AssemblyOffset", offset)
            mesh:SetAttribute("CollisionUse", if nearRoute then "Hollow wall" else "Upper scenery")
            if not sector.PrimaryPart then sector.PrimaryPart = mesh end
        end
    end

    local roots = group(art, "ButtressRoots")
    local rootOffset = Vector3.new(0, -45, 0)
    for index = 0, 8 do
        local name = string.format("HA_Buttress_%02d", index)
        local unit = group(roots, string.format("Buttress_%02d", index), "Model") :: Model
        local mesh = clone(name, unit, CFrame.new(Config.Origin + rootOffset), nil, true)
        mesh:SetAttribute("AssemblyOffset", rootOffset)
        mesh:SetAttribute("CollisionUse", "Root solid")
        unit.PrimaryPart = mesh
        unit:SetAttribute("AssemblyOffset", rootOffset)
    end

    local branches = group(art, "BranchFamilies")
    local families: {Model} = {}
    for index = 0, 7 do
        local unit = group(branches, string.format("BoughFamily_%02d", index), "Model") :: Model
        local offset = boughOffsets[index + 1]
        local mesh = clone(string.format("HA_Bough_%02d", index), unit, CFrame.new(Config.Origin + offset), nil, index < 4)
        mesh:SetAttribute("AssemblyOffset", offset)
        mesh:SetAttribute("CollisionUse", if index < 4 then "Lower bough solid" else "Upper scenery")
        unit.PrimaryPart = mesh
        unit:SetAttribute("FamilyId", index)
        unit:SetAttribute("AssemblyOffset", offset)
        unit:SetAttribute("EditableUnit", true)
        table.insert(families, unit)
    end

    local scenicBoughs: {ScenicBough} = {
        {asset = "HA_Bough_04", root = Vector3.new(54.4, 205, 8.2), yaw = -.15, scale = Vector3.new(.65, .70, .65)},
        {asset = "HA_Bough_04", root = Vector3.new(-38.7, 211, 39.1), yaw = -2.35, scale = Vector3.new(.70, .75, .70)},
        {asset = "HA_Bough_04", root = Vector3.new(-27, 218, -47.9), yaw = -4.20, scale = Vector3.new(.60, .65, .60)},
        {asset = "HA_Bough_05", root = Vector3.new(23.1, 246, 45.5), yaw = math.pi - 1.10, scale = Vector3.new(.65, .70, .65)},
        {asset = "HA_Bough_05", root = Vector3.new(-50.7, 252, -5.5), yaw = math.pi - 3.25, scale = Vector3.new(.75, .75, .75)},
        {asset = "HA_Bough_05", root = Vector3.new(32.4, 263, -39.4), yaw = math.pi - 5.40, scale = Vector3.new(.60, .65, .60)},
    }
    local sourceRoots: {[string]: Vector3} = {HA_Bough_04 = Vector3.new(38, 226, -32), HA_Bough_05 = Vector3.new(-28, 268, 21)}
    local sourceCrowns: {[string]: {Vector3}} = {
        HA_Bough_04 = {Vector3.new(147, 291, -46), Vector3.new(195, 310, -32)},
        HA_Bough_05 = {Vector3.new(-132, 329, 55), Vector3.new(-185, 343, 27)},
    }
    local middleStart = triangles
    local lowestScenery = math.huge
    for index, data in scenicBoughs do
        local unit = group(branches, string.format("BoughFamily_%02d", index + 7), "Model") :: Model
        local sourceRoot = sourceRoots[data.asset]
        local frame = CFrame.new(Config.Origin + data.root) * CFrame.Angles(0, data.yaw, 0)
            * CFrame.new(-sourceRoot * data.scale)
        local mesh = clone(data.asset, unit, frame, data.scale)
        local metadata = Manifest[data.asset]
        local lowest = data.root.Y + (metadata.center.Y - metadata.size.Y / 2 - sourceRoot.Y) * data.scale.Y
        local highest = data.root.Y + (metadata.center.Y + metadata.size.Y / 2 - sourceRoot.Y) * data.scale.Y
        lowestScenery = math.min(lowestScenery, lowest)
        assert(lowest >= 191.2, "Keep added branches above the tested flight space")
        mesh:SetAttribute("Scenery", true)
        mesh:SetAttribute("RouteSurface", nil)
        mesh:SetAttribute("CollisionUse", "Upper scenery")
        mesh:SetAttribute("LowestLocalY", lowest)
        mesh:SetAttribute("HighestLocalY", highest)
        unit.PrimaryPart = mesh
        unit:SetAttribute("FamilyId", index + 7)
        unit:SetAttribute("AssemblyRoot", data.root)
        unit:SetAttribute("Scenery", true)
        unit:SetAttribute("EditableUnit", true)
        for crownIndex, sourcePoint in sourceCrowns[data.asset] do
            local position = frame * (sourcePoint * data.scale) + Vector3.new(0, if crownIndex == 1 then 8 else 7, 0)
            local size = if crownIndex == 1 then Vector3.new(62, 30, 56) else Vector3.new(57, 27, 52)
            local greenery = centered(if crownIndex == 1 then "HA_FoliageMassA" else "HA_FoliageMassB", unit,
                CFrame.new(position) * CFrame.Angles(0, data.yaw + crownIndex * .3, 0), size)
            greenery.Name = "AttachedCanopy_" .. crownIndex
            greenery:SetAttribute("Scenery", true)
            greenery:SetAttribute("RouteSurface", nil)
        end
    end
    art:SetAttribute("AddedBranchTriangles", triangles - middleStart)
    art:SetAttribute("AddedBranchMinY", lowestScenery)

    local relief = group(art, "UpperBarkRelief", "Model") :: Model
    local reliefStart = triangles
    local lowestRelief = math.huge
    for index, angle in {.25, 2.55, 4.60} do
        local points = {
            Vector3.new(math.cos(angle) * 63, 200, math.sin(angle) * 63),
            Vector3.new(math.cos(angle + .08) * 54, 244, math.sin(angle + .08) * 54),
            Vector3.new(math.cos(angle - .035) * 46, 286, math.sin(angle - .035) * 46),
        }
        for segment = 1, 2 do
            local a, b = points[segment], points[segment + 1]
            local midpoint = (a + b) / 2
            local frame = CFrame.lookAt(Config.Origin + midpoint, Config.Origin + b)
            local size = Vector3.new(8, 6, (b - a).Magnitude + 3)
            local extentY = (math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y
                + math.abs(frame.LookVector.Y) * size.Z) / 2
            local lowest = midpoint.Y - extentY
            assert(lowest > 195, "Keep bark relief above the tested flight space")
            lowestRelief = math.min(lowestRelief, lowest)
            local root = centered("HA_RootSpan", relief, frame, size, true)
            root.Name = string.format("BarkRib_%d_%d", index, segment)
            root:SetAttribute("LocalStart", a)
            root:SetAttribute("LocalEnd", b)
            root:SetAttribute("LowestLocalY", lowest)
            root:SetAttribute("Scenery", true)
            root:SetAttribute("RouteSurface", nil)
            root:SetAttribute("CollisionUse", "Upper bark relief")
            if not relief.PrimaryPart then relief.PrimaryPart = root end
        end
    end
    art:SetAttribute("AddedReliefTriangles", triangles - reliefStart)
    art:SetAttribute("AddedReliefMinY", lowestRelief)

    local surfaces: {Surface} = {}
    for _, sectionName in sectionNames do
        local section = child(decoration, sectionName)
        for _, model in section:GetChildren() do
            local top = model:FindFirstChild("Top")
            if model:IsA("Model") and top and top:IsA("BasePart") then
                table.insert(surfaces, {model = model, prototype = top, section = sectionName,
                    frame = top.CFrame * CFrame.new(0, .6, 0), size = top.Size})
            end
        end
    end

    local supports = group(art, "ShelfSupports")
    local margins = group(art, "RouteGreenery")
    for index, surface in surfaces do
        local model = surface.model
        local tip = string.match(model.Name, "^X01_") ~= nil
        local depth = if tip then 3.5 else 6.5
        local name = if tip then "HA_ShelfTip" else "HA_ShelfWide"
        local mesh = centered(name, model, surface.frame * CFrame.new(0, -depth / 2, 0),
            Vector3.new(surface.size.X, depth, surface.size.Z), true)
        disablePrototype(surface.prototype, "TopPrototype")
        mesh.Name = "Top"
        mesh:SetAttribute("RouteSurface", true)
        mesh:SetAttribute("SurfaceTopCFrame", surface.frame)
        mesh:SetAttribute("CollisionUse", "Visible fitted shelf")
        model.PrimaryPart = mesh
        model:SetAttribute("MeshSurface", true)
        local body = model:FindFirstChild("SupportedBark")
        if body and body:IsA("BasePart") then disablePrototype(body, "SupportedBark") end

        if not tip and model.Name ~= "PulseRefuge" and model.Name ~= "J1" and model.Name ~= "J3" then
            local rootsSection = surface.section == "S01_AncientRoots"
            local supportDepth = if rootsSection then 18
                elseif surface.section == "S02_LivingHeartwood" then 15
                elseif surface.section == "S03_HangingGardens" then 20 else 18
            local supportWidth = if rootsSection then surface.size.X * .40 else math.min(4.5, surface.size.X * .25)
            local supportLength = if rootsSection then surface.size.Z * .40 else math.min(5, surface.size.Z * .25)
            local support = centered("HA_ShelfTip", supports,
                surface.frame * CFrame.new(0, -depth + .15 - supportDepth / 2, 0),
                Vector3.new(supportWidth, supportDepth, supportLength), true)
            support.Name = model.Name .. "_OrganicStem"
            support:SetAttribute("StationId", model.Name)
            support:SetAttribute("CollisionUse", "Narrow shelf underside")
        end

        if not tip and model.Name ~= "J1" and model.Name ~= "J2" and model.Name ~= "PulseRefuge" then
            for side = -1, 1, 2 do
                local scale = if surface.section == "S01_AncientRoots" then 1 else .8
                local position = surface.frame * Vector3.new(side * (surface.size.X / 2 + 3.8 * scale), -2.6 * scale, surface.size.Z * .12)
                local frame = CFrame.new(position) * surface.frame.Rotation * CFrame.Angles(0, index * .53 + side, 0)
                local greenery = centered(if (index + side) % 3 == 0 then "HA_HangingMass" else "HA_FoliageMassA", margins,
                    frame, Vector3.new(9.2 * scale, 5.6 * scale, 9.6 * scale))
                greenery.Name = model.Name .. (if side < 0 then "_LeftGreenery" else "_RightGreenery")
                greenery:SetAttribute("StationId", model.Name)
            end
            if index % 3 == 0 and model.Name ~= "F0" then
                local fern = clone("HA_Fern", margins,
                    surface.frame * CFrame.new(surface.size.X / 2 + 1.3, -1, -surface.size.Z * .25), Vector3.new(.48, .48, .48))
                fern.Name = model.Name .. "_Fern"
            end
        end
    end

    for _, sectionName in sectionNames do
        for _, prototype in child(decoration, sectionName):GetDescendants() do
            if prototype:IsA("BasePart") and (prototype.Name == "PulseLane" or prototype.Name == "RefugeConnection"
                or prototype.Name == "MainBloomApproach" or prototype.Name == "HardBloomApproach"
                or string.match(prototype.Name, "^CatchReturn_%d+$") or string.match(prototype.Name, "^FinishWalk_%d+$")) then
                local name = prototype.Name
                local frame = prototype.CFrame * CFrame.new(0, .7, 0)
                local mesh = centered("HA_RootSpan", prototype.Parent :: Instance, frame * CFrame.new(0, -3.45, 0),
                    Vector3.new(prototype.Size.X, 6.9, prototype.Size.Z), true)
                disablePrototype(prototype, name .. "Prototype")
                mesh.Name = name
                mesh:SetAttribute("RouteSurface", true)
                mesh:SetAttribute("SurfaceTopCFrame", frame)
                mesh:SetAttribute("CollisionUse", "Visible fitted root walk")
            end
        end
    end

    local lowerGreenery: {FamilyGreenery} = {
        {family = 1, point = Vector3.new(-143, 149, 15), size = Vector3.new(25, 11, 24)},
        {family = 1, point = Vector3.new(-123, 148, 10), size = Vector3.new(20, 9, 18)},
        {family = 2, point = Vector3.new(106, 59, 28), size = Vector3.new(23, 11, 22)},
        {family = 2, point = Vector3.new(87, 54, -45), size = Vector3.new(25, 12, 23)},
        {family = 3, point = Vector3.new(34, 65, 111), size = Vector3.new(27, 12, 26)},
        {family = 3, point = Vector3.new(69, 66, 114), size = Vector3.new(26, 12, 20)},
        {family = 4, point = Vector3.new(-140, 110, 79), size = Vector3.new(28, 14, 25)},
        {family = 4, point = Vector3.new(-122, 109, 123), size = Vector3.new(27, 12, 24)},
        {family = 4, point = Vector3.new(-86, 101, 122), size = Vector3.new(23, 12, 22)},
    }
    for index, data in lowerGreenery do
        local mesh = foliage(if index % 2 == 0 then "HA_HangingMass" else "HA_FoliageMassB", families[data.family], data.point, data.size, index * .61)
        mesh.Name = "JoinedGreenery_" .. index
    end

    local backdrop = group(art, "RouteBackdrops")
    local backdrops: {Greenery} = {
        {point = Vector3.new(-209, 5, 91), size = Vector3.new(25, 15, 26)},
        {point = Vector3.new(-166, 16, 46), size = Vector3.new(22, 13, 24)},
        {point = Vector3.new(-71, 29, -30), size = Vector3.new(20, 17, 19)},
        {point = Vector3.new(-53, 41, -54), size = Vector3.new(21, 17, 19)},
        {point = Vector3.new(64, 63.8, -67), size = Vector3.new(18, 8, 14)},
        {point = Vector3.new(114, 91, -40), size = Vector3.new(23, 18, 21)},
        {point = Vector3.new(122, 94, 16), size = Vector3.new(25, 16, 23)},
        {point = Vector3.new(110, 101, 76), size = Vector3.new(25, 17, 23)},
        {point = Vector3.new(68, 109, 124), size = Vector3.new(25, 18, 22)},
        {point = Vector3.new(15, 113, 142), size = Vector3.new(25, 17, 23)},
        {point = Vector3.new(-132, 148, 118), size = Vector3.new(23, 17, 21)},
        {point = Vector3.new(-143, 150, 68), size = Vector3.new(25, 17, 23)},
        {point = Vector3.new(-115, 151, 29), size = Vector3.new(18, 12, 18)},
    }
    for index, data in backdrops do
        local mesh = foliage(if index % 3 == 0 then "HA_HangingMass" else "HA_FoliageMassB", backdrop, data.point, data.size, index * .77)
        mesh.Name = "Backdrop_" .. index
        mesh:SetAttribute("SightlineRole", "Behind route target")
    end
    local refugeGreenery = foliage("HA_HangingMass", margins, Vector3.new(12, 60.8, -40), Vector3.new(10, 5, 9), .65)
    refugeGreenery.Name = "PulseRefuge_LowerGreenery"
    refugeGreenery:SetAttribute("StationId", "PulseRefuge")

    local crown: {FamilyGreenery} = {
        {family = 5, point = Vector3.new(88, 278, -47), size = Vector3.new(74, 32, 66)},
        {family = 5, point = Vector3.new(144, 306, -43), size = Vector3.new(84, 35, 74)},
        {family = 5, point = Vector3.new(187, 318, -32), size = Vector3.new(56, 29, 51)},
        {family = 6, point = Vector3.new(-78, 316, 49), size = Vector3.new(84, 36, 79)},
        {family = 6, point = Vector3.new(-129, 340, 52), size = Vector3.new(98, 42, 84)},
        {family = 6, point = Vector3.new(-176, 351, 29), size = Vector3.new(76, 35, 80)},
        {family = 7, point = Vector3.new(62, 393, -20), size = Vector3.new(76, 37, 71)},
        {family = 7, point = Vector3.new(113, 419, -8), size = Vector3.new(81, 35, 75)},
        {family = 8, point = Vector3.new(-46, 432, 34), size = Vector3.new(79, 39, 75)},
        {family = 8, point = Vector3.new(-90, 455, 29), size = Vector3.new(78, 34, 74)},
        {family = 8, point = Vector3.new(0, 458, -5), size = Vector3.new(113, 48, 108)},
        {family = 8, point = Vector3.new(-32, 448, 29), size = Vector3.new(80, 38, 76)},
        {family = 7, point = Vector3.new(36, 444, -29), size = Vector3.new(83, 37, 82)},
    }
    for index, data in crown do
        local mesh = foliage(if index % 2 == 0 then "HA_FoliageMassB" else "HA_FoliageMassA", families[data.family], data.point, data.size, index * .43)
        mesh.Name = "CrownMass_" .. index
    end

    local s4 = child(decoration, "S04_SanctuaryBough")
    for _, flower in child(s4, "Blooms"):GetChildren() do
        local center = partChild(flower, "Center")
        local radius = center:GetAttribute("BloomRadius") :: number
        local small = radius <= 3
        local ratio = radius / (if small then 3 else 11)
        local point = flower:GetAttribute("LocalTop") :: Vector3
        local mesh = clone(if small then "HA_BloomSmall" else "HA_BloomBroad", flower,
            CFrame.new(Config.Origin + point), Vector3.new(ratio, ratio, ratio), true)
        mesh.Name = "FlowerSurface"
        mesh:SetAttribute("CollisionUse", "Visible static flower and petals")
        center.Transparency = 1
        partChild(flower, "Rim").Transparency = 1
        for _, prototype in flower:GetChildren() do
            if prototype:IsA("BasePart") and string.match(prototype.Name, "^Petal_%d+$") then
                disablePrototype(prototype, prototype.Name)
            end
        end
    end
    local finish = modelChild(s4, "F0")
    local finishPoint = finish:GetAttribute("LocalTop") :: Vector3
    local incoming = Vector3.new(-92, 162, 34) - finishPoint
    local sanctuaryYaw = .4 - math.atan2(incoming.Z, incoming.X)
    local sanctuary = clone("HA_Sanctuary", finish,
        CFrame.new(Config.Origin + finishPoint) * CFrame.Angles(0, sanctuaryYaw, 0), nil, true)
    sanctuary.Name = "SanctuaryArtwork"
    sanctuary:SetAttribute("EntranceYaw", sanctuaryYaw)
    sanctuary:SetAttribute("CollisionUse", "Visible static sanctuary and petals")

    local s3 = child(decoration, "S03_HangingGardens")
    local leafCollision = child(library, "HA_LeafCollisionChecked")
    assert(leafCollision:IsA("MeshPart"), "Leaf collision template must be a MeshPart")
    for _, leaf in child(s3, "Leaves"):GetChildren() do
        assert(leaf:IsA("Model"), "Leaf must be a Model")
        local surface = partChild(leaf, "Surface")
        local scale = Vector3.new(surface.Size.Z / 12, .45, 1)
        local mesh = clone("HA_FoldingLeaf", leaf,
            surface.CFrame * CFrame.new(0, .55, 0) * CFrame.Angles(0, math.pi / 2, 0), scale)
        mesh:ApplyMesh(leafCollision)
        mesh.CanCollide = true
        mesh.CanQuery = true
        disablePrototype(surface, "SurfacePrototype")
        disablePrototype(partChild(leaf, "Midrib"), "Midrib")
        mesh.Name = "Surface"
        mesh:SetAttribute("RouteSurface", true)
        leaf.PrimaryPart = mesh
        leaf:SetAttribute("MeshSurface", true)
        leaf:SetAttribute("Span", mesh.Size.X)
        leaf:SetAttribute("OpenCFrame", mesh.CFrame)
        local vein = Instance.new("Part")
        vein.Name = "WarningVein"
        vein.Anchored = true
        vein.CanCollide = false
        vein.CanTouch = false
        vein.CanQuery = false
        vein.Size = Vector3.new(mesh.Size.X * .75, .1, .18)
        vein.Material = Enum.Material.Neon
        vein.Color = Color3.fromRGB(255, 206, 88)
        vein.Transparency = 1
        vein.CFrame = mesh.CFrame * CFrame.new(0, mesh.Size.Y / 2 + .05, 0)
        vein.Parent = leaf
    end

    local hazards = child(decoration, "HeartwoodHazards")
    for index = 1, 2 do
        local pod = child(hazards, "Pod_" .. index)
        local prototype = partChild(pod, "Pod")
        local mesh = centered("HA_Seedpod", pod, CFrame.new(prototype.Position + Vector3.new(0, .1, 0)), Manifest.HA_Seedpod.size)
        mesh.Name = "PodArtwork"
        prototype.Transparency = 1
    end

    local socketPoint = Config.Origin + Vector3.new(49, 83.5, -49)
    local socketFrame = CFrame.lookAt(socketPoint, Config.Origin + Vector3.new(26, 60, -20))
    local socket = clone("HA_HeartwoodSocket", art, socketFrame, nil, true)
    socket.Name = "HeartwoodSocket"
    socket:SetAttribute("CollisionUse", "Embedded heartwood bark")
    local socketRoots = group(art, "HeartwoodConnection", "Model") :: Model
    local connection = {
        Vector3.new(51.5, 87.5, -53), Vector3.new(56.5, 93, -57),
        Vector3.new(59, 101, -59), Vector3.new(59, 111, -56),
    }
    for index = 1, #connection - 1 do
        local a, b = connection[index], connection[index + 1]
        local frame = CFrame.lookAt(Config.Origin + (a + b) / 2, Config.Origin + b)
        local root = centered("HA_RootSpan", socketRoots, frame, Vector3.new(8 - index * .5, 7, (b - a).Magnitude + 2.8), true)
        root.Name = "SocketRoot_" .. index
        root:SetAttribute("LocalStart", a)
        root:SetAttribute("LocalEnd", b)
        root:SetAttribute("CollisionUse", "Joined heartwood root")
        if index == 1 then socketRoots.PrimaryPart = root end
    end
    local knot = partChild(hazards, "HeartKnot")
    knot.Size = Vector3.new(3.4, 6.3, 1.4)
    knot.CFrame = socketFrame * CFrame.new(0, 0, -.75)
    knot:SetAttribute("EmbeddedSocket", true)

    course:SetAttribute("ArtTriangles", triangles)
    course:SetAttribute("ArtVersion", Config.BuildId)
    course:SetAttribute("Study", false)
    return triangles
end

return Art
