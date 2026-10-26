local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")
local files = {
	"src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau",
	"src/ServerScriptService/Services/MoonlitCitadelService.luau",
	"tools/moonlit-citadel/phase2/ClientProbe.luau",
	"tools/moonlit-citadel/phase2/ServerProbe.luau",
	"tools/moonlit-citadel/phase2/CapacityCheck.luau",
	"tools/moonlit-citadel/phase2/Readback.luau",
	"tools/moonlit-citadel/phase2/Compile.luau",
}
local builderDirectory = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
for _, name in fs.readDir(builderDirectory) do
	if name:match("%.luau$") then table.insert(files, builderDirectory .. name) end
end
for _, path in process.args do table.insert(files, path) end
local checked, seen = {}, {}
for _, path in files do
	if seen[path] then continue end
	seen[path] = true
	local source = fs.readFile(path)
	assert(luau.load(source), path)
	table.insert(checked, {path = path, sha256 = serde.hash("sha256", source)})
end
print(serde.encode("json", {compiled = #checked, sources = checked, scope = "New Moonlit Phase2 files plus explicitly requested fixture sources"}, true))
