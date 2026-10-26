local fs=require("@lune/fs")
local luau=require("@lune/luau")
local files={"src/ServerStorage/CourseBuilders/EggRush/NativeTraversal.luau","src/ServerStorage/CourseBuilders/EggRush/RestartP2/Builder.luau","tests/studio/EggRushP2Closeout.server.luau","tests/studio/EggRushP2Closeout.client.luau","tests/studio/EggRushP2ConcurrentExit.server.luau","src/StarterPlayer/StarterPlayerScripts/Controllers/ArrivalTransition.luau","src/StarterPlayer/StarterPlayerScripts/Controllers/ArrivalAssets.luau","src/StarterPlayer/StarterPlayerScripts/Controllers/TournamentPresentation.luau","tests/studio/EggRushP2ReturnProbe.server.luau","tests/studio/EggRushP2InputIsolation.client.luau"}
for _,path in files do luau.load(fs.readFile(path),{debugName=path}) end
print("Egg Rush closeout source compile passed: "..#files)
