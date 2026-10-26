"""Read actual saved assembled mesh faces and bind their native part-axis mapping."""
import hashlib
import json
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Vector

ROOT = next(p for p in Path(__file__).resolve().parents if (p / "default.project.json").exists())
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / "tools/moonlit-citadel/phase3/closeout-20261014/drafts/crown-refinement/render02/MC_CROWN_REFINEMENT_CANDIDATE.blend"
PLAN = ROOT / "docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan51.json"
NATIVE = ROOT / "docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/final/enclosure_source49_layout.json"
AXIS = Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
INVERSE = AXIS.inverted()


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cf(row):
    return Matrix(((row[3],row[4],row[5],row[0]),(row[6],row[7],row[8],row[1]),
                   (row[9],row[10],row[11],row[2]),(0,0,0,1)))


def main():
    assert bpy.app.background
    output = HERE / "actual-assembled-keep.json"
    assert not output.exists()
    source_hash, plan_hash = sha(SOURCE), sha(PLAN)
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    data = json.loads(PLAN.read_text())
    unit = next(u for u in data["units"] if u["name"] == "GrandRearCentralPinnacle")
    matrix = cf(unit["localCF"])
    inverse_unit = (matrix @ Matrix.Diagonal((*unit["scale"],1))).inverted()
    parts = []
    for role in ("Stone","StoneLight","Slate"):
        obj = bpy.data.objects["GrandRearCentralPinnacle__"+role]
        points = [tuple(INVERSE @ (obj.matrix_world @ v.co)) for v in obj.data.vertices]
        asset_points = [tuple(inverse_unit @ Vector(p)) for p in points]
        parts.append({"name":obj.name,"material":role,"vertices":points,"assetVertices":asset_points,
                      "faces":[list(p.vertices) for p in obj.data.polygons],
                      "blenderMatrix":[v for row in obj.matrix_world for v in row],
                      "blenderMeshVertices":[tuple(v.co) for v in obj.data.vertices]})
    light = bpy.data.objects["GrandRearCentralPinnacle__StoneLight"]
    native = json.loads(NATIVE.read_text())
    native_part = next(p for p in native["parts"] if p["path"].endswith("GrandRearCentralPinnacle.MC_TL_GrandPinnacle__StoneLight"))
    native_matrix = cf(native_part["cf"])
    raw_course_matrix = INVERSE @ light.matrix_world
    bindings = []
    for axis in range(3):
        direction = Vector(tuple(native_matrix[row][axis] for row in range(3))).normalized()
        dots = [direction.dot(Vector(tuple(raw_course_matrix[row][raw] for row in range(3))).normalized()) for raw in range(3)]
        selected = max(range(3),key=lambda index:abs(dots[index]))
        assert abs(dots[selected])>.999999
        bindings.append({"nativeAxis":"XYZ"[axis],"nativeDirectionCourseLocal":tuple(direction),
                         "blenderMeshLocalAxis":"XYZ"[selected],"signedAlignment":dots[selected]})
    windows=[]
    for obj in bpy.data.objects:
        if not str(obj.get("Source50Unit","")).startswith("UpperKeepWarmLancet"):
            continue
        windows.append({"name":obj.name,"unit":obj.get("Source50Unit"),
                        "vertices":[tuple(INVERSE @ (obj.matrix_world @ v.co)) for v in obj.data.vertices],
                        "faces":[list(p.vertices) for p in obj.data.polygons],
                        "matrix":[v for row in obj.matrix_world for v in row]})
    assert len(windows)==14
    result={"sourceBlend":str(SOURCE.relative_to(ROOT)),"sourceBlendSHA256":source_hash,"sourcePlanSHA256":plan_hash,
            "unit":unit,"actualParts":parts,"nativeStoneLightPart":native_part,"nativeAxisBindings":bindings,
            "windowMaterialParts":windows,"protectedCollectionCount":len(bpy.data.collections["Unchanged_Source49_Visible_Course"].all_objects),
            "geometryMoved":False,"studioTouched":False,"scriptSHA256":sha(Path(__file__))}
    output.write_text(json.dumps(result,indent=2)+"\n")
    assert sha(SOURCE)==source_hash and sha(PLAN)==plan_hash
    print(json.dumps({"parts":len(parts),"windowMaterialParts":len(windows),"nativeAxisBindings":bindings}),flush=True)


if __name__=="__main__":
    main()
