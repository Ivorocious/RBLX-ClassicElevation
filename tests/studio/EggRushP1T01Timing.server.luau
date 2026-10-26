--!nonstrict
local RunService, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer(), "Passive native server observation only")
local CourseService = require(game.ServerScriptService.Services.CourseService)
local EggRushService = require(game.ServerScriptService.Services.EggRushService)
local RaceService = require(game.ServerScriptService.Services.RaceService)
local reportName = script:GetAttribute("ReportName") or "R03T01Timing"
assert(not Storage:FindFirstChild(reportName), "Preserve the existing timing report")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = reportName, Storage
stored:SetAttribute("State", "Observing")
local report = {candidateId = "ER_P1_R01", pacingRevision = "T01", ownerApproval = false,
 method = "Passive actual shared runtime clock, states, poses and warnings; virtual admission timestamps never move or control a player",
 requiredRuntimeSeconds = 30.2, maximumWallSeconds = 65, mechanisms = {}, findings = {},
 limits = {
  "Only the report object is authored; no course/player/timing/network/camera writes or runtime lifecycle calls.",
  "Virtual leader/follower and early/late arrivals share the observed global clock; they are not two physical racers or multiplayer proof.",
  "Unchanged geometry and retained motion support reuse of earlier safe-wait geometry evidence; this observer does not prove occupied waiting support, carry or recovery.",
  "Warning playback flags and colors do not prove human audibility or player readability.",
  "No complete-race pacing, all-avatar, arbitrary-arrival or crowd/FPS proof.",
 }}
local vector = function(v) return {v.X, v.Y, v.Z} end
local frame = function(cf) return {cf:GetComponents()} end
local function finding(name, kind, detail)
 if #report.findings < 48 then table.insert(report.findings, {model = name, kind = kind, detail = detail}) end
 report.findingCount = (report.findingCount or 0) + 1
end
local function close(a, b) return math.abs(a - b) < .0001 end
local function schedule(segments, clock, phase)
 local period = 0
 for _, segment in segments do period += segment[1] end
 local q = (clock + phase) % period
 for _, segment in segments do
  if q < segment[1] then
   local alpha = q / segment[1]
   if segment[2] ~= "Rolling" then alpha = alpha * alpha * (3 - 2 * alpha) end
   return segment[2], segment[3] + (segment[4] - segment[3]) * alpha
  end
  q -= segment[1]
 end
 error("No scheduled segment")
end
local function admission(clock, phase, period, window)
 local q = (clock + phase) % period
 local accepted = q >= window.first and q <= window.last - window.needed
 return accepted, if q >= window.first and q <= window.last then window.last - q else 0
