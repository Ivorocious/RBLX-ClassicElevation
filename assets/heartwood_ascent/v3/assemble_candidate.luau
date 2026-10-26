local builder=game.ServerStorage.CourseBuilders.HeartwoodAscent
local Config=loadstring(game.ReplicatedStorage.Config.HeartwoodConfig.Source)()
assert(Config.BuildId=="HA_V1_04","Wait for HA04 source synchronization")
local Layout=loadstring(builder.Layout.Source)()
local Manifest=loadstring(builder.ArtManifest.Source)()
local function inject(source,names,arguments)
    for _,name in names do source=source:gsub("local "..name.." = require[^\n]*\n","") end
    return loadstring("return function("..table.concat(names,",")..")\n"..source.."\nend")()(table.unpack(arguments))
end
local Build=inject(builder.Build.Source,{"Config","Layout"},{Config,Layout})
local Art=inject(builder.Art.Source,{"Config","Manifest"},{Config,Manifest})
local library=game.ServerStorage.AssetLibraries.HeartwoodV1HA04
assert(library:GetAttribute("State")=="Complete", "Finish library creation first")
assert(not workspace:FindFirstChild("HeartwoodHA04Precheck"),"Preserve prior precheck")
local course=Build.Create("HeartwoodHA04Precheck",false)
course.Parent=workspace
local ok,result=pcall(Art.Assemble,course,library)
course:SetAttribute("AssemblyState",if ok then "Complete" else "Failed")
assert(ok,tostring(result))
local parts,meshes,collision=0,0,0
for _,p in course:GetDescendants() do
 if p:IsA("BasePart") then parts+=1;if p.CanCollide then collision+=1 end end
 if p:IsA("MeshPart") then meshes+=1 end
end
return {name=course.Name,parts=parts,meshes=meshes,collision=collision,triangles=result}
