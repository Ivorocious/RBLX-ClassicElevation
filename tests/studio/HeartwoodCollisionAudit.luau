return function(course)
    local origin=course.Bounds.CourseOrigin.Position
    local art=course.Decoration.HeartwoodArt
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={art};params.RespectCanCollide=true
    local blockers,ghosts,checked={}, {}, 0
    local function check(surface,plane,owner)
        for _,f in {Vector3.zero,Vector3.new(.35,0,0),Vector3.new(-.35,0,0),Vector3.new(0,0,.35),Vector3.new(0,0,-.35)} do
            local pt=surface.CFrame:PointToWorldSpace(Vector3.new(f.X*surface.Size.X,0,f.Z*surface.Size.Z))
            local y=if plane then plane.Y else surface.Position.Y+surface.Size.Y/2
            local hit=workspace:Raycast(Vector3.new(pt.X,y+7.5,pt.Z),Vector3.new(0,-7.3,0),params)
            checked+=1
            if hit then table.insert(blockers,{surface=owner,part=hit.Instance:GetFullName(),floor=y-origin.Y,hit=hit.Position.Y-origin.Y,point={pt.X-origin.X,pt.Z-origin.Z}}) end
        end
    end
    for _,p in course.Decoration:GetDescendants() do
        if p:IsA("BasePart") and p.Name:find("Prototype",1,true) then
            if p.CanCollide or p.CanQuery then table.insert(ghosts,p:GetFullName()) end
        end
        if p:IsA("BasePart") and p.Name=="Top" then check(p,p.Parent:GetAttribute("LocalTop")+origin,p.Parent.Name) end
    end
    for _,flower in course.Decoration.S04_SanctuaryBough.Blooms:GetChildren() do
        check(flower.Center,flower:GetAttribute("LocalTop")+origin,flower.Name)
    end
    return {build=course:GetAttribute("HeartwoodBuild"),checked=checked,blockers=blockers,ghosts=ghosts,
        scope="Five body-height vertical collision samples per footing/flower; does not prove all edges or flight clearance."}
end
