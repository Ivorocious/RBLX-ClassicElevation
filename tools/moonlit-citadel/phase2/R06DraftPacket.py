from pathlib import Path
import hashlib
import json
import sys

root = Path(__file__).resolve().parents[3]
label = sys.argv[1]
assert label.isalnum(), 'Use a fresh alphanumeric draft label'
draft = 'docs/artifacts/moonlit-citadel/phase2/revision06/'
inputs = {
    'CourseConfig': draft + 'MoonlitCitadelCourseConfig.luau',
    'AssemblyConfig': draft + 'MoonlitCitadelAssemblyConfig.luau',
    'Layout': draft + 'route/R06Layout.luau',
    'RouteBuilder': draft + 'RouteBuilder.luau',
    'VisualAssembly': draft + 'VisualAssembly.luau',
    'Wayfinding': draft + 'clarity/Wayfinding.luau',
    'DecorativeClearance': draft + 'clarity/DecorativeClearance.luau',
    'KitConfig': 'src/ReplicatedStorage/Config/MoonlitCitadelConfig.luau',
    'MeshKit': 'src/ServerStorage/CourseBuilders/MoonlitCitadel/MeshKit.luau',
}
rows = []
for name, source_path in inputs.items():
    data = (root / source_path).read_bytes()
    rows.append({'name': name, 'file': source_path,
                 'source': data.decode('utf-8-sig').replace('\r\n', '\n'),
                 'sha256': hashlib.sha256(data).hexdigest()})
output = root / f'docs/artifacts/moonlit-citadel/phase2/MC_P2_R06_draft{label}.json'
assert not output.exists(), 'Preserve previous source packets'
output.write_text(json.dumps({'candidate': 'MC_P2_C01_R06', 'sources': rows}), encoding='utf-8')
print(json.dumps({'output': str(output), 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(), 'sources': len(rows)}))
