local fs=require("@lune/fs")
local luau=require("@lune/luau")
local files={
	"src/ReplicatedStorage/Config/MoonlitCitadelConfig.luau",
	"src/ServerStorage/CourseBuilders/MoonlitCitadel/Kit.luau",
	"src/ServerStorage/CourseBuilders/MoonlitCitadel/MeshKit.luau",
	"src/ServerStorage/CourseBuilders/MoonlitCitadel/AssetBindings.luau",
	"src/ServerStorage/CourseBuilders/MoonlitCitadel/BlenderInstaller.luau",
	"src/ServerStorage/CourseBuilders/MoonlitCitadel/Installer.luau",
	"src/ServerStorage/CourseBuilders/MoonlitCitadel/PreviewSession.luau",
	"src/ServerScriptService/MoonlitCitadelPreview.server.luau",
	"src/StarterPlayer/StarterPlayerScripts/Controllers/MoonlitCitadelPreviewView.luau",
	"tools/moonlit-citadel/PlayerProbe.luau",
	"tools/moonlit-citadel/BuildNative.luau",
	"tools/moonlit-citadel/RepairNative.luau",
	"tools/moonlit-citadel/NormalizeImport.luau",
	"tools/moonlit-citadel/InstallClientProbe.luau",
	"tools/moonlit-citadel/LanternProbe.luau",
	"tools/moonlit-citadel/LanternWaitProbe.luau",
	"tools/moonlit-citadel/isolated-preview.server.luau",
	"tools/moonlit-citadel/RecoveryProbe.luau",
	"tools/moonlit-citadel/RoughProbe.luau",
	"tools/moonlit-citadel/RepairRough.luau",
	"tools/moonlit-citadel/RepairCp03.luau",
	"tools/moonlit-citadel/RepairRoughJoin.luau",
	"tools/moonlit-citadel/BuildBl02.luau",
	"tools/moonlit-citadel/NormalizeBl02.luau",
	"tools/moonlit-citadel/Bl02WaitProbe.luau",
	"tools/moonlit-citadel/ReadbackBl02.luau",
	"tools/moonlit-citadel/GeometryEvidenceBl02.luau",
}
for _,path in files do assert(luau.load(fs.readFile(path)),path)end
print("Moonlit sources compiled: "..#files)
