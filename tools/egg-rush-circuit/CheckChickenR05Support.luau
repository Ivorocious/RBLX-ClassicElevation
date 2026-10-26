--!nonstrict
local archive=game.ServerStorage.EggRushChickenR05_20261026
local fixture=archive.Candidate_ChickenR05_C01:Clone()
fixture.Name="R05_SupportFixture";fixture.Parent=workspace
local m=fixture.Obstacles.Mechanisms.GuardianPeck
local sources=archive.BuildSources_C01
local controller=require(sources.ChickenPeck).Bind(m,fixture,require(sources.GuardianPeck).Sample)
local roost=fixture.Decoration.ChickenRoostR04
for _,p in roost:GetDescendants() do if p:IsA("BasePart")then p.CanQuery=true end end
local query=RaycastParams.new();query.FilterType=Enum.RaycastFilterType.Include;query.FilterDescendantsInstances={roost}
local result={candidate="ER_P2_R05_C01",poses=0,plantedPalms=0,missingSupport=0,maximumSupportGap=0,
 method="Native downward rays beneath planted foot palms over the existing roost; separate visible wedge tip ray"}
local ok,failure=xpcall(function()
 for index=0,105 do
  controller.Advance(0,index*17.25/105,function()end,false)
  result.poses+=1
  for _,foot in {m.Feet.Left,m.Feet.Right} do
   local p=assert(foot:FindFirstChild("Foot-1")or foot:FindFirstChild("Foot1"))
   local bottom=p.Position-Vector3.yAxis*p.Size.Y/2
   if math.abs(bottom.Y-(fixture:GetPivot().Position.Y+16))<.01 then
    result.plantedPalms+=1
    local hit=workspace:Raycast(bottom+Vector3.yAxis*.5,-Vector3.yAxis*4,query)
    if hit then result.maximumSupportGap=math.max(result.maximumSupportGap,math.abs(bottom.Y-hit.Position.Y))else result.missingSupport+=1 end
   end
  end
  if index%10==0 then task.wait()end
 end
 controller.Stop()
 local beak=m.Head.Beak
 assert(beak:IsA("WedgePart"),"Visible pointed beak must retain its primitive")
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={beak}
 local origin=m.Head:GetPivot():PointToWorldSpace(Vector3.new(0,-1.98,-11))
 local hit=workspace:Raycast(origin,m.Head:GetPivot():VectorToWorldSpace(Vector3.new(0,0,4)),ray)
 assert(hit,"Beak tip ray did not hit the visible wedge")
 local localHit=m.Head:GetPivot():PointToObjectSpace(hit.Position)
 result.beakTipSurfaceError=(localHit-Vector3.new(0,-1.98,-9.98)).Magnitude
 assert(result.beakTipSurfaceError<.01,"Native wedge points in the wrong direction")
 assert(result.plantedPalms>=106 and result.missingSupport==0 and result.maximumSupportGap<.01,"Planted feet leave the roost")
end,debug.traceback)
controller.Stop();fixture:Destroy()
result.ok=ok;result.failure=if ok then nil else tostring(failure);result.fixtureRemoved=fixture.Parent==nil
return game.HttpService:JSONEncode(result)
