--!strict
local Editing={}
function Editing.Apply()
    assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
    local c=workspace.Course_CityRun
    assert(c:GetAttribute("ReviewBuildId")=="C13_02")
    local module=script.Parent.C13Manifest:Clone();module.Parent=script.Parent
    local data=require(module);module:Destroy();assert(data.revision=="C13_03")
    local root=c.Decoration.C13Terminal;local units=root:GetChildren();local assemblies={}
    for _,unit in units do
        local definition=data.components[unit.Name];assert(definition and definition.assembly,unit.Name)
        local name=definition.assembly
        local parent=assemblies[name]
        if not parent then
            parent=Instance.new("Model");parent.Name=name;parent:SetAttribute("EditableAssembly",true);parent.Parent=root;assemblies[name]=parent
        end
        unit.Parent=parent
    end
    local count=0
    for _,assembly in assemblies do assembly.WorldPivot=assembly:GetBoundingBox();count+=1 end
    c:SetAttribute("ReviewBuildId","C13_03")
    return {build="C13_03",assemblies=count,units=#units,descendants=#c:GetDescendants()}
end
return Editing
