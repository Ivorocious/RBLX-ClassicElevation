--!nonstrict
local Builder = {}

function Builder.Create(kit)
 assert(game:GetService("RunService"):IsStudio(), "Author this Phase 1 study in Studio")
 local root = require(script.Parent.Study).Build(kit)
 root.Name = "Course_EggRush"
 assert(root:GetAttribute("CandidateId") == "ER_P1_R01" and root:GetAttribute("Phase") == 1, "Unexpected Phase 1 candidate")
 assert(root.CourseInfo:GetAttribute("Enabled") == false, "Install this study for testing deliberately")
 return root
end

return Builder
