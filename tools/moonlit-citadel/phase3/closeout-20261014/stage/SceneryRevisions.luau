--!nonstrict
local Crown = {}
local v = Vector3.new
local edits = {
    GrandFlankPinnacle1 = {asset = "MC_TL_FlankPinnacle", scale = v(.9, .3, .9)},
    ["GrandFlankPinnacle-1"] = {asset = "MC_TL_FlankPinnacle", scale = v(.9, .3, .9)},
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
    return {}
end

Crown.Views = {
    centrePanorama = {camera = v(-8, 155.5, -30), look = v(172, 124, 4)},
    southwestCompanion = {camera = v(-23.5, 155.5, -18.5), look = v(-144, 170, 106)},
    arrival = {camera = v(18.7705, 154.6667, -42.4292), look = v(-8, 155.5, -30)},
}
Crown.EditedNames = {"GrandFlankPinnacle-1", "GrandFlankPinnacle1"}
return Crown
