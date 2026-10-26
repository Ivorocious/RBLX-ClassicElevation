local fs = require("@lune/fs")
local luau = require("@lune/luau")
local files = {
	"tools/moonlit-citadel/phase2/R06BuildDraft.luau",
	"tools/moonlit-citadel/phase2/R06PrepareFixture.luau",
	"tools/moonlit-citadel/phase2/R06ClientProbe.luau",
	"docs/artifacts/moonlit-citadel/phase2/revision06/RouteBuilder.luau",
	"docs/artifacts/moonlit-citadel/phase2/revision06/VisualAssembly.luau",
	"docs/artifacts/moonlit-citadel/phase2/revision06/MoonlitCitadelAssemblyConfig.luau",
	"docs/artifacts/moonlit-citadel/phase2/revision06/MoonlitCitadelCourseConfig.luau",
	"docs/artifacts/moonlit-citadel/phase2/revision06/route/R06Layout.luau",
	"docs/artifacts/moonlit-citadel/phase2/revision06/clarity/Wayfinding.luau",
	"docs/artifacts/moonlit-citadel/phase2/revision06/clarity/DecorativeClearance.luau",
	"tools/moonlit-citadel/phase2/R06ClientSuite.luau",
	"tools/moonlit-citadel/phase2/R06Suite.server.luau",
	"tools/moonlit-citadel/phase2/R06Suite.client.luau",
}
for _, path in files do
	assert(luau.load(fs.readFile(path)), "Source did not compile: " .. path)
end
print("R06 draft syntax PASS: " .. #files .. " source files; execution and native checks remain separate")
