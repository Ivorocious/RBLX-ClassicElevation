assert(game.PlaceId==85558151074819 and not game:GetService('RunService'):IsRunning())
local ss=game.ServerStorage
local function folder(parent,name)
    local f=parent:FindFirstChild(name)
    if not f then f=Instance.new('Folder');f.Name=name;f.Parent=parent end
    return f
end
local archive=folder(folder(ss,'Archive'),'ShipwreckCove')
local kits=folder(ss.AssetLibraries,'ShipwreckCove')
local inventory={}
local active={__ShipwreckCove_NormalizedKit04='Kit04',__ShipwreckCove_RevisionKit13='Kit13'}
for _,n in {25,26,27,28,29,30,31} do active['__ShipwreckCove_Kit'..n]='Kit'..n end
for _,child in ss:GetChildren() do
    local target,newName
    if active[child.Name] then target=kits;newName=active[child.Name]
    elseif child.Name:match('^__Shipwreck') or child.Name:match('^__SC') or child.Name=='Course_ShipwreckCove' then
        local bucket='Milestones'
        if child.Name:lower():find('export') then bucket='ExportBuffers'
        elseif child.Name:lower():find('source') or child.Name:lower():find('install') or child.Name:lower():find('preparation') or child.Name:lower():find('builder') then bucket='SourceSnapshots'
        elseif child.Name:lower():find('kit') or child.Name:lower():find('raw') or child.Name:lower():find('import') then bucket='ImportHistory'
        elseif child.Name:lower():find('avatar') or child.Name:lower():find('scale') or child.Name:lower():find('toolbox') then bucket='TestFixtures' end
        target=folder(archive,bucket)
    end
    if target then
        local old=child:GetFullName()
        child:SetAttribute('ArchivedFrom',old)
        local name=newName or child.Name;local suffix=1
        while target:FindFirstChild(name) do suffix+=1;name=(newName or child.Name)..'_'..suffix end
        child.Name=name;child.Parent=target
        table.insert(inventory,{from=old,to=child:GetFullName(),descendants=#child:GetDescendants()})
    end
end
for _,name in {'FloatingIslandAnimation','C18RuntimeRunner'} do
    local s=game.ServerScriptService:FindFirstChild(name)
    if s and s:IsA('BaseScript') then
        local old=s:GetFullName();s:SetAttribute('PreviouslyEnabled',s.Enabled);s.Enabled=false
        s.Parent=folder(archive,'LegacyTestScripts')
        table.insert(inventory,{from=old,to=s:GetFullName()})
    end
end
local map=workspace.Course_ShipwreckCove
for _,part in workspace:GetChildren() do
    if part.Name=='CoastBank04' and part:IsA('MeshPart') then
        part:SetAttribute('OwnerPlaced',true);part.Parent=map.Decoration.Scenery
    elseif part.Name=='RouteChevron' and part:IsA('BasePart') then
        part:SetAttribute('OwnerPlaced',true);part.Parent=map.RouteMarkers
    end
end
return inventory
