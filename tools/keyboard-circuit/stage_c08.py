import json
from pathlib import Path

root = Path.cwd()
builders = root / "src/ServerStorage/CourseBuilders/KeyboardCircuit"
sources = {p.name.removesuffix(".luau").removesuffix(".server"): p.read_text(encoding="utf-8") for p in builders.glob("*.luau")}
extras = {
    "ConfigSnapshot": "src/ReplicatedStorage/Config/KeyboardCircuitConfig.luau",
    "KeyboardCircuitFeedback": "src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitFeedback.luau",
    "KeyboardCircuitAudio": "src/StarterPlayer/StarterPlayerScripts/Controllers/KeyboardCircuitAudio.luau",
    "KeyboardCircuitPreview": "src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPreview.client.luau",
}
sources.update({name: (root / path).read_text(encoding="utf-8") for name, path in extras.items()})
assert len(sources) == 14

def quote(value):
    equals = ""
    while "]" + equals + "]" in value:
        equals += "="
    return "[" + equals + "[" + value + "]" + equals + "]"

literal = "{\n" + ",\n".join("[" + json.dumps(name) + "] = " + quote(value) for name, value in sources.items()) + "\n}"
destination = root / "docs/artifacts/keyboard-circuit/phase1"
(destination / "C08-source-package.json").write_text(json.dumps(sources, ensure_ascii=False), encoding="utf-8")
code = '''--!strict
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local storage = game:GetService("ServerStorage")
assert(not storage:FindFirstChild("KeyboardCircuit_C08_Prepared"), "Inspect the existing prepared build")
local sources = SOURCES
local prepared = Instance.new("Folder")
prepared.Name = "KeyboardCircuit_C08_Prepared"
local root = Instance.new("Model")
root.Name = "KeyboardCircuit_P1_C08"
root:SetAttribute("CourseId", "keyboard-circuit")
root:SetAttribute("CandidateRevision", "KC_P1_C08")
root:SetAttribute("Phase1Only", true)
root:SetAttribute("KCSessionEnabled", true)
local function snapshot(parent)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "SourceSnapshot", parent
    for name, source in sources do
        local copy = Instance.new(if name == "Session" then "Script" else if name == "KeyboardCircuitPreview" then "LocalScript" else "ModuleScript")
        copy.Name, copy.Source = name, source
        if copy:IsA("BaseScript") then copy.Disabled = true end
        copy.Parent = folder
    end
    return folder
end
local source = snapshot(root)
assert(require(source.ConfigSnapshot).Revision == "KC_P1_C08")
local garden = Instance.new("Folder")
garden.Name, garden.Parent = "StudGardenV2", root
storage.CourseBuilders.StudGardenV2.HazardClock:Clone().Parent = garden
local template = assert(storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true))
require(source.Sample).Build(root, Vector3.new(2300, 330, -1300), template)
require(source.RouteStudy).Build(root, Vector3.new(2300, 330, -1850))
root.Parent = prepared
local kit = require(source.Kit).Build(prepared, template)
snapshot(kit)
prepared.Parent = storage
return {prepared = prepared:GetFullName(), candidate = #root:GetDescendants(), kit = #kit:GetDescendants(), sourceCount = #source:GetChildren(), current = workspace.KeyboardCircuit_P1_C07:GetFullName()}
'''.replace("SOURCES", literal)
(root / "tools/keyboard-circuit/PrepareCandidateC08.luau").write_text(code, encoding="utf-8", newline="\n")
print(json.dumps({"sources": len(sources), "tool": "tools/keyboard-circuit/PrepareCandidateC08.luau"}))
