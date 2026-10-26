local fs,luau,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/serde")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/"
local files={"WorldAssemblyDT02MappingDraft.luau","CheckSavedCorrection54.luau","CheckCorrectionClearance54.luau",
    "AuditNative54Adapter.luau","ExtractAfterCorrectionSnapshot.luau"}
local hashes={};for _,name in files do local raw=fs.readFile(own..name);luau.load(raw,{debugName=name});hashes[name]=serde.hash("sha256",raw) end
local result={pass=true,preparedFiles=#files,hashes=hashes,actualCandidateVerified=false,productionEdited=false,original53HelpersModified=false}
fs.writeFile(own.."preparation-syntax54.json",serde.encode("json",result,true).."\n")
print(serde.encode("json",{pass=true,preparedFiles=#files,actualCandidateVerified=false}))
