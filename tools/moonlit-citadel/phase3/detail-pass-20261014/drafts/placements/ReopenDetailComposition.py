"""Read back the saved additive composition and verify counts, frames and old mesh preservation."""
import hashlib
import importlib.util
import json
from pathlib import Path

import bpy
from mathutils import Matrix

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
spec=importlib.util.spec_from_file_location('detail_composition_helpers',HERE/'RenderDetailComposition.py')
helpers=importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
out=HERE/'render02'
saved=out/'MC_DETAIL53_CANDIDATE.blend'
report=json.loads((out/'detail-composition-report.json').read_text())
assert helpers.sha(saved)==report['blend']['sha256']
assert helpers.sha(HERE/'detail-placement-plan.json')==report['planSHA256']
bpy.ops.wm.open_mainfile(filepath=str(saved))
world=list(bpy.data.collections['Final_233_World_Units'].all_objects)
protected=list(bpy.data.collections['Unchanged_Source49_Visible_Course'].all_objects)
details=list(bpy.data.collections['DT01_Additive_78_Details'].all_objects)
assert len(world)==639 and len(protected)==717 and len(details)==250
assert helpers.frozen_digest(world)==report['oldWorldDigest']
assert helpers.frozen_digest(protected)==report['oldProtectedDigest']
assert len({obj['Detail53Unit']for obj in details})==78
assert sum(len(face.vertices)-2 for obj in details for face in obj.data.polygons)==92092
mapping={row['object']:row for row in report['assemblyMapping']}
maximum_error=0
for obj in details:
    wanted=mapping[obj.name]['blenderMatrix']
    actual=[value for line in obj.matrix_world for value in line]
    maximum_error=max(maximum_error,max(abs(a-b)for a,b in zip(actual,wanted)))
    assert not obj['NativeCanCollide'] and not obj['NativeCanQuery'] and not obj['NativeCanTouch']
assert maximum_error<.001
result={'readable':True,'blendSHA256':helpers.sha(saved),'units':78,'meshParts':250,'triangles':92092,
        'maximumSavedMatrixError':maximum_error,'all639OldWorldPartsPreserved':True,'all717ProtectedVisibleObjectsPreserved':True,
        'allNewArtFlagsFalse':True,'nativeVerified':False,'studioTouched':False,'liveBlenderTouched':False}
(out/'detail-reopen-report.json').write_text(json.dumps(result,indent=2)+'\n')
print('DETAIL_REOPEN_PASS '+json.dumps(result),flush=True)
