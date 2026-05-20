--!strict

type ServiceContext = {
	Services: { [string]: any },
}

local PlayerRaceService = {}

local isInitialized = false
local isStarted = false

function PlayerRaceService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
	-- TODO: Own per-player race status, eligibility, joins, leaves, and late-race choices.
end

function PlayerRaceService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[PlayerRaceService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	-- TODO: Connect player lifecycle events after status handling is implemented.
end

return PlayerRaceService
