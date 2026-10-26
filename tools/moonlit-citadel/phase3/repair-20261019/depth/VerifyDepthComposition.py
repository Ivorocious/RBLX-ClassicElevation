"""Check retained actual Blender faces and vertical open-void sight lines."""
import collections
import hashlib
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / "default.project.json").exists())
INVERSE = Matrix(((1,0,0),(0,0,1),(0,-1,0)))


def canonical(face):
    return min(tuple(face[i:] + face[:i]) for i in range(3))


def geometry(objects):
    vertices, triangles = [], []
    for obj in objects:
        offset = len(vertices)
        vertices.extend(INVERSE @ (obj.matrix_world @ v.co) for v in obj.data.vertices)
        for face in obj.data.polygons:
            for i in range(1,len(face.vertices)-1):
                triangles.append((offset+face.vertices[0],offset+face.vertices[i],offset+face.vertices[i+1]))
    return vertices, triangles


def main():
    assert bpy.app.background
    path = HERE / "comparison01/MC_DEPTH_DP01_COMPARISON.blend"
    bpy.ops.wm.open_mainfile(filepath=str(path))
    original = [obj for obj in bpy.data.collections["Final_233_World_Units"].all_objects if obj.get("Source50Unit")=="MC_EC_InnerRavine"]
    new = list(bpy.data.collections["DP01_Open_Chasm_Candidate"].all_objects)
    for obj in original: obj.hide_viewport = False
    bpy.context.view_layer.update()
    old_tops = [obj for obj in original if "__RockA." in obj.name or "__RockB." in obj.name]
    assert len(original)==3 and len(old_tops)==2 and len(new)==2
    new_top = [obj for obj in new if obj.name.endswith("__RockTop")]
    ov, of = geometry(old_tops)
    nv, nf = geometry(new_top)
    assert len(of)==29264 and len(nf)==12759
    tolerance = .001
    cells, unique, old_ids = {}, [], []
    for point in ov:
        cell = tuple(math.floor(v/tolerance) for v in point)
        found = None
        for x in (-1,0,1):
            for y in (-1,0,1):
                for z in (-1,0,1):
                    for index in cells.get((cell[0]+x,cell[1]+y,cell[2]+z),[]):
                        if (unique[index]-point).length<tolerance: found=index
        if found is None:
            found=len(unique)
            unique.append(point.copy())
            cells.setdefault(cell,[]).append(found)
        old_ids.append(found)
    tree = KDTree(len(unique))
    for index,point in enumerate(unique): tree.insert(point,index)
    tree.balance()
    old_faces = collections.Counter(canonical([old_ids[i] for i in face]) for face in of)
    high_faces = collections.Counter(canonical([old_ids[i] for i in face]) for face in of if max(ov[i].y for i in face)>=-23)
    new_ids, max_error = [], 0
    for point in nv:
        nearest,index,error=tree.find(point)
        assert error<.001, (tuple(point),tuple(nearest),error)
        max_error=max(max_error,error)
        new_ids.append(index)
    new_faces=collections.Counter(canonical([new_ids[i] for i in face]) for face in nf)
    assert not new_faces-old_faces and not high_faces-new_faces, (sum((new_faces-old_faces).values()),sum((high_faces-new_faces).values()))
    old_v,old_f=geometry(original)
    new_v,new_f=geometry(new)
    old_bvh=BVHTree.FromPolygons(old_v,old_f,all_triangles=True)
    new_bvh=BVHTree.FromPolygons(new_v,new_f,all_triangles=True)
    probes=[]
    for name,x,z in (("Gate",-144,138),("CP01",-144,-112),("CP02",-80,28),("CP03",112,-52),("CP04",112,-86),("Crown",-8,-30)):
        before=old_bvh.ray_cast(Vector((x,-24,z)),Vector((0,-1,0)),2000)
        after=new_bvh.ray_cast(Vector((x,-24,z)),Vector((0,-1,0)),2000)
        row={"name":name,"from":[x,-24,z],"beforeTerrainY":None if before[0] is None else before[0].y,
             "afterTerrainY":None if after[0] is None else after[0].y,"openVoidTo2024StudsBelowOrigin":after[0] is None}
        assert before[0] is not None and after[0] is None, row
        probes.append(row)
    report={"pass":True,"scene":str(path.relative_to(ROOT)),"sceneSha256":hashlib.sha256(path.read_bytes()).hexdigest(),
            "actualOldTopTriangles":len(of),"actualNewTopTriangles":len(nf),"allNewTopTrianglesMatchOriginalOrientedFaces":True,
            "allOld797UpperBankTrianglesRetained":sum(high_faces.values())==797,"maxRetainedVertexError":max_error,
            "openVoidProbes":probes,"physicsChanged":False,"actualNativeFallsVerified":False,"nativeImportedFacesVerified":False}
    assert report["allOld797UpperBankTrianglesRetained"]
    (HERE/"comparison01/retained-face-void-proof.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print("DEPTH_FACE_VOID_PASS "+json.dumps({"retained":len(nf),"highBanks":sum(high_faces.values()),"openVoidColumns":len(probes),"maxVertexError":max_error}),flush=True)


if __name__=="__main__":main()
