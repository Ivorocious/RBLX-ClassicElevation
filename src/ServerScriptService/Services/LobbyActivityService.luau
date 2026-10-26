--!strict
local Records=require(game.ReplicatedStorage.Shared.LobbySessionRecords)
local Builder=require(game.ServerStorage.CourseBuilders.LobbyBuilders.LobbyAmenities)
local Service={}
local state=Records.New()
local results: any
local amenities: Folder?
local function render()
 if not amenities then return end
 local boards=amenities.Records
 local wins=boards.SessionWins.Display
 local latest=boards.LatestRace.Display
 local leaders=Records.Leaders(state)
 wins.Subtitle.Text=if state.paused then "Session records paused" else "This server"
 wins.Empty.Visible=#leaders==0
 latest.Subtitle.Text=state.latest and state.latest.courseName or ""
 latest.Empty.Text=if state.latest then "No official finishes" else "No completed races yet"
 latest.Empty.Visible=not state.latest or #state.latest.finishers==0
 for index=1,5 do
  for _,entry in {{wins,leaders[index],true},{latest,state.latest and state.latest.finishers[index],false}} do
   local row=entry[1]:FindFirstChild("Row"..index)
   local value=entry[2]
   row.Visible=value~=nil
   if value then
    row.Rank.Text=tostring(if entry[3] then index else value.placement)
    row.Racer.Text=value.displayName
    row.Value.Text=if entry[3] then tostring(value.wins) else Records.Time(value.finishTime)
   end
  end
 end
end
function Service.Init(context: any)
 results=context.Services.ResultsService
 local lobby=workspace:FindFirstChild("Lobby")
 if lobby and lobby:IsA("Model") then amenities=Builder.Ensure(lobby) end
end
function Service.Start() render() end
function Service.RecordCompletedRace(): boolean
 if not results then return false end
 local captured=Records.Capture(state,results.GetCurrentRaceResult())
 if captured then render() end
 return captured
end
return Service
