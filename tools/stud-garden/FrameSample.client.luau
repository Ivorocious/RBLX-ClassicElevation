--!strict

local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
assert(RunService:IsStudio() and RunService:IsClient() and RunService:IsRunning(), "Studio client only")
assert(game.PlaceId == 85558151074819 and workspace:GetAttribute("StudGardenTestEnabled") == true, "Explicit owned test required")
local course = workspace.RaceCourse
assert(course:GetAttribute("CourseId") == "stud_garden", "Stud Garden sample required")
local camera = workspace.CurrentCamera
local function packed(value: Vector3): {number} return {value.X, value.Y, value.Z} end
local savedType, savedFrame, savedSubject = camera.CameraType, camera.CFrame, camera.CameraSubject
local samplePosition, sampleLook = script:GetAttribute("SamplePosition"), script:GetAttribute("SampleLookAt")
assert(typeof(samplePosition) == "Vector3" and typeof(sampleLook) == "Vector3", "Explicit sample view required")
local sampleFrame = CFrame.lookAt(samplePosition, sampleLook)
local binding = "StudGardenFrame_" .. script.Name
local function holdView()
	camera.CameraType, camera.CFrame = Enum.CameraType.Scriptable, sampleFrame
end
RunService:BindToRenderStep(binding, Enum.RenderPriority.Last.Value, holdView)
holdView()
task.wait(0.25)
local report: any = {evidence="Short solo Studio rendering sample; not device or multiplayer acceptance", section=script:GetAttribute("Section"),
	build=course:GetAttribute("StudGardenBuild"), layout=course:GetAttribute("LayoutRevision"), art=course.Art:GetAttribute("ArtRevision"),
	clients=#Players:GetPlayers(), viewport={camera.ViewportSize.X,camera.ViewportSize.Y}, cameraPosition=packed(camera.CFrame.Position),
	cameraLook=packed(camera.CFrame.LookVector), cameraType=camera.CameraType.Name, hardware="not measured", foreground="not verified"}
local qualityOk, quality = pcall(function() return tostring(UserSettings().GameSettings.SavedQualityLevel) end)
report.savedQuality = if qualityOk then quality else "unavailable"
local npcCount = 0
for _, model in workspace:GetChildren() do
	if model:GetAttribute("StudGardenCrowdStudy") then
		for _, actor in model:GetChildren() do if actor:IsA("Model") and actor:FindFirstChildOfClass("Humanoid") then npcCount += 1 end end
	end
end
report.physicalNPCs = npcCount
local samples, total = {}, 0
local began = os.clock()
local ok, failure = xpcall(function()
	while os.clock() - began < 10 do
		local dt = RunService.RenderStepped:Wait()
		if dt > 0 then table.insert(samples,dt); total += dt end
	end
	report.cameraEndPosition, report.cameraEndLook = packed(camera.CFrame.Position), packed(camera.CFrame.LookVector)
	report.cameraEndType = camera.CameraType.Name
	report.cameraDriftStuds = (camera.CFrame.Position - samplePosition).Magnitude
end, function(message) return debug.traceback(tostring(message), 2) end)
RunService:UnbindFromRenderStep(binding)
camera.CameraType, camera.CameraSubject, camera.CFrame = savedType, savedSubject, savedFrame
assert(ok, failure)
report.cameraRestored = camera.CameraType == savedType and camera.CameraSubject == savedSubject
table.sort(samples)
assert(#samples > 0, "No rendered frames recorded")
local function percentile(fraction: number): number return samples[math.clamp(math.ceil(#samples*fraction),1,#samples)]*1000 end
report.durationSeconds, report.frames = os.clock()-began, #samples
report.meanFrameMs, report.medianFrameMs, report.p95FrameMs, report.maximumFrameMs = total/#samples*1000, percentile(0.5), percentile(0.95), samples[#samples]*1000
report.meanFPS = #samples/total
report.memoryMb = game:GetService("Stats"):GetTotalMemoryUsageMb()
script:SetAttribute("Complete",true)
local value = Instance.new("StringValue")
value.Name, value.Value, value.Parent = "ResultJSON", Http:JSONEncode(report), script
