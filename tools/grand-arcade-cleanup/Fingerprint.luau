return function(root, roots, ignored)
    local function number(n)
        return string.format("%.5f", if math.abs(n)<.000005 then 0 else n)
    end
    local function value(v)
        if typeof(v)=="number" then return number(v) end
        if typeof(v)=="CFrame" then
            local components={v:GetComponents()}
            for i,n in components do components[i]=number(n) end
            return table.concat(components,",")
        end
        if typeof(v)=="Vector3" then return number(v.X)..","..number(v.Y)..","..number(v.Z) end
        if typeof(v)=="Color3" then return number(v.R)..","..number(v.G)..","..number(v.B) end
        return tostring(v)
    end
    local function reference(o)
        if not o then return "nil" end
        for _,r in roots do
            if o==r or o:IsDescendantOf(r) then
                return r.ClassName..":"..r.Name.."/"..(if o==r then "." else o:GetFullName():sub(#r:GetFullName()+2))
            end
        end
        return "external:"..o:GetFullName()
    end
    local function hash(rows)
        table.sort(rows)
        local h=2166136261
        for _,row in rows do
            for i=1,#row do
                local x=bit32.bxor(h,string.byte(row,i))
                local low,high=bit32.band(x,65535),bit32.rshift(x,16)
                h=(low*403+bit32.band(low*256+high*403,65535)*65536)%4294967296
            end
        end
        return string.format("%08x",h)
    end
    local result={name=root.Name,class=root.ClassName,instances=0,parts=0,colliders=0,scripts=0,objectReferences=0}
    local rows,geometry={},{}
    local all=root:GetDescendants();table.insert(all,root)
    for _,o in all do
        if ignored and ignored[o] then continue end
        local path=if o==root then "." else o:GetFullName():sub(#root:GetFullName()+2)
        if root.Name=="Lobby" and o.ClassName=="Status" then
            assert(path=="Podium.Slots.First.Avatar.Humanoid.Status" or path=="Podium.Slots.Second.Avatar.Humanoid.Status" or path=="Podium.Slots.Third.Avatar.Humanoid.Status")
            assert(#o:GetChildren()==0 and next(o:GetAttributes())==nil and not o.Archivable)
            continue
        end
        result.instances+=1
        table.insert(rows,path.."/class="..o.ClassName.."/archivable="..tostring(o.Archivable))
        for k,v in o:GetAttributes() do table.insert(rows,path.."/@"..k.."="..value(v)) end
        for _,tag in o:GetTags() do table.insert(rows,path.."/tag="..tag) end
        local props={}
        if o:IsA("BasePart") then
            result.parts+=1
            if o.CanCollide then result.colliders+=1 end
            props={"CFrame","Size","Color","Transparency","Material","MaterialVariant","Reflectance","Anchored","CanCollide","CanTouch","CanQuery","CastShadow","CollisionGroup","Massless","TopSurface","BottomSurface","LeftSurface","RightSurface","FrontSurface","BackSurface"}
        elseif o:IsA("Model") then
            table.insert(rows,path.."/pivot="..value(o:GetPivot()).."/scale="..number(o:GetScale()).."/primary="..reference(o.PrimaryPart))
        elseif o:IsA("LuaSourceContainer") then result.scripts+=1;props={"Source"}
        elseif o:IsA("ObjectValue") then result.objectReferences+=1;table.insert(rows,path.."/value="..reference(o.Value))
        elseif o:IsA("ValueBase") then props={"Value"}
        elseif o:IsA("TextLabel") then props={"Text","TextColor3","Font","TextScaled","TextWrapped","Size","Position","Visible"}
        elseif o:IsA("ImageLabel") then props={"Image","ImageColor3","ImageTransparency","Size","Position","Visible"}
        end
        if o:IsA("MeshPart") then
            for _,key in {"MeshId","TextureID","DoubleSided","RenderFidelity","CollisionFidelity"} do table.insert(props,key) end
        end
        for _,key in props do
            local row=path.."/"..key.."="..value(o[key]);table.insert(rows,row)
            if o:IsA("BasePart") then table.insert(geometry,row) end
        end
    end
    result.contentHash,result.geometryHash=hash(rows),hash(geometry)
    return result
end