end
local records = {}
local ok, failure = xpcall(function()
 local course = assert(CourseService.GetActiveCourse(), "No active course")
 assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("SampleRevision") == 3
  and course:GetAttribute("PacingRevision") == "T01", "Wrong active timing candidate")
 local diagnostics = EggRushService.GetDiagnostics()
 assert(diagnostics.bound and not diagnostics.holding and type(diagnostics.elapsed) == "number", "Runtime must already be running")
 local raceId = RaceService.GetCurrentRaceId()
 report.raceId, report.runtimeStart, report.course = raceId, diagnostics.elapsed, course:GetFullName()
 local function add(name, kind, attrs, segments, travel, axis, angle, window)
  local model = assert(course.Obstacles.Mechanisms:FindFirstChild(name), "Missing " .. name)
  assert(model:GetAttribute("ERMechanism") == kind, "Wrong mechanism kind " .. name)
  for attribute, wanted in attrs do assert(close(assert(model:GetAttribute(attribute)), wanted), name .. " changed " .. attribute) end
  if travel then assert((model:GetAttribute("Travel") - travel).Magnitude < .0001, name .. " changed travel") end
  if axis then assert((model:GetAttribute("RotationAxis") - axis).Magnitude < .0001, name .. " changed axis") end
  local warning = assert(model:FindFirstChild("Warning"))
  assert(warning:IsA("ObjectValue") and warning.Value and warning.Value:IsDescendantOf(course), name .. " warning reference")
  local period = 0
  for _, segment in segments do period += segment[1] end
  local row = {name = name, kind = kind, period = period, phase = attrs.PhaseSeconds, attributes = attrs,
   travel = travel and vector(travel), axis = axis and vector(axis), samples = 0, states = {}, transitions = {},
   completeStateDurations = {}, measuredPeriods = {}, maximumPositionError = 0, maximumBasisError = 0,
   minimumTravel = math.huge, maximumTravel = -math.huge, minimumAngle = math.huge, maximumAngle = -math.huge,
   admissions = {}, warningSamples = 0}
  table.insert(report.mechanisms, row)
  local record = {model = model, row = row, kind = kind, segments = segments, period = period,
   phase = attrs.PhaseSeconds, travel = travel, axis = axis, angle = angle, warning = warning.Value,
   sound = warning.Value:FindFirstChild("WarningSound"), originalCollisions = {}, lastEntries = {}}
  for _, part in model:GetDescendants() do
   if part:IsA("BasePart") then record.originalCollisions[part] = part.CanCollide end
  end
  if kind == "EggRoller" then assert(record.sound, name .. " needs retained warning sound") end
  if window then
   row.admissionPolicy = window
   local firstCycle = math.ceil((report.runtimeStart + record.phase - window.first) / period)
   local start = firstCycle * period + window.first - record.phase
   local last = firstCycle * period + window.last - window.needed - record.phase
   for _, requested in {{"VirtualLeader", start + .1}, {"VirtualFollower", start + .6},
    {"LastSafeMinus.05", last - .05}, {"TooLatePlus.05", last + .05}} do
    local accepted, remaining = admission(requested[2], record.phase, period, window)
    table.insert(row.admissions, {label = requested[1], requestedClock = requested[2], requestedAccepted = accepted,
     requestedRemaining = remaining, syntheticArrival = true})
   end
  end
  table.insert(records, record)
 end
 local eggSegments = {{9.7,"Clear",0,0},{1.3,"Warning",0,0},{3.5,"Rolling",0,1}}
 for i, phase in {8.72, 1.92} do
  add("EggBand" .. i, "EggRoller", {RestSeconds=9.7,WarningSeconds=1.3,MoveSeconds=3.5,RollTurns=2,PhaseSeconds=phase},
   eggSegments, Vector3.new(63.75,0,0), Vector3.new(0,0,-1), nil, {first=0,last=11,needed=if i==1 then 3.05 else 2.15})
 end
 add("SidewaysTray", "Tray", {BoardSeconds=3,WarningSeconds=1.2,MoveSeconds=2.8,ExitSeconds=3.5,ClosingWarningSeconds=1.2,PhaseSeconds=13.09},
  {{3,"Boarding",0,0},{1.2,"DepartureWarning",0,0},{2.8,"Travel",0,1},{3.5,"Exit",1,1},
   {1.2,"ReturnWarning",1,1},{2.8,"Returning",1,0}}, Vector3.new(0,0,21), nil, nil, {first=0,last=4.2,needed=1.1})
 add("GuardianTail", "Tail", {RestSeconds=2.3,WarningSeconds=1.5,MoveSeconds=1.6,FarWaitSeconds=6,ClosingWarningSeconds=1.5,SweepAngleDegrees=50,PhaseSeconds=1.59},
  {{2.3,"Rest",0,0},{1.5,"Warning",0,0},{1.6,"Sweeping",0,1},{6,"FarWait",1,1},
   {1.5,"ReturnWarning",1,1},{1.6,"Returning",1,0}}, nil, Vector3.new(0,-1,0), math.rad(50), {first=5.4,last=12.9,needed=3.4})
 local shellSegments = {{1.8,"Closed",0,0},{1.2,"Warning",0,0},{1.2,"Opening",0,1},{8,"Open",1,1},
  {1.4,"ClosingWarning",1,1},{1.2,"Closing",1,0}}
 for i=1,9 do
  local crown = i > 4
  local index = if crown then i-4 else i
  local phase = if crown then 14.15 elseif i > 2 then 1 else 0
  add((if crown then "CrownLip" else "ShellLip") .. index, "ShellLip",
   {ClosedSeconds=1.8,WarningSeconds=1.2,MoveSeconds=1.2,OpenSeconds=8,ClosingWarningSeconds=1.4,ClosedAngleDegrees=90,PhaseSeconds=phase},
   shellSegments, nil, Vector3.xAxis, math.pi/2,
   if crown and index==1 then {first=4.2,last=13.6,needed=4.8} elseif not crown and (index==1 or index==3)
    then {first=4.2,last=13.6,needed=3.4} else nil)
 end
 assert(#records == 13, "Expected all thirteen actual mechanisms")
 local started, previousClock, lastProgress = os.clock(), diagnostics.elapsed, -1
 report.maximumRuntimeSampleGap = 0
 repeat
  RunService.Heartbeat:Wait()
  diagnostics = EggRushService.GetDiagnostics()
  assert(CourseService.GetActiveCourse() == course and RaceService.GetCurrentRaceId() == raceId, "Course/race changed")
  assert(diagnostics.bound and not diagnostics.holding and type(diagnostics.elapsed) == "number", "Runtime stopped or held")
  local clock = diagnostics.elapsed
  assert(clock >= previousClock, "Shared runtime clock reset")
  report.maximumRuntimeSampleGap = math.max(report.maximumRuntimeSampleGap, clock-previousClock)
  previousClock = clock
  for _, record in records do
   local model, row = record.model, record.row
   assert(model:IsDescendantOf(course), "Mechanism removed")
   local expected, alpha = schedule(record.segments, clock, record.phase)
   local actual, pivot = model:GetAttribute("ERState"), model:GetPivot()
   local transform
   if record.travel then
    transform = CFrame.new(record.travel * alpha)
    if record.kind == "EggRoller" then transform *= CFrame.fromAxisAngle(record.axis, math.pi*4*alpha) end
   else
    transform = CFrame.fromAxisAngle(record.axis, record.angle * (if record.kind=="ShellLip" then 1-alpha else alpha))
   end
   if not record.rest then record.rest = pivot * transform:Inverse();row.inferredRestFrame = frame(record.rest) end
   local predicted = record.rest * transform
   row.maximumPositionError = math.max(row.maximumPositionError, (pivot.Position-predicted.Position).Magnitude)
   row.maximumBasisError = math.max(row.maximumBasisError, 1-pivot.RightVector:Dot(predicted.RightVector), 1-pivot.UpVector:Dot(predicted.UpVector))
   if actual ~= expected and not record.stateMismatch then record.stateMismatch=true;finding(row.name,"StateMismatch",{clock=clock,expected=expected,actual=actual}) end
   row.samples += 1;row.states[actual or "Missing"] = true
   local relative = record.rest:ToObjectSpace(pivot)
   if record.travel then
    local distance = relative.Position:Dot(record.travel.Unit)
    row.minimumTravel, row.maximumTravel = math.min(row.minimumTravel,distance), math.max(row.maximumTravel,distance)
   else
    local _, angle = relative.Rotation:ToAxisAngle()
    row.minimumAngle, row.maximumAngle = math.min(row.minimumAngle,angle), math.max(row.maximumAngle,angle)
   end
   local warning = expected=="Warning" or expected=="DepartureWarning" or expected=="ReturnWarning" or expected=="ClosingWarning"
   if warning then
    row.warningSamples += 1
    if record.warning.Color ~= Color3.fromRGB(255,194,55) and not record.colorMismatch then
     record.colorMismatch=true;finding(row.name,"WarningColor",clock)
    end
   end
   if record.sound and (record.sound.IsPlaying ~= warning or (warning and not record.sound.Looped)) and not record.soundMismatch then
    record.soundMismatch=true;finding(row.name,"WarningPlaybackFlags",{clock=clock,state=actual,playing=record.sound.IsPlaying,looped=record.sound.Looped})
   end
   for part, original in record.originalCollisions do
    if part.CanCollide ~= original and not record.collisionMismatch then record.collisionMismatch=true;finding(row.name,"CollisionFlagChanged",part:GetFullName()) end
    if record.kind=="EggRoller" and part:GetAttribute("ERLethal")==true then
     if (part.Transparency<1) ~= (expected=="Rolling") and not record.visibilityMismatch then
      record.visibilityMismatch=true;finding(row.name,"EggVisibility",{clock=clock,state=actual,transparency=part.Transparency})
     end
    end
   end
   if actual ~= record.lastState then
    if record.lastState and record.entryClock then
     table.insert(row.completeStateDurations,{state=record.lastState,seconds=clock-record.entryClock})
    end
    local previousEntry = record.lastEntries[actual]
    if previousEntry then table.insert(row.measuredPeriods,{state=actual,seconds=clock-previousEntry}) end
    if record.lastState then record.lastEntries[actual] = clock end
    table.insert(row.transitions,{clock=clock,state=actual,pivot=frame(pivot),initialCensored=record.lastState==nil})
    record.entryClock = if record.lastState then clock else nil
    record.lastState = actual
   end
   for _, sample in row.admissions do
    if not sample.observedClock and clock >= sample.requestedClock then
     local accepted, remaining = admission(clock,record.phase,record.period,row.admissionPolicy)
     sample.observedClock,sample.actualState,sample.actualPivot = clock,actual,frame(pivot)
     sample.observedAccepted,sample.observedRemaining,sample.sampleLateBy = accepted,remaining,clock-sample.requestedClock
     sample.boundaryResolved = sample.sampleLateBy < .04
     if sample.boundaryResolved and accepted ~= sample.requestedAccepted then finding(row.name,"AdmissionBoundary",sample.label) end
    end
   end
  end
  report.runtimeEnd,report.wallSeconds = clock,os.clock()-started
  local elapsed = clock-report.runtimeStart
  if math.floor(elapsed) ~= lastProgress then lastProgress=math.floor(elapsed);stored:SetAttribute("RuntimeObserved",elapsed) end
  assert(report.wallSeconds <= report.maximumWallSeconds, "Runtime observation exceeded wall deadline")
 until report.runtimeEnd-report.runtimeStart >= report.requiredRuntimeSeconds
 local timeTolerance = math.max(.045,2*report.maximumRuntimeSampleGap+.005)
 report.timeToleranceSeconds = timeTolerance
 for _, record in records do
  local row = record.row
  for _, segment in record.segments do
   if not row.states[segment[2]] then finding(row.name,"MissingState",segment[2]) end
  end
  for _, interval in row.completeStateDurations do
   for _, segment in record.segments do
    if interval.state==segment[2] and math.abs(interval.seconds-segment[1])>timeTolerance then finding(row.name,"StateDuration",interval) end
   end
  end
  for _, period in row.measuredPeriods do
   if math.abs(period.seconds-record.period)>timeTolerance then finding(row.name,"MeasuredPeriod",period) end
  end
  if #row.measuredPeriods==0 then finding(row.name,"NoCompleteRepeat","Observation did not cover a repeated state entry") end
  if row.maximumPositionError>.04 or row.maximumBasisError>.0001 then finding(row.name,"PoseDisagreement",{position=row.maximumPositionError,basis=row.maximumBasisError}) end
  if record.travel then
   local tolerance = if record.kind=="Tray" then .04 else record.travel.Magnitude/3.5*report.maximumRuntimeSampleGap+.05
   if math.abs(row.minimumTravel)>.04 or math.abs(row.maximumTravel-record.travel.Magnitude)>tolerance then finding(row.name,"TravelExtent",{minimum=row.minimumTravel,maximum=row.maximumTravel,tolerance=tolerance}) end
   row.minimumAngle,row.maximumAngle = nil,nil
  else
   if row.minimumAngle>.001 or math.abs(row.maximumAngle-record.angle)>.001 then finding(row.name,"AngularExtent",{minimum=row.minimumAngle,maximum=row.maximumAngle}) end
   row.minimumTravel,row.maximumTravel = nil,nil
  end
  for _, sample in row.admissions do
   if not sample.observedClock or not sample.boundaryResolved then finding(row.name,"AdmissionSampleInconclusive",sample.label) end
  end
 end
 report.complete = true
end,debug.traceback)
report.failure = if ok then nil else failure
report.ok = ok and report.complete==true and (report.findingCount or 0)==0
-- Failed setup can leave unsampled infinities, which JSON cannot represent.
for _, row in report.mechanisms do
 for _, key in {"minimumTravel","maximumTravel","minimumAngle","maximumAngle"} do
  if row[key] and math.abs(row[key])==math.huge then row[key]=nil end
 end
end
stored.Value = Http:JSONEncode(report)
stored:SetAttribute("State",if report.ok then "Complete" elseif report.complete then "Finding" else "Inconclusive")
