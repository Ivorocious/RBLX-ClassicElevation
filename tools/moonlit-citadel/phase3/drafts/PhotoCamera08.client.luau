--!nonstrict
assert(game.RunService:IsStudio() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local player, camera, run = game.Players.LocalPlayer, workspace.CurrentCamera, game.RunService
local folder = player.PlayerGui:FindFirstChild('P3PhotoState') or Instance.new('Folder')
folder.Name, folder.Parent = 'P3PhotoState', player.PlayerGui
local beforeType, beforeFrame, beforeFocus, beforeFov = camera.CameraType, camera.CFrame, camera.Focus, camera.FieldOfView
local started, name = os.clock(), 'P3OwnedPhotoCamera'
local eye, target
local connection
local screenStates = {}
for _, item in player.PlayerGui:GetChildren() do
	if item:IsA('ScreenGui') then screenStates[item] = item.Enabled end
end
local v = Vector3.new
local views = {GatePortal={v(-179,10,143),v(-190,8,130)}, GateExitPortal={v(-122,16,111),v(-130,12,81)}, WestOuter={v(-216,39,-128),v(-216,39,-68)}, WestInner={v(-185,48,51),v(-198,47,26)}, CloisterNear={v(-106,59,60),v(-116,59,111)}, CloisterLanding={v(-72,59,151),v(-76,59,180)}, CrownLookback08={v(2,157,-25),v(-35,153,-31)}, Overview={v(-410,260,360),v(-15,77,0)}, CrownArrival={v(-29,157,-19),v(-8,153,-30)}, E1Arrival = {v(-161, 35, -91), v(-144, 29.5, -112)},
		E1NormalFork = {v(-141, 35, -107), v(-177, 29.5, -142)},
		E1ExpertFork = {v(-147, 35, -111), v(-129, 30.5, -99)},
		E1ExpertLanding = {v(-130, 35, -122), v(-129, 33, -91)},
		E1ExpertReverse = {v(-120, 43, -77), v(-129, 33, -103)},
		E2Arrival = {v(-44, 59, 122), v(-39, 54, 100)},
		E2Fork = {v(-56, 59, 108), v(-24, 54, 102)},
		E2ExpertLanding = {v(-44, 59, 104), v(-16, 55, 104)},
		E2NormalLanding = {v(-44, 59, 96), v(-44, 53, 66)},
		E2Reverse = {v(-18, 61, 102), v(-47, 54, 108)},
		E3Bay1Arrival = {v(103, 113, -72), v(117, 109, -85)},
		E3Bay2Arrival = {v(121, 113, -72), v(136, 109, -81)},
		E3NormalCommit = {v(124, 113, -87), v(142, 108, -68)},
		E3ExpertRightLanding = {v(129, 113, -80), v(146, 115, -87)},
		E3ExpertLeftLanding = {v(95, 113, -80), v(78, 115, -87)},
		E3Reverse = {v(141, 118, -78), v(117, 109, -86)},
	

 GateForward={Vector3.new(-150,8,160),Vector3.new(-117,5,146)},
 GateReverse={Vector3.new(-185,12,148),Vector3.new(-137,5,170)},
 E1Fork={Vector3.new(-150,35,-128),Vector3.new(-124,35,-96)},
 E1Landing={Vector3.new(-134,40,-99),Vector3.new(-120,39,-82)},
 E1Reverse={Vector3.new(-125,44,-78),Vector3.new(-140,36,-108)},
 E2ForkWide={Vector3.new(-64,59,116),Vector3.new(-18,58,104)},
 E2Exit={Vector3.new(107,72,115),Vector3.new(125,67,101)},
 E2ReverseWide={Vector3.new(75,70,107),Vector3.new(44,63,105)},
 E3Fork={Vector3.new(110,113,-66),Vector3.new(137,112,-85)},
 E3Bay2={Vector3.new(143,132,-85),Vector3.new(124,130,-97)},
 E3Bay1={Vector3.new(81,132,-85),Vector3.new(102,130,-97)},
 E3Exit={Vector3.new(126,140,-78),Vector3.new(126,137,-100)},
 Crown={Vector3.new(-22,157,-11),Vector3.new(-8,153,-30)},
 CrownReverse={Vector3.new(-8,157,-44),Vector3.new(-60,151,-30)},
}

local origin = Vector3.new(4000,300,2600)
run:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
	if eye then
		for item in screenStates do if item.Parent then item.Enabled = false end end
		camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, 70
		camera.CFrame, camera.Focus = CFrame.lookAt(origin + eye, origin + target), CFrame.new(origin + target)
	end
end)
connection = folder:GetAttributeChangedSignal('View'):Connect(function()
	local view = views[folder:GetAttribute('View')]
	if view then
		for item in screenStates do item.Enabled = false end
		eye, target = view[1],view[2];folder:SetAttribute('RenderedView',folder:GetAttribute('View'))
	end
end)
folder:SetAttribute('Stop',nil)
folder:SetAttribute('Ready',true)
while script.Parent and os.clock() - started < 600 and folder:GetAttribute('Stop') ~= true do task.wait(.2) end
run:UnbindFromRenderStep(name);connection:Disconnect()
camera.CameraType,camera.CFrame,camera.Focus,camera.FieldOfView = beforeType,beforeFrame,beforeFocus,beforeFov
for item, enabled in screenStates do if item.Parent then item.Enabled = enabled end end
folder:SetAttribute('Ready',false)
