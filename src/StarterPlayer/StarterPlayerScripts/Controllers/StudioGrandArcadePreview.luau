--!strict
local RunService=game:GetService("RunService")
local Artwork=require(game.ReplicatedStorage.Config.VotingArtwork)
local Presentation=require(script.Parent.TournamentPresentation)
local Preview={}
local generation=0
local restore={}
local function clear()
 generation+=1
 Presentation.Stop()
 for _,row in restore do if row.item.Parent then row.item[row.property]=row.value end end
 table.clear(restore)
end
local function change(item,property,value)
 table.insert(restore,{item=item,property=property,value=item[property]});item[property]=value
end
function Preview.Open(kind: string): boolean
 if not RunService:IsStudio() or not workspace:FindFirstChild("GrandArcade") then return false end
 clear()
 local id=generation
 local stage=workspace.GrandArcade
 local rows,lineup={},{}
 for i=1,5 do
  local row=table.clone(Artwork.Reference[i]);row.image=Artwork.Image(row.id);table.insert(rows,row);table.insert(lineup,row.id)
  local bay=stage.Displays:FindFirstChild("Bay"..i)
  change(bay.MapPanel.Display.Artwork,"Image",row.image)
  change(bay.MapPanel.Display.Fallback,"Visible",false)
  change(bay.Plaque.Display.Title,"Text","RACE "..i.."  ·  "..row.name)
 end
 local index=if kind=="Next" then 3 else 1
 local time=workspace:GetServerTimeNow()
 local seconds=if index==1 then 9 else 3
 local snapshot={tournamentId="LOCAL_STAGE_FIXTURE",phase="Racing",catalog=rows,lineup=lineup,raceIndex=index,results={},
  preparation={token="LOCAL_STAGE_FIXTURE_"..id,index=index,courseId=lineup[index],status="Presentation",startedAt=time,revealUntil=time+seconds}}
 Presentation.Start(snapshot,function(_,step)
  if step=="Rendered" and id==generation then
   local p=game.Players.LocalPlayer.PlayerGui:FindFirstChild("TournamentStagePresentation")
   if p then
    local label=Instance.new("TextLabel")
    label.Name,label.Text,label.Font,label.TextSize="FixtureLabel","DEVELOPMENT PREVIEW",Enum.Font.FredokaOne,16
    label.BackgroundTransparency,label.TextColor3,label.Size,label.Position,label.Parent=1,Color3.fromRGB(255,230,157),UDim2.fromOffset(240,26),UDim2.new(.5,-120,1,-28),p
   end
  end
 end)
 task.delay(seconds,function()
  if generation~=id then return end
  if kind=="Failure" then snapshot.preparation.status="Failed";Presentation.Update(snapshot);clear()
  elseif kind=="Slow" then snapshot.preparation.status="Preparing";Presentation.Update(snapshot)
  else clear() end
 end)
 if kind=="Slow" then task.delay(seconds+6,function() if generation==id then clear() end end) end
 return true
end
function Preview.Close() clear() end
return Preview
