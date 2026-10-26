--!nonstrict
local Appearance = {}
Appearance.WorldAssemblySHA256 = "816d5e4cdeeabbdc3fc5e9fc62758afa5a5eca3aa7737ccd9ee087725b845a4d"
local Palette = {
	Stone={155,164,175},StoneLight={193,196,195},StoneDark={109,121,140},Slate={63,80,109},SlateBand={90,106,132},
	Iron={72,83,102},Brass={174,140,83},Lead={79,73,64},Leaf={70,99,80},Flower={148,143,174},Grass={91,129,64},
	Earth={104,86,63},Rock={102,111,108},Wood={101,77,53},Foliage={70,117,67},Needles={62,102,73},
}
local Quiet={Amber={172,120,61},AmberLight={210,169,108},AmberPale={227,195,140}}
local Focal={Amber={210,145,54},AmberLight={241,190,98},AmberPale={255,223,157}}
local Grand={Stone={124,134,149},StoneLight={185,190,193},StoneDark={80,96,116},Slate={43,60,86}}
local function color(rgb)return Color3.fromRGB(table.unpack(rgb)) end

function Appearance.Expected(part,data)
	local source=part:GetAttribute("SourceMaterial") or part.Name:match("__(.+)$")
	local expected={Color=part.Color,Material=part.Material,CastShadow=part.CastShadow}
	if data.color then expected.Color=if typeof(data.color)=="Color3" then data.color else Color3.new(table.unpack(data.color))
	elseif Palette[source] then expected.Color=color(Palette[source])
	elseif Quiet[source] then expected.Color=color(Quiet[source]) end
	if data.materialRole=="GrandStone" and Grand[source] then expected.Color=color(Grand[source]) end
	if source=="Rock" or source=="RockA" or source=="RockB" then expected.Color,expected.Material=color({100,112,116}),Enum.Material.Rock
	elseif source=="Grass" then expected.Color,expected.Material=color({91,119,75}),Enum.Material.Grass
	elseif source=="Earth" then expected.Material=Enum.Material.Ground
	elseif source=="Wood" then expected.Material=Enum.Material.Wood
	elseif data.material then expected.Material=Enum.Material[data.material]
	elseif source=="Slate" or source=="SlateBand" or source=="Leaf" or source=="Flower" then expected.Material=Enum.Material.SmoothPlastic
	elseif source=="Iron" or source=="Brass" or source=="Lead" then expected.Material=Enum.Material.Metal
	elseif source=="StoneLight" then expected.Material=Enum.Material.SmoothPlastic
	elseif source and source:find("Stone",1,true) then expected.Material=Enum.Material.Concrete
	elseif Quiet[source] then expected.Material=Enum.Material.SmoothPlastic end
	if data.asset=="MC_LanternCore" then expected.Color,expected.Material,expected.CastShadow=color({244,179,85}),Enum.Material.Neon,false
	elseif data.asset=="MC_WindowGlass" and data.materialRole=="MainKeepWindow" then
		expected.Color,expected.Material,expected.CastShadow=color(Focal[source] or {241,190,98}),Enum.Material.Neon,false
	elseif data.asset=="MC_WindowGlass" and data.materialRole=="SecondaryWarmWindow" then
		expected.Color,expected.Material,expected.CastShadow=color(Quiet[source] or {210,169,108}),Enum.Material.Neon,false
	end
	return expected
end
return Appearance
