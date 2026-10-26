assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer() and game.PlaceId==85558151074819 and game.GameId==10191126818)
assert(not workspace:FindFirstChild("RaceCourse"), "Do not replace an existing runtime course")
local source=game.ServerStorage.CourseLibrary.Course_CityRun
assert(source.CourseInfo:GetAttribute("CourseId")=="city_run" and source.Start:IsA("BasePart"))
local copy=source:Clone()
copy.Name="RaceCourse"
copy:SetAttribute("KCM04OwnedAmbienceFixture",true)
copy:SetAttribute("KCM04AmbienceFixtureRelocated",true)
for _,item in copy:GetDescendants()do if item:IsA("BaseScript")then item.Disabled=true end end
copy:PivotTo(copy:GetPivot()+Vector3.new(20000,0,0))
local pad=Instance.new("Part")
pad.Name="KCM04OwnedAmbienceLanding"
pad.Anchored=true
pad.Size=Vector3.new(18,1,18)
pad.CFrame=copy.Start.CFrame-Vector3.new(0,1,0)
pad.CanTouch=false
pad.Parent=copy
copy.Parent=workspace
return game.HttpService:JSONEncode({ownedRuntimeCopy=true,start=tostring(copy.Start.Position),source=source:GetFullName(),scriptsInert=true})
