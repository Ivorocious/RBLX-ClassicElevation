--!strict

local Depth = {Candidate = "MC_DEPTH_VEIL_20261020"}
local LOWEST_MIST_TOP = -24

function Depth.Apply(course: Model): Folder
    local decoration = assert(course:FindFirstChild("Decoration"), "Course decoration is missing")
    local existing = decoration:FindFirstChild("MoonlitDepthVeil")
    if existing then
        assert(existing:IsA("Folder") and existing:GetAttribute("Candidate") == Depth.Candidate,
            "Preserve the existing depth effect before replacement")
        return existing
    end
    local origin = course:GetAttribute("Origin")
    assert(typeof(origin) == "Vector3", "Course origin is missing")
    local veil = Instance.new("Folder")
    veil.Name = "MoonlitDepthVeil"
    veil:SetAttribute("Candidate", Depth.Candidate)
    veil:SetAttribute("OriginalFloorRetained", true)
    for column, x in {-195, -75, 45, 165} do
        for row, z in {-156, 0, 156} do
            local y = -29 - ((column + row) % 3) * 3
            -- Horizontal wisps rise less than half a stud during their full lifetime.
            assert(y + .5 + .02 * 24 <= LOWEST_MIST_TOP)
            local anchor = Instance.new("Part")
            anchor.Name = string.format("LowMist_%d_%d", column, row)
            anchor.Size = Vector3.new(108, 1, 126)
            anchor.CFrame = CFrame.new(origin + Vector3.new(x, y, z))
            anchor.Anchored, anchor.Transparency, anchor.CastShadow = true, 1, false
            anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
            anchor:SetAttribute("MoonlitDepthVeil", true)
            anchor.Parent = veil
            local mist = Instance.new("ParticleEmitter")
            mist.Name = "RavineVeil"
            mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
            mist.Color = ColorSequence.new(Color3.fromRGB(24, 33, 49))
            mist.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 96),
                NumberSequenceKeypoint.new(.6, 112), NumberSequenceKeypoint.new(1, 118)})
            mist.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .12),
                NumberSequenceKeypoint.new(.75, .2),
                NumberSequenceKeypoint.new(1, 1)})
            mist.Lifetime, mist.Rate = NumberRange.new(20, 24), .4
            mist.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
            mist.EmissionDirection, mist.SpreadAngle = Enum.NormalId.Top, Vector2.zero
            mist.Speed, mist.Acceleration = NumberRange.new(.02), Vector3.zero
            mist.VelocityInheritance = 0
            mist.Rotation, mist.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-.5, .5)
            mist.LightInfluence, mist.LightEmission = 0, 0
            mist:SetAttribute("PrewarmParticles", 8)
            mist.Parent = anchor
        end
    end
    veil:SetAttribute("Emitters", 12)
    veil:SetAttribute("MaximumSpriteTopLocalY", -28.02)
    veil.Parent = decoration
    return veil
end

return Depth
