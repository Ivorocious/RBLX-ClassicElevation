local fs=require("@lune/fs")
local luau=require("@lune/luau")
local Clock=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/StudGarden/HazardClock.luau"))()
local Phase=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/StudGarden/HazardState.luau"))()
local timing={Clear=1,Warning=.5,Active=1}
local function close(a,b) assert(math.abs(a-b)<.000001) end
local function sequence(stallAt)
	local clock=Clock.New(0)
	local wall,active=0,0
	for i=1,50 do
		if i==stallAt then
			local before=clock.elapsed
			local oldPhase,oldAlpha=Phase.Phase(before,timing)
			wall+=2
			local first,last,advanced=Clock.Step(clock,wall)
			assert(not advanced and #Phase.ActiveIntervals(first,last,timing)==0)
			close(first,before);close(last,before)
			local newPhase,newAlpha=Phase.Phase(last,timing)
			assert(oldPhase==newPhase);close(oldAlpha,newAlpha)
		end
		wall+=.1
		local first,last,advanced=Clock.Step(clock,wall)
		assert(advanced)
		for _,range in Phase.ActiveIntervals(first,last,timing) do active+=range[2]-range[1] end
	end
	close(clock.elapsed,5);close(active,2)
	assert(clock.pausedStalls==(if stallAt then 1 else 0))
end
sequence(nil)
sequence(10)
sequence(15)
sequence(20)
local still=Clock.New(3)
local first,last,advanced=Clock.Step(still,3)
assert(not advanced and first==0 and last==0 and still.pausedStalls==0)
print("HazardClock: normal, clear-boundary, warning-boundary, active-stall and zero-delta checks passed; full active intervals preserved")
