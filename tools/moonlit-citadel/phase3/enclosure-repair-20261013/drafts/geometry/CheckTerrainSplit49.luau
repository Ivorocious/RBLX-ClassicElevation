local fs,luau,roblox,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local own="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/"
local originalPath="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/landscape/EnclosureGeometry.luau"
local stage="tools/moonlit-citadel/phase3/enclosure-repair-20261013/stage/"
local hashes,cache={},{}
local function read(path)local bytes=fs.readFile(path);hashes[path]=serde.hash("sha256",bytes);return bytes end
local original=luau.load(read(originalPath),{environment={Vector3=roblox.Vector3}})()
local parent=setmetatable({}, {__index=function(_,name)return {moduleName=name} end})
local function load(name)
 if cache[name] then return cache[name] end
 local result=luau.load(read(stage..name..".luau"),{environment={Vector3=roblox.Vector3,script={Parent=parent},require=function(ref)return load(ref.moduleName)end}})()
 cache[name]=result;return result
end
local split=load("EnclosureGeometry")
local failures,stack,leaves={}, {},0
local function mismatch(reason)
 if #failures>=30 then return end
 local keys={};for _,key in stack do table.insert(keys,tostring(key))end
 table.insert(failures,{path=table.concat(keys,"/"),reason=reason})
end
local function compare(a,b)
 if typeof(a)~=typeof(b) then mismatch("Type differs");return end
 if typeof(a)=="Vector3" then leaves+=3;if a~=b then mismatch("Exact Vector3 differs")end;return end
 if type(a)~="table" then leaves+=1;if a~=b then mismatch("Exact value differs")end;return end
 for key,value in a do table.insert(stack,key);compare(value,b[key]);table.remove(stack)end
 for key in b do if a[key]==nil then table.insert(stack,key);mismatch("Added field");table.remove(stack)end end
end
compare(original,split)
local assets,occupied={},0
for name,meta in original do
 local rows=#(meta.occupied or {});occupied+=rows
 table.insert(assets,{name=name,parts=meta.parts,triangles=meta.triangles,occupiedRows=rows})
end
table.sort(assets,function(a,b)return a.name<b.name end)
local report={pass=#failures==0,exactLeafValues=leaves,occupiedRows=occupied,assets=assets,failures=failures,inputHashes=hashes,
 sourcePacketHash="7ee0f410f862b8a4a6f3424eb11dadbeb6311208adba5e4ab4b821db4606ccca",
 scope="Exact full metadata and occupied/top triangle equality; no repeated clearance or native calls"}
fs.writeFile(own.."terrain-split-equality49.json",serde.encode("json",report,true))
print(serde.encode("json",{pass=report.pass,exactLeafValues=leaves,occupiedRows=occupied,failures=failures}))
assert(report.pass,"Data-only terrain split differs from original authored metadata")
