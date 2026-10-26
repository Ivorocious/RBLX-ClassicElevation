--!strict

if game:GetService("RunService"):IsStudio() then
	local controllers = script.Parent:WaitForChild("Controllers")
	require(controllers:WaitForChild("StudioFlightController")).Init()
end
