--!strict

type ServiceContext = {
	Services: { [string]: any },
}

local CheckpointService = {}

local isInitialized = false
local isStarted = false

function CheckpointService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
	-- TODO: Validate checkpoint and finish progress server-side in a later phase.
end

function CheckpointService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[CheckpointService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	-- TODO: Bind course checkpoint parts after the Workspace course structure exists.
end

return CheckpointService
