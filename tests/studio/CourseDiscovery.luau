local Test = {}

function Test.Run(service)
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local library = game.ServerStorage.CourseLibrary
	local fixtures = {}
	local id = "__duplicate_discovery_fixture"
	local function make()
		local model = Instance.new("Model")
		model.Name = "DuplicateDiscoveryFixture"
		local info = Instance.new("Folder")
		info.Name = "CourseInfo"
		info:SetAttribute("CourseId", id)
		info.Parent = model
		model.Parent = library
		table.insert(fixtures,model)
	end
	local ok, failure = xpcall(function()
		service.DiscoverCourses()
		local before = #service.GetDiscoveredCourseIds()
		make(); make(); make()
		service.DiscoverCourses()
		assert(service.GetCourseInfo(id) == nil, "Duplicate ID remained selectable")
		assert(#service.GetDiscoveredCourseIds() == before, "Duplicate IDs leaked into order")
	end, debug.traceback)
	for _, model in fixtures do model:Destroy() end
	service.DiscoverCourses()
	assert(ok, failure)
	return {duplicateIdRejected=true,ids=service.GetDiscoveredCourseIds()}
end

return Test
