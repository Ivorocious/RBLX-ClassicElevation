"""Freeze and compare accepted course source; writes only inside this draft folder."""
import argparse
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / 'default.project.json').is_file())
COURSE = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
EXACT = [COURSE + name + '.luau' for name in ['Layout','ExpertRoutes','SupportingObstacles','RouteHazardLayout',
          'RouteHazardGoals','RouteHazards','Runtime','Coverage','Wayfinding','RouteBuilder','VisualAssembly']]
EXACT += ['src/ReplicatedStorage/Config/' + name + '.luau' for name in
          ['MoonlitCitadelCourseConfig','MoonlitCitadelAssemblyConfig','MoonlitCitadelConfig','RaceConfig','CourseConfig','CheckpointConfig']]
EXACT += ['src/ReplicatedStorage/Shared/' + name + '.luau' for name in ['RaceConstants','RaceTypes','ForwardGate','MoonlitCitadelAmbienceGate']]
EXACT += ['src/ServerScriptService/Services/' + name + '.luau' for name in
          ['MoonlitCitadelService','CheckpointService','RaceService','PlayerRaceService','RespawnService','CourseService',
           'CourseHazardService','CourseMotionService','StagingService','ArrivalDelivery']]
EXACT += [str(p.relative_to(ROOT)).replace('\\','/') for p in
          sorted((ROOT / 'src/ServerStorage/CourseBuilders/MoonlitCitadel').glob('*.luau'))]

def digest(data):
    return hashlib.sha256(data).hexdigest()

def current():
    files = {}
    for name in EXACT:
        path = ROOT / name
        if not path.is_file():
            raise FileNotFoundError('Required protected source is missing: ' + name)
        data = path.read_bytes()
        files[name] = {'sha256':digest(data),'bytes':len(data),'mode':'exact-file'}
    env_path = COURSE + 'EnvironmentPlan.luau'
    text = (ROOT / env_path).read_text(encoding='utf-8-sig')
    marker = 'local function placeTemplate('
    if text.count(marker) != 1 or text.count('function Environment.PlaceSolidArrow(') != 1:
        raise ValueError('Arrow implementation boundary changed; inspect explicitly before recapturing')
    protected = text[text.index(marker):].replace('\r\n','\n').encode()
    files[env_path + '#accepted-arrow-tail'] = {'sha256':digest(protected),'bytes':len(protected),'mode':'arrow-tail-only'}
    return {'schema':1,'requiredNativeIdentity':{'candidate':'MC_P3_REWORK_R04','source':38,'build':32,
            'packet':'56d992fa0cda21e53736b06f3d409e36911b1b77a9d3b5d9ce9cd1584b0dfc05'},'files':files,
            'artEditable':['WorldPlan.luau','WorldAssembly.luau','EnvironmentPlan.Get/Profile',
                           'MoonlitCitadelAmbienceConfig.luau'],
            'nativeBaselineRequired':True,'nativeBaselineCapturedByThisTool':False}

def owned_output(name):
    path = (HERE / name).resolve()
    if HERE not in path.parents:
        raise ValueError('Output must remain inside the protection draft folder')
    return path

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode',choices=['capture','compare'])
    parser.add_argument('--baseline',default='accepted-source-baseline-complete.json')
    parser.add_argument('--report',default='source-comparison.json')
    args = parser.parse_args()
    baseline_path = owned_output(args.baseline)
    state = current()
    if args.mode == 'capture':
        if baseline_path.exists():
            raise FileExistsError('Baseline already exists; preserve it and choose a fresh filename')
        baseline_path.write_text(json.dumps(state,indent=2)+'\n')
        print('Captured',len(state['files']),'protected source hashes;',baseline_path)
        return
    baseline = json.loads(baseline_path.read_text())
    names = set(baseline['files']) | set(state['files'])
    changed = [name for name in sorted(names) if baseline['files'].get(name) != state['files'].get(name)]
    report = {'pass':not changed,'changed':changed,'checked':len(names),'nativeGeometryCompared':False}
    owned_output(args.report).write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))
    raise SystemExit(1 if changed else 0)

if __name__ == '__main__':
    main()
