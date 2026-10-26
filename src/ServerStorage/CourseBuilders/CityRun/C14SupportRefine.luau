--!strict
local Refine = {}
function Refine.Apply(imported)
    assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
    local course=workspace.Course_CityRun
    assert(course:GetAttribute("ReviewBuildId")=="C14_02")
    local source=script.Parent.C14Manifest:Clone()
    local data=require(source)
    source:Destroy()
    assert(data.revision=="C14_03")
    local markers,parts={},{}
    for _,part in imported:GetDescendants() do
        assert(not part:IsA("LuaSourceContainer"))
        if not part:IsA("MeshPart") then continue end
        assert(data.meshes[part.Name] and not parts[part.Name])
        parts[part.Name]=part
        for _,key in {"Origin","Right","Up","Forward"} do
            if part.Name:find("Marker"..key.."__",1,true) then markers[key]=part end
        end
    end
    for name in data.meshes do assert(parts[name],"Missing mesh "..name) end
    imported:ScaleTo(imported:GetScale()*10/(markers.Right.Position-markers.Origin.Position).Magnitude)
    local frame=CFrame.fromMatrix(markers.Origin.Position,(markers.Right.Position-markers.Origin.Position).Unit,
        (markers.Up.Position-markers.Origin.Position).Unit,(markers.Origin.Position-markers.Forward.Position).Unit)
    local archive=Instance.new("Folder")
    archive.Name,archive.Parent="C14_02SupportUnits",game.ServerStorage.CityRun_C14_Archive
    local legacyWall=workspace:FindFirstChild("DepotEast")
    if legacyWall then
        assert(legacyWall:IsA("BasePart") and legacyWall:GetAttribute("InvisibleBoundary")==true)
        legacyWall:SetAttribute("C14OriginalPath",legacyWall:GetFullName())
        legacyWall.Parent=archive
    end
    local units={}
    for name,definition in data.components do
        if name:match("_Brackets$") or name=="C14_ExitLinkPier" then
            local section=course.Obstacles.C14Routes[definition.section]
            local previous=section:FindFirstChild(name)
            if previous then previous.Parent=archive end
            local model=Instance.new("Model")
            model.Name,model.Parent=name,section
            model:SetAttribute("EditableUnit",true)
            model:SetAttribute("C14Role","Scenery")
            model:SetAttribute("Section",definition.section)
            units[name]=model
        elseif definition.role=="Hazard" then
            local unit=course.Obstacles.C14Routes[definition.section][name]
            local part=assert(unit:FindFirstChildWhichIsA("MeshPart"))
            part.CFrame=CFrame.new(unpack(definition.position))
            part.Size=Vector3.new(unpack(definition.size))
            for key,value in definition.attrs do part:SetAttribute(key,value) end
            if definition.attrs.WorldMotionAxis then part:SetAttribute("MotionAxis",definition.attrs.WorldMotionAxis) end
            unit.WorldPivot=part.CFrame
        end
    end
    local count=0
    for name,part in parts do
        local mesh=data.meshes[name]
        local model=units[mesh.component]
        if not model then continue end
        part.CFrame=CFrame.new(3500,0,0)*frame:ToObjectSpace(part.CFrame)
        local color=data.colors[mesh.material]
        part.Color=Color3.new(unpack(color))
        part.Material=if mesh.material=="Stone" then Enum.Material.Concrete else Enum.Material.Metal
        part.TextureID=""
        part.Anchored,part.CanCollide,part.CanTouch,part.CanQuery=true,false,false,false
        part.DoubleSided=true
        part:SetAttribute("SourceTriangles",mesh.triangles)
        part.Parent=model
        count+=1
    end
    for _,model in units do model.WorldPivot=model:GetBoundingBox() end
    local retained=course.Decoration.C14Scenery.RetainedBuildingSupports
    local columns=0
    for _,model in game.ServerStorage.CityRun_C14_Archive.ReplacedRoutes:GetChildren() do
        if model.Name:match("^RoofMainEntry_") then
            for _,part in model:GetChildren() do
                if part:IsA("MeshPart") and part.Name:find("__Stone__",1,true) then
                    local unit=Instance.new("Model")
                    unit.Name,unit.Parent=model.Name.."_Pier",retained
                    part.Parent=unit
                    unit.WorldPivot=part.CFrame
                    unit:SetAttribute("EditableUnit",true)
                    columns+=1
                end
            end
        end
    end
    imported.Parent=archive
    course:SetAttribute("ReviewBuildId",data.revision)
    return {build=data.revision,supportMeshes=count,retainedEntryPiers=columns}
end
return Refine
