--!nonstrict
local player=game.Players.LocalPlayer
local controls=require(player.PlayerScripts.PlayerModule):GetControls()
local original=controls.controlsEnabled
assert(typeof(original)=="boolean")
script:SetAttribute("OriginalControlsEnabled",original)
controls:Disable()
script:SetAttribute("ControlsIsolated",controls.controlsEnabled==false)
local samples={}
local last
local connection=game:GetService("RunService").RenderStepped:Connect(function()
 local gui=player.PlayerGui:FindFirstChild("RaceHUD")
 local canvas=gui and gui:FindFirstChild("RaceHudCanvas")
 local timer=canvas and canvas:FindFirstChild("Timer")
 local content=timer and timer:FindFirstChild("Content")
 local lap=content and content:FindFirstChild("Lap")
 local text=lap and lap:FindFirstChild("Text")
 if text and text.Text~=last then
  last=text.Text
  local visible=true
  local p=text
  while p and p~=player.PlayerGui do
   if p:IsA("GuiObject") and not p.Visible then visible=false end
   if p:IsA("ScreenGui") and not p.Enabled then visible=false end
   p=p.Parent
  end
  table.insert(samples,{text=text.Text,visible=visible,size={text.AbsoluteSize.X,text.AbsoluteSize.Y},position={text.AbsolutePosition.X,text.AbsolutePosition.Y},unixMs=DateTime.now().UnixTimestampMillis})
  script:SetAttribute("HudSamples",game.HttpService:JSONEncode(samples))
 end
end)
script:GetAttributeChangedSignal("Restore"):Connect(function()
 if script:GetAttribute("Restore")~=true then return end
 connection:Disconnect()
 if original then controls:Enable() else controls:Disable() end
 script:SetAttribute("ControlsRestored",controls.controlsEnabled==original)
end)
