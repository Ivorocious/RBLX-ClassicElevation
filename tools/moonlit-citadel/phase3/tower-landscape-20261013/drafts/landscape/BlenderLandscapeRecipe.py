"""Four closed landscape units for the lead's joint Blender export."""
import importlib.util
from pathlib import Path

_path = Path(__file__).with_name("LandscapeKitRecipes.py")
_spec = importlib.util.spec_from_file_location("moonlit_rural_landscape_meshes", _path)
_module = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_module)
PALETTE = _module.PALETTE


def recipes(a, e):
    result = []
    notes = {
        "MC_P3_Rural_Mound": "Edge-plane origin Y0; grass peakY6; rock footY-14;64x52 rounded mound; three closed material meshes; decorative only.",
        "MC_P3_Rural_BroadleafClump": "Root-plane originY0 with2stud embedded roots; three rounded trees22/30/25high; two closed material meshes; no alpha leaves.",
        "MC_P3_Rural_EvergreenGrove": "Root-plane originY0 with2stud embedded roots; three trees24/34/29high; closed flat-shaded tier foliage; two material meshes.",
        "MC_P3_Rural_HeatherFern": "Soil-plane originY0;18wide low closed shrub/heather group; Flower and Leaf meshes; no cards or planes.",
    }
    for name, mesh in _module.build_recipes().items():
        geometry = a._Mesh()
        for face, material in zip(mesh.faces, mesh.materials):
            vertices = [(mesh.vertices[index][0], -mesh.vertices[index][2], mesh.vertices[index][1]) for index in face]
            geometry.add(vertices, [tuple(range(len(vertices)))], material, material in {"Grass", "Foliage", "Wood"})
        low, high = mesh.bounds()
        low_blender, high_blender = (low[0], -high[2], low[1]), (high[0], -low[2], high[1])
        centre = tuple((lo + hi) / 2 for lo, hi in zip(low_blender, high_blender))
        size = tuple(hi - lo for lo, hi in zip(low_blender, high_blender))
        result.append((name, geometry, [e.box_proxy(centre, size)], notes[name]))
    return result
