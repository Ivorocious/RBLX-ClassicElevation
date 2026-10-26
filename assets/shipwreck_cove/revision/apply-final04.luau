-- Restore FINAL_03's verified native backup first, then sync current repository scripts with Rojo.
assert(game:GetService('RunService'):IsStudio() and not game:GetService('RunService'):IsRunning(), 'Edit mode required')
assert(game.PlaceId==85558151074819 and game.CreatorId==86069177, 'Wrong experience')
local course=workspace:FindFirstChild('Course_ShipwreckCove')
assert(course, 'Restore the course into Workspace')
if course:GetAttribute('ReviewBuild')=='SC27_FINAL_04' then return 'Already applied' end
assert(course:GetAttribute('ReviewBuild')=='SC27_FINAL_03', 'Expected verified FINAL_03 backup')
assert(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime.Source:find('visible water'), 'Sync FINAL_04 scripts through Rojo first')
local archive=course:Clone()
archive.Name='__SC27Final03BeforeRecoveryPatch'
archive.Parent=game.ServerStorage
for _,name in {'WAIT FOR LOW TIDEFront','WAIT FOR LOW TIDEBack'} do
    local sign=assert(course.RouteMarkers:FindFirstChild(name), name)
    sign.CFrame+=Vector3.new(16,-2.5,0)
end
local water=course.Decoration.H02.SurgeWater
water.TextureID=''
water.Color=Color3.fromRGB(28,145,163)
course:SetAttribute('PlacedVisualTriangles',32880)
course:SetAttribute('ReviewBuild','SC27_FINAL_04')
return 'SC27_FINAL_04 restored; local save still required'
