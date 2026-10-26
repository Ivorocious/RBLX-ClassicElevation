local source=game.ServerStorage.CourseLibrary.SGV2_Phase3_F04
local clone=source:Clone()
local runtime=require(game.ServerStorage.CourseBuilders.StudGardenV2.CourseRuntime)
local before={}
for _,p in clone:GetDescendants() do
 if p:IsA("BasePart") then before[p]={cf=p.CFrame,color=p.Color,transparency=p.Transparency}
 elseif p:IsA("TextLabel") then before[p]={text=p.Text} end
end
local h
local ok,res=xpcall(function()
 h=runtime.Start(clone,function()return false end,function()error("Unexpected fixture recovery")end)
 local started=os.clock()
 repeat task.wait(.02) until (clone.H1_Sprinkler:GetAttribute("Phase")=="Active" and clone.H1_Sprinkler:GetAttribute("PhaseAlpha")>.5 and clone.H2_Fruit:GetAttribute("Phase")=="Active") or os.clock()-started>20
 assert(clone.H1_Sprinkler:GetAttribute("Phase")=="Active" and clone.H2_Fruit:GetAttribute("Phase")=="Active","Both active phases required")
 local diagnostics=h.Diagnostics()
 h.Stop();h=nil
 local checked=0
 for p,b in before do
  if p:IsA("BasePart") then
   assert((p.CFrame.Position-b.cf.Position).Magnitude<.002 and (p.CFrame.RightVector-b.cf.RightVector).Magnitude<.002,p:GetFullName().." transform not restored")
   assert(p.Color==b.color and p.Transparency==b.transparency,p:GetFullName().." visual not restored")
  else assert(p.Text==b.text,p:GetFullName().." text not restored") end
  checked+=1
 end
 for _,haz in {clone.H1_Sprinkler,clone.H2_Fruit} do assert(haz:GetAttribute("RuntimeActive")==nil or haz:GetAttribute("RuntimeActive")==false) end
 h=runtime.Start(clone,function()return false end,function()error("Unexpected restart recovery")end);task.wait(.4);h.Stop();h=nil
 return {ok=true,checked=checked,diagnostics=diagnostics,restarted=true,stoppedDuring="Both hazards Active",scope="Native detached clone Start/Stop/restart with ineligible player callback; original transforms/text/colors restored"}
end,debug.traceback)
if h then h.Stop()end
clone:Destroy()
assert(ok,res)
return res
