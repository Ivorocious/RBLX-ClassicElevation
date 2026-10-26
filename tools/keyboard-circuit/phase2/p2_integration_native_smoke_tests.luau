local fs = require("@lune/fs")
local luau = require("@lune/luau")
local checks = 0
local function check(value, message) checks += 1; assert(value, message) end
for _, specification in {
	{"p2_integration_native_server.luau", "KCP2LifecycleServer", true},
	{"p2_integration_native_client.luau", "KCP2LifecycleClient", false},
	{"p2_integration_native_fault.client.luau", "KCP2LoadingFault", false},
} do
	local name, key, server = table.unpack(specification)
	local shared = {KCP2TraversalProbe = {}}
	local controls = {}
	local candidate = {FindFirstChild = function(_, requested) return if requested == "StudioProbeControls" then controls else nil end}
	local workspace = {FindFirstChild = function(_, requested) return if requested == "KeyboardCircuit_P2_C01" then candidate else nil end}
	local services = {
		RunService = {IsStudio = function() return true end, IsServer = function() return server end, IsClient = function() return not server end},
		Players = {LocalPlayer = {}}, Workspace = workspace, HttpService = {}, ContextActionService = {},
	}
	local function denied() error("Installing a fixture must not mutate, spawn work or invoke a case") end
	local environment = setmetatable({
		shared = shared, workspace = workspace,
		game = {GetService = function(_, service) return assert(services[service], service) end},
		RaycastParams = {new = function() return {} end}, Enum = {RaycastFilterType = {Include = 1}},
		Instance = {new = denied}, task = {spawn = denied, defer = denied, wait = denied},
	}, {__index = getfenv()})
	local result = luau.load(fs.readFile("tools/keyboard-circuit/phase2/" .. name), {environment = environment})()
	check(result.installed == true, name .. " installed")
	check(shared[key] and #shared[key].records == 0, name .. " no case started")
	check(shared[key].active ~= true, name .. " no active fixture work")
end
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_integration_native_smoke_receipt.json", require("@lune/serde").encode("json", {
	passed = true, checks = checks, nativeExecuted = false,
	scope = "Prepared fixture installation only in thin mocked services; case functions and Roblox behavior were not executed",
}, true))
print(checks .. " offline fixture-installation checks passed; native cases remain unexecuted")
