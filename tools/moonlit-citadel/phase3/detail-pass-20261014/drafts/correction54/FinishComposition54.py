"""Reopen the final R01 composition, verify preservation, and save exact final gate comparisons."""
import importlib.util
import json
from pathlib import Path

import bpy

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('correction_helpers',HERE/'RenderCorrection54.py')
h=importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
out=HERE/'render03'
saved=out/'MC_CORRECTION54_CANDIDATE.blend'
report_path=out/'correction54-composition-report.json'
report=json.loads(report_path.read_text())
assert h.h.sha(saved)==report['blend']['sha256']
assert h.h.sha(h.PLAN)==report['planSHA256']
bpy.ops.wm.open_mainfile(filepath=str(saved))
scene=bpy.context.scene
world=list(bpy.data.collections['Final_233_World_Units'].all_objects)
protected=list(bpy.data.collections['Unchanged_Source49_Visible_Course'].all_objects)
details=list(bpy.data.collections['DT54_Corrected_77_Details'].all_objects)
archived=list(bpy.data.collections['DT01_Additive_78_Details'].all_objects)
assert len(world)==639 and len(protected)==717 and len(details)==242 and len(archived)==250
assert h.h.frozen_digest(world)==report['oldWorldDigest']
assert h.h.frozen_digest(protected)==report['oldProtectedDigest']
assert len({obj['Detail54Unit']for obj in details})==77
assert sum(len(face.vertices)-2 for obj in details for face in obj.data.polygons)==84222
assert all(obj.hide_render and obj.hide_viewport for obj in archived)
mapping={row['object']:row for row in report['mapping']}
error=0
for obj in details:
    current=[value for row in obj.matrix_world for value in row]
    error=max(error,max(abs(a-b)for a,b in zip(current,mapping[obj.name]['matrix'])))
    assert not obj['NativeCanCollide'] and not obj['NativeCanQuery'] and not obj['NativeCanTouch']
assert error<.001
camera=bpy.data.objects['gate']
assert list(camera['CourseLocalEye'])==[-144,5.5,138]
for profile in ('night','day'):
    report['views'].append(h.render(scene,out,'after54-gate-'+profile,camera,profile))
report['comparableBeforeViews']={
    'gate-night':'../render01/before53-gate-night.png',
    'gate-day':'../render01/before53-gate-day.png',
    'west-night':'../render01/before53-west-night.png',
    'machinery-night':'../render01/before53-machinery-night.png'}
report['savedReopening']={'readable':True,'old639WorldPartsExact':True,'old717ProtectedVisibleObjectsExact':True,
                          'all250Original53DetailsRetainedHidden':True,'details':77,'meshParts':242,'triangles':84222,
                          'maximumSavedMatrixError':error,'allNewArtFlagsFalse':True,'nativeVerified':False}
report_path.write_text(json.dumps(report,indent=2)+'\n')
(out/'correction54-reopen-report.json').write_text(json.dumps(report['savedReopening'],indent=2)+'\n')
print('CORRECTION54_REOPEN_PASS '+json.dumps(report['savedReopening']),flush=True)
