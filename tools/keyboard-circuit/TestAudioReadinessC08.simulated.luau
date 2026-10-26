-- Simulated lifecycle checks only; this script does not connect to Roblox Studio.
-- Run from the repository root with .tools/lune-0.10.5/lune.exe run tools/keyboard-circuit/TestAudioReadinessC08.simulated.luau
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local audioSource = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitAudio.luau")
local configSource = fs.readFile("src/ReplicatedStorage/Config/KeyboardCircuitConfig.luau")
luau.load(audioSource)
luau.load(configSource)
local function world(mode, cancelFails)
 local now, queue, connections, objects, cancelled = 0, {}, {}, {}, {}
 local requests, writes, warnings = 0, 0, {}
 local mockTask = {}
 local function schedule(fn, due)
  local co = coroutine.create(fn)
  table.insert(queue, {thread = co, due = due})
  return co
 end
 mockTask.defer = function(fn) return schedule(fn, now) end
 mockTask.delay = function(seconds, fn) return schedule(fn, now + seconds) end
 mockTask.wait = function(seconds) return coroutine.yield(seconds or 0) end
 mockTask.cancel = function(co)
  if cancelFails then error("controlled cancellation failure") end
  cancelled[co] = true
  coroutine.close(co)
 end
 local methods = {}
 function methods:Destroy()
  self._data.destroyed = true
  self._data.Parent = nil
  self._data.IsPlaying = false
 end
 function methods:Play() self._data.IsPlaying = true end
 function methods:Stop() self._data.IsPlaying = false end
 function methods:FindFirstChild(name)
  for _, object in objects do
   if object.Parent == self and object.Name == name then return object end
  end
  return nil
 end
 local instance = {}
 instance.new = function(className)
  local data = {ClassName = className, IsLoaded = false, TimeLength = 0, IsPlaying = false, SoundId = "", Volume = 0}
  local object = setmetatable({_data = data}, {
   __index = function(_, name) return methods[name] or data[name] end,
   __newindex = function(_, name, value)
    if name == "SoundId" then
     assert(not data.destroyed, "SoundId mutation after destruction")
     writes += 1
     data.IsLoaded, data.TimeLength = false, 0
    end
    data[name] = value
   end,
  })
  table.insert(objects, object)
  return object
 end
 local heartbeat = {}
 function heartbeat:Connect(fn)
  local connection = {Connected = true, callback = fn}
  function connection:Disconnect() self.Connected = false end
  table.insert(connections, connection)
  return connection
 end
 local service = {Heartbeat = heartbeat}
 function service:IsClient() return true end
 local provider = {}
 function provider:PreloadAsync(list)
  requests += 1
  local attempt = requests
  if mode == "exception" and attempt == 1 then error("controlled first preload failure") end
  mockTask.wait(if mode == "stalled" then 100 else .2)
  for _, sound in list do
   if not sound._data.destroyed then
    local missing = sound.Name == "Clicky_up" and (mode == "failed" or (mode == "retry" and attempt == 1))
    sound._data.IsLoaded = not missing
    sound._data.TimeLength = if missing or mode == "zeroDuration" then 0 else .5
   end
  end
 end
 local mockOs = table.clone(os)
 mockOs.clock = function() return now end
 local environment = setmetatable({
  game = {GetService = function(_, name) return if name == "RunService" then service else provider end},
  Instance = instance, task = mockTask, os = mockOs, warn = function(message) table.insert(warnings, message) end,
  NumberRange = {new = function(minimum, maximum) return {Min = minimum, Max = maximum} end},
 }, {__index = getfenv(0)})
 local config = luau.load(configSource, {environment = environment})()
 assert(config.AudioReadyTimeout == 10)
 local folder = instance.new("Folder")
 folder.Parent = {}
 local audio = luau.load(audioSource, {environment = environment})().Start(folder, config)
 local function tick(seconds)
  now += seconds
  for _, connection in connections do
   if connection.Connected then connection.callback() end
  end
  local progress = true
  local resumed = 0
  while progress do
   progress = false
   for index, item in queue do
    if item.due <= now then
     table.remove(queue, index)
     progress = true
     if not cancelled[item.thread] and coroutine.status(item.thread) ~= "dead" then
      local ok, delay = coroutine.resume(item.thread)
      assert(ok, tostring(delay))
      if coroutine.status(item.thread) ~= "dead" then
       item.due = now + math.max(delay or 0, .001)
       table.insert(queue, item)
      end
     end
     resumed += 1
     assert(resumed < 1000, "unbounded resumption loop")
     break
    end
   end
  end
 end
 local function advance(seconds)
  for _ = 1, math.ceil(seconds / .01) do tick(.01) end
 end
 local function spawn(fn) return schedule(fn, now) end
 local function metrics()
  local connected, alive = 0, 0
  for _, connection in connections do if connection.Connected then connected += 1 end end
  for _, object in objects do if object.ClassName == "Sound" and not object._data.destroyed then alive += 1 end end
  return {requests = requests, writes = writes, connected = connected, alive = alive, warnings = #warnings}
 end
 local function loadAll()
  for _, object in objects do
   if object.ClassName == "Sound" and object.Name:find("_") then object._data.IsLoaded, object._data.TimeLength = true, .5 end
  end
 end
 return {audio = audio, config = config, folder = folder, tick = tick, advance = advance, spawn = spawn, metrics = metrics, loadAll = loadAll}
end
local cases = 0
local function pass(name) cases += 1; print("PASS " .. name) end
do
 local w = world("success")
 assert(not w.audio.IsResolved())
 local result
 w.spawn(function() result = w.audio.AwaitReady() end)
 w.advance(.5)
 assert(result and result.state == "ready" and result.loaded == 8 and #result.failed == 0 and result.preloadComplete)
 assert(w.audio.IsResolved() and w.metrics().requests == 1 and w.metrics().connected == 0)
 local d = w.audio.Diagnostics()
 assert(d.maxVoices == 8 and d.totals.played == 0 and d.readiness.state == "ready")
 assert(d.body.Creamy.decay == .12 and d.body.Thocky.wet == -24)
 assert(w.audio.Play("Creamy", "down", w.config.OwnVolume))
 assert(w.audio.Diagnostics().totals.played == 1)
 w.audio.Stop()
 assert(w.audio.Readiness().state == "stopped" and not w.audio.IsResolved() and w.metrics().alive == 0)
 pass("cold success, bounded 8 voices and unchanged body/playback")
end
do
 local w = world("retry")
 w.advance(.6)
 local r = w.audio.Readiness()
 assert(r.state == "ready" and r.retryStarted and w.metrics().requests == 2 and r.loaded == 8)
 assert(w.audio.Diagnostics().audio.Clicky.up.id:find("https://www.roblox.com/asset/", 1, true))
 w.audio.Stop()
 pass("one canonical retry succeeds")
end
do
 local w = world("failed")
 local result
 w.spawn(function() result = w.audio.AwaitReady() end)
 w.advance(.6)
 assert(result and result.state == "degraded" and result.reason == "failed" and result.elapsed < 10)
 assert(result.loaded == 7 and #result.failed == 1 and result.failed[1].family == "Clicky" and result.failed[1].kind == "up")
 assert(result.retryStarted and result.preloadComplete and w.metrics().requests == 2 and w.audio.IsResolved())
 result.failed[1].family = "tampered"
 assert(w.audio.Readiness().failed[1].family == "Clicky")
 w.audio.Stop()
 pass("permanent failure resolves early with isolated failed-clip diagnostics")
end
do
 local w = world("stalled")
 w.advance(10.1)
 local r = w.audio.Readiness()
 assert(r.state == "degraded" and r.reason == "deadline" and r.elapsed >= 10 and r.elapsed < 10.05)
 assert(#r.failed == 8 and w.audio.IsResolved() and w.metrics().connected == 0)
 w.loadAll()
 assert(w.audio.Readiness().state == "degraded" and #w.audio.Readiness().failed == 8)
 assert(w.audio.AwaitReady().state == "degraded" and w.audio.Diagnostics().totals.played == 0)
 w.audio.Stop()
 pass("deadline settles without AwaitReady; late load cannot reset or replay")
end
do
 local w = world("stalled", true)
 w.tick(.01)
 local result
 w.spawn(function() result = w.audio.AwaitReady() end)
 w.tick(.01)
 w.audio.Stop()
 local before = w.metrics().writes
 w.advance(100.2)
 assert(result and result.state == "stopped" and w.audio.Readiness().state == "stopped")
 assert(w.metrics().writes == before and w.metrics().requests == 1 and w.metrics().connected == 0 and w.metrics().alive == 0)
 assert(w.audio.Diagnostics().totals.played == 0)
 pass("Stop during yield; cancellation failure cannot permit module mutations")
end
do
 local w = world("success")
 local result = w.audio.AwaitReady(function() return true end)
 assert(result.state == "cancelled" and w.audio.Readiness().state == "loading")
 w.advance(.5)
 assert(w.audio.IsResolved() and w.audio.Readiness().state == "ready")
 w.audio.Stop()
 pass("caller cancellation is separate from shared readiness")
end
do
 local w = world("exception")
 w.advance(.5)
 local r = w.audio.Readiness()
 assert(r.state == "ready" and r.retryStarted and r.error and w.metrics().requests == 2)
 w.audio.Stop()
 pass("initial preload exception still permits one canonical retry")
end
do
 local w = world("zeroDuration")
 w.advance(.5)
 local r = w.audio.Readiness()
 assert(r.state == "degraded" and #r.failed == 8 and w.metrics().requests == 2)
 w.audio.Stop()
 pass("IsLoaded alone cannot pass zero-duration clips")
end
do
 local w = world("success")
 local result
 w.spawn(function() result = w.audio.AwaitReady() end)
 w.folder.Parent = nil
 w.tick(.01)
 assert(result and result.state == "stopped" and result.reason == "removed" and not w.audio.IsResolved())
 w.audio.Stop()
 pass("removed owner folder cancels entry waiting")
end
do
 local w = world("success")
 w.advance(.5)
 w.audio.Audition("Creamy")
 local before = w.audio.Diagnostics().totals.played
 w.audio.Stop()
 w.advance(.3)
 assert(w.audio.Diagnostics().totals.played == before)
 w.audio.Stop()
 assert(w.metrics().alive == 0)
 pass("audition delayed release and repeated Stop remain safe")
end
print("Audio readiness syntax + " .. cases .. " focused simulated lifecycle cases passed; native loading/playback still requires Studio verification")

