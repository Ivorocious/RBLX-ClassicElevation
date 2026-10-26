assert(game:GetService("RunService"):IsClient())
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Probe = {results = {}, active = false}
local fields = {"FrameTime", "RenderCPUFrameTime", "RenderGPUFrameTime", "HeartbeatTime", "PhysicsStepTime", "SceneDrawcallCount", "SceneTriangleCount", "UI2DDrawcallCount", "UI3DDrawcallCount", "InstanceCount", "PrimitivesCount", "MovingPrimitivesCount", "ContactsCount", "DataReceiveKbps", "DataSendKbps", "PhysicsReceiveKbps", "PhysicsSendKbps"}
local function summarize(values)
 if #values == 0 then return {available = false} end
 table.sort(values)
 local sum = 0
 for _, value in values do sum += value end
 return {available = true, samples = #values, mean = sum / #values, p50 = values[math.max(1, math.ceil(#values * .5))], p95 = values[math.max(1, math.ceil(#values * .95))], maximum = values[#values]}
end
function Probe.Capture(label, seconds)
 assert(not Probe.active, "A capture is already running")
 Probe.active = true
 local row = {label = label, candidate = "KC_P2_C01", clientCount = #game.Players:GetPlayers(), viewport = {workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y}, engine = {}, renderIntervals = {}, started = os.clock(), fullPlaceIncluded = true}
 table.insert(Probe.results, row)
 task.spawn(function()
  local values = {}
  for _, field in fields do values[field] = {} end
  local intervals = {}
  local connection = RunService.RenderStepped:Connect(function(dt) table.insert(intervals, dt) end)
  local last = -math.huge
  while os.clock() - row.started < seconds do
   if os.clock() - last >= .1 then
    last = os.clock()
    for _, field in fields do
     local ok, value = pcall(function() return Stats[field] end)
     if ok and type(value) == "number" and value == value and value < math.huge then table.insert(values[field], value) end
    end
   end
   task.wait(.02)
  end
  connection:Disconnect()
  for _, field in fields do row.engine[field] = summarize(values[field]) end
  row.renderIntervals = summarize(intervals)
  local ok, memory = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
  row.totalSessionMemoryMb = if ok then memory else nil
  row.memoryTrackingEnabled = Stats.MemoryTrackingEnabled
  row.categoriesMb = {}
  if Stats.MemoryTrackingEnabled then
   for _, tag in Enum.DeveloperMemoryTag:GetEnumItems() do
    local success, value = pcall(function() return Stats:GetMemoryUsageMbForTag(tag) end)
    if success then row.categoriesMb[tag.Name] = value end
   end
  end
  row.elapsed, row.finished, Probe.active = os.clock() - row.started, true, false
 end)
 return {started = true, label = label, seconds = seconds, boundary = "Local Studio client/full-place engine metrics; no course-only attribution, improvement percentage, physical-device or intended-crowd capacity proof"}
end
shared.KCP2Performance = Probe
return {installed = true}
