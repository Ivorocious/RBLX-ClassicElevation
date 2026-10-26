assert(game:GetService('RunService'):IsStudio())
local player=game.Players:GetPlayers()[1]
local original=player.Character
local map=game.ServerStorage.CourseLibrary.Course_ShipwreckCove:Clone()
map.Name='__SC31ContactFixture';map:PivotTo(map:GetPivot()+Vector3.new(0,0,700));map.Parent=workspace
local dummy=Instance.new('Model');dummy.Name='__SC31ContactBody'
local h=Instance.new('Humanoid');h.Parent=dummy
local body=Instance.new('Part');body.Name='HumanoidRootPart';body.Size=Vector3.new(.2,.2,.2);body.Anchored=true;body.CanCollide=false;body.Parent=dummy
dummy.PrimaryPart=body;dummy.Parent=workspace;player.Character=dummy
local hits={}
local runtime=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(map,function(_,reason)table.insert(hits,reason)end,function(p)return p==player end)
runtime.Step(.4,0,false)
local rows={}
for _,hazard in map.Decoration.Obstacles:GetChildren() do
    if not hazard:IsA('BasePart') then continue end
    local row={name=hazard.Name,position=tostring(hazard.Position),outsideHits=0,insideHits=0}
    for axis=1,3 do
        for _,sign in {-1,1} do
            local offset=Vector3.new(if axis==1 then (hazard.Size.X/2+.12)*sign else 0,if axis==2 then (hazard.Size.Y/2+.12)*sign else 0,if axis==3 then (hazard.Size.Z/2+.12)*sign else 0)
            body.CFrame=hazard.CFrame*CFrame.new(offset);table.clear(hits);runtime.Step(.4,0,true)
            row.outsideHits+=#hits
            offset=offset.Unit*(offset.Magnitude-.04)
            body.CFrame=hazard.CFrame*CFrame.new(offset);table.clear(hits);runtime.Step(.4,0,true)
            row.insideHits+=#hits
        end
    end
    row.passed=row.outsideHits==0 and row.insideHits==6
    table.insert(rows,row)
end
runtime.Stop();player.Character=original;dummy:Destroy();map:Destroy()
script:SetAttribute('Result',game.HttpService:JSONEncode({build='SC31_CANDIDATE_06',method='Production Runtime with one 0.2-stud test body, six faces per visible hazard; 0.02-stud separation versus 0.02-stud overlap. Controlled stationary clock, not avatar traversal.',hazards=rows}))
