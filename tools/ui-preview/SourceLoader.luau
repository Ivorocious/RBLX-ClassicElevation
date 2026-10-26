--!strict
local Loader = {}

local controllerNames = {"ArrivalScreen", "ArrivalView", "ArrivalStage", "ArrivalDialog", "ArrivalEntranceView", "LobbyUiController", "LobbyView", "LobbyPresentation", "LobbyIcons", "PhaseCapsule", "UiTheme", "UiReveal",
	"UiKit", "RacePresentation", "RaceHudView", "RaceMomentsView", "FinishTicketView", "RaceFlowPresentation"}
local configNames = {"OnboardingConfig", "ArrivalEmblemGenerated", "RaceConfig", "VotingArtwork"}
local sharedNames = {"RacerAppearance", "RaceConstants", "RaceTypes", "FormatTime"}

function Loader.Load()
	local starter = game:GetService("StarterPlayer").StarterPlayerScripts
	local replicated = game:GetService("ReplicatedStorage")
	local sandbox = Instance.new("Folder")
	sandbox.Name = "ClassicElevationUIPreviewSources"
	local function copyGroup(parent, name, source, names)
		assert(source, "Missing " .. name .. ". Connect Rojo to this project and refresh.")
		local folder = Instance.new("Folder")
		folder.Name, folder.Parent = name, parent
		for _, moduleName in names do
			local original = source:FindFirstChild(moduleName)
			assert(original and original:IsA("ModuleScript"), "Missing " .. moduleName .. ". Connect Rojo to this project and refresh.")
			local module = Instance.new("ModuleScript")
			module.Name = moduleName
			-- Clone on each refresh so require does not keep an earlier version of the UI.
			module.Source = original.Source:gsub('game:GetService%("ReplicatedStorage"%)', 'script.Parent.Parent')
			module.Parent = folder
		end
		return folder
	end
	local ok, result = pcall(function()
		copyGroup(sandbox, "Config", replicated:FindFirstChild("Config"), configNames)
		copyGroup(sandbox, "Shared", replicated:FindFirstChild("Shared"), sharedNames)
		local controllers = copyGroup(sandbox, "Controllers", starter:FindFirstChild("Controllers"), controllerNames)
		return {
			Screen = require(controllers.ArrivalScreen),
			View = require(controllers.ArrivalView),
			Entrance = require(controllers.ArrivalEntranceView),
			Lobby = require(controllers.LobbyUiController),
			Kit = require(controllers.UiKit),
			RacePresentation = require(controllers.RacePresentation),
			RaceHudView = require(controllers.RaceHudView),
			RaceMomentsView = require(controllers.RaceMomentsView),
			FinishTicketView = require(controllers.FinishTicketView),
			RaceFlowPresentation = require(controllers.RaceFlowPresentation),
			Artwork = require(sandbox.Config.VotingArtwork),
			Config = require(sandbox.Config.OnboardingConfig),
			Appearance = require(sandbox.Shared.RacerAppearance),
			Destroy = function() sandbox:Destroy() end,
		}
	end)
	if not ok then sandbox:Destroy(); error(result, 0) end
	return result
end

return Loader
