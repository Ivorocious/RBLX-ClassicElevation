--!strict

type ServiceContext = {
	Services: { [string]: any },
}

local ResultsService = {}

local isInitialized = false
local isStarted = false

function ResultsService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
	-- TODO: Record placements, times, DNFs, falls, splits, summaries, and session PBs.
end

function ResultsService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[ResultsService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	-- TODO: Publish current-race results after result collection is implemented.
end

return ResultsService
