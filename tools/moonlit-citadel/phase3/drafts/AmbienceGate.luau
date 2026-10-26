--!strict

local Gate = {}

function Gate.Allows(course: Instance?, config: any, position: Vector3, humanoid: Humanoid?): boolean
	if not config.UseCourseBounds then return true end
	if not humanoid or humanoid.Health <= 0 then return false end
	if not course or not course:IsA("Model") or course.Name ~= "RaceCourse"
		or course:GetAttribute("CourseId") ~= config.CourseId
		or course:GetAttribute("MoonlitCourse") ~= true
		or course:GetAttribute("RuntimeActiveCourse") ~= true then return false end
	local required = config.RequiredCourseAttribute
	if typeof(required) == "string" and course:GetAttribute(required) ~= true then return false end
	local center, size = course:GetAttribute("BoundsCenter"), course:GetAttribute("BoundsSize")
	if typeof(center) ~= "Vector3" or typeof(size) ~= "Vector3" then return false end
	local delta, half = position - center, size / 2
	return math.abs(delta.X) <= half.X and math.abs(delta.Y) <= half.Y and math.abs(delta.Z) <= half.Z
end

return Gate
