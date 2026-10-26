local fs = require("@lune/fs")
local luau = require("@lune/luau")
for _, path in {
	"tools/moonlit-citadel/phase2/R06RouteCommand.server.luau",
	"tools/moonlit-citadel/phase2/R06RouteCommand.client.luau",
	"tools/moonlit-citadel/phase2/SnapshotOwnedNative.luau",
	"tools/moonlit-citadel/phase2/ExtractOwnedNative.luau",
	"tools/moonlit-citadel/phase2/InstallRouteCommands.luau",
} do
	assert(luau.compile(fs.readFile(path)), path)
	print(path .. " compiled")
end
