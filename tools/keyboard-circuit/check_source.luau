local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local path = "src/ServerStorage/CourseBuilders/KeyboardCircuit/"
local count=0
for _,name in fs.readDir(path) do
	if name:sub(-5)==".luau" then luau.load(fs.readFile(path..name), {debugName=name}); count+=1 end
end
for _,extra in {"src/ReplicatedStorage/Config/KeyboardCircuitConfig.luau", "src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitFeedback.luau", "src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitAudio.luau", "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPreview.client.luau"} do
	luau.load(fs.readFile(extra), {debugName=extra}); count+=1
end
local layout=luau.load(fs.readFile(path.."Layout.luau"))()
local xml=fs.readFile("docs/artifacts/keyboard-circuit/keyboard-circuit.drawio")
for i,id in layout.Main do
	local following=layout.Main[i%#layout.Main+1]
	assert(xml:find('source="'..id..'" target="'..following..'"',1,true),"Native normal connection "..id)
end
for _,branch in layout.Branches do
	assert(xml:find('source="'..branch.from..'" target="'..branch.id..'"',1,true))
	assert(xml:find('source="'..branch.id..'" target="'..branch.before..'"',1,true))
end
print(serde.encode("json",{compiled=count,mainConnections=#layout.Main,expertConnections=4,status="passed",limits="Syntax and native XML agreement; no jump, contact or runtime proof."}))
