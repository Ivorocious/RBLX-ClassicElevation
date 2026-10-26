--!strict
local Config = require(script.Parent.Parent.Config.OnboardingConfig)
local Appearance = {}

function Appearance.Description(look)
	local description = Instance.new("HumanoidDescription")
	description.UseAvatarSettings = true
	local function color(rgb) return Color3.fromRGB(rgb[1], rgb[2], rgb[3]) end
	local skin = color(Config.Skin[look.skin])
	description.HeadColor, description.LeftArmColor, description.RightArmColor = skin, skin, skin
	description.TorsoColor = color(Config.Colors[look.top])
	description.LeftLegColor, description.RightLegColor = color(Config.Colors[look.legs]), color(Config.Colors[look.legs])
	description.HairAccessory = if Config.Hair[look.hair].assetId == 0 then "" else tostring(Config.Hair[look.hair].assetId)
	description.BodyTypeScale, description.ProportionScale = 0, 0
	description.HeightScale, description.WidthScale, description.DepthScale, description.HeadScale = 1, 1, 1, 1
	return description
end

return Appearance
