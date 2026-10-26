return function(root,Kit)
    local giants=root.GardenGiants
    assert(not giants:FindFirstChild("GiantGardenBanks"))
    local V,C=Vector3.new,CFrame.new
    local frame=C(root:GetPivot().Position)
    local m=Kit.model(giants,"GiantGardenBanks",frame)
    for _,row in {{"Avatar",-40,-247,183,94},{"Bunny",-228,-40,90,101}} do
        local f=frame*C(row[2],0,row[3])
        for _,layer in {{-8,14,1,"soil"},{-1.6,1.2,1.025,"leaf"},{-.8,.5,1,"grass"}} do
            local lift=if row[1]=="Avatar" and layer[1]>-8 then .55 else 0
            local p=Kit.box(m,row[1].."Bank",f,V(0,layer[1]+lift,0),V(row[4]*layer[3],layer[2],row[5]*layer[3]),layer[4],"Decoration")
            p.Material=Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs
        end
        for _,s in {-1,1} do
            local p=Kit.box(m,row[1].."SoilShoulder",f,V(s*row[4]*.38,-10,0),V(row[4]*.2,17,row[5]*.82),"timber","Decoration")
            p.Material=Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs
        end
    end
    return {parts=#m:GetChildren()}
end
