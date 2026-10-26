--!nonstrict
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local config=require(game.ReplicatedStorage.Config.MoonlitCitadelConfig)
local root=workspace:FindFirstChild(config.BlenderRootName)
if not root or root:GetAttribute("PreviewEnabled")~=true then return end
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local session
local ok,reason=xpcall(function()
	task.wait(3)
	local services=script.Parent.Services
	assert(require(services.RaceService).ApplyStudioAction("HoldLobby"),"Cannot hold the existing test race")
	local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local accepted,message=require(services.OnboardingService).SetStudioPreset(player,"Returning racer")
	assert(accepted,message)
	local deadline=os.clock()+15
	repeat task.wait(.1) until player:GetAttribute("OnboardingReady")==true or os.clock()>deadline
	assert(player:GetAttribute("OnboardingReady")==true,"Temporary Studio arrival is not ready")
	session=require(game.ServerStorage.CourseBuilders.MoonlitCitadel.PreviewSession).Start(root)
	assert(session:Enter(player,root:GetAttribute("RequestedArea") or "UpperSample"))
	root:SetAttribute("PreviewState","Running")
	root:GetAttributeChangedSignal("PreviewCommand"):Connect(function()
		local command=root:GetAttribute("PreviewCommand")
		if command=="Reset" then session:Reset()
		elseif command=="Stop" then session:Stop();root:SetAttribute("PreviewState","Stopped")
		elseif command=="Enter" then session:Enter(player,root:GetAttribute("RequestedArea") or "UpperSample")end
	end)
	while root.Parent and root:GetAttribute("PreviewState")=="Running"do
		root:SetAttribute("PreviewReport",HttpService:JSONEncode(session:GetReport()))
		task.wait(.2)
	end
end,debug.traceback)
if not ok then
	if session then session:Stop()end
	root:SetAttribute("PreviewState","Failed")
	root:SetAttribute("PreviewFailure",reason)
	warn("Moonlit preview: "..reason)
end
