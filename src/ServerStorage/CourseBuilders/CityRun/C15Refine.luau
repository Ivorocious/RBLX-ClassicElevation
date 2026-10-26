--!strict
local Refine = {}
function Refine.Apply()
 assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
 local c = workspace.Course_CityRun
 assert(c:GetAttribute("ReviewBuildId") == "C15_01")
 local r = c.Obstacles.C15Routes
 for i=1,16 do
  local name=string.format("C15_Post_%02d",i);local d=2*i/18
  local m=r.TerminalPosts[name];m:PivotTo(m:GetPivot()+Vector3.new(0,d,0))
  for _,p in r.TerminalPosts[name.."_Stem"]:GetChildren() do
   if not p:IsA("BasePart") then continue end
   if string.find(p.Name,"__Ink__",1,true) then
    -- Imported stems use a rotated local frame.
    local a=p.CFrame:VectorToObjectSpace(Vector3.yAxis)
    p.Size+=Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z))*d
    p.CFrame+=Vector3.new(0,d/2,0)
   else p.CFrame+=Vector3.new(0,d,0) end
  end
 end
 for _,name in {"C15_Post_17","C15_Post_17_Stem"} do
  local m=r.TerminalPosts[name];m:SetAttribute("C15OriginalPath",m:GetFullName());m.Parent=game.ServerStorage.CityRun_C15_Archive
 end
 for i=0,23 do
  local name=string.format("C15_Corner_%02d",i);local d=Vector3.new(0,1-math.sin(math.pi*i/23),0)
  for _,key in {name,name.."_Brackets"} do local m=r.CornerLedges[key];m:PivotTo(m:GetPivot()+d) end
 end
 for _,p in c.Decoration.C13Terminal.C13_RouteSupport:GetChildren() do
  if p.Name=="C13_ExpertStringer" or string.match(p.Name,"^C13_ExpertPier_") then
   p:SetAttribute("C15OriginalPath",p:GetFullName());p.Parent=game.ServerStorage.CityRun_C15_Archive
  end
 end
 c:SetAttribute("ReviewBuildId","C15_03");c:SetAttribute("VisualReviewPassed",false)
 return "C15_03: post finish clearance and corner endpoint separation"
end
return Refine

