--!strict
local Config = require(game.ReplicatedStorage.Config.HeartwoodConfig)
local Manifest = require(script.Parent.ArtManifest)
local Art = {}

local meshRotation = CFrame.Angles(0, math.pi, 0)
local sectionNames = {"S01_AncientRoots", "S02_LivingHeartwood", "S03_HangingGardens", "S04_SanctuaryBough"}
local shelfVariants = {"HA_ShelfWide", "HA_ShelfWideB", "HA_ShelfWideC"}
local foliageAssets: {[string]: boolean} = {HA_FoliageMassA = true, HA_FoliageMassB = true, HA_HangingMass = true}
local boughOffsets = {
    Vector3.new(0, -16, 0), Vector3.new(0, -12, 0), Vector3.new(0, -16, 0), Vector3.new(-18, -12, 0),
    Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero,
}

type Surface = {model: Model, prototype: BasePart, section: string, sectionIndex: number, frame: CFrame, size: Vector3}
type FamilyGreenery = {family: number, point: Vector3, size: Vector3}
type ScenicBough = {asset: string, root: Vector3, yaw: number, scale: Vector3}
type ForestTree = {asset: string, point: Vector2, yaw: number, scale: Vector3, layer: string}

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

local function partBounds(part: BasePart): (Vector3, Vector3)
    local frame, size = part.CFrame, part.Size
    local extent = Vector3.new(
        math.abs(frame.RightVector.X) * size.X + math.abs(frame.UpVector.X) * size.Y + math.abs(frame.LookVector.X) * size.Z,
        math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y + math.abs(frame.LookVector.Y) * size.Z,
        math.abs(frame.RightVector.Z) * size.X + math.abs(frame.UpVector.Z) * size.Y + math.abs(frame.LookVector.Z) * size.Z
    ) / 2
    return frame.Position - extent, frame.Position + extent
end

