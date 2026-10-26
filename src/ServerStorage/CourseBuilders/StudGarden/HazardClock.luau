--!strict

local HazardClock={}
export type State={wall: number,elapsed: number,pausedStalls: number}

function HazardClock.New(now: number): State
	return {wall=now,elapsed=0,pausedStalls=0}
end

function HazardClock.Step(state: State,now: number): (number,number,boolean)
	local previous=state.elapsed
	local dt=now-state.wall
	state.wall=now
	-- Hold motion and warnings together instead of skipping an unchecked sweep.
	if dt<=0 or dt>.2 then
		if dt>.2 then state.pausedStalls+=1 end
		return previous,previous,false
	end
	state.elapsed+=dt
	return previous,state.elapsed,true
end

return HazardClock
