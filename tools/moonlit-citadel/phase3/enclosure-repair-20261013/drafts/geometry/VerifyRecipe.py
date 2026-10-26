"""Pure Python checks of authored ER01 polygons; does not execute Blender."""
import collections
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import types

sys.dont_write_bytecode = True

HERE = Path(__file__).resolve().parent


def load_recipe():
    for name in ("bpy", "bmesh", "mathutils"):
        sys.modules[name] = types.ModuleType(name)
    sys.modules["mathutils"].Vector = lambda value: value
    spec = importlib.util.spec_from_file_location("er_recipe", HERE / "BlenderEnclosureRepairKit.py")
    recipe = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(recipe)
    a = recipe.load(recipe.ROOT / "assets/moonlit_citadel/bl02/architecture.py", "er_a")
    e = recipe.load(recipe.ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py", "er_e")
    original = a._Mesh

    class RecordingMesh(original):
        def __init__(self):
            super().__init__()
            self.boxes = []

        def box(self, center, size, color="Stone"):
            self.boxes.append({"material": color, "low": [c-s/2 for c, s in zip(center, size)],
                               "high": [c+s/2 for c, s in zip(center, size)]})
            super().box(center, size, color)

    a._Mesh = RecordingMesh
    return recipe, a, e


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def check_part(part):
    vertices, faces = part["vertices"], part["faces"]
    edges, directed = collections.Counter(), collections.Counter()
    adjacency = collections.defaultdict(set)
    for face in faces:
        for i, j in zip(face, face[1:] + face[:1]):
            edges[tuple(sorted((i, j)))] += 1
            directed[i, j] += 1
            adjacency[i].add(j)
            adjacency[j].add(i)
    assert all(n == 2 for n in edges.values()), part["name"]
    assert all(directed[i, j] == directed[j, i] for i, j in directed), part["name"]
    remaining, components = set(adjacency), []
    while remaining:
        component, pending = set(), [next(iter(remaining))]
        while pending:
            i = pending.pop()
            if i not in component:
                component.add(i)
                pending.extend(adjacency[i]-component)
        remaining -= component
        components.append(component)
    volumes = []
    for component in components:
        volume = 0
        for face in faces:
            if face[0] not in component:
                continue
            for j in range(1, len(face)-1):
                p, q, r = (vertices[i] for i in (face[0], face[j], face[j+1]))
                volume += dot(p, cross(q, r))/6
        assert volume > 1e-8, (part["name"], volume)
        volumes.append(volume)
    for face in faces:
        p, q, r = (vertices[i] for i in face[:3])
        normal = cross([q[i]-p[i] for i in range(3)], [r[i]-p[i] for i in range(3)])
        assert dot(normal, normal) > 1e-16
        assert all(abs(dot(normal, [vertices[j][i]-p[i] for i in range(3)])) < 1e-6 for j in face)
    return {"name": part["name"], "triangles": sum(len(f)-2 for f in faces),
            "closed_components": len(components), "component_volumes": volumes,
            "bounds": [[min(v[i] for v in vertices) for i in range(3)],
                       [max(v[i] for v in vertices) for i in range(3)]]}


def main():
    recipe, a, e = load_recipe()
    assets, results = [], []
    for name, factory in recipe.FACTORIES.items():
        g, occupied, notes = factory(a, e)
        record = recipe.authored_record(name, g)
        record["boxes"] = [{"material": b["material"],
                            "low": [b["low"][0], b["low"][2], -b["high"][1]],
                            "high": [b["high"][0], b["high"][2], -b["low"][1]]} for b in g.boxes]
        checks = [check_part(p) for p in record["parts"]]
        if name.startswith("MC_AR_"):
            stone, footer, coping = record["boxes"][:3]
            assert abs(footer["high"][1]-stone["low"][1]-.01) < 1e-8
            assert abs(stone["high"][1]-coping["low"][1]-.01) < 1e-8
        elif name == "MC_ER_MainKeepShell":
            exterior = recipe.authored_record(name, recipe.keep_recipe.exterior(a))
            exterior_check = check_part(exterior["parts"][0])
            record["canonical_exterior"] = exterior["parts"][0]
            assert exterior_check["closed_components"] == 1
            assert not recipe.keep_recipe.contains(recipe.keep_recipe.CORE, 0, 0)
            assert not recipe.keep_recipe.contains(recipe.keep_recipe.COPING, 0, 0)
            assert recipe.keep_recipe.contains(recipe.keep_recipe.CORE, 0, -20)
            record["boxes"] = [{"low": [b["low"][0], b["low"][2], -b["high"][1]],
                                "high": [b["high"][0], b["high"][2], -b["low"][1]]} for b in occupied]
            record["exterior_check"] = exterior_check
        else:
            exterior_mesh,stats = recipe.crown_recipe.exterior(a)
            exterior = recipe.authored_record(name,exterior_mesh)
            exterior_check = check_part(exterior["parts"][0])
            assert abs(sum(exterior_check["component_volumes"])-stats["union_volume"]) < 1e-5
            record["canonical_exterior"] = exterior["parts"][0]
            record["exterior_check"] = exterior_check
            record["exterior_stats"] = stats
            record["boxes"] = record["solid_boxes"]
        results.append({"asset": name, "parts": checks, "triangles": sum(p["triangles"] for p in checks),
                        "occupied_boxes_blender": occupied, "notes": notes})
        assets.append(record)
    result = {"candidate": recipe.BUILD, "verification": "Pure authored polygon check; Blender/native import pending",
              "recipe_sha256": hashlib.sha256((HERE / "BlenderEnclosureRepairKit.py").read_bytes()).hexdigest(),
              "assets": results, "parts": sum(len(a["parts"]) for a in assets),
              "triangles": sum(a["triangles"] for a in results)}
    (HERE / "recipe-check.json").write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
    (HERE / "authored-vertices.json").write_text(json.dumps({"axes": "Roblox", "assets": assets})+"\n", encoding="utf-8")
    print(json.dumps({"parts": result["parts"], "triangles": result["triangles"],
                      "assets": [{"asset": a["asset"], "triangles": a["triangles"]} for a in results]}))


if __name__ == "__main__":
    main()
