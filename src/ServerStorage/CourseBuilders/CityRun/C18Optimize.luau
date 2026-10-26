-- Offline edit-time pass; apply only to the preserved optimized inspection template.
local Optimize = {}

local function eligibleVisual(part: BasePart): boolean
    if part.CanCollide or part.CanTouch or not part.Anchored then return false end
    if #game:GetService("CollectionService"):GetTags(part) > 0 then return false end
    for name in part:GetAttributes() do
        if string.find(name, "Hazard") or string.find(name, "Motion") or string.find(name, "Conveyor") then return false end
    end
    local ancestor = part.Parent
    while ancestor do
        if ancestor.Name == "OwnerEdits" then return false end
        ancestor = ancestor.Parent
    end
    return true
end

function Optimize.Apply(template: Model)
    assert(template.Name == "Optimized" and template.Parent.Name == "CityRunInspectionSources", "Use the optimized template only")
    assert(not game:GetService("RunService"):IsRunning(), "Stop Play before editing templates")
    local report = { queryDisabled = 0, boxCollision = 0, removedRoots = {}, removedParts = 0 }
    for _, root in template.Context:GetChildren() do
        local far = root:IsA("BasePart") and (root.Position - Vector3.new(3500, 0, 0)).Magnitude > 5000
        if far or root.Name == "ObstacleKit_Palette" then
            table.insert(report.removedRoots, root.Name)
            if root:IsA("BasePart") then report.removedParts += 1 end
            for _, part in root:GetDescendants() do
                if part:IsA("BasePart") then report.removedParts += 1 end
            end
            root:Destroy()
        end
    end
    for _, group in {template.RaceCourse.Decoration, template.Context} do
        for index, part in group:GetDescendants() do
            if index % 64 == 0 then task.wait() end
            if part:IsA("BasePart") and eligibleVisual(part) then
                if part.CanQuery then part.CanQuery = false; report.queryDisabled += 1 end
                if part:IsA("MeshPart") and part.CollisionFidelity ~= Enum.CollisionFidelity.Box then
                    part.CollisionFidelity = Enum.CollisionFidelity.Box
                    report.boxCollision += 1
                end
            end
        end
    end
    template:SetAttribute("OptimizationBuild", "C18_01")
    return report
end

function Optimize.Reuse(template: Model, groups)
    assert(template.Name == "Optimized" and template.Parent.Name == "CityRunInspectionSources", "Use the optimized template only")
    assert(not game:GetService("RunService"):IsRunning(), "Stop Play before editing templates")
    local paths = {}
    local prefix = #template:GetFullName() + 2
    for _, part in template:GetDescendants() do
        if part:IsA("MeshPart") then
            local path = part:GetFullName():sub(prefix)
            paths[path] = if paths[path] == nil then part else false
        end
    end
    local report = { reused = 0, skipped = 0, alreadyShared = 0 }
    for _, group in groups do
        local source = paths[group.canonicalPath]
        if not source or source.MeshId ~= group.canonicalMeshId then
            report.skipped += #group.members
            continue
        end
        for _, member in group.members do
            local part = paths[member.path]
            if part and part.MeshId == source.MeshId then report.alreadyShared += 1; continue end
            if not part or part.MeshId ~= member.expectedMeshId or not eligibleVisual(part)
                or part.TextureID ~= source.TextureID or part:FindFirstChildOfClass("SurfaceAppearance")
                or source:FindFirstChildOfClass("SurfaceAppearance")
                or (part.MeshSize - source.MeshSize).Magnitude > .025
                or (part.Size - source.Size).Magnitude > .045 then
                report.skipped += 1
                continue
            end
            local size, cframe = part.Size, part.CFrame
            local render, collision, fluid = part.RenderFidelity, part.CollisionFidelity, part.FluidFidelity
            part:ApplyMesh(source)
            part.Size = size
            part.CFrame = cframe
            part.RenderFidelity = render
            part.CollisionFidelity = collision
            part.FluidFidelity = fluid
            report.reused += 1
        end
    end
    return report
end

return Optimize
