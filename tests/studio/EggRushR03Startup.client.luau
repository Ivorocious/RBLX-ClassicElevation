--!nonstrict
local player=game.Players.LocalPlayer
local events={}
local function record(name)
 table.insert(events,{name=name,unixMs=DateTime.now().UnixTimestampMillis,queue=game:GetService("ContentProvider").RequestQueueSize})
 script:SetAttribute("Events",game.HttpService:JSONEncode(events))
end
record("ClientScriptEntered")
game:GetService("RunService").RenderStepped:Once(function()record("FirstRender")end)
player:GetAttributeChangedSignal("ArrivalTransitionPhase"):Connect(function()record("Arrival:"..tostring(player:GetAttribute("ArrivalTransitionPhase")))end)
player:GetAttributeChangedSignal("OnboardingReady"):Connect(function()record("OnboardingReady:"..tostring(player:GetAttribute("OnboardingReady")))end)
if not game:IsLoaded() then game.Loaded:Wait() end
record("DataModelLoaded")
