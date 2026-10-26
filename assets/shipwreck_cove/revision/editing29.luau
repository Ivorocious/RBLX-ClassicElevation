assert(not game:GetService('RunService'):IsRunning(),'Edit mode only')
local course=workspace.Course_ShipwreckCove
assert(course:IsA('Folder') and course:GetAttribute('EditablePiecesVersion')==1)
local clone=course:Clone();clone.Name='__SC29EditingProbe';clone.Parent=game.ServerStorage
local result={build=course:GetAttribute('ReviewBuild'),checks={}}
local ok,err=pcall(function()
 local platforms=clone.EditablePlatforms
 local first=platforms:FindFirstChild('S03_00') or platforms:GetChildren()[1]
 assert(first and first:IsA('Model'))
 local collider=first.PrimaryPart;assert(collider)
 local visual=first:FindFirstChildWhichIsA('MeshPart');assert(visual)
 local relative=collider.CFrame:ToObjectSpace(visual.CFrame)
 local before=collider.Position
 first:PivotTo(first:GetPivot()+Vector3.new(3,2,1))
 assert((collider.Position-before-Vector3.new(3,2,1)).Magnitude<.001)
 assert((collider.CFrame:ToObjectSpace(visual.CFrame).Position-relative.Position).Magnitude<.001)
 result.checks.moveKeepsVisualAndCollision=true
 local second
 for _,piece in platforms:GetChildren() do if piece~=first then second=piece;break end end
 assert(second);local name=second.Name;local count=#platforms:GetChildren()
 second:Destroy();assert(#platforms:GetChildren()==count-1 and first.Parent==platforms)
 result.checks.deleteAffectsOnlyOnePlatform=true
 local runtime=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Authoring).ToRuntime(clone)
 clone=runtime
 assert(runtime:IsA('Model') and runtime.Obstacles.WalkingSurfaces:FindFirstChild(first.Name))
 assert(not runtime.Obstacles.WalkingSurfaces:FindFirstChild(name))
 assert(collider.Parent==runtime.Obstacles.WalkingSurfaces)
 result.checks.runtimeRetainsManualMoveAndDeletion=true
 local arrows=0
 for _,v in course:GetDescendants() do if v.Name:match('^RouteArrow_') then arrows+=1 end end
 assert(arrows<=8);result.arrows=arrows
 for _,zone in {'Surge1','Surge2'} do
  assert(course.Decoration[zone].SurgeWave.Transparency==1)
  assert(course.Decoration[zone].SurgeWater.Transparency==1)
 end
 result.checks.waitingWavesHiddenInEdit=true
 result.platformGroups=#course.EditablePlatforms:GetChildren()
end)
clone:Destroy()
result.passed=ok;result.error=if ok then nil else tostring(err)
return game.HttpService:JSONEncode(result)
