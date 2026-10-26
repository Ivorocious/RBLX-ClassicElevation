--!nonstrict
local Crown = {}
local v = Vector3.new
local edits = {
    GrandFlankPinnacle1 = {asset = "MC_TL_FlankPinnacle", scale = v(.9, .3, .9)},
    ["GrandFlankPinnacle-1"] = {asset = "MC_TL_FlankPinnacle", scale = v(.9, .3, .9)},
    CrownBaseUnifiedShell = {asset = "MC_ER_CrownBaseShell", shift = v(0, -12, 0)},
}

function Crown.Revise(data)
    local edit = edits[data.name]
    if not edit then return data end
    assert(data.asset == edit.asset, "Crown revision does not match the frozen Source49 asset")
    local revised = table.clone(data)
    if edit.scale then revised.scale = edit.scale end
    if edit.shift then revised.localCF += edit.shift end
    return revised
end

function Crown.Additions()
    local units = {}
    local function mass(name, point, scale)
        table.insert(units, {name = name, district = "CrownArrival", asset = "MC_AR_MasonryMass",
            library = "ER01", localCF = CFrame.new(point), scale = scale, materialRole = "StoneStructure"})
    end
    -- The carrier stays inside the exact accepted floor footprint and penetrates its existing underside.
    mass("CrownRaisedFloorCarrier", v(-8, 125, -30), v(1.4, (148.6 - 125) / 24, 2.08))
    for index, x in {-26, -14, -2, 10} do
        mass("CrownSouthScreenFoot" .. index, v(x, 136.5, -10), v(.052, 13.1 / 24, .18))
    end
    for index, z in {-46, -33, -20, -7} do
        mass("CrownWestScreenFoot" .. index, v(-31, 136.5, z), v(.0936, 13.1 / 24, .1))
    end
    mass("CrownEmblemLowerPier", v(-8, 136.5, -9.1), v(.36, 13.1 / 24, .16))
    return units
end

Crown.Views = {
    centrePanorama = {camera = v(-8, 155.5, -30), look = v(172, 124, 4)},
    southwestCompanion = {camera = v(-23.5, 155.5, -18.5), look = v(-144, 170, 106)},
    arrival = {camera = v(18.7705, 154.6667, -42.4292), look = v(-8, 155.5, -30)},
}
Crown.EditedNames = {"GrandFlankPinnacle-1", "GrandFlankPinnacle1", "CrownBaseUnifiedShell"}
return Crown
