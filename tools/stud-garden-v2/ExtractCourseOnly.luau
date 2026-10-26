local fs=require("@lune/fs")
local process=require("@lune/process")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local fingerprint=require("./Fingerprint")
local roots=roblox.deserializeModel(fs.readFile(assert(process.args[1])))
local course=nil
for _,root in roots do
 if root.Name=="Course_StudGardenV2" then course=root end
end
assert(course,"Course missing from archive")
for _,v in course:GetDescendants() do
 assert(not v:IsA("LuaSourceContainer"),"Geometry-only import cannot include scripts")
end
assert(course.CourseInfo:GetAttribute("Enabled")==false,"Preview must remain disabled")
fs.writeFile(assert(process.args[2]),roblox.serializeModel({course}))
print(serde.encode("json",{name=course.Name,candidate=course:GetAttribute("CandidateId"),scripts=0,geometry=fingerprint(course)}))
