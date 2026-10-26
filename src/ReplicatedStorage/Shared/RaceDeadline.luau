--!strict
local Module = {}
function Module.Seconds(info: any,config: any): number
 local authored = if typeof(info.targetNewPlayerTime) == "number" and info.targetNewPlayerTime > 0
  and info.targetNewPlayerTime < math.huge then info.targetNewPlayerTime else 0
 local evidence = config.CourseTimeLimits[info.courseId]
 local floor = if evidence then evidence.seconds else config.RaceDuration
 return math.clamp(math.max(floor,authored*config.AuthoredDeadlineMultiplier+config.DeadlineRecoverySeconds),
  config.MinimumRaceDuration,config.MaximumRaceDuration)
end
return Module
