assert(game.PlaceId==0 and game.RunService:IsRunning());local course=workspace.RaceCourse;local tools=game.ServerStorage.MoonlitPhase2Tools;local report={candidate=course:GetAttribute("CandidateId"),source="Native server Sound engine playback observations; not human audibility or mix approval",samples={}}
local f=Instance.new("Folder");f.Name="MC_P2_C01_R04_AudioObserved01";f.Parent=game.ServerStorage.MoonlitPhase2Evidence;f:SetAttribute("State","Running")
task.spawn(function()
 local ok,err=xpcall(function()
  local endAt=os.clock()+16
  repeat assert(workspace.RaceCourse==course,"Course changed during audio observation");local row={at=workspace:GetServerTimeNow(),sounds={}}
   for _,s in course:GetDescendants() do if s:IsA("Sound") then table.insert(row.sounds,{path=s:GetFullName(),id=s.SoundId,loaded=s.IsLoaded,playing=s.IsPlaying,pos=s.TimePosition,length=s.TimeLength,volume=s.Volume}) end end
   assert(#row.sounds==7);table.insert(report.samples,row);task.wait(.1)
  until os.clock()>=endAt
 end,debug.traceback)
 report.state=if ok then "Complete" else "Failed";report.failure=if not ok then tostring(err) else nil
 local raw=game.HttpService:JSONEncode(report);f:SetAttribute("JSONBytes",#raw);f:SetAttribute("JSONChunks",math.ceil(#raw/60000))
 for offset=1,#raw,60000 do local v=Instance.new("StringValue");v.Name=string.format("JSON_%03d",math.ceil(offset/60000));v.Value=raw:sub(offset,offset+59999);v.Parent=f end
 f:SetAttribute("State",report.state)
end)
return {path=f:GetFullName(),state="Running"}
