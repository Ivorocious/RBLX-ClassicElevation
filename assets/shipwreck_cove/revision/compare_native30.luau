local fs=require('@lune/fs')
local roblox=require('@lune/roblox')
local serde=require('@lune/serde')
local function snapshot(path)
    local root=roblox.deserializeModel(fs.readFile(path))[1]
    local rows={}
    for _,p in root:GetDescendants()do
        if p:IsA('BasePart')then
            local values={p:GetFullName(),p.ClassName,tostring(p.CFrame),tostring(p.Size),tostring(p.Color),tostring(p.Transparency),tostring(p.Reflectance),tostring(p.Material),tostring(p.CanCollide),tostring(p.CanQuery),tostring(p.CanTouch)}
            if p:IsA('MeshPart')then
                for _,key in {'MeshId','TextureID','MeshContent','TextureContent'}do
                    local ok,value=pcall(function()return p[key]end)
                    table.insert(values,key..'='..(if ok then tostring(value) else '<not exposed by Lune>'))
                end
            end
            table.insert(rows,table.concat(values,'|'))
        end
    end
    table.sort(rows)
    return table.concat(rows,'\n'),#rows
end
local folder='assets/shipwreck_cove/revision/'
local a,count=snapshot(folder..'SC30_CANDIDATE_03.rbxm')
local b,countB=snapshot(folder..'SC30_CANDIDATE_04.rbxm')
assert(a==b and count==countB,'Geometry or appearance changed')
fs.writeFile('docs/artifacts/shipwreck-cove/review30/c03-c04-geometry.json',serde.encode('json',{from='SC30_CANDIDATE_03',to='SC30_CANDIDATE_04',equal=true,parts=count,properties='Path,class,CFrame,size,color,transparency,reflectance,material,collide/query/touch',meshLimit='Mesh and texture fields compared where exposed by Lune; unchanged Layout and Kit hashes supply additional asset identity evidence.'},true))
print('C03/C04 appearance and collision properties match for '..count..' parts')
