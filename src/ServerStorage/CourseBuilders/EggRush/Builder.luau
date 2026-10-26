--!nonstrict
local Builder={}
function Builder.Create(kit)
 assert(game:GetService("RunService"):IsStudio(),"Author this course in Studio")
 local root=require(script.Parent.Authoring).Build()
 require(script.Parent.Finish).Shellworks(root,kit)
 require(script.Parent.WorldFinish).Build(root,kit)
 require(script.Parent.MechanismFinish).Apply(root,kit)
 root:SetAttribute("Phase",3)
 root:SetAttribute("CandidateId","ER_P3_C15_WORLD")
 root.CourseInfo:SetAttribute("Enabled",true)
 return root
end
return Builder
