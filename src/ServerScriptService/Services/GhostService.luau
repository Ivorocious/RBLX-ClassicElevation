--!strict

type ServiceContext = {
	Services: { [string]: any },
}

local GhostService = {}

local isInitialized = false
local isStarted = false

function GhostService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
	-- TODO: Manage finished-player ghost racing without affecting official results.
end

function GhostService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[GhostService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	-- TODO: Apply ghost non-interference rules after collision handling is implemented.
end

return GhostService
