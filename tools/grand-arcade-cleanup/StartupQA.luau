local services=game.ServerScriptService.Services
local service=require(services.GrandArcadeService)
local started=os.clock()
repeat task.wait(.1) until service.IsAvailable() or os.clock()-started>20
assert(service.IsAvailable(),"Grand Arcade service did not bind the installed stage")
local stage=workspace.GrandArcade
repeat task.wait(.1) until stage:FindFirstChild("Presenter") and stage:GetAttribute("TournamentId")~=nil or os.clock()-started>25
assert(stage:FindFirstChild("Presenter"),"Presenter did not start")
assert(stage:GetAttribute("TournamentId")~=nil,"Tournament service did not render")
assert(stage:GetAttribute("GrandArcadeRepair")=="R01")
local slots,ranks,panels=0,0,0
local titles={}
for index=1,5 do
    local bay=assert(stage.Displays:FindFirstChild("Bay"..index))
    assert(bay.MapPanel.Display.Artwork and bay.MapPanel.Display.Fallback)
    assert(bay.MapPanel.Display:FindFirstChild("NeutralCrest"),"Bay was not rendered")
    panels+=1
    titles[index]=bay.Plaque.Display.Title.Text
    for rank=1,3 do
        assert(bay:FindFirstChild("Slot"..rank));slots+=1
        assert(bay:FindFirstChild("Rank"..rank).Display.Finisher);ranks+=1
    end
end
assert(stage.FallReturn.CanTouch)
local connection=workspace.Lobby.GrandArcadeConnection
assert(connection:GetAttribute("Revision")=="C01" and not connection:FindFirstChild("Recovery"))
local parts=0;for _,o in connection:GetDescendants() do if o:IsA("BasePart") then parts+=1 end end
assert(parts==79)
for _,parent in {game.ServerStorage,game.ServerStorage.AssetImports,game.ServerStorage.DeveloperArchives,game.ServerStorage.CourseBuilders,game.ServerStorage.CourseBuilders.LobbyBuilders} do
    for _,o in parent:GetChildren() do assert(not o.Name:lower():find("grandarcade"),"Retired item is still present: "..o:GetFullName()) end
end
return game.HttpService:JSONEncode({ok=true,serviceAvailable=true,presenterStarted=true,tournamentRendered=true,
    panels=panels,slots=slots,rankDisplays=ranks,titles=titles,connectionParts=parts,oldImportsAbsent=true,
    fallReturnTouchEnabled=true,seconds=os.clock()-started,
    scope="Solo Studio startup and normal tournament display render; no fabricated race results or traversal claim"})
