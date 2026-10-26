--!strict
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local View = {}

function View.Start()
	assert(RunService:IsStudio() and RunService:IsClient(),"Local Studio preview only")
	local prior = {}
	local settings = {ClockTime=14.5, Brightness=2, Ambient=Color3.fromRGB(150,156,166), OutdoorAmbient=Color3.fromRGB(176,185,198), ExposureCompensation=0}
	for key,value in settings do prior[key]=Lighting[key]; Lighting[key]=value end
	local stopped=false
	return {Stop=function()
		if stopped then return end
		stopped=true
		for key,value in prior do Lighting[key]=value end
	end}
end

return View
