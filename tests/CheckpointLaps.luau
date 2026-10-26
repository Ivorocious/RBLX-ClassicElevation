local fs, luau, roblox = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local checks = 0
local function check(value, message) assert(value,message);checks+=1 end
local function signal()
 local listeners={}
 local object={}
 function object:Connect(callback)
  local connection={Connected=true}
  function connection:Disconnect() self.Connected=false end
  table.insert(listeners,{callback=callback,connection=connection})
  return connection
 end
 function object:Fire(...)
  for _,entry in listeners do if entry.connection.Connected then entry.callback(...) end end
 end
 return object
end
local heartbeat=signal()
local character,root,humanoid={},{Position=Vector3.new(0,3,2)},{Health=100}
local player={UserId=1,Name="Racer",Character=character}
function root:IsA(class) return class=="BasePart" end
function character:FindFirstChild(name) return if name=="HumanoidRootPart" then root else nil end
function character:FindFirstChildOfClass(class) return if class=="Humanoid" then humanoid else nil end
function character:GetAttribute() return nil end
local touched={}
function touched:FindFirstAncestorWhichIsA() return character end
local players={PlayerRemoving=signal()}
function players:GetPlayers() return {player} end
function players:GetPlayerFromCharacter(value) return if value==character then player else nil end
local function part(name,frame,size,attributes)
 local p={Name=name,CFrame=frame,Position=frame.Position,Size=size,Touched=signal()}
 function p:GetAttribute(key) return attributes and attributes[key] end
 function p:FindFirstChild() return nil end
 return p
end
local start=part("Start",CFrame.new(80,10,40),Vector3.new(28,2,32),{RespawnCFrame=CFrame.new(76,15,40)})
local finish=part("Finish",CFrame.new(),Vector3.new(28,12,1),{RequireForwardCrossing=true})
local checkpoints={}
for i=1,4 do checkpoints[i]={index=i,name="CP"..i,part=part("CP"..i,CFrame.new(i*10,10,0),Vector3.new(14,1,8))} end
local elapsed,status=0,"Racing"
local result={currentLap=1,requiredLaps=3,nextCheckpointIndex=1,lapTimes={},checkpointSplits={}}
local services={
 RaceService={IsRaceActive=function() return true end,GetCurrentRaceId=function() return "race1" end,GetElapsedRaceTime=function() return elapsed end},
 CourseService={GetActiveCourseModel=function() return {Name="EggRush"} end,GetRaceFormat=function() return "LapBased" end,GetLapCount=function() return 3 end,
  GetStartPart=function() return start end,GetFinishPart=function() return finish end,GetOrderedCheckpoints=function() return checkpoints end},
 PlayerRaceService={IsOfficialRacer=function() return true end,GetPlayerStatus=function() return status end,SetPlayerStatus=function(_,value) status=value end},
 ResultsService={
  UpdateCheckpointProgress=function(_,lap,total,nextIndex) result.currentLap,result.requiredLaps,result.nextCheckpointIndex=lap,total,nextIndex end,
  RecordCheckpointSplit=function(_,index,name,lap,time) table.insert(result.checkpointSplits,{index=index,lap=lap,time=time}) end,
  RecordLapComplete=function(_,lap,time,nextLap) result.lapTimes[lap]=time;result.currentLap=nextLap end,
  RecordFinish=function() return result end,
 },
}
local replicated={Shared={ForwardGate="ForwardGate",RaceConstants="RaceConstants",RaceTypes="RaceTypes"},Config={CheckpointConfig="CheckpointConfig"}}
local workspace={GetServerTimeNow=function() return elapsed end}
local game={ReplicatedStorage=replicated}
function game:GetService(name) return ({Players=players,ReplicatedStorage=replicated,RunService={Heartbeat=heartbeat,IsStudio=function() return true end}})[name] end
local modules={ForwardGate=require("../src/ReplicatedStorage/Shared/ForwardGate"),CheckpointConfig=require("../src/ReplicatedStorage/Config/CheckpointConfig"),
 RaceTypes={},RaceConstants={RaceFormat={LapBased="LapBased",PointToPoint="PointToPoint"},PlayerRaceStatus={Racing="Racing",Finished="Finished"}}}
local service=luau.load(fs.readFile("src/ServerScriptService/Services/CheckpointService.luau"),{environment={game=game,workspace=workspace,Vector3=Vector3,CFrame=CFrame,require=function(key) return assert(modules[key]) end,print=function() end,warn=function() end}})()
service.Init({Services=services});service.Start()
local function cross(a,b)
 root.Position=Vector3.new(0,3,a);elapsed+=.1;heartbeat:Fire(.1)
 root.Position=Vector3.new(0,3,b);elapsed+=.1;heartbeat:Fire(.1)
end
check(service.GetLatestCheckpointIndex(player)==0,"Fresh race recovers at Start")
check(service.GetCheckpointRespawnCFrame(player)==start:GetAttribute("RespawnCFrame"),"Authored Start recovery is used")
cross(1,-1)
check(result.currentLap==1 and next(result.lapTimes)==nil,"Initial forward Start crossing does not award lap")
for lap=1,3 do
 checkpoints[4].part.Touched:Fire(touched)
 check(service.GetLatestCheckpointIndex(player)==0,"Future CP does not change lap start recovery")
 for index=1,4 do
  elapsed+=1;checkpoints[index].part.Touched:Fire(touched)
  check(service.GetLatestCheckpointIndex(player)==index,"Ordered checkpoint accepted")
 end
 cross(-1,1)
 check(result.lapTimes[lap]==nil,"Reverse lap crossing is rejected")
 cross(1,-1)
 check(result.lapTimes[lap]~=nil and #result.lapTimes==lap,"Forward gate records exactly one lap")
 check(#result.checkpointSplits==lap*4,"Only ordered actual checkpoint splits retained")
 if lap<3 then
  check(result.currentLap==lap+1 and result.nextCheckpointIndex==1,"Next lap starts at first required CP")
  check(service.GetLatestCheckpointIndex(player)==0,"Completed lap recovery resets to Start")
  check(service.GetCheckpointRespawnCFrame(player)==start:GetAttribute("RespawnCFrame"),"Next-lap fall targets authored Start")
 else check(status=="Finished","Third lap finishes the racer") end
end

local kit={SetChip=function(chip,text) chip.Text=text end}
local view=luau.load(fs.readFile("src/StarterPlayer/StarterPlayerScripts/Controllers/RaceHudView.luau"),{environment={
 script={Parent={UiKit="UiKit",RacePresentation="RacePresentation"}},require=function(key) return if key=="UiKit" then kit else {} end,
 Vector2=roblox.Vector2,Color3=roblox.Color3,UDim2=roblox.UDim2,
}})()
local hud={lap={},timer={}}
for lap=1,3 do
 view.SetLap(hud,lap,3)
 check(hud.lap.Visible and hud.lap.Text=="LAP "..lap.." / 3","Each server-fed lap has a separate complete label")
 check(hud.timer.Size.Y.Offset==134,"Multi-lap timer reserves lap row space")
end
view.SetLap(hud,1,1)
check(not hud.lap.Visible and hud.timer.Size.Y.Offset==96,"Point-to-point timer keeps its original size")
print(string.format("Checkpoint lap/start and lap HUD: %d checks passed",checks))
