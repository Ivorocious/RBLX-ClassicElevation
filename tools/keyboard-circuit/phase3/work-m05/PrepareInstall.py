from pathlib import Path
import json

root = Path(__file__).resolve().parents[4]
work = root / 'tools/keyboard-circuit/phase3/work-m05'
baseline = root / 'tools/keyboard-circuit/phase3/work-m04/sources'
runtime = ['ArchiveEffects', 'ArchiveSkyConfig', 'ConfigSnapshot', 'EnvironmentParts', 'HazardIndicators', 'KeyboardCircuitAudio', 'KeyboardCircuitFeedback', 'MechanismRuntime', 'Mechanisms', 'Motion', 'Parts']
for name in runtime:
    destination = work / 'sources' / (name + '.luau')
    if not destination.exists():
        destination.write_bytes((baseline / (name + '.luau')).read_bytes())
globals = {
    'ServerScriptService.Services.StudioDevService': 'src/ServerScriptService/Services/StudioDevService.luau',
    'StarterPlayer.StarterPlayerScripts.Controllers.StudioDevController': 'src/StarterPlayer/StarterPlayerScripts/Controllers/StudioDevController.luau',
    'StarterPlayer.StarterPlayerScripts.Controllers.LobbyUiController': 'src/StarterPlayer/StarterPlayerScripts/Controllers/LobbyUiController.luau',
    'StarterPlayer.StarterPlayerScripts.KeyboardCircuit': 'src/StarterPlayer/StarterPlayerScripts/KeyboardCircuit.client.luau',
    'StarterPlayer.StarterPlayerScripts.ClassicAscentAmbience': 'src/StarterPlayer/StarterPlayerScripts/ClassicAscentAmbience.client.luau',
}
packet = {
    'sources': {name: (work / 'sources' / (name + '.luau')).read_bytes().decode('utf-8') for name in runtime},
    'adapter': (work / 'sources/StandardCourse.luau').read_bytes().decode('utf-8'),
    'presentation': (work / 'Presentation.luau').read_bytes().decode('utf-8'),
    'runtime': (work / 'sources/CourseRuntime.server.luau').read_bytes().decode('utf-8'),
    'globals': {name: (root / path).read_bytes().decode('utf-8') for name, path in globals.items()},
}
encoded = json.dumps(packet, ensure_ascii=True)
(work / 'InstallPacket.json').write_bytes(encoded.encode('utf-8'))
chunks = work / 'transfer'
chunks.mkdir(exist_ok=True)
for index, offset in enumerate(range(0, len(encoded), 40000)):
    (chunks / (str(index) + '.txt')).write_bytes(encoded[offset:offset+40000].encode('ascii'))
print(json.dumps({'runtimeModules': len(runtime), 'globalSources': len(globals)}))
