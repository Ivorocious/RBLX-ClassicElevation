--!nonstrict
local v=Vector3.new
local assets={}
for _,block in {require(script.Parent.EnclosureTerrainDataA),require(script.Parent.EnclosureTerrainDataB)} do for name,meta in block do assets[name]=meta end end
for _,meta in assets do
    if not meta.xs then continue end
    local occupied={}
    for row=1,#meta.zs-1 do
        for column=1,#meta.xs-1 do
            local a=v(meta.xs[column],meta.heights[row][column],meta.zs[row])
            local b=v(meta.xs[column+1],meta.heights[row][column+1],meta.zs[row])
            local c=v(meta.xs[column],meta.heights[row+1][column],meta.zs[row+1])
            local d=v(meta.xs[column+1],meta.heights[row+1][column+1],meta.zs[row+1])
            local triangles=if (row+column)%2==0 then {{a,c,d},{a,d,b}} else {{a,c,b},{b,c,d}}
            for _,top in triangles do
                local low=v(math.min(top[1].X,top[2].X,top[3].X),meta.bottomY,math.min(top[1].Z,top[2].Z,top[3].Z))
                local high=v(math.max(top[1].X,top[2].X,top[3].X),math.max(top[1].Y,top[2].Y,top[3].Y),math.max(top[1].Z,top[2].Z,top[3].Z))
                table.insert(occupied,{low=low,high=high,top=top})
            end
        end
    end
    meta.occupied=occupied
end
return assets
