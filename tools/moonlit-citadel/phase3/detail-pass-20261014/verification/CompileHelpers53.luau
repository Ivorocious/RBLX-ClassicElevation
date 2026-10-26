local fs,luau,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/serde")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/"
local files={"CaptureSnapshot53.luau","CompareSnapshots53.luau","DetailClearance53.luau","AuditNative53.luau",
    "CheckSavedDetail53.luau","CheckDetailClearance53.luau","ExtractSnapshotCache53.luau","CheckCapture53.luau","CompareSourceGuard53.luau"}
local hashes={};for _,name in files do local raw=fs.readFile(own..name);luau.load(raw,{debugName=name});hashes[name]=serde.hash("sha256",raw) end
local result={pass=true,compiled=#files,hashes=hashes,productionEdited=false,studioTouched=false}
fs.writeFile(own.."helper-syntax53.json",serde.encode("json",result,true).."\n")
print(serde.encode("json",{pass=true,compiled=#files}))
