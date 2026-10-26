if not game:GetService("RunService"):IsStudio() or game.PlaceId ~= 85558151074819 then return end
local Players = game:GetService("Players")
local owner = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local remote = Instance.new("RemoteFunction")
remote.Name, remote.Parent = "__LobbyFullControllerControl", game.ReplicatedStorage:WaitForChild("Remotes")
local revision = 4000000
local snapshot
local originalGate
remote.OnServerInvoke = function(player, action)
 if player ~= owner then return false end
 if action == "Start" then
  originalGate = owner:GetAttribute("TournamentCourseReady")
  local now = workspace:GetServerTimeNow()
  snapshot = {revision=revision,tournamentId="FULL_CONTROLLER_RESPAWN_FIXTURE",phase="Racing",catalog={},lineup={},raceIndex=1,results={},preparation={token="FULL_CONTROLLER_RESPAWN_FIXTURE",index=1,courseId="NO_FIXTURE_COURSE",status="Presentation",startedAt=now,revealUntil=now+9}}
  owner:SetAttribute("TournamentCourseReady", false)
 elseif action == "Death" then
  owner.Character.Humanoid.Health = 0
  return true
 elseif action == "Fail" then
  snapshot.preparation.status = "Failed"
  owner:SetAttribute("TournamentCourseReady", originalGate)
 elseif action == "Restore" then
  snapshot = require(script.Parent.TournamentService).GetSnapshot(owner)
  owner:SetAttribute("TournamentCourseReady", originalGate)
 else return false end
 revision += 1
 snapshot.revision = revision
 game.ReplicatedStorage.Remotes.TournamentChanged:FireClient(owner, snapshot)
 return true
end
