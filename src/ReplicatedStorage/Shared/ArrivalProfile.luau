--!strict
-- Pure transitions are shared with the local tests; only the server writes profiles.
local Profile = {}

function Profile.New()
	return {version = 1, revision = 0, completed = false, mode = "Avatar", gold = 0, bonusClaimed = false}
end

function Profile.ValidLook(look: any, config: any): boolean
	if type(look) ~= "table" then return false end
	for key, limit in {hair = #config.Hair, skin = #config.Skin, top = #config.Colors, legs = #config.Colors} do
		local value = look[key]
		if type(value) ~= "number" or value ~= value or value % 1 ~= 0 or value < 1 or value > limit then return false end
	end
	for key in look do
		if key ~= "hair" and key ~= "skin" and key ~= "top" and key ~= "legs" then return false end
	end
	return true
end

function Profile.Read(value: any, config: any)
	if value == nil then return Profile.New() end
	assert(type(value) == "table" and value.version == 1, "Unsupported profile")
	assert(type(value.completed) == "boolean" and type(value.bonusClaimed) == "boolean", "Invalid profile flags")
	assert(value.mode == "Avatar" or value.mode == "Custom", "Invalid avatar mode")
	assert(type(value.gold) == "number" and value.gold >= 0 and value.gold < 1e12 and value.gold % 1 == 0, "Invalid balance")
	assert(type(value.revision) == "number" and value.revision >= 0 and value.revision % 1 == 0, "Invalid revision")
	assert(value.look == nil or Profile.ValidLook(value.look, config), "Invalid saved look")
	assert(value.mode ~= "Custom" or value.look ~= nil, "Missing custom look")
	return table.clone(value)
end

function Profile.Commit(current: any, mode: string, look: any, operationId: string, config: any)
	local nextProfile = Profile.Read(current, config)
	assert(mode == "Avatar" or mode == "Custom", "Invalid choice")
	assert(mode ~= "Custom" or Profile.ValidLook(look, config), "Invalid look")
	if nextProfile.lastOperationId == operationId then return nextProfile end
	nextProfile.mode, nextProfile.completed = mode, true
	nextProfile.revision += 1
	nextProfile.lastOperationId = operationId
	if mode == "Custom" then
		nextProfile.look = table.clone(look)
		if not nextProfile.bonusClaimed then
			nextProfile.gold += config.CreationBonus
			nextProfile.bonusClaimed = true
		end
	end
	return nextProfile
end

return Profile
