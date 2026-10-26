--!nonstrict
local Variants = {LibraryName="MoonlitCitadel_Surface_SR02Library", AssetId=99796608028640}
local variants = {
    ["rbxassetid://74777192495639"]={asset="MC_AR_GalleryBody46", material="Stone", name="MC_AR_GalleryBody46__Stone", meshId="rbxassetid://110675077090500", beforeTriangles=72, triangles=85},
    ["rbxassetid://118738378150073"]={asset="MC_AR_GalleryBody46", material="StoneLight", name="MC_AR_GalleryBody46__StoneLight", meshId="rbxassetid://130321844193232", beforeTriangles=324, triangles=332},
    ["rbxassetid://106822859589956"]={asset="MC_ER_LanternBracket", material="Stone", name="MC_ER_LanternBracket__Stone", meshId="rbxassetid://103505608210895", beforeTriangles=24, triangles=32},
    ["rbxassetid://95347984279384"]={asset="MC_GuideIron", material="Iron", name="MC_GuideIron__Iron", meshId="rbxassetid://94053570210534", beforeTriangles=132, triangles=160},
    ["rbxassetid://125835125733789"]={asset="MC_P3_SlateGable", material="StoneLight", name="MC_P3_SlateGable__StoneLight", meshId="rbxassetid://74254182455173", beforeTriangles=144, triangles=156},
    ["rbxassetid://91450645007176"]={asset="MC_WeightIron", material="Iron", name="MC_WeightIron__Iron", meshId="rbxassetid://74196985263519", beforeTriangles=48, triangles=72},
    ["rbxassetid://118114614682002"]={asset="MC_WindowTracery", material="Lead", name="MC_WindowTracery__Lead", meshId="rbxassetid://135492025140978", beforeTriangles=1312, triangles=1340},
}
local assetDeltas = {}
for _,row in variants do assetDeltas[row.asset]=(assetDeltas[row.asset] or 0)+row.triangles-row.beforeTriangles end

function Variants.WithGeometry(source)
    local result=table.clone(source)
    for asset,delta in assetDeltas do
        if result[asset] then
            local row=table.clone(result[asset])
            row.triangles += delta
            result[asset]=row
        end
    end
    return result
end

function Variants.Apply(root, expected)
    local library=assert(game.ServerStorage.CourseAssetKits:FindFirstChild(Variants.LibraryName), "Install the verified surface repair library")
    assert(library:GetAttribute("ImportVerified") and library:GetAttribute("AxisVerified"), "Verify native surface repair faces")
    local prepared={}
    for _,part in root:GetDescendants() do
        if not part:IsA("MeshPart") then continue end
        local row=variants[part.MeshId]
        if not row then continue end
        assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,
            "Surface replacement must remain outside gameplay contact: "..part:GetFullName())
        local expectedTriangles=if row.asset=="MC_GuideIron" or row.asset=="MC_WeightIron" or row.asset=="MC_WindowTracery" then nil else row.beforeTriangles
        assert(part:GetAttribute("SourceAsset")==row.asset and part:GetAttribute("SourceMaterial")==row.material
            and part:GetAttribute("SourceTriangles")==expectedTriangles, "Surface replacement provenance differs")
        local template=assert(library:FindFirstChild(row.name))
        assert(template:IsA("MeshPart") and template.MeshId==row.meshId and template:GetAttribute("SourceTriangles")==row.triangles,
            "Surface template differs")
        table.insert(prepared,{part=part,template=template,row=row})
    end
    assert(not expected or #prepared==expected, "Surface replacement count differs")
    for _,entry in prepared do
        local part=entry.part
        local frame,size,texture=part.CFrame,part.Size,part.TextureID
        local render,shadow,double=part.RenderFidelity,part.CastShadow,part.DoubleSided
        part:ApplyMesh(entry.template)
        part.CFrame,part.Size,part.TextureID=frame,size,texture
        part.RenderFidelity,part.CastShadow,part.DoubleSided=render,shadow,double
        if part:GetAttribute("SourceTriangles")~=nil then part:SetAttribute("SourceTriangles",entry.row.triangles) end
        assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch)
    end
    return #prepared
end

return Variants

