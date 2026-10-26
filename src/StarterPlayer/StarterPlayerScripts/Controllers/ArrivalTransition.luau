--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local View = require(script.Parent.ArrivalView)
local EntranceView = require(script.Parent.ArrivalEntranceView)
local Assets = require(script.Parent.ArrivalAssets)
local Lobby = require(script.Parent.LobbyUiController)
local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local Timing = require(ReplicatedStorage.Config.OnboardingConfig).Entrance
local Transition = {}
local Ownership = require(script.Parent.CameraOwnership)

local function ease(t) return math.clamp(t*t*t*(t*(t*6-15)+10),0,1) end

function Transition.Create(gui, music, sourceTitle)
	local player = Players.LocalPlayer
	local view = EntranceView.Create(gui, sourceTitle)
	local root = view.Root
	local curtain = view.Curtain
	local top = view.Top
	local bottom = view.Bottom
	local mark = view.Mark
	local pieces = view.Pieces
	local title = view.Title
	local loading = view.Loading
	local retry = view.Retry
	local skip=Instance.new("TextButton")
	skip.Name,skip.Text,skip.Font,skip.TextSize="SkipCinematic","Skip cinematic",Enum.Font.GothamBold,14
	skip.Size,skip.Position,skip.AnchorPoint=UDim2.fromOffset(160,44),UDim2.new(1,-16,1,-16),Vector2.new(1,1)
	skip.BackgroundColor3,skip.BackgroundTransparency,skip.TextColor3=Color3.fromRGB(10,16,34),.25,Color3.fromRGB(221,232,255)
	View.Make("UICorner","Corners",skip,{CornerRadius=UDim.new(.5,0)})
	View.Make("UIStroke","Edge",skip,{Color=Color3.new(1,1,1),Transparency=.8,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	skip.Visible,skip.Parent=false,root
	local skipped=false
	skip.Activated:Connect(function() skipped=true; skip.Text="Cinematic skipped" end)
	local epoch, running, preload = 0, false, nil
	local camera, savedCamera, bindName = nil, nil, "ArrivalLobbyCamera"
	local lease = nil
	local activeOptions, retriedFailure = nil, {}
	local sourceTitleVisible = true
	local function phase(value)
		root:SetAttribute("Phase",value)
		player:SetAttribute("ArrivalTransitionPhase",value)
	end
	local function setCamera()
		RunService:UnbindFromRenderStep(bindName)
		RunService:UnbindFromRenderStep(bindName.."Native")
		Ownership.Release(lease); lease=nil
		camera, savedCamera = nil, nil
	end
	local function volume()
		return if activeOptions and activeOptions.volume then activeOptions.volume() else 0
	end
	local function cancel()
		epoch += 1
		running, root.Visible, retry.Visible,preload = false,false,false,nil
		setCamera(); Lobby.CancelEntrance()
		skip.Visible=false
		sourceTitle.Visible = sourceTitleVisible
		music.Volume = volume()
		phase("Idle")
	end
	local function warm(delivery)
		if not delivery or (preload and preload.token == delivery.token) then return end
		local job = {token=delivery.token,done=false,failed=false,lobby=nil}
		preload = job
		task.spawn(function()
			local ok, reason = pcall(function()
				local deadline = os.clock()+25
				local lobby
				repeat
					if preload ~= job then return end
					lobby = workspace:FindFirstChild(delivery.lobby)
					local count = 0
					if lobby then for _, item in lobby:GetDescendants() do if item:IsA("BasePart") then count += 1 end end end
					local spawn = lobby and lobby:FindFirstChild(delivery.spawn or RaceConfig.LobbySpawnMarkerName)
					if game:IsLoaded() and lobby and lobby:IsA("Model") and spawn and spawn:IsA("BasePart") and count >= delivery.partCount then break end
					assert(os.clock()<deadline,"Lobby replication timed out")
					task.wait(.15)
				until false
				job.lobby = lobby
				if preload~=job then return end
				local assets = Lobby.PrepareEntrance()
				for _, visual in Assets.LobbyVisuals(lobby) do table.insert(assets,visual) end
				task.spawn(function()
					Assets.WarmOptional(ContentProvider,assets,function(id,status)
						if preload==job then warn("[ArrivalDelivery] Optional lobby visual "..id..": "..status) end
					end)
				end)
				local geometryReady, geometryFailure = Assets.PreloadLobbyGeometry(ContentProvider,lobby,function(id,status)
					if preload==job then warn("[ArrivalDelivery] Optional lobby texture "..id..": "..status) end
				end)
				assert(geometryReady,geometryFailure)
			end)
			if not ok then warn("[ArrivalDelivery] "..tostring(reason)) end
			job.failed, job.failure, job.done = job.failed or not ok, if ok then nil else tostring(reason), true
		end)
	end
	local function animate(seconds, token, update)
		local elapsed = 0
		repeat
			assert(token==epoch,"Cancelled")
			elapsed += RunService.RenderStepped:Wait()
			assert(token==epoch,"Cancelled")
			update(ease(math.min(1,elapsed/seconds)),math.min(1,elapsed/seconds))
		until elapsed >= seconds
	end
	local function waitFor(token, predicate, seconds)
		local deadline = os.clock()+seconds
		repeat
			assert(token==epoch,"Cancelled")
			if predicate() then return end
			assert(os.clock()<deadline,"Loading timed out")
			task.wait(.05)
		until false
	end
	local function run(delivery, options)
		if running or root.Visible then cancel() end
		running, activeOptions = true, options
		skipped=false; skip.Text="Skip cinematic"; skip.Visible=true
		epoch += 1
		local token = epoch
		lease=Ownership.Acquire("Arrival",cancel,false)
		warm(delivery)
		Lobby.PrepareEntrance()
		root.Visible, retry.Visible, curtain.Visible = true, false, true
		curtain.BackgroundTransparency = 1
		top.Visible, bottom.Visible = false, false
		mark.ImageTransparency, title.TextTransparency = 1, 0
		local movingTitle = sourceTitle.Visible and sourceTitle.Parent.Visible
		local origin = sourceTitle.AbsolutePosition-root.AbsolutePosition
		local startPosition = if movingTitle then UDim2.fromOffset(origin.X,origin.Y) else UDim2.fromScale(.08,.48)
		local startSize = if movingTitle then UDim2.fromOffset(sourceTitle.AbsoluteSize.X,sourceTitle.AbsoluteSize.Y) else UDim2.fromScale(.84,.09)
		local startLimit = if movingTitle then sourceTitle.TextLimit.MaxTextSize else 46
		title.Position, title.Size = startPosition, startSize
		title.TextLimit.MaxTextSize, title.TextStrokeTransparency = startLimit, 1
		sourceTitleVisible = sourceTitle.Visible
		sourceTitle.Visible = false
		loading.Text, loading.Visible = "", false
		music.Volume = volume()
		phase("Logo")
		task.spawn(function()
			local ok, err = pcall(function()
				animate(if options.returning or not options.motion then .2 else Timing.TitleMoveSeconds,token,function(t)
					curtain.BackgroundTransparency = 1-t
					title.Position = if options.motion then startPosition:Lerp(UDim2.fromScale(.08,.48),t) else UDim2.fromScale(.08,.48)
					title.Size = if options.motion then startSize:Lerp(UDim2.fromScale(.84,.09),t) else UDim2.fromScale(.84,.09)
					title.TextLimit.MaxTextSize = if options.motion then startLimit+(46-startLimit)*t else 46
					title.TextTransparency = if options.motion then 0 else 1-t
					mark.ImageTransparency = 1-math.clamp((t-.35)/.65,0,1)
					for i, piece in pieces do
						local lift = if options.motion then (1-t)*(.7+i*.10) else 0
						piece.part.CFrame = CFrame.new(0,-lift,0)*CFrame.Angles(0,(if options.motion then (1-t)*.5 else 0),0)*piece.frame
					end
				end)
				options.covered()
				phase("LogoHold")
				local hold = if options.returning then Timing.ReturningHoldSeconds elseif options.motion then Timing.LogoHoldSeconds else .35
				local logoUntil = os.clock()+hold
				waitFor(token,function() return os.clock()>=logoUntil end,Timing.LogoHoldSeconds+2)
				phase("Loading")
				loading.Text, loading.Visible = "Loading…", true
				waitFor(token,function() return preload and preload.token==delivery.token and preload.done end,30)
				assert(not preload.failed,preload.failure or "Lobby delivery unavailable")
				local lobby = preload.lobby
				camera = workspace.CurrentCamera
				assert(camera,"Camera unavailable")
				savedCamera = {kind=camera.CameraType,subject=camera.CameraSubject,frame=camera.CFrame,fov=camera.FieldOfView}
				local readyHumanoid
				waitFor(token,function()
					readyHumanoid = if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
					return readyHumanoid and readyHumanoid.Health>0
				end,20)
				-- Sample Roblox's actual orbit and zoom while the title still covers the world.
				camera.CameraSubject,camera.CameraType = readyHumanoid,Enum.CameraType.Custom
				RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
				assert(token==epoch,"Cancelled")
				local playerFrame,playerFocus = camera.CFrame,camera.Focus
				local front = Vector3.new(0,0,-1)
				local center = delivery.center
				local distance = math.max(delivery.size.X,delivery.size.Z)*1.35
				local overview = CFrame.lookAt(center+front*distance+Vector3.new(20,distance*.23,0),center)
				local currentFrame = if options.returning or not options.motion then playerFrame else overview
				local currentFov = if options.returning or not options.motion then savedCamera.fov else 55
				local nativeBlend = 0
				local handoffRequested,handoffStarted,hudStarted = false,false,false
				local acknowledged,response = options.returning,nil
				-- Initialize the player camera before its update, then draw the blended frame afterward.
				RunService:BindToRenderStep(bindName.."Native",Enum.RenderPriority.Camera.Value-1,function()
					if token~=epoch or not handoffRequested or handoffStarted or workspace.CurrentCamera~=camera then return end
					handoffStarted = true
					camera.CFrame,camera.Focus = playerFrame,playerFocus
					camera.CameraSubject,camera.CameraType = readyHumanoid,Enum.CameraType.Custom
					if not options.returning then task.spawn(function()
						local success,value=pcall(options.acknowledge,delivery.token)
						if token~=epoch then return end
						response,acknowledged=if success then value else nil,true
					end) end
				end)
				camera.CameraType = Enum.CameraType.Scriptable
				RunService:BindToRenderStep(bindName,Enum.RenderPriority.Camera.Value+1,function()
					if token~=epoch or workspace.CurrentCamera~=camera then return end
					local native = camera.CFrame
					camera.CFrame, camera.FieldOfView = currentFrame:Lerp(native,nativeBlend),currentFov
					root:SetAttribute("CameraBlend",nativeBlend)
				end)
				RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
				assert(token==epoch,"Cancelled")
				phase("Overview")
				curtain.Visible, top.Visible, bottom.Visible = false, true, true
				animate(if options.returning or not options.motion then .2 else Timing.RevealSeconds,token,function(t)
					top.Size, bottom.Size = UDim2.fromScale(1,.5*(1-t)), UDim2.fromScale(1,.5*(1-t))
					mark.ImageTransparency = t
					title.Position = UDim2.fromScale(.08,if options.motion then .48-.36*t else .48)
					title.TextStrokeTransparency = 1-.35*t
				end)
				local character, humanoid, body
				waitFor(token,function()
					character = player.Character
					humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
					body = if character then character:FindFirstChild("HumanoidRootPart") else nil
					local head = character and character:FindFirstChild("Head")
					local colliding = false
					if character then
						for _, part in character:GetChildren() do
							if part:IsA("BasePart") and part.CanCollide then colliding=true; break end
						end
					end
					return humanoid and humanoid.Health>0 and humanoid.RigType==Enum.HumanoidRigType.R15
						and body and body:IsA("BasePart") and head and head:IsA("BasePart") and colliding
				end,20)
				local characterVisuals = Assets.CharacterVisuals(character)
				task.spawn(function()
					Assets.WarmOptional(ContentProvider,characterVisuals,function(id,status)
						if token==epoch then warn("[ArrivalDelivery] Optional character visual "..id..": "..status) end
					end)
				end)
				local params = RaycastParams.new()
				params.FilterType,params.FilterDescendantsInstances = Enum.RaycastFilterType.Include,{lobby}
				params.RespectCanCollide = true
				local floor = workspace:Raycast(body.Position+Vector3.new(0,2,0),Vector3.new(0,-20,0),params)
				assert(floor,"Spawn floor unavailable")
				local floorDone, floorReady, floorFailure = false, false, nil
				task.spawn(function()
					floorReady, floorFailure = Assets.PreloadFloor(ContentProvider,floor.Instance,function(id,status)
						if token==epoch then warn("[ArrivalDelivery] Optional floor visual "..id..": "..status) end
					end)
					floorDone = true
				end)
				waitFor(token,function() return floorDone end,25)
				assert(floorReady,floorFailure)
				if delivery.failOnce and not retriedFailure[delivery.token] then retriedFailure[delivery.token]=true; error("Simulated delivery failure") end
				local holdUntil = os.clock()+(delivery.delaySeconds or 0)
				waitFor(token,function() return os.clock()>=holdUntil end,12)
				loading.Text, loading.Visible = "", false
				phase("Handoff")
				local target = body.Position+Vector3.new(0,2,0)
				local finish = playerFrame
				local start = currentFrame
				local bend = target+Vector3.new(0,65,-20)
				if not options.motion then
					curtain.Visible = true
					animate(.18,token,function(t) curtain.BackgroundTransparency=1-t end)
				end
				local duration = if skipped then .18 elseif options.returning then .45 elseif options.motion then Timing.ApproachSeconds else .18
				local landing = math.min(Timing.LandingSeconds,duration)
				root:SetAttribute("HandoffStartedAt",os.clock())
				animate(duration,token,function(t,progress)
					if skipped then t,progress=1,1 end
					assert(player.Character==character and humanoid.Health>0,"Character changed")
					assert(workspace.CurrentCamera==camera,"Camera changed")
					local position = start.Position*(1-t)^2 + bend*2*(1-t)*t + finish.Position*t^2
					currentFrame = if options.motion and not options.returning then CFrame.new(position)*start.Rotation:Lerp(finish.Rotation,t) else finish
					if not options.motion then curtain.BackgroundTransparency=t end
					currentFov = if options.returning or not options.motion then savedCamera.fov else 55+(savedCamera.fov-55)*t
					local tail = ease(math.clamp((progress-(1-landing/duration))/(landing/duration),0,1))
					title.TextTransparency = tail
					music.Volume = volume()*(1-tail)
					root:SetAttribute("AudioGain",1-tail)
					if tail>0 then handoffRequested=true end
					nativeBlend = tail
					if not hudStarted and tail>=.5 and acknowledged and (options.returning or (response and response.ok and response.phase=="Ready")) then
						hudStarted=true
						Lobby.RevealEntrance(options.motion)
					end
				end)
				phase("WaitingAck")
				waitFor(token,function() return acknowledged end,15)
				assert(options.returning or (response and response.ok and response.phase=="Ready"),"Arrival not confirmed")
				RunService:UnbindFromRenderStep(bindName)
				RunService:UnbindFromRenderStep(bindName.."Native")
				camera.CameraSubject, camera.CameraType = humanoid,Enum.CameraType.Custom
				camera.FieldOfView = savedCamera.fov
				Ownership.Release(lease); lease=nil
				savedCamera, camera = nil,nil
				phase("Settling")
				if not hudStarted then Lobby.RevealEntrance(options.motion) end
				waitFor(token,Lobby.EntranceSettled,3)
				Lobby.FinishEntrance()
				root.Visible,running = false,false
				skip.Visible=false
				sourceTitle.Visible = sourceTitleVisible
				phase("Complete")
				root:SetAttribute("CompleteAt",os.clock())
				options.completed(response)
			end)
			if not ok and token==epoch then
				warn("[ArrivalTransition] "..tostring(err))
				running = false
				setCamera(); Lobby.CancelEntrance()
				curtain.Visible,curtain.BackgroundTransparency = true,.15
				phase("Failed")
				loading.Text, loading.Visible, retry.Visible = "Couldn’t load the lobby. Please retry.", true, true
				if game:GetService("UserInputService").GamepadEnabled then game:GetService("GuiService").SelectedObject=retry end
			end
		end)
	end
	retry.Activated:Connect(function()
		if running or not activeOptions then return end
		local options = activeOptions
		local delivery = options.delivery
		setCamera()
		preload = nil
		title.Position = UDim2.fromScale(.08,.46)
		run(delivery,options)
	end)
	local function returned(options)
		local delivery = {token="returning-"..tostring(os.clock()),lobby=RaceConfig.LobbyModelName,partCount=0,center=Vector3.zero,size=Vector3.zero}
		options.delivery,options.returning = delivery,true
		run(delivery,options)
		return true
	end
	player.CharacterRemoving:Connect(function()
		if not running then return end
		epoch += 1; running=false
		setCamera(); Lobby.CancelEntrance()
		phase("Failed")
		curtain.Visible,curtain.BackgroundTransparency = true,.15
		loading.Text,loading.Visible,retry.Visible = "Your character is loading. Retry when ready.",true,true
	end)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if not running or not camera or workspace.CurrentCamera==camera then return end
		epoch += 1; running=false
		setCamera(); Lobby.CancelEntrance()
		phase("Failed")
		curtain.Visible,curtain.BackgroundTransparency = true,.15
		loading.Text,loading.Visible,retry.Visible = "The camera changed. Please retry.",true,true
	end)
	gui.Destroying:Connect(cancel)
	return {Preload=warm,Run=run,RunReturned=returned,Cancel=cancel,Token=function() return if activeOptions then activeOptions.delivery.token else nil end,IsRunning=function() return running or root.Visible end}
end

return Transition
