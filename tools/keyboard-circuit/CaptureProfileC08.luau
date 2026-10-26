local MP = require("@rbx/LibMP")
local snapshot = MP.Control:CaptureToBufferSync()
local session = assert(MP.Session.OpenFromBuffer(snapshot))
local frames, timers = {}, {}
local first, last = session:GetFrameIdMin(), session:GetFrameIdMax()
local scale = session:FetchGlobalDesc().TickToMsCpu
for id = first, last do
    local frame = session:FetchFrameDesc(id)
    table.insert(frames, {id = id, absoluteId = frame.FrameAbsoluteId, ms = (frame.TickEndCpu - frame.TickStartCpu) * scale})
end
local iter = session:CreateLogIterator()
iter:Configure({SkipGpuThreads = true, SkipEvents = true, EmitThreadFrameEnd = true})
local state = iter:GetState()
local function add(id, began, ended)
    local descriptor = session:FetchTimerDesc(id)
    local name = descriptor.TimerName
    if not name:find("KC_") and not name:lower():find("script") and not name:lower():find("surface") then return end
    local item = timers[name] or {inclusiveCpuMs = 0, portions = 0}
    item.inclusiveCpuMs += math.max(0, ended - began) * scale
    item.portions += 1
    timers[name] = item
end
while iter:Step() do
    if state:IsThreadFrameEnd() then
        for depth = state:ThreadStackDepth() - 1, 0, -1 do
            local element = iter:GetCurrentThreadStackElement(depth)
            if element then add(element:EnterTimerId(), element:EnterTimestampFrameLocal(), state:Timestamp()) end
        end
    elseif state:IsExit() and not state:ThreadStackWasOverflowed() then
        local began
        if not state:ThreadStackIsUnderflowed() then
            began = iter:GetCurrentThreadStackElement(state:ThreadStackDepth()):EnterTimestampFrameLocal()
        else
            began = session:FetchFrameDesc(state:FrameId()).TickStartCpu
        end
        add(state:TimerId(), began, state:Timestamp())
    end
end
iter:Dispose()
session:Dispose()
table.sort(frames, function(a, b) return a.ms < b.ms end)
local function percentile(p) return frames[math.max(1, math.ceil(#frames * p))].ms end
return {frames = #frames, frameSpan = {first, last}, medianFrameMs = percentile(.5), p95FrameMs = percentile(.95), timers = timers, limits = "Local Studio CPU snapshot; inclusive timer work can overlap and is not a device or multiplayer FPS gain."}
