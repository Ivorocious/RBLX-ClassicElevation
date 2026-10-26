local RunService=game:GetService('RunService')
local HttpService=game:GetService('HttpService')
assert(RunService:IsStudio())
local player=game.Players:GetPlayers()[1]
local original=player.Character
local fixture=game.ServerStorage.CourseLibrary.Course_ShipwreckCove:Clone()
fixture.Name='__SC32CrossbarProbe';fixture:PivotTo(fixture:GetPivot()+Vector3.new(600,0,0));fixture.Parent=workspace
local avatar=Instance.new('Model');avatar.Name='__SC32ContactProbe'
local h=Instance.new('Humanoid');h.Parent=avatar
local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Size=Vector3.new(2,2,1);root.Anchored=true;root.CanCollide=false;root.Parent=avatar
avatar.PrimaryPart=root;avatar.Parent=workspace;player.Character=avatar
local hits={}
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,function(p,reason)table.insert(hits,reason)end,function(p)return p==player end)
local base={}
for _,p in fixture.Obstacles.WalkingSurfaces:GetChildren() do if p.Name:match('^Spar%d+$') then base[p]=p.CFrame end end
local results={build=fixture:GetAttribute('ReviewBuild'),contacts={},solid=true,method='Controlled actual Runtime contact callback using a test Player.Character body box; not human traversal.'}
for i=0,2 do
    local name='ExpertCrossbar32_'..i
    local bar=fixture.Decoration.Obstacles[name]
    local positions={}
    for step=0,20 do
        root.Position=Vector3.new(0,500,0)
        local t=i*10+step*.2
        controller.Step(t,.05,true)
        table.insert(positions,bar.Position.Z)
    end
    root.CFrame=bar.CFrame;table.clear(hits)
    controller.Step(i*10+4,.001,true)
    local inside=table.find(hits,name)~=nil
    root.CFrame=bar.CFrame*CFrame.new(bar.Size.X/2+root.Size.X/2+.1,0,0);table.clear(hits)
    controller.Step(i*10+4,.001,true)
    local outside=table.find(hits,name)==nil
    local minimum,maximum=math.huge,-math.huge
    for _,v in positions do minimum=math.min(minimum,v);maximum=math.max(maximum,v) end
    table.insert(results.contacts,{name=name,inside=inside,outside=outside,travel=maximum-minimum,literalSize=tostring(bar.Size)})
end
for p,cf in base do if p.CFrame~=cf or not p.CanCollide then results.solid=false end end
controller.Stop();player.Character=original;avatar:Destroy();fixture:Destroy()
script:SetAttribute('Result',HttpService:JSONEncode(results))
