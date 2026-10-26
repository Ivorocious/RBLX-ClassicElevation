local root=workspace.CityRunV3AssetReview
assert(not root:FindFirstChild('CityRunV3DistrictAddon01'))
local model=game:GetService('InsertService'):LoadAsset(94105724616140)
model.Name='CityRunV3DistrictAddon01';model.Parent=root
local rows=game:GetService('HttpService'):JSONDecode([==[[{"id":"V3_LoadingFacade","size":[24,14,2.825000047683716],"center":[0,-0.9125000238418579,7],"position":[17600,100,12000]},{"id":"V3_ServiceStock","size":[12.75,4.5,4.550000190734863],"center":[2.625,-0.02499997615814209,2.25],"position":[17636,100,12000]},{"id":"V3_WorksiteHoarding","size":[17,8,2.5999999046325684],"center":[0,0,4],"position":[17672,100,12000]},{"id":"V3_MaterialsStock","size":[10.5,5.099999904632568,8],"center":[-0.25,0,2.549999952316284],"position":[17708,100,12000]},{"id":"V3_ServiceCanopy","size":[24,11.25,12.440000534057617],"center":[0,-0.06999993324279785,5.625],"position":[17744,100,12000]}]]==])
for _,r in rows do
 local p=model:FindFirstChild(r.id,true);assert(p and p:IsA('MeshPart'),r.id)
 local c=r.center;local rot=CFrame.Angles(0,math.pi,0)
 p.Size=Vector3.new(table.unpack(r.size));p.PivotOffset=CFrame.new(c[1],-c[3],-c[2])*rot:Inverse()
 p:PivotTo(CFrame.new(table.unpack(r.position)))
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.DoubleSided=false;p.CastShadow=true
 p:SetAttribute('V3AssetId',r.id);p:SetAttribute('Build','V3_DISTRICT_ADDON_01');p:SetAttribute('VisualOnly',true)
end
return {count=#rows,asset=94105724616140}
