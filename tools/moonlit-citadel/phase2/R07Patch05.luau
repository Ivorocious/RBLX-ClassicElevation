--!nonstrict
return function(rows)
 assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
 assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177)
 local H,E=game.HttpService,game.EncodingService
 local function hash(s)local b=E:ComputeBufferHash(buffer.fromstring(s:gsub("\r\n","\n")),Enum.HashAlgorithm.Sha256);local t={}for i=0,buffer.len(b)-1 do t[#t+1]=string.format("%02x",buffer.readu8(b,i))end return table.concat(t)end
 local recovery=assert(game.ServerStorage.MoonlitR07OriginalRecovery)
 local report={candidate="MC_P2_C01_R07",kind="Two guidance sources and one supported takeoff adjustment; course collision geometry unchanged",sources={},arrows={}}
 for _,r in rows do
  local item=game
  for name in r.instancePath:gmatch("[^/]+")do item=assert(item:FindFirstChild(name),r.instancePath)end
  assert(item:IsA("ModuleScript"));item.Source=r.source;assert(hash(item.Source)==r.sha256)
  report.sources[#report.sources+1]={path=r.instancePath,sha256=r.sha256}
 end
 for _,course in {game.ServerStorage.CourseLibrary.Course_MoonlitCitadel,workspace.Course_MoonlitCitadel}do
  assert(course:GetAttribute("CandidateId")=="MC_P2_C01_R07")
  local approach=course.Obstacles.Lifts.CP04Terrace.Contact
  local target=course.Obstacles.UpperNormalApproach.GateTakeoff.Contact.Position+Vector3.new(0,.5,0)
  local point=approach.CFrame:PointToWorldSpace(Vector3.new(9,approach.Size.Y/2+(approach:GetAttribute("VisualTopOffset")or 0)+.04,5.5))
  local up=approach.CFrame.UpVector
  local d=target-point;d-=up*d:Dot(up);d=d.Unit
  local frame=CFrame.fromMatrix(point,d:Cross(up).Unit,up,-d)
  local folder=course.Decoration.Wayfinding
  local strokes={{"Stem",Vector3.new(0,0,.85),Vector3.new(0,0,-.55)},{"Left",Vector3.new(-.7,0,.1),Vector3.new(0,0,-.85)},{"Right",Vector3.new(.7,0,.1),Vector3.new(0,0,-.85)}}
  for _,s in strokes do
   local item=assert(folder:FindFirstChild("E3_UpperLiftLandingNormalChoice"..s[1]))
   local old={item.CFrame:GetComponents()}
   local a=frame:PointToWorldSpace(s[2]+Vector3.new(0,.028,0));local b=frame:PointToWorldSpace(s[3]+Vector3.new(0,.028,0))
   local f=(b-a).Unit;item.CFrame=CFrame.fromMatrix((a+b)/2,f:Cross(up).Unit,up,-f)
   item:SetAttribute("ArrowForward",d);item:SetAttribute("ArrowTarget",point+d*10)
   report.arrows[#report.arrows+1]={path=item:GetFullName(),before=old,forward={d.X,d.Y,d.Z}}
  end
 end
 recovery:SetAttribute("Patch05Receipt",H:JSONEncode(report))
 return report
end