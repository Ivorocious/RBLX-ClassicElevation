--!strict
if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("HeartwoodVerificationEnabled") == true then
    require(game.ServerStorage.CourseBuilders.HeartwoodAscent.Verification).Start()
end
