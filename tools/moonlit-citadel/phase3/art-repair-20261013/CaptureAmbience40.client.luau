local H=game.HttpService local p=game.Players.LocalPlayer local L=game.Lighting
local cfg=require(game.ReplicatedStorage.Config.MoonlitCitadelAmbienceConfig)
local function encode(v) if typeof(v)=="Color3" then return {v.R,v.G,v.B} elseif typeof(v)=="Vector3" then return {v.X,v.Y,v.Z} elseif typeof(v)=="EnumItem" then return v.Name end return v end
local report={lighting={},objects={},phase1={},activeCourse=nil,profileConfig={clock=cfg.Lighting.ClockTime,density=cfg.Atmosphere.Density},sources={}}
for k in cfg.Lighting do report.lighting[k]=encode(L[k]) end
for _,o in L:GetChildren() do local props=nil if o:IsA("Sky") then props={"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","MoonTextureId","SunTextureId","StarCount","CelestialBodiesShown","SkyboxOrientation","SunAngularSize","MoonAngularSize"}
elseif o:IsA("Atmosphere") then props={"Density","Offset","Haze","Glare","Color","Decay"}
elseif o:IsA("ColorCorrectionEffect") then props={"Enabled","Brightness","Contrast","Saturation","TintColor"}
elseif o:IsA("BloomEffect") then props={"Enabled","Intensity","Size","Threshold"}
elseif o:IsA("SunRaysEffect") then props={"Enabled","Intensity","Spread"} end
if props then local row={class=o.ClassName,name=o.Name,properties={}} for _,k in props do row.properties[k]=encode(o[k]) end table.insert(report.objects,row) end end
table.sort(report.objects,function(a,b) if a.class==b.class then return a.name<b.name end return a.class<b.class end)
for _,n in cfg.HideWorkspaceRoots do local root=workspace:FindFirstChild(n) if root then for _,o in root:GetDescendants() do if o:IsA("BasePart") then table.insert(report.phase1,{path=o:GetFullName(),transparency=o.LocalTransparencyModifier}) end end end end
table.sort(report.phase1,function(a,b)return a.path<b.path end)
local course=workspace:FindFirstChild("RaceCourse") local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
if course then report.activeCourse={id=course:GetAttribute("CourseId"),runtime=course:GetAttribute("RuntimeActiveCourse"),night=course:GetAttribute("MoonlitNightAmbience"),source=course:GetAttribute("SourceRevision"),build=course:GetAttribute("BuildRevision"),packet=course:GetAttribute("SourcePacketHash"),lights=0,sounds={},gateAllowed=false}
for _,o in course:GetDescendants() do if o:IsA("Light") and o.Enabled then report.activeCourse.lights+=1 elseif o:IsA("Sound") then table.insert(report.activeCourse.sounds,{name=o.Name,playing=o.IsPlaying,loaded=o.IsLoaded,id=o.SoundId}) end end
if root then report.activeCourse.gateAllowed=require(game.ReplicatedStorage.Shared.MoonlitCitadelAmbienceGate).Allows(course,cfg,root.Position,p.Character:FindFirstChildOfClass("Humanoid")) end end
local controller=p.PlayerScripts:FindFirstChild("ClassicAscentAmbience") report.controller=controller~=nil
report.playerAttrs=p:GetAttributes() report.position=root and {root.Position.X,root.Position.Y,root.Position.Z}
local folder=p.PlayerScripts:FindFirstChild("ArtRepairAmbienceCheck40")
if not folder then folder=Instance.new("Folder");folder.Name,folder.Parent="ArtRepairAmbienceCheck40",p.PlayerScripts end
local snap=Instance.new("StringValue") snap.Name,snap.Value,snap.Parent=STAGE,H:JSONEncode(report),folder
return snap.Value