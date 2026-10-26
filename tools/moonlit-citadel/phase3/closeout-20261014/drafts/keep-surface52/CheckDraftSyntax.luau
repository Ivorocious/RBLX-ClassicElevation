local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local base = "tools/moonlit-citadel/phase3/closeout-20261014/drafts/keep-surface52/"
local files = {"SceneryRevisions.luau", "WorldAssembly.luau"}
for _, name in files do
    luau.load(fs.readFile(base .. name), {debugName = name})
end
local report = {pass = true, compiledFiles = files, execution = false, studioTouched = false}
fs.writeFile(base .. "draft-syntax-check.json", serde.encode("json", report, true) .. "\n")
print(serde.encode("json", report))
