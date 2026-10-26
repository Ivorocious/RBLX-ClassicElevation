local fs,luau=require('@lune/fs'),require('@lune/luau')
for _,path in {'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/Layout.luau','src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/ExpertRoutes.luau','tools/moonlit-citadel/phase3/rework-20261012/InstallR13.luau'} do luau.load(fs.readFile(path));print('Compiled '..path)end
