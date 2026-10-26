assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818, "Wrong experience")
assert(not game:GetService("RunService"):IsRunning(), "Edit cleanup only")
local expected = game.HttpService:JSONDecode([====[[{"path":"ServerStorage.KeyboardCircuitPhase2Archive","name":"KeyboardCircuitPhase2Archive","byClass":{"Vector3Value":1434,"ModuleScript":1665,"Part":252930,"MeshPart":175713,"WeldConstraint":5496,"Folder":2871,"ObjectValue":7594,"Attachment":2556,"Script":96,"ProximityPrompt":4,"HingeConstraint":124,"UITextSizeConstraint":2394,"LocalScript":99,"TextLabel":183423,"Model":17831,"PrismaticConstraint":128,"Frame":6589,"UIStroke":2186,"SurfaceGui":180836},"sources":1860,"class":"Folder","descendants":843969,"parts":428643},{"path":"ServerStorage.KCP2I08TwoLapSources01","name":"KCP2I08TwoLapSources01","byClass":{"Folder":1,"LocalScript":1,"Script":1,"ModuleScript":14},"sources":16,"class":"Folder","descendants":17,"parts":0},{"path":"ServerStorage.KCP2I08TwoLapNativeRecovery01","name":"KCP2I08TwoLapNativeRecovery01","byClass":{"Vector3Value":68,"ModuleScript":42,"Part":7954,"MeshPart":6030,"WeldConstraint":172,"Folder":92,"ObjectValue":228,"Attachment":82,"Script":3,"HingeConstraint":4,"LocalScript":3,"TextLabel":6314,"Model":554,"PrismaticConstraint":4,"Frame":140,"UIStroke":72,"SurfaceGui":6314},"sources":48,"class":"Folder","descendants":28076,"parts":13984},{"path":"ServerStorage.KCP2I09ExperienceSources03","name":"KCP2I09ExperienceSources03","byClass":{"Folder":1,"LocalScript":1,"Script":1,"ModuleScript":14},"sources":16,"class":"Folder","descendants":17,"parts":0},{"path":"ServerStorage.KCP2I09ExperienceNativeRecovery03","name":"KCP2I09ExperienceNativeRecovery03","byClass":{"Vector3Value":50,"ModuleScript":42,"Part":7942,"MeshPart":6012,"WeldConstraint":172,"Folder":80,"ObjectValue":202,"Attachment":82,"Script":3,"HingeConstraint":4,"LocalScript":3,"TextLabel":6312,"Model":548,"PrismaticConstraint":4,"Frame":140,"UIStroke":72,"SurfaceGui":6312},"sources":48,"class":"Folder","descendants":27980,"parts":13954},{"path":"ServerStorage.KCP3M01Sources01","name":"KCP3M01Sources01","byClass":{"Vector3Value":50,"ModuleScript":108,"LocalScript":6,"MeshPart":6318,"WeldConstraint":172,"Folder":82,"ObjectValue":202,"Attachment":82,"Script":6,"HingeConstraint":4,"PrismaticConstraint":4,"TextLabel":6618,"Model":805,"UIStroke":56,"Frame":124,"Part":9409,"SurfaceGui":6618},"sources":120,"class":"Folder","descendants":30664,"parts":15727},{"path":"ServerStorage.KCP3M01NativeRecovery01","name":"KCP3M01NativeRecovery01","byClass":{"Vector3Value":50,"ModuleScript":54,"Part":8980,"MeshPart":6216,"WeldConstraint":172,"Folder":80,"ObjectValue":202,"Attachment":82,"Script":3,"HingeConstraint":4,"LocalScript":3,"TextLabel":6516,"Model":716,"PrismaticConstraint":4,"Frame":140,"UIStroke":72,"SurfaceGui":6516},"sources":60,"class":"Folder","descendants":29810,"parts":15196},{"path":"ServerStorage.CourseAssetKits.KeyboardCircuit_Phase2EditableKit_K02","name":"KeyboardCircuit_Phase2EditableKit_K02","byClass":{"UIStroke":28,"LocalScript":1,"Script":1,"ModuleScript":14,"Part":2388,"MeshPart":1826,"PrismaticConstraint":2,"SurfaceGui":1940,"Folder":9,"ObjectValue":18,"TextLabel":1940,"Model":138,"Frame":28,"Attachment":41,"HingeConstraint":2,"WeldConstraint":86},"sources":16,"class":"Model","descendants":8462,"parts":4214},{"path":"ServerStorage.DeveloperArchives.KeyboardCircuitP1_Archives","name":"KeyboardCircuitP1_Archives","byClass":{"ProximityPrompt":48,"Script":34,"ModuleScript":288,"Part":9337,"MeshPart":43068,"UIStroke":60,"SurfaceGui":7016,"Folder":42,"ObjectValue":52,"TextLabel":7076,"Model":2019,"Frame":60,"Attachment":100,"PrismaticConstraint":50,"WeldConstraint":3662},"sources":322,"descendants":72912,"parts":52405},{"path":"ServerStorage.AssetImports.KCKeyImport_K01","name":"KCKeyImport_K01","byClass":{"MeshPart":2,"PackageLink":1},"sources":0,"descendants":3,"parts":2}]]====])
assert(shared.KCM05PreservationBefore and shared.KCM05ExtraBefore, "Missing live preservation record")
local function find(path)
	local root = game
	for name in path:gmatch("[^.]+") do root = assert(root:FindFirstChild(name), path) end
	return root
end
local roots = {}
for _, row in expected do
	local root = find(row.path)
	assert(#root:GetDescendants() == row.descendants, "History changed after export: " .. row.path)
	table.insert(roots, root)
end
for _, row in shared.KCM05PreservationBefore.unrelated do
	assert(#find(row.path):GetDescendants() == row.count, "Unrelated content changed: " .. row.path)
end
local receipt = {revision="KC_P3_M05_01", recovery="docs/artifacts/keyboard-circuit/phase3/m05-recovery", removed={}, instancesRemoved=0, finished=false}
shared.KCM05CleanupReceipt = receipt
for index, root in roots do
	local row = expected[index]
	root:Destroy()
	table.insert(receipt.removed, {path=row.path, instances=row.descendants + 1})
	receipt.instancesRemoved += row.descendants + 1
end
for _, row in shared.KCM05PreservationBefore.unrelated do
	assert(#find(row.path):GetDescendants() == row.count, "Unrelated content changed: " .. row.path)
end
receipt.finished = true
return game.HttpService:JSONEncode(receipt)
