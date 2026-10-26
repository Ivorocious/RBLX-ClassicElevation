local root=game.ReplicatedStorage:WaitForChild("GrandArcadeCoordinatorFixture",15)
if not root then return end
local remotes=root:WaitForChild("Remotes")
local ready=remotes:WaitForChild("TournamentStageReady")
remotes:WaitForChild("TournamentChanged").OnClientEvent:Connect(function(snapshot)
 local prep=snapshot.preparation
 if not prep or prep.status=="Failed" then return end
 if root:GetAttribute("Mode")=="NoRender" then return end
 ready:FireServer({token="STALE_TOKEN",step="Ready"})
 if prep.status=="Presentation" then
  game:GetService("RunService").RenderStepped:Wait()
  ready:FireServer({token=prep.token,step="Rendered"})
 elseif (prep.status=="Preparing" or prep.status=="Ready") and root:GetAttribute("Mode")~="NoReady" then
  ready:FireServer({token=prep.token,step="Ready"})
 end
end)
ready:FireServer({step="FixtureConnected"})
-- This acknowledgement only starts the isolated fixture; it never touches production voting.
remotes.GetTournamentState:InvokeServer()
