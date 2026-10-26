local RunService=game:GetService('RunService')
assert(RunService:IsStudio())
local course=assert(workspace:FindFirstChild('RaceCourse'))
assert(course:GetAttribute('ShipwreckBuild')=='SC_MAP_30')
local ocean=course.Decoration.Ocean
game.Players.LocalPlayer:RequestStreamAroundAsync(Vector3.new(-1513,77,11),5)
local camera=workspace.CurrentCamera
camera.CameraType=Enum.CameraType.Scriptable
local lagoon=assert(ocean:WaitForChild('Lagoon30',10))
camera.CFrame=CFrame.lookAt(lagoon.Position+Vector3.new(0,55,85),lagoon.Position)
local sample=assert(ocean:WaitForChild('Current30_00',10))
local heights={}
local minY,maxY=math.huge,-math.huge
local collisionCount=0
for _,p in ocean:GetChildren()do
    assert(p:IsA('BasePart') and p:GetAttribute('OceanMotion'))
    if p.CanCollide or p.CanTouch or p.CanQuery then collisionCount+=1 end
end
for i=1,30 do
    table.insert(heights,sample.Position.Y)
    minY=math.min(minY,sample.Position.Y);maxY=math.max(maxY,sample.Position.Y)
    task.wait(.3)
end
assert(maxY-minY>.05 and maxY-minY<=.241,'Expected bounded subtle vertical animation')
assert(collisionCount==0,'Ocean visuals must not affect gameplay')
local savedName=course.Name
course.Name='__SC30OceanCleanupProbe'
task.wait(.7)
local restored=sample.CFrame
task.wait(.4)
assert(sample.CFrame==restored,'Detached course still animates')
course.Name=savedName
task.wait(.7)
script:SetAttribute('Result',game.HttpService:JSONEncode({build=course:GetAttribute('ReviewBuild'),
    oceanParts=#ocean:GetChildren(),samples=#heights,minY=minY,maxY=maxY,range=maxY-minY,
    collisionCount=collisionCount,detachedCourseStops=true,heights=heights,
    method='Actual Studio client LocalScript sampling live RaceCourse; cosmetic animation only'}))
