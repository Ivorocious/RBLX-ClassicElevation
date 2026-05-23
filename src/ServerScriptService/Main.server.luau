--!strict

local ServerScriptService = game:GetService("ServerScriptService")

type ServiceModule = {
	Init: ((any) -> ())?,
	Start: ((any) -> ())?,
}

type StartupContext = {
	Services: { [string]: ServiceModule },
}

local SERVICE_NAMES = {
	"PlayerRaceService",
	"ResultsService",
	"StagingService",
	"RaceService",
	"CheckpointService",
	"RespawnService",
	"GhostService",
}

local servicesFolder = ServerScriptService:WaitForChild("Services")
local loadedServices: { [string]: ServiceModule } = {}
local startupContext: StartupContext = {
	Services = loadedServices,
}

local function loadService(serviceName: string): ServiceModule?
	local moduleScript = servicesFolder:FindFirstChild(serviceName)

	if moduleScript == nil or not moduleScript:IsA("ModuleScript") then
		warn(string.format("[Server] Service module %s was not found.", serviceName))
		return nil
	end

	local didRequire, serviceModule = pcall(require, moduleScript)

	if not didRequire then
		warn(string.format("[Server] Failed to require %s: %s", serviceName, tostring(serviceModule)))
		return nil
	end

	if typeof(serviceModule) ~= "table" then
		warn(string.format("[Server] Service %s did not return a table.", serviceName))
		return nil
	end

	return serviceModule :: ServiceModule
end

local function callLifecycleMethod(serviceName: string, service: ServiceModule, methodName: "Init" | "Start")
	local lifecycleMethod = service[methodName]

	if lifecycleMethod == nil then
		return
	end

	local didRun, errorMessage = pcall(lifecycleMethod, startupContext)

	if not didRun then
		warn(string.format("[Server] %s.%s failed: %s", serviceName, methodName, tostring(errorMessage)))
	end
end

for _, serviceName in ipairs(SERVICE_NAMES) do
	local service = loadService(serviceName)

	if service ~= nil then
		loadedServices[serviceName] = service
	end
end

for _, serviceName in ipairs(SERVICE_NAMES) do
	local service = loadedServices[serviceName]

	if service ~= nil then
		callLifecycleMethod(serviceName, service, "Init")
	end
end

for _, serviceName in ipairs(SERVICE_NAMES) do
	local service = loadedServices[serviceName]

	if service ~= nil then
		callLifecycleMethod(serviceName, service, "Start")
	end
end

print("[Server] Project Classic Elevation Phase 2 services bootstrapped.")
