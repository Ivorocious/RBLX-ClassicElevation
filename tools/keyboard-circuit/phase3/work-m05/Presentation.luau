--!strict
local Presentation = {}

export type Report = {killParts: number, changedParts: number}

function Presentation.Apply(course: Model): Report
	assert(course:GetAttribute("CourseId") == "keyboard_circuit", "Keyboard Circuit presentation requires its shared course")
	local report = {killParts = 0, changedParts = 0}
	for _, item in course:GetDescendants() do
		if item:IsA("TextLabel") then
			if item.Text == "7 CHECKPOINTS" then item.Text = "8 CHECKPOINTS" end
			if item.Text == "/ 7" then item.Text = "/ 8" end
			if item.Text == "LAP FINISH" and item:FindFirstAncestor("LapFinishStation") then item.Text = "FINAL CHECKPOINT" end
		end
		if item:IsA("BasePart") and item:GetAttribute("HazardType") == "Kill" then
			report.killParts += 1
			if item.Material ~= Enum.Material.Neon then
				item.Material = Enum.Material.Neon
				report.changedParts += 1
			end
		end
	end
	return report
end

return Presentation
