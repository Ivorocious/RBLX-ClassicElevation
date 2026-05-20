--!strict

type ServiceContext = {
	Services: { [string]: any },
}

local RaceService = {}

local isInitialized = false
local isStarted = false

function RaceService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
	-- TODO: Own the round state machine and authoritative race clock in Phase 2.
end

function RaceService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[RaceService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	-- TODO: Start the round loop once state transitions are implemented.
end

return RaceService
