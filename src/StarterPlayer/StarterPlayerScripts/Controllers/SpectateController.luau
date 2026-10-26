--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CameraOwnership = require(script.Parent.CameraOwnership)
local Config = require(game:GetService("ReplicatedStorage").Config.RaceConfig)
local Controller = {}
local player = Players.LocalPlayer
local targets: {any} = {}
local targetId: number? = nil
local lease: any = nil
local watching = false
local onExit: (() -> ())? = nil
local requestFocus: ((number) -> ())? = nil
local loadingAt: number? = nil

local function livingTarget(id: number): Humanoid?
 local racer = Players:GetPlayerByUserId(id)
 local character = racer and racer.Character
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 return if humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") then humanoid else nil
end

function Controller.Stop(notify: boolean?)
 local wasWatching = watching
 watching,targetId,loadingAt = false,nil,nil
 RunService:UnbindFromRenderStep("RaceSpectateCamera")
 CameraOwnership.Release(lease); lease = nil
 if notify and wasWatching and onExit then onExit() end
end

function Controller.Cycle(direction: number)
 local index = 0
 for i,target in targets do if target.userId == targetId then index = i; break end end
 for step=1,#targets do
  local candidate = targets[((index-1+direction*step)%#targets)+1]
  local racer = Players:GetPlayerByUserId(candidate.userId)
  local humanoid = racer and racer.Character and racer.Character:FindFirstChildOfClass("Humanoid")
  if candidate.userId ~= player.UserId and (not humanoid or humanoid.Health > 0) then
   targetId,loadingAt = candidate.userId,os.clock()
   if requestFocus then requestFocus(targetId :: number) end
   return
  end
 end
 targetId = nil
end

function Controller.Update(list: any, enabled: boolean, exit: () -> (), focus: ((number) -> ())?)
 targets = if typeof(list)=="table" then list else {}
 onExit = exit
 requestFocus = focus
 if not enabled or player:GetAttribute("ArrivalOpen")==true then Controller.Stop(); return end
 if not watching then
  lease = CameraOwnership.Acquire("Spectate",function() Controller.Stop() end,false)
  if not lease then return end
  watching = true
  RunService:BindToRenderStep("RaceSpectateCamera",Enum.RenderPriority.Camera.Value-1,function()
   if not watching or not CameraOwnership.IsOwner(lease) then return end
   local listed = false
   for _,target in targets do if target.userId==targetId then listed=true; break end end
   local racer = targetId and Players:GetPlayerByUserId(targetId)
   local currentHumanoid = racer and racer.Character and racer.Character:FindFirstChildOfClass("Humanoid")
   if not listed or (currentHumanoid and currentHumanoid.Health <= 0) then Controller.Cycle(1) end
   local humanoid = if targetId then livingTarget(targetId) else nil
   if not humanoid then
    if targetId and not loadingAt then
     loadingAt = os.clock()
     if requestFocus then requestFocus(targetId) end
    end
    if not targetId or (loadingAt and os.clock()-loadingAt >= Config.SpectateLoadSeconds) then Controller.Stop(true) end
    return
   end
   loadingAt = nil
   local camera = workspace.CurrentCamera
   if camera ~= lease.camera then Controller.Stop(true); return end
   camera.CameraType,camera.CameraSubject = Enum.CameraType.Custom,humanoid
  end)
 end
end

function Controller.GetTargetName(): string
 if loadingAt then return "Loading racer…" end
 for _,target in targets do if target.userId==targetId then return tostring(target.displayName or target.name or "Racer") end end
 return "Finding a racer…"
end

-- The watched racer for the Watching screen: user id (nil while none) and whether focus is still loading.
function Controller.GetTarget(): (number?, boolean)
 return targetId, loadingAt ~= nil
end

player.CharacterRemoving:Connect(function() Controller.Stop(true) end)
player:GetAttributeChangedSignal("ArrivalOpen"):Connect(function() if player:GetAttribute("ArrivalOpen")==true then Controller.Stop(true) end end)
return Controller
