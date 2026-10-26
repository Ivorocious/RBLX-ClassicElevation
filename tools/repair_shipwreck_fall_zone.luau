-- Restore only the editable Shipwreck reset plane; preserve every playable surface.
assert(game.PlaceId == 85558151074819, "Wrong experience")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play first")
local course = workspace:FindFirstChild("Course_ShipwreckCove")
assert(course and course:GetAttribute("ManualEditing") == true, "Editable Shipwreck required")
local zone = course.FallZones.FallZone_Main
local origin = course.Bounds.CourseOrigin
assert(zone:IsA("BasePart") and origin:IsA("BasePart"))
assert(zone.Size == Vector3.new(480, 2, 430), "Unexpected reset plane size")
local before = {zone.CFrame:GetComponents()}
zone.CFrame = origin.CFrame * CFrame.new(0, -1, 0)
zone.Locked = true
return {before=before, after={zone.CFrame:GetComponents()}, locked=zone.Locked}