function Art.Assemble(course: Model, library: Folder): number
    local decoration = child(course, "Decoration")
    assert(not decoration:FindFirstChild("HeartwoodArt"), "Preserve the existing assembled art")
    local art = group(decoration, "HeartwoodArt")
    art:SetAttribute("AssetLibrary", library.Name)
    art:SetAttribute("RouteCoordinates", "HA02")
    local triangles = 0
    local foliageCount, foliageTriangles = 0, 0

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
        if metadata.package == "structure" or metadata.package == "pod" or string.match(name, "^HA_Forest") then
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
        if foliageAssets[name] then
            assert(metadata.triangles <= 600, "Use the bounded HA04 foliage kit")
            foliageCount += 1
            foliageTriangles += metadata.triangles
        end
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
            local size = if crownIndex == 1 then Vector3.new(74, 30, 64) else Vector3.new(68, 28, 58)
            local position = frame * (sourcePoint * data.scale) + Vector3.new(0, size.Y * .23, 0)
            local greenery = centered(if crownIndex == 1 then "HA_FoliageMassA" else "HA_FoliageMassB", unit,
                CFrame.new(position) * CFrame.Angles(0, data.yaw + crownIndex * .3, 0), size)
            greenery.Name = "AttachedCanopy_" .. crownIndex
            greenery:SetAttribute("Scenery", true)
            greenery:SetAttribute("RouteSurface", nil)
            greenery:SetAttribute("AttachmentRole", "Bough crown")
            greenery:SetAttribute("BranchAnchor", sourcePoint)
        end
    end
    art:SetAttribute("AddedBranchTriangles", triangles - middleStart)
    art:SetAttribute("AddedBranchMinY", lowestScenery)

    art:SetAttribute("AddedReliefTriangles", 0)

    local surfaces: {Surface} = {}
    for sectionIndex, sectionName in sectionNames do
        local section = child(decoration, sectionName)
        for _, model in section:GetChildren() do
            local top = model:FindFirstChild("Top")
            if model:IsA("Model") and top and top:IsA("BasePart") then
                table.insert(surfaces, {model = model, prototype = top, section = sectionName, sectionIndex = sectionIndex,
                    frame = top.CFrame * CFrame.new(0, .6, 0), size = top.Size})
            end
        end
    end
    table.sort(surfaces, function(a, b)
        return if a.section ~= b.section then a.section < b.section else a.model.Name < b.model.Name
    end)

    local supports = group(art, "ShelfSupports")
    local margins = group(art, "RouteGreenery")
    for index, surface in surfaces do
        local model = surface.model
        local tip = string.match(model.Name, "^X01_") ~= nil
        local depth = if tip then 3.5 else 6.5
        local name = if tip then "HA_ShelfTip"
            elseif model.Name == "Main_1" then "HA_ShelfWide"
            else shelfVariants[(index + surface.sectionIndex) % #shelfVariants + 1]
        local mesh = centered(name, model, surface.frame * CFrame.new(0, -depth / 2, 0),
            Vector3.new(surface.size.X, depth, surface.size.Z), true)
        disablePrototype(surface.prototype, "TopPrototype")
        mesh.Name = "Top"
        mesh:SetAttribute("RouteSurface", true)
        mesh:SetAttribute("SurfaceTopCFrame", surface.frame)
        mesh:SetAttribute("CollisionUse", "Visible fitted shelf")
        mesh:SetAttribute("ShelfVariant", name)
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

        if not tip and model.Name ~= "J1" and model.Name ~= "J2" and model.Name ~= "PulseRefuge"
            and model.Name ~= "F0" and not string.match(model.Name, "^Entry_") then
            local rootsSection = surface.section == "S01_AncientRoots"
            local sides = {if model.Name == "R2" or model.Name == "R3" or index % 2 ~= 0 then 1 else -1}
            if rootsSection and index % 2 == 0 then table.insert(sides, -sides[1]) end
            for sideIndex, side in sides do
                local height = if rootsSection then 7.2 else 6.2
                local size = Vector3.new(math.clamp(surface.size.X * .66, 10, 19), height,
                    math.clamp(surface.size.Z * .64, 11, 20))
                local position = surface.frame * Vector3.new(side * (surface.size.X / 2 + size.X * .16),
                    -height / 2 - .85, surface.size.Z * (if sideIndex == 1 then -.12 else .18))
                local frame = CFrame.new(position) * surface.frame.Rotation * CFrame.Angles(0, side * .16, 0)
                local asset = if index % 4 == 0 then "HA_HangingMass"
                    elseif (index + sideIndex) % 2 == 0 then "HA_FoliageMassA" else "HA_FoliageMassB"
                local greenery = centered(asset, margins, frame, size)
                greenery.Name = model.Name .. (if side < 0 then "_LeftGreenery" else "_RightGreenery")
                greenery:SetAttribute("StationId", model.Name)
                greenery:SetAttribute("AttachmentRole", "Shelf side and underside")
                greenery:SetAttribute("FoliageTopLocalY", surface.frame.Position.Y - Config.Origin.Y - .85)
            end
            if rootsSection and index % 4 == 0 then
                local fern = clone("HA_Fern", margins,
                    surface.frame * CFrame.new(surface.size.X / 2 - 1, -.6, -surface.size.Z * .28), Vector3.new(.32, .32, .32))
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
        {family = 1, point = Vector3.new(-135, 143, 21), size = Vector3.new(56, 24, 42)},
        {family = 1, point = Vector3.new(-107, 128, 18), size = Vector3.new(42, 20, 40)},
        {family = 2, point = Vector3.new(100, 43, 24), size = Vector3.new(48, 20, 38)},
        {family = 2, point = Vector3.new(89, 43, -25), size = Vector3.new(38, 18, 42)},
        {family = 3, point = Vector3.new(53, 46, 76), size = Vector3.new(50, 22, 44)},
        {family = 3, point = Vector3.new(29, 50, 103), size = Vector3.new(54, 24, 42)},
        {family = 4, point = Vector3.new(-137, 102, 82), size = Vector3.new(58, 25, 46)},
        {family = 4, point = Vector3.new(-123, 102, 115), size = Vector3.new(64, 24, 44)},
        {family = 4, point = Vector3.new(-86, 110, 51), size = Vector3.new(44, 20, 34)},
    }
    for index, data in lowerGreenery do
        local mesh = foliage(if index % 2 == 0 then "HA_HangingMass" else "HA_FoliageMassB", families[data.family], data.point, data.size, index * .61)
        mesh.Name = "JoinedGreenery_" .. index
        mesh:SetAttribute("AttachmentRole", "Lower bough underside")
    end

    local refugeGreenery = foliage("HA_HangingMass", margins, Vector3.new(12, 60.8, -40), Vector3.new(10, 5, 9), .65)
    refugeGreenery.Name = "PulseRefuge_LowerGreenery"
    refugeGreenery:SetAttribute("StationId", "PulseRefuge")
    refugeGreenery:SetAttribute("AttachmentRole", "Refuge underside")

    local crown: {FamilyGreenery} = {
        {family = 5, point = Vector3.new(87, 261, -49), size = Vector3.new(92, 34, 78)},
        {family = 5, point = Vector3.new(147, 291, -46), size = Vector3.new(106, 38, 86)},
        {family = 5, point = Vector3.new(195, 310, -32), size = Vector3.new(80, 29, 70)},
        {family = 5, point = Vector3.new(139, 291, -63), size = Vector3.new(72, 31, 68)},
        {family = 5, point = Vector3.new(154, 291, -26), size = Vector3.new(80, 32, 66)},
        {family = 6, point = Vector3.new(-77, 301, 50), size = Vector3.new(94, 36, 82)},
        {family = 6, point = Vector3.new(-132, 329, 55), size = Vector3.new(114, 40, 92)},
        {family = 6, point = Vector3.new(-185, 343, 27), size = Vector3.new(91, 32, 84)},
        {family = 6, point = Vector3.new(-126, 329, 35), size = Vector3.new(80, 34, 68)},
        {family = 6, point = Vector3.new(-142, 329, 75), size = Vector3.new(75, 30, 68)},
        {family = 7, point = Vector3.new(66, 377, -20), size = Vector3.new(94, 36, 84)},
        {family = 7, point = Vector3.new(118, 408, -8), size = Vector3.new(98, 34, 82)},
        {family = 7, point = Vector3.new(104, 403, -24), size = Vector3.new(72, 32, 68)},
        {family = 7, point = Vector3.new(80, 390, -1), size = Vector3.new(70, 30, 62)},
        {family = 8, point = Vector3.new(-49, 417, 35), size = Vector3.new(100, 38, 88)},
        {family = 8, point = Vector3.new(-91, 447, 28), size = Vector3.new(96, 35, 84)},
        {family = 8, point = Vector3.new(-70, 437, 11), size = Vector3.new(74, 31, 70)},
        {family = 8, point = Vector3.new(-63, 431, 52), size = Vector3.new(78, 32, 68)},
    }
    for index, data in crown do
        local mesh = foliage(if index % 2 == 0 then "HA_FoliageMassB" else "HA_FoliageMassA", families[data.family],
            data.point + Vector3.new(0, data.size.Y * .23, 0), data.size, index * .43)
        mesh.Name = "CrownMass_" .. index
        mesh:SetAttribute("Scenery", true)
        mesh:SetAttribute("AttachmentRole", "Lateral bough crown")
        mesh:SetAttribute("BranchAnchor", data.point)
    end
    local cap = group(trunk, "CrownCap", "Model") :: Model
    for index, data in {
        {point = Vector3.new(0, 460, -5), size = Vector3.new(126, 46, 110)},
        {point = Vector3.new(30, 453, -18), size = Vector3.new(82, 34, 76)},
        {point = Vector3.new(-22, 456, 19), size = Vector3.new(86, 36, 76)},
    } do
        local mesh = foliage(if index == 2 then "HA_FoliageMassB" else "HA_FoliageMassA", cap, data.point, data.size, index * .7)
        mesh.Name = "TopCrown_" .. index
        mesh:SetAttribute("Scenery", true)
        mesh:SetAttribute("AttachmentRole", "Trunk crown")
        if not cap.PrimaryPart then cap.PrimaryPart = mesh end
    end
    cap:SetAttribute("EditableUnit", true)

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

    local forest = group(art, "ForestSurroundings")
    local forestStart = triangles
    local ground = clone("HA_ForestGround", forest, CFrame.new(Config.Origin), nil, true)
    ground.Name = "ForestGround"
    ground.Material = Enum.Material.Ground
    ground:SetAttribute("Scenery", true)
    ground:SetAttribute("CollisionUse", "Visible earth below recovery")
    local _, groundMaximum = partBounds(ground)
    assert(groundMaximum.Y - Config.Origin.Y < -30, "Keep forest ground below the recovery zone")
    assert(ground:IsDescendantOf(workspace), "Place the candidate in Workspace before fitting forest roots")

    local groundParams = RaycastParams.new()
    groundParams.FilterType = Enum.RaycastFilterType.Include
    groundParams.FilterDescendantsInstances = {ground}
    groundParams.RespectCanCollide = true
    local routeBounds = {}
    for _, part in decoration:GetDescendants() do
        if part:IsA("BasePart") and part.CanCollide and (part:GetAttribute("RouteSurface") == true
            or part.Name == "FlowerSurface" or part.Name == "SanctuaryArtwork") then
            local minimum, maximum = partBounds(part)
            table.insert(routeBounds, {minimum = minimum, maximum = maximum, name = part:GetFullName()})
        end
    end

    local trees: {ForestTree} = {
        {asset = "HA_ForestNearA", point = Vector2.new(284, 34), yaw = -.18, scale = Vector3.new(.96, 1, .96), layer = "Near"},
        {asset = "HA_ForestNearB", point = Vector2.new(260, -280), yaw = .48, scale = Vector3.new(.94, .96, .94), layer = "Near"},
        {asset = "HA_ForestNearA", point = Vector2.new(-26, -279), yaw = -.44, scale = Vector3.new(1, .94, 1), layer = "Near"},
        {asset = "HA_ForestNearB", point = Vector2.new(-342, -20), yaw = .32, scale = Vector3.new(.92, .98, .92), layer = "Near"},
        {asset = "HA_ForestNearA", point = Vector2.new(228, 290), yaw = -.62, scale = Vector3.new(.96, .95, .96), layer = "Near"},
        {asset = "HA_ForestNearB", point = Vector2.new(-54, 312), yaw = .14, scale = Vector3.new(1, 1, 1), layer = "Near"},
    }
    for index = 0, 7 do
        local angle = index * math.pi / 4 + .13 * math.cos(index * 1.7)
        local radius = 410 + index % 3 * 16
        local scale = .94 + index % 3 * .04
        local point = if index == 7 then Vector2.new(360, -390) else Vector2.new(math.cos(angle) * radius, math.sin(angle) * radius)
        table.insert(trees, {asset = "HA_ForestMid", point = point,
            yaw = angle + .21, scale = Vector3.new(scale, .94 + index % 2 * .06, scale), layer = "Middle"})
    end
    for index = 0, 11 do
        local angle = index * math.pi / 6 + .12 * math.sin(index * 2.17)
        local radius = 530 + index % 3 * 37 + index % 2 * 28
        local scale = .93 + index % 3 * .035
        local point = if index == 11 then Vector2.new(510, -540) else Vector2.new(math.cos(angle) * radius, math.sin(angle) * radius)
        table.insert(trees, {asset = "HA_ForestFar", point = point,
            yaw = angle - .28, scale = Vector3.new(scale, .95 + index % 2 * .05, scale), layer = "Far"})
    end

    local forestLayers: {[string]: Instance} = {}
    for index, data in trees do
        local layer = forestLayers[data.layer]
        if not layer then
            layer = group(forest, data.layer)
            forestLayers[data.layer] = layer
        end
        local rayOrigin = Config.Origin + Vector3.new(data.point.X, -25, data.point.Y)
        local hit = assert(workspace:Raycast(rayOrigin, Vector3.new(0, -320, 0), groundParams), "Forest root has no earth support")
        local metadata = Manifest[data.asset]
        local sourceBottom = metadata.center.Y - metadata.size.Y / 2
        local root = Vector3.new(data.point.X, hit.Position.Y - Config.Origin.Y - sourceBottom * data.scale.Y - 2, data.point.Y)
        local unit = group(layer, string.format("ForestTree_%02d", index), "Model") :: Model
        local mesh = clone(data.asset, unit, CFrame.new(Config.Origin + root) * CFrame.Angles(0, data.yaw, 0), data.scale, true)
        local minimum, maximum = partBounds(mesh)
        for _, bounds in routeBounds do
            local separated = maximum.X < bounds.minimum.X - 48 or minimum.X > bounds.maximum.X + 48
                or maximum.Z < bounds.minimum.Z - 48 or minimum.Z > bounds.maximum.Z + 48
            assert(separated, "Forest bounds intrude on route clearance: " .. bounds.name)
        end
        mesh:SetAttribute("Scenery", true)
        mesh:SetAttribute("CollisionUse", "Distant forest solid")
        unit.PrimaryPart = mesh
        unit:SetAttribute("EditableUnit", true)
        unit:SetAttribute("WholeTree", true)
        unit:SetAttribute("ForestLayer", data.layer)
        unit:SetAttribute("GroundLocalY", hit.Position.Y - Config.Origin.Y)
        unit:SetAttribute("RootBurial", 2)
        unit:SetAttribute("RouteBuffer", 48)
    end
    art:SetAttribute("ForestTrees", #trees)
    art:SetAttribute("ForestTriangles", triangles - forestStart)
    art:SetAttribute("FoliagePlacements", foliageCount)
    art:SetAttribute("FoliageTriangles", foliageTriangles)
    art:SetAttribute("ArtWorkingTarget", 250000)
    assert(foliageCount <= 110, "Keep foliage placements attached and bounded")
    assert(triangles <= 250000, "Heartwood art exceeds the HA04 working target")

    course:SetAttribute("ArtTriangles", triangles)
    course:SetAttribute("ArtVersion", Config.BuildId)
    course:SetAttribute("Study", false)
    return triangles
end

return Art
