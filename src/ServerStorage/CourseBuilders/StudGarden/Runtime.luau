--!strict

local Sprinkler=require(script.Parent.SprinklerRuntime)
local Fruit=require(script.Parent.FruitRuntime)
local Runtime={}

function Runtime.Start(course: Model,eligible: (Player)->boolean,recover: (Player,string)->boolean)
	assert(course:GetAttribute("CourseId")=="stud_garden_v2","Stud Garden course required")
	local giants=course:FindFirstChild("GardenGiants")
	if giants then
		-- Cloning an avatar can restore torso collision even with its state machine disabled.
		for _,part in giants:GetDescendants() do
			if part:IsA("Humanoid") then part.EvaluateStateMachine=false
			elseif part:IsA("BasePart") then part.CanCollide=false;part.CanTouch=false;part.CanQuery=false end
		end
	end
	local sprinkler=Sprinkler.Start(course,eligible,recover)
	local ok,fruit=pcall(Fruit.Start,course.H2_Fruit,eligible,recover)
	if not ok then sprinkler.Stop();error(fruit) end
	return {
		Stop=function() sprinkler.Stop();fruit.Stop() end,
		Diagnostics=function() return {sprinkler=sprinkler.Diagnostics(),fruit=fruit.Diagnostics()} end,
	}
end

return Runtime
