--!strict
local SolidGround = {}
local groundNames = {ConnectedShoreBank=true, ShoreEntry28=true}
for i=0,5 do groundNames['Beach'..i]=true end
for i=0,2 do groundNames['ShoreDuneFacet'..i]=true end

function SolidGround.IsLegacyStrip(name: string): boolean
    return name:match('^S04_Shore_0[2-6]$') ~= nil or name:match('^ShoreWalk[2-5]$') ~= nil or name=='ShoreEntry28'
end

function SolidGround.Apply(course: Instance)
    local templates=require(script.Parent.AssetLibrary).Find('Kit31')
    assert(templates, 'Missing precise shoreline collision templates')
    local count=0
    for _,part in course:GetDescendants() do
        if part:IsA('MeshPart') and groundNames[part.Name] then
            local template=templates:FindFirstChild(part:GetAttribute('Asset'))
            assert(template and template:IsA('MeshPart'), 'Missing shoreline mesh template')
            local size,cf,texture=part.Size,part.CFrame,part.TextureID
            part:ApplyMesh(template)
            part.Size=size;part.CFrame=cf;part.TextureID=texture
            part.CanCollide=true;part.CanQuery=true;part.CanTouch=false
            part:SetAttribute('SolidGround',true)
            part:SetAttribute('EditingHint','The visible mesh is the walking surface; move or delete this piece directly.')
            count+=1
        elseif part:IsA('Part') and SolidGround.IsLegacyStrip(part.Name) then
            part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
            part:SetAttribute('RouteReferenceOnly',true)
        end
    end
    local bank=course.Decoration.Scenery:FindFirstChild('ConnectedShoreBank',true)
    if bank and bank:IsA('MeshPart') then
        if bank.Parent.Name=='SolidShoreBank' then
            bank.CanCollide=false;bank.CanQuery=false
            return count
        end
        local geometry=require(script.Parent.ShoreGeometry)
        local row
        for _,entry in geometry do if entry.name=='ConnectedShoreBank' then row=entry;break end end
        assert(row)
        local group=Instance.new('Model');group.Name='SolidShoreBank';group.Parent=bank.Parent
        bank.Parent=group;bank.CanCollide=false;bank.CanQuery=false
        group.PrimaryPart=bank
        group:SetAttribute('EditingHint','Move this bank model to move the sand and its fitted collision together.')
        local origin=course.Bounds:FindFirstChild('CourseOrigin')
        local cf=if origin then origin.CFrame else CFrame.new(Vector3.new(unpack(require(script.Parent.Layout).origin)))
        for index,tri in row.triangles do
            local a,b,c=cf:PointToWorldSpace(Vector3.new(unpack(tri[1]))),cf:PointToWorldSpace(Vector3.new(unpack(tri[2]))),cf:PointToWorldSpace(Vector3.new(unpack(tri[3])))
            local ab,ac,bc=b-a,c-a,c-b
            if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
            elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
            ab,ac,bc=b-a,c-a,c-b
            local right=ac:Cross(ab).Unit
            local back=bc.Unit
            local up=bc:Cross(right).Unit
            local height=math.abs(ab:Dot(up))
            for side,values in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
                if values[4]<.01 or height<.01 then continue end
                local wedge=Instance.new('WedgePart');wedge.Name='Ground_'..index..'_'..side
                wedge.Size=Vector3.new(.06,height,values[4])
                wedge.CFrame=CFrame.fromMatrix(values[1],values[2],up,values[3])
                wedge.Anchored=true;wedge.Transparency=1;wedge.CanCollide=true;wedge.CanQuery=true
                wedge.CanTouch=false;wedge.CastShadow=false;wedge.Locked=true
                wedge:SetAttribute('SolidGround',true);wedge.Parent=group
            end
        end
    end
    return count
end

return SolidGround
