return function(root)
    local buckets, pairs = {}, {}
    local axes = {Vector3.xAxis, Vector3.yAxis, Vector3.zAxis}
    local function components(v) return {v.X,v.Y,v.Z} end
    for _,p in root:GetDescendants() do
        if not p:IsA("Part") or p.Shape~=Enum.PartType.Block or p.Transparency>.94 then continue end
        local size=components(p.Size)
        for axis=1,3 do for _,sign in {-1,1} do
            local n=p.CFrame:VectorToWorldSpace(axes[axis])*sign
            local u=p.CFrame:VectorToWorldSpace(axes[axis%3+1])
            local v=p.CFrame:VectorToWorldSpace(axes[(axis+1)%3+1])
            local c=p.Position+n*size[axis]/2
            local d=n:Dot(c)
            local key=string.format("%d,%d,%d",math.round(n.X*1000),math.round(n.Y*1000),math.round(n.Z*1000))
            local bins=buckets[key] or {};buckets[key]=bins
            local bin=math.round(d*20)
            local face={part=p,n=n,u=u,v=v,c=c,d=d,hu=size[axis%3+1]/2,hv=size[(axis+1)%3+1]/2}
            for k=bin-1,bin+1 do for _,other in bins[k] or {} do
                if other.part==p or math.abs(other.d-d)>.012 or other.n:Dot(n)<.999999 then continue end
                local delta=c-other.c
                local overlap=true
                local area=math.huge
                for _,a in {u,v,other.u,other.v} do
                    local ar=math.abs(a:Dot(u))*face.hu+math.abs(a:Dot(v))*face.hv
                    local br=math.abs(a:Dot(other.u))*other.hu+math.abs(a:Dot(other.v))*other.hv
                    local length=math.min(2*ar,2*br,ar+br-math.abs(delta:Dot(a)))
                    if length<.12 then overlap=false;break end
                    area=math.min(area,length)
                end
                if overlap then
                    table.insert(pairs,{a=p:GetFullName():sub(#root:GetFullName()+2),b=other.part:GetFullName():sub(#root:GetFullName()+2),
                        normal=components(n),separation=math.abs(other.d-d),minimumOverlap=area,
                        differentColor=p.Color~=other.part.Color,position=components(c-root:GetPivot().Position)})
                end
            end end
            bins[bin]=bins[bin] or {};table.insert(bins[bin],face)
        end end
    end
    table.sort(pairs,function(a,b)return a.minimumOverlap>b.minimumOverlap end)
    return pairs
end
