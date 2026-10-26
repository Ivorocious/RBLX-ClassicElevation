-- Offline clone fixture only; no Studio or production data is changed.
local fs,roblox,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local own="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/"
local Audit=luau.load(fs.readFile(own.."AuditNative49.luau"),{environment={CFrame=roblox.CFrame,Vector3=roblox.Vector3}})()
local library=roblox.deserializeModel(fs.readFile("docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_er01_library_verified.rbxm"))[1]
local course=roblox.Instance.new("Model");course.Name="Course_MoonlitCitadel"
course:SetAttribute("CourseId","moonlit_citadel");course:SetAttribute("Origin",roblox.Vector3.new(4000,300,2600))
course:SetAttribute("SourceRevision",49);course:SetAttribute("BuildRevision",43)
course:SetAttribute("SourcePacketHash","7ee0f410f862b8a4a6f3424eb11dadbeb6311208adba5e4ab4b821db4606ccca")
local decoration=roblox.Instance.new("Folder");decoration.Name,decoration.Parent="Decoration",course
local world=roblox.Instance.new("Folder");world.Name,world.Parent="Phase3World",decoration
local district=roblox.Instance.new("Folder");district.Name,district.Parent="Keep",world
local source=roblox.Instance.new("ModuleScript");source.Name,source.Source="ProtectedFixture","return {accepted=true}"
local template=library.MC_ER_MainKeepShell;local unit=template:Clone();unit.Name,unit.Parent="KeepFixture",district
local scale=roblox.Vector3.new(1.3,.7,.9)
local localCF=roblox.CFrame.new(-8,-38,-30)*roblox.CFrame.Angles(0,math.pi/2,0)
local placement=roblox.CFrame.new(course:GetAttribute("Origin"))*localCF
for _,part in unit:GetDescendants() do if part:IsA("BasePart") then
 local old=part.CFrame;part.Size*=scale;part.CFrame=placement*roblox.CFrame.new(old.Position*scale)*old.Rotation
 part.Anchored,part.CanCollide,part.CanQuery,part.CanTouch=true,false,false,false
end end
unit:SetAttribute("MCEditUnit","MC_ER_MainKeepShell");unit:SetAttribute("District","Keep")
unit:SetAttribute("CourseLocalFrame",localCF);unit:SetAttribute("AuthorScale",scale)
world:SetAttribute("PlanUnits",1);world:SetAttribute("MeshParts",2)
world:SetAttribute("ArtRepairCandidate","ER01")
local plan={{name=unit.Name,district="Keep",asset="MC_ER_MainKeepShell",library="ER01",localCF={localCF:GetComponents()},scale={scale.X,scale.Y,scale.Z}}}
local options={expectedUnits=1,expectedMeshes=2,expectedCourses=1,requiredSources=1,
 approvedTemplateMetadata=serde.decode("json",fs.readFile(own.."approved-template-metadata49.json")),
 sourceChecks={{name="ProtectedFixture",actual=source,expectedSource="return {accepted=true}"}}}
local function run()return Audit.Run({course},{ER01=library},plan,options)end
local good=run();assert(good.pass and good.models[1].checkedParts==2)
local part=unit:FindFirstChildWhichIsA("MeshPart",true)
part.CanCollide=true;local flags=run();assert(not flags.pass);part.CanCollide=false
local oldCF=part.CFrame;part.CFrame=oldCF+roblox.Vector3.new(.01,0,0)
local pose=run();assert(not pose.pass);part.CFrame=oldCF
local oldMesh=part.MeshContent;part.MeshContent=library.MC_AR_MasonryMass:FindFirstChildWhichIsA("MeshPart",true).MeshContent
local mesh=run();assert(not mesh.pass);part.MeshContent=oldMesh
source.Source="return {accepted=false}";local guarded=run();assert(guarded.geometryPass and not guarded.pass)
local report={pass=true,fixtures={validClone=good.pass,contactFlagDetected=not flags.pass,poseChangeDetected=not pose.pass,
 meshChangeDetected=not mesh.pass,protectedSourceChangeDetected=not guarded.pass},studioUsed=false,offlineOnly=true}
fs.writeFile(own.."native-audit-fixtures49.json",serde.encode("json",report,true));print(serde.encode("json",report))
