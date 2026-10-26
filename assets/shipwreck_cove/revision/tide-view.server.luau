-- Studio-only controlled production states for native visual inspection.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local template = game.ServerStorage.CourseLibrary.Course_ShipwreckCove
local layout = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
assert(template:GetAttribute("ShipwreckBuild") == layout.build, "Build mismatch")
assert(not workspace:FindFirstChild("__SCControlledTideReview"), "Remove previous owned fixture first")
local fixture = template:Clone()
fixture.Name = "__SCControlledTideReview"
fixture:PivotTo(fixture:GetPivot() + Vector3.new(600, 0, 0))
fixture.Parent = workspace
local runtime = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime)
local controller = runtime.Create(fixture, function() end, function() return false end)
script:SetAttribute("Clock", 2)
game:GetService("RunService").Heartbeat:Connect(function(dt)
    controller.Step(script:GetAttribute("Clock") or 2, dt, false)
end)
