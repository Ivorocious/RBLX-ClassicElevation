--!nonstrict
local Detail = {}
local function frame(row) return if typeof(row)=="CFrame" then row else CFrame.new(table.unpack(row)) end
local function vector(row) return if typeof(row)=="Vector3" then row else Vector3.new(table.unpack(row)) end

function Detail.PrepareVolumes(clearance,layout,config,signs)
    local volumes,seen={},{ }
    for mask=0,7 do for lower=1,2 do for upper=1,2 do
        local selected=table.clone(layout)
        selected.GetRoute=function() return layout.GetRoute({bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0},{lower,upper}) end
        for _,volume in clearance.Prepare(selected,config) do
            local key=volume.reason.."|"..tostring(volume.frame).."|"..tostring(volume.size)
            if not seen[key] then seen[key]=true;table.insert(volumes,volume) end
        end
    end end end
    local views={
        {name="Natural crown southeast",camera={6,155.5,-18},lookAt={38,85,106}},
        {name="Finish centre east",camera={-8,155.5,-30},lookAt={172,124,4}},
        {name="Natural crown arrival",camera={18.7705,154.6667,-42.4292},lookAt={6,155.5,-18}},
    }
    for _,sign in signs or {} do
        local cf=frame(sign.frame)
        local size=vector(sign.size)
        local normal=vector(sign.normal or {0,0,-1})
        local offset=Vector3.new(normal.X*size.X/2,normal.Y*size.Y/2,normal.Z*size.Z/2)
        local target=cf:PointToWorldSpace(offset)
        local camera=cf:PointToWorldSpace(offset+normal*9)
        table.insert(views,{name="Preserved sign "..sign.path,
            camera={camera.X,camera.Y,camera.Z},lookAt={target.X,target.Y,target.Z}})
    end
    clearance.AddImportantViews(volumes,views)
    return volumes,views
end

function Detail.OccupiedRows(plan,metadata)
    local rows,units={},{ }
    for _,data in plan.units or plan do
        if data.library~="DT01" then continue end
        assert(not units[data.name],"Unique new detail unit names required")
        units[data.name]=true
        local info=assert(metadata.assets[data.asset],"Actual detail asset occupied geometry is missing: "..data.asset)
        assert(type(info.occupied)=="table" and #info.occupied>0,"Use measured detail occupied boxes")
        local cf,scale=frame(data.localCF),vector(data.scale)
        assert(scale.X>0 and scale.Y>0 and scale.Z>0,"Detail author scale must be positive")
        for index,occupied in info.occupied do
            local low,high=vector(occupied.low),vector(occupied.high)
            assert(high.X>low.X and high.Y>low.Y and high.Z>low.Z,"Positive occupied box extents required")
            local centre=(low+high)/2
            table.insert(rows,{path=data.district.."/"..data.name.."/occupied"..index,
                frame={ (cf*CFrame.new(centre*scale)):GetComponents() },
                size={((high-low)*scale).X,((high-low)*scale).Y,((high-low)*scale).Z},
                anchored=true,collide=false,query=false,touch=false,transparency=0})
        end
    end
    return rows
end

function Detail.Check(clearance,layout,config,plan,metadata,signs)
    local volumes,views=Detail.PrepareVolumes(clearance,layout,config,signs)
    local rows=Detail.OccupiedRows(plan,metadata)
    local result=clearance.CheckParts(rows,volumes)
    local pass=true
    for _,field in {"blocking","headroom","camera","visibility","invalidContactFlags"} do if #result[field]>0 then pass=false end end
    return {pass=pass,routeCombinations=32,protectedVolumes=#volumes,occupiedRows=#rows,views=views,clearance=result,
        newUnitsOnly=true,wallAttachmentIsNotRejected=true,nativeVisualAcceptance=false,
        boundary="Measured occupied boxes test routes, hazards, follow cameras, landing sight, preserved signs and three accepted crown/arrival corridors. Actual rendered composition remains a native check."}
end
return Detail
