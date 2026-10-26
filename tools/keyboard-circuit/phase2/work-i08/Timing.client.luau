--!strict
local Timing = {}

function Timing.Remaining(kind: string, elapsed: number, index: number, tuning): number
	local offset = (index - 1) * (if kind == "Fallaway" then tuning.LaneOffset else tuning.Offset or 0)
	if elapsed < offset then return if kind == "Foundry" then offset - elapsed else 0 end
	local phase = (elapsed - offset) % tuning.Period
	if kind == "Foundry" then
		local clearAt = tuning.Warning + tuning.Drop + tuning.Down + tuning.Return
		return if phase >= clearAt then tuning.Period - phase else 0
	elseif kind == "Domino" then
		local clearAt = tuning.Rest + tuning.Warning + tuning.Drop
		return if phase >= clearAt and phase < clearAt + tuning.Clear then clearAt + tuning.Clear - phase else 0
	elseif kind == "Shift" then return if phase < tuning.Open then tuning.Open - phase else 0
	elseif kind == "Sweep" then return if phase < tuning.Rest then tuning.Rest + tuning.Warning - phase else 0
	elseif kind == "Shuttle" then return if phase < tuning.BoardDwell then tuning.BoardDwell - phase else 0
	elseif kind == "Fallaway" then return if phase < tuning.Open then tuning.Open - phase else 0
	end
	error("Unsupported pacing window " .. kind)
end

shared.KCP2I08Timing = Timing
return {installed = true, timing = "shared.KCP2I08Timing", boundary = "Read-only remaining-window estimate; actual server admission/state is also required."}

