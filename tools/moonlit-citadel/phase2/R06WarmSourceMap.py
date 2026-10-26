from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[3]
base=root/'docs/artifacts/moonlit-citadel/phase2'
old=json.loads((base/'MC_P2_R06_frozen_source_map05.json').read_text())
fresh=json.loads((base/'MC_P2_R06_frozen_source_map06.json').read_text())
path='ServerStorage/CourseBuilders/MoonlitCitadelCourse/Layout'
replacement=next(row for row in fresh['sources'] if row['instancePath']==path)
old['sources']=[replacement if row['instancePath']==path else row for row in old['sources']]
old['scope']='Warm owned fixture: current Moonlit and shared core; older unrelated manual palette/motion snapshot has zero active records in this Moonlit native model. Current repository palette files remain untouched.'
old['parents']={'map05':hashlib.sha256((base/'MC_P2_R06_frozen_source_map05.json').read_bytes()).hexdigest(),'map06':hashlib.sha256((base/'MC_P2_R06_frozen_source_map06.json').read_bytes()).hexdigest()}
output=base/'MC_P2_R06_frozen_source_map07.json'
assert not output.exists()
output.write_text(json.dumps(old),encoding='utf-8')
print(json.dumps({'sources':len(old['sources']),'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}))
