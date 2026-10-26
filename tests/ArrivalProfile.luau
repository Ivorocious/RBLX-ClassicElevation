local Profile = require("../src/ReplicatedStorage/Shared/ArrivalProfile")
local Config = require("../src/ReplicatedStorage/Config/OnboardingConfig")
local tests = 0
local function check(value, message)
	assert(value, message)
	tests += 1
end
local original = Profile.New()
local avatar = Profile.Commit(original, "Avatar", nil, "avatar-0001", Config)
check(avatar.gold == 0 and avatar.completed and not avatar.bonusClaimed, "Avatar path preserves later bonus")
local custom = Profile.Commit(avatar, "Custom", Config.DefaultLook, "custom-0001", Config)
check(custom.gold == Config.CreationBonus and custom.bonusClaimed, "First custom save grants bonus")
check(original.completed == false and avatar.gold == 0, "Transitions do not mutate earlier profiles")
local duplicate = Profile.Commit(custom, "Custom", Config.DefaultLook, "custom-0001", Config)
check(duplicate.revision == custom.revision and duplicate.gold == custom.gold, "Ambiguous-save retry is idempotent")
local again = Profile.Commit(custom, "Custom", {hair=2,skin=3,top=5,legs=7}, "custom-0002", Config)
check(again.gold == custom.gold and again.revision == custom.revision + 1, "Revisiting does not duplicate reward")
local switched = Profile.Commit(again, "Avatar", nil, "avatar-0002", Config)
check(switched.look.top == 5 and switched.bonusClaimed, "Switching keeps custom look and claim")
local roundTrip = Profile.Commit(switched, "Custom", switched.look, "custom-0003", Config)
check(roundTrip.gold == Config.CreationBonus, "Avatar/custom cycling does not farm Gold")
for _, look in {false, {}, {hair=0,skin=1,top=1,legs=1}, {hair=1,skin=1,top=0/0,legs=1}, {hair=1,skin=1,top=1.5,legs=1}, {hair=1,skin=1,top=1,legs=1,gold=999}, {hair=1,skin=1,top=1,legs=100}} do
	check(not Profile.ValidLook(look, Config), "Reject invalid or injected appearance")
end
for _, profile in {{version=2}, {version=1,gold=-1}, {version=1,completed=true,bonusClaimed=true,mode="Custom",gold=100,revision=1}} do
	check(not pcall(Profile.Read, profile, Config), "Invalid existing data cannot reset to new")
end
check(not pcall(Profile.Commit, custom, "Administrator", nil, "invalid-0001", Config), "Reject unknown mode")
local reconnect = Profile.Read(roundTrip, Config)
check(reconnect.completed and reconnect.look.top == 5 and reconnect.gold == Config.CreationBonus, "Returning profile survives reload")
print(string.format("ArrivalProfile: %d checks passed", tests))
