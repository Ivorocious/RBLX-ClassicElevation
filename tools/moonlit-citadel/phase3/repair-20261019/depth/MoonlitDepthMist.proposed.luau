--!strict
local Mist = {}
local SITES = {
    {point=Vector3.new(-144,-180,85),size=160},
    {point=Vector3.new(-145,-240,-90),size=180},
    {point=Vector3.new(-60,-270,25),size=190},
    {point=Vector3.new(110,-300,-85),size=180},
    {point=Vector3.new(15,-390,-30),size=240},
}

function Mist.Start(course: Model, enabled: boolean): () -> ()
    if not enabled then return function() end end
    assert(game:GetService("RunService"):IsClient(), "Depth mist belongs only to the local client")
    assert(course.Name == "RaceCourse" and course:GetAttribute("CourseId") == "moonlit_citadel"
        and course:GetAttribute("MoonlitCourse") == true and course:GetAttribute("RuntimeActiveCourse") == true)
    local origin = course:GetAttribute("Origin")
    assert(typeof(origin) == "Vector3" and not course:FindFirstChild("LocalMoonlitDepthMist"))
    local folder = Instance.new("Folder")
    folder.Name = "LocalMoonlitDepthMist"
    for index, site in SITES do
        local anchor = Instance.new("Part")
        anchor.Name, anchor.Size, anchor.Position = "DepthMist"..index, Vector3.new(42,26,42), origin+site.point
        anchor.Anchored, anchor.Transparency, anchor.CastShadow = true, 1, false
        anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = false, false, false
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name, emitter.Texture = "LocalChasmHaze", "rbxasset://textures/particles/smoke_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(28,41,63))
        emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,site.size*.65),NumberSequenceKeypoint.new(1,site.size)})
        emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.78),NumberSequenceKeypoint.new(.75,.82),NumberSequenceKeypoint.new(1,1)})
        emitter.Lifetime, emitter.Rate, emitter.Speed = NumberRange.new(40,48), .1, NumberRange.new(.1,.25)
        emitter.Rotation, emitter.RotSpeed = NumberRange.new(0,360), NumberRange.new(-.5,.5)
        emitter.LightInfluence, emitter.LightEmission = 0, 0
        emitter.Parent, anchor.Parent = anchor, folder
    end
    folder.Parent = course
    for _, anchor in folder:GetChildren() do
        local emitter = anchor:FindFirstChildOfClass("ParticleEmitter")
        if emitter then emitter:Emit(5) end
    end
    local destroyed = false
    local connection: RBXScriptConnection? = nil
    local function cleanup()
        if destroyed then return end
        destroyed = true
        if connection then connection:Disconnect(); connection = nil end
        folder:Destroy()
    end
    connection = course.Destroying:Connect(cleanup)
    return cleanup
end

return Mist
