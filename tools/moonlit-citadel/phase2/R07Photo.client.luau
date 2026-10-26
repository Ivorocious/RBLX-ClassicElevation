--!nonstrict
assert(game.RunService:IsStudio() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local player, camera, run = game.Players.LocalPlayer, workspace.CurrentCamera, game.RunService
local folder = player.PlayerGui:FindFirstChild('R07PhotoState') or Instance.new('Folder')
folder.Name, folder.Parent = 'R07PhotoState', player.PlayerGui
local beforeType, beforeFrame, beforeFocus, beforeFov = camera.CameraType, camera.CFrame, camera.Focus, camera.FieldOfView
local started, name = os.clock(), 'R07OwnedPhotoCamera'
local eye, target
local connection
local screenStates = {}
for _, item in player.PlayerGui:GetChildren() do
	if item:IsA('ScreenGui') then screenStates[item] = item.Enabled end
end
local views = {
	E1 = {Vector3.new(-75,34,-82),Vector3.new(-51,33,-74)},
	E1Route = {Vector3.new(-72,37,-85),Vector3.new(-57,32,-62)},
	E1Fork = {Vector3.new(-84,35,-95),Vector3.new(-57,34,-66)},
	E3Choice = {Vector3.new(76,113,2),Vector3.new(94,113,-16)},
	E2 = {Vector3.new(-49,58,66),Vector3.new(-16,56,54)},
	E3 = {Vector3.new(73,113,-13),Vector3.new(103,113,-12)},
	Weave = {Vector3.new(-112,24,-9),Vector3.new(-75,25,-34)},
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
