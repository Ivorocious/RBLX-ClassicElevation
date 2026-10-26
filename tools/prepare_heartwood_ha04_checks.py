"""Keep HA03 checks as history and derive the HA04 native backup recipes."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
for relative in ('tests/studio/HeartwoodExportHA03.luau','tests/studio/HeartwoodNativeRestoreHA03.luau','tests/HeartwoodNativeBackupHA03.luau'):
    source=(root/relative).read_text().replace('HA03','HA04').replace('HA_V1_03','HA_V1_04')
    if 'Restore' in relative:
        marker='        local leaves = copy.Decoration.S03_HangingGardens.Leaves:GetChildren()'
        addition='''        local forest = copy.Decoration.HeartwoodArt.ForestSurroundings
        local forestCount = 0
        for _, layer in forest:GetChildren() do
            if layer:IsA("Folder") then
                for _, tree in layer:GetChildren() do
                    if tree:IsA("Model") and tree:GetAttribute("WholeTree") == true then
                        table.insert(unitChecks, moveUnit(tree, false)); forestCount += 1
                    end
                end
            end
        end
        assert(forestCount == 26, "Expected 26 editable whole forest trees")
'''
        source=source.replace(marker,addition+marker)
    (root/relative.replace('HA03','HA04')).write_text(source)
print('HA04 export, native restore and local reopen recipes prepared.')
