--!strict
if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("StudGardenTestEnabled") == true then
	task.defer(function()
		require(game.ServerStorage.CourseBuilders.StudGarden.TestSession).Start()
	end)
end
