--!strict
local Artwork = {}
Artwork.Clock = "rbxassetid://93456088285475"
Artwork.ClockBounds = Rect.new(58,56,1198,1200)
Artwork.SelectionBadge = "rbxassetid://78230411831312"
Artwork.Thumbnails = {
 ["city-run"]="rbxassetid://119029563626512",
 ["shipwreck-cove"]="rbxassetid://139014909913564",
 ["cloud-causeway"]="rbxassetid://93796760408222",
 ["frost-peak"]="rbxassetid://91104645883638",
 ["lava-works"]="rbxassetid://101974227018586",
 ["crystal-cavern"]="rbxassetid://131600023320561",
 ["desert-ruins"]="rbxassetid://124313522006950",
 ["moonbase"]="rbxassetid://97974533912865",
 -- In-course captures from the UI overhaul concept page (uploaded 2026-10-20).
 ["keyboard-circuit"]="rbxassetid://104038269662838",
 ["moonlit-citadel"]="rbxassetid://134676491966291",
 ["stud-garden"]="rbxassetid://90774738352339",
 ["egg-rush"]="rbxassetid://133924210498243",
}
Artwork.Reference = {
 {id="city_run",name="City Run",art="city-run"},
 {id="shipwreck_cove",name="Shipwreck Cove",art="shipwreck-cove"},
 {id="cloud_causeway",name="Cloud Causeway",art="cloud-causeway"},
 {id="frost_peak",name="Frost Peak",art="frost-peak"},
 {id="lava_works",name="Lava Works",art="lava-works"},
 {id="crystal_cavern",name="Crystal Cavern",art="crystal-cavern"},
 {id="desert_ruins",name="Desert Ruins",art="desert-ruins"},
 {id="moonbase",name="Moonbase",art="moonbase"},
 {id="keyboard_circuit",name="Keyboard Circuit",art="keyboard-circuit"},
 {id="moonlit_citadel",name="Moonlit Citadel",art="moonlit-citadel"},
 {id="stud_garden_v2",name="Stud Garden",art="stud-garden"},
 {id="egg_rush_circuit",name="Egg Rush",art="egg-rush"},
}
function Artwork.Image(courseId: string): string
 for _,entry in Artwork.Reference do if entry.id==courseId then return Artwork.Thumbnails[entry.art] or "" end end
 return ""
end
return Artwork
