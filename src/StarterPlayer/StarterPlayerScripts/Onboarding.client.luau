--!strict
local controllers = script.Parent:WaitForChild("Controllers")
require(controllers:WaitForChild("OnboardingController")).Init()
