local fs, luau = require("@lune/fs"), require("@lune/luau")
for _, path in {"src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/Wayfinding.luau", "tools/moonlit-citadel/phase2/R06LiftChoiceCues.luau", "tools/moonlit-citadel/phase2/R06ChoiceOnlyGuidance.luau"} do
	assert(luau.load(fs.readFile(path)), path)
end
print("Landing cue source and bounded native installer compile")
