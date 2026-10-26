local fs=require("@lune/fs")
local process=require("@lune/process")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local fingerprint=require("./Fingerprint")
local course=roblox.deserializeModel(fs.readFile(assert(process.args[1])))[1]
local result={}
for _,v in course:GetDescendants() do
 if v:IsA("Model") then
  local row=fingerprint(v);row.path=v:GetFullName():sub(#course:GetFullName()+2);table.insert(result,row)
 end
end
fs.writeFile(assert(process.args[2]),serde.encode("json",result,true))
print(#result)
