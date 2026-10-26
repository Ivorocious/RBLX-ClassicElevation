local fs,roblox,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local own='tools/moonlit-citadel/phase3/closeout-20261014/verification52/'
local planPath='docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan52.json'
local planRaw=fs.readFile(planPath)
assert(serde.hash('sha256',planRaw)=='3b0e592a6695e70a881d30daaa7bfb27915a60bec6acce75e685358b7a7266c2')
local Oracle=luau.load(fs.readFile(own..'PartAdjustmentOracle52.luau'),{environment={Vector3=roblox.Vector3}})()
local Geometry=luau.load(fs.readFile(own..'GeometryAudit52.luau'),{environment={CFrame=roblox.CFrame,Vector3=roblox.Vector3}})()
local target
for _,unit in serde.decode('json',planRaw).units do if unit.name==Oracle.Unit then target=unit end end
assert(target and Oracle.ValidatePlan({target}).pass)
local libraries={}
local kits='docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/'
for _,library in roblox.deserializeModel(fs.readFile(kits..'enclosure_before_source48_kits.rbxm')) do
 for key,name in Geometry.LibraryNames do if library.Name==name then libraries[key]=library end end
end
libraries.ER01=roblox.deserializeModel(fs.readFile(kits..'enclosure_er01_library_verified.rbxm'))[1]
local template=assert(libraries.TL01:FindFirstChild(target.asset))
local unit=template:Clone();unit.Name=target.name
local cf=roblox.CFrame.new(table.unpack(target.localCF));local scale=roblox.Vector3.new(table.unpack(target.scale))
unit:SetAttribute('MCEditUnit',target.asset);unit:SetAttribute('District',target.district)
unit:SetAttribute('CourseLocalFrame',cf);unit:SetAttribute('AuthorScale',scale)
local meshes=0;local adjusted,sibling,baseSize
for _,part in unit:GetDescendants() do if part:IsA('BasePart') then
 part.CFrame=cf*roblox.CFrame.new(part.CFrame.Position*scale)*part.CFrame.Rotation
 part.Size=part.Size*scale;part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
 if part:IsA('MeshPart') then meshes+=1 end
 if part.Name==Oracle.Part then
  adjusted=part;baseSize=part.Size
  part.CFrame,part.Size=Oracle.Expected(target,part,part.CFrame,part.Size)
 elseif not sibling then sibling=part end
end end
assert(adjusted and sibling)
local course=roblox.Instance.new('Model');course.Name='ScopedSynthetic52'
course:SetAttribute('CourseId','moonlit_citadel');course:SetAttribute('Origin',roblox.Vector3.zero)
course:SetAttribute('SourceRevision',52);course:SetAttribute('BuildRevision',46);course:SetAttribute('SourcePacketHash','80978718783aa23b70cd08d4edb240674ae3e53da827ab396f90ce5d67043617')
local decoration=roblox.Instance.new('Folder');decoration.Name='Decoration';decoration.Parent=course
local world=roblox.Instance.new('Folder');world.Name='Phase3World';world.Parent=decoration
world:SetAttribute('PlanUnits',1);world:SetAttribute('MeshParts',meshes);world:SetAttribute('ArtRepairCandidate','ER01')
local district=roblox.Instance.new('Folder');district.Name=target.district;district.Parent=world;unit.Parent=district
local options={expectedIdentity={source=52,build=46,packet='80978718783aa23b70cd08d4edb240674ae3e53da827ab396f90ce5d67043617'},
 expectedUnits=1,expectedMeshes=meshes,expectedCourses=1,requireSourceGuard=false,adjustmentOracle=Oracle,
 approvedTemplateMetadata=serde.decode('json',fs.readFile('tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/approved-template-metadata49.json'))}
local function audit()return Geometry.Run({course},libraries,{units={target}},options) end
local function rejected(kind)
 local report=audit()
 if report.geometryPass then return false end
 for _,failure in report.failures do if failure.kind==kind then return true end end
 return false
end
local positive=audit();assert(positive.geometryPass,serde.encode('json',positive.failures))
local fixtures={approvedFourPercent=true}
local corrected=adjusted.Size;adjusted.Size=baseSize;fixtures.missingRelief=rejected('PartSize')
adjusted.Size=baseSize*roblox.Vector3.new(1,1,1.02);fixtures.twoPercentRejected=rejected('PartSize');adjusted.Size=corrected
local oldCF=adjusted.CFrame;adjusted.CFrame=oldCF+roblox.Vector3.new(.05,0,0);fixtures.positionCorrectionRejected=rejected('PartFrame');adjusted.CFrame=oldCF
local otherSize=sibling.Size;sibling.Size=otherSize*roblox.Vector3.new(1,1,1.04);fixtures.extraPartResizeRejected=rejected('PartSize');sibling.Size=otherSize
for name,pass in fixtures do assert(pass,name) end
local result={pass=true,scope='Focused single-unit synthetic geometry oracle integration; not a live/native or rendered appearance result',
 fixtures=fixtures,checkedUnits=1,checkedParts=meshes,finalPlan52Bound=true,productionEdited=false,studioTouched=false,
 inputHashes={[planPath]=serde.hash('sha256',planRaw),[own..'GeometryAudit52.luau']=serde.hash('sha256',fs.readFile(own..'GeometryAudit52.luau')),
 [own..'PartAdjustmentOracle52.luau']=serde.hash('sha256',fs.readFile(own..'PartAdjustmentOracle52.luau'))}}
fs.writeFile(own..'geometry-override52-fixtures.json',serde.encode('json',result,true))
print(serde.encode('json',result))
