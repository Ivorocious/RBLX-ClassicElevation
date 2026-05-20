--!strict

type ServiceContext = {
	Services: { [string]: any },
}

local RespawnService = {}

local isInitialized = false
local isStarted = false

function RespawnService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
	-- TODO: Respawn racers to their latest validated checkpoint after falls.
end

function RespawnService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[RespawnService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	-- TODO: Watch fall volumes or fall threshold once checkpoint state is available.
end

return RespawnService
