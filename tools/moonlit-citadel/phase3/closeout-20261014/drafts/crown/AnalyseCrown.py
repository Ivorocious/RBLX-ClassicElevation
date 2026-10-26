"""Check standing crown rays against existing authored scenery, without Blender or Studio."""
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import types

import numpy as np

sys.dont_write_bytecode = True
ROOT = next(p for p in Path(__file__).resolve().parents if (p / "default.project.json").exists())
HERE = Path(__file__).resolve().parent
ENCLOSURE = ROOT / "tools/moonlit-citadel/phase3/enclosure-repair-20261013"
ARTIFACTS = ROOT / "docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013"


class RecipeVector(np.ndarray):
    def __new__(cls, value):
        return np.asarray(value, dtype=float).view(cls)

    @property
    def length(self):
        return float(np.linalg.norm(self))

    def normalize(self):
        self /= self.length

    def normalized(self):
        return RecipeVector(self / self.length)

    def cross(self, other):
        return RecipeVector(np.cross(self, other))


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    sys.modules[name] = result
    spec.loader.exec_module(result)
    return result


def recipes():
    for name in ("bpy", "bmesh", "mathutils"):
        sys.modules[name] = types.ModuleType(name)
    sys.modules["mathutils"].Vector = RecipeVector
    architecture = load(ROOT / "assets/moonlit_citadel/bl02/architecture.py", "crown_architecture")
    exporter = load(ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py", "crown_exporter")
    assets = {a["asset"]: a["parts"] for a in json.loads((ENCLOSURE / "drafts/geometry/combined-authored.json").read_text())["assets"]}
    screen, _ = exporter.crown_screen(architecture)
    assets["MC_P3_CrownScreen"] = []
    for material in dict.fromkeys(screen.colors):
        faces = [face for face, color in zip(screen.faces, screen.colors) if color == material]
        used = sorted({index for face in faces for index in face})
        indices = {index: new for new, index in enumerate(used)}
        assets["MC_P3_CrownScreen"].append({"name": "CrownScreen__" + material, "material": material,
            "vertices": [(screen.vertices[i][0], screen.vertices[i][2], -screen.vertices[i][1]) for i in used],
            "faces": [[indices[i] for i in face] for face in faces]})
    tower = load(ROOT / "tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/tower/BlenderTowerRecipe.py", "crown_tower")
    for factory in (tower.grand_pinnacle, tower.flank_pinnacle, tower.stepped_buttress):
        unit = factory()
        assets[unit.name] = [{"name": unit.name + "__" + role, "material": role, "vertices": [(x, z, -y) for x, y, z in vertices], "faces": faces}
                             for role, (vertices, faces) in unit.geometry.items()]
    sys.path.insert(0, str(ENCLOSURE / "drafts/landscape"))
    landscape = load(ENCLOSURE / "drafts/landscape/EnclosureRecipes.py", "crown_landscape")
    for name, mesh in landscape.build_recipes().items():
        assets[name] = [{"name": name, "vertices": mesh.vertices, "faces": mesh.faces}]
    return assets


def placed_triangles(parts, unit):
    frame = np.array(unit["localCF"])
    matrix = frame[3:].reshape((3, 3))
    scale = np.array(unit["scale"])
    triangles = []
    for part in parts:
        vertices = (np.array(part["vertices"]) * scale) @ matrix.T + frame[:3]
        for face in part["faces"]:
            triangles.extend((vertices[face[0]], vertices[face[i]], vertices[face[i + 1]]) for i in range(1, len(face) - 1))
    return np.array(triangles)


def ray_triangle_hits(origin, target, triangles):
    direction = target - origin
    a = triangles[:, 0]
    e1 = triangles[:, 1] - a
    e2 = triangles[:, 2] - a
    p = np.cross(direction, e2)
    det = np.einsum("ij,ij->i", e1, p)
    valid = np.abs(det) > 1e-10
    inv = np.divide(1, det, out=np.zeros_like(det), where=valid)
    rel = origin - a
    u = np.einsum("ij,ij->i", rel, p) * inv
    q = np.cross(rel, e1)
    v = q @ direction * inv
    t = np.einsum("ij,ij->i", e2, q) * inv
    select = valid & (u >= -1e-7) & (v >= -1e-7) & (u + v <= 1 + 1e-7) & (t > 1e-6) & (t < .999999)
    return sorted(float(x) for x in t[select])


def ray_box(origin, target, part):
    frame = np.array(part["cf"])
    matrix = frame[3:].reshape((3, 3))
    o = matrix.T @ (origin - frame[:3])
    d = matrix.T @ (target - origin)
    half = np.array(part["size"]) / 2
    lo, hi = 0.0, 1.0
    for k in range(3):
        if abs(d[k]) < 1e-8:
            if abs(o[k]) > half[k]:
                return None
        else:
            a, b = sorted(((-half[k] - o[k]) / d[k], (half[k] - o[k]) / d[k]))
            lo, hi = max(lo, a), min(hi, b)
            if lo > hi:
                return None
    return lo if 1e-6 < lo < .999999 else None


def revised(units, kind):
    result = json.loads(json.dumps(units))
    for unit in result:
        if kind != "installed49" and unit["name"] in ("GrandFlankPinnacle-1", "GrandFlankPinnacle1"):
            unit["scale"] = [.9, .3, .9]
        if kind == "loweredRim" and unit["name"] == "CrownBaseUnifiedShell":
            unit["localCF"][1] -= 12
    if kind == "loweredRim":
        def add(name, point, scale):
            result.append({"name": name, "district": "CrownArrival", "asset": "MC_AR_MasonryMass", "library": "ER01",
                           "localCF": list(point) + [1, 0, 0, 0, 1, 0, 0, 0, 1], "scale": list(scale), "materialRole": "StoneStructure"})
        add("CrownRaisedFloorCarrier", (-8, 125, -30), (1.4, (148.6 - 125) / 24, 2.08))
        for index, x in enumerate((-26, -14, -2, 10), 1):
            add(f"CrownSouthScreenFoot{index}", (x, 136.5, -10), (.052, 13.1 / 24, .18))
        for index, z in enumerate((-46, -33, -20, -7), 1):
            add(f"CrownWestScreenFoot{index}", (-31, 136.5, z), (.0936, 13.1 / 24, .1))
        add("CrownEmblemLowerPier", (-8, 136.5, -9.1), (.36, 13.1 / 24, .16))
    return result


def run():
    original = json.loads((ARTIFACTS / "combined-plan49.json").read_text())["units"]
    native = json.loads((ARTIFACTS / "final/enclosure_source49_layout.json").read_text())["parts"]
    assets = recipes()
    eyes = {"centre": (-8, 155.5, -30), "southwestStanding": (-23.5, 155.5, -18.5)}
    targets = {
        "forwardGateRoof": (-144, 82, 106),
        "southwestArrivalBastionRoof": (-229, 92, 104),
        "westClimbCP01": (-144, 33.5, -112),
        "archRouteMid": (-144, 26, -5),
        "galleryRoof": (18, 109, 122),
        "galleryLanterns": (-35, 67, 56),
        "southeastBastionRoof": (130, 85, 140),
        "southwestWoodedHorizon": (-225, 184, 238),
        "southWoodedHorizon": (-95, 205, 260),
        "upperMachineRoute": (102, 143, -115),
        "upperCauseway": (78, 143, -162),
        "eastGalleryBastionUpper": (231, 144, 35),
        "eastWoodland": (305, 190, 60),
        "southeastWoodland": (250, 165, 235),
        "southeastBastionTip": (130, 96.4, 140),
        "forwardGateUpperFrame": (-144, 190, 106),
        "easternMidRoofCorridor": (200, 130, 80),
        "easternWoodedGapCorridor": (285, 177, 112),
        "southeastLowLayerCorridor": (250, 112, 122),
        "eastGalleryBastionFarEdgeCorridor": (230, 142, 66),
    }
    report = {"standingFloorBounds": {"low": [-26, 150, -44], "high": [10, 150, -16]},
              "eyeHeight": 5.5, "nativeImageNeeded": True, "changes": {}, "cases": {}, "inputHashes": {}}
    for kind in ("installed49", "turretsOnly", "loweredRim"):
        units = revised(original, kind)
        scene = [(unit, placed_triangles(assets[unit["asset"]], unit)) for unit in units if unit["asset"] in assets]
        exact_names = {unit["name"] for unit, _ in scene}
        conservative = []
        for part in native:
            if part["transparency"] >= 1:
                continue
            path = part["path"].split(".")
            if "Phase3World" in path:
                index = path.index("Phase3World")
                if path[index + 2] in exact_names:
                    continue
            conservative.append(part)
        case = {"authoredSceneryTriangles": sum(len(t) for _, t in scene), "fallbackPartBounds": len(conservative), "rays": []}
        for eye_name, eye in eyes.items():
            origin = np.array(eye)
            for target_name, point in targets.items():
                target = np.array(point)
                exact = []
                for unit, triangles in scene:
                    if len(triangles) == 0:
                        continue
                    hits = ray_triangle_hits(origin, target, triangles)
                    if hits:
                        exact.append({"name": unit["name"], "distance": hits[0] * float(np.linalg.norm(target - origin)), "fraction": hits[0]})
                exact.sort(key=lambda hit: hit["fraction"])
                bounds = []
                for part in conservative:
                    hit = ray_box(origin, target, part)
                    if hit is not None:
                        bounds.append({"path": part["path"], "distance": hit * float(np.linalg.norm(target - origin)), "fraction": hit})
                bounds.sort(key=lambda hit: hit["fraction"])
                case["rays"].append({"eye": eye_name, "target": target_name, "origin": list(eye), "point": list(point),
                                     "exactHits": exact[:5], "conservativeBoundsHits": bounds[:5]})
        report["cases"][kind] = case
    candidate = revised(original, "turretsOnly")
    before = {u["name"]: u for u in original}
    report["changes"] = {u["name"]: {"before": before.get(u["name"]), "after": u} for u in candidate if u != before.get(u["name"])}
    report["selectedCase"] = "turretsOnly"
    report["rejectedLargerAlternative"] = "The raised-rim/carrier alternative did not improve the four chosen exact-centre E/SE corridors; leave CrownBase and both screens exact."
    for path in (Path(__file__).resolve(), ARTIFACTS / "combined-plan49.json", ARTIFACTS / "final/enclosure_source49_layout.json",
                 ENCLOSURE / "drafts/geometry/combined-authored.json",
                 ROOT / "tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/tower/BlenderTowerRecipe.py",
                 ROOT / "assets/moonlit_citadel/phase3/drafts/world_kit.py"):
        report["inputHashes"][str(path.relative_to(ROOT)).replace("\\", "/")] = hashlib.sha256(path.read_bytes()).hexdigest()
    (HERE / "crown-rays.json").write_text(json.dumps(report, indent=2) + "\n")
    (HERE / "candidate-unit-plan.json").write_text(json.dumps(candidate, indent=2) + "\n")
    for kind, case in report["cases"].items():
        print(kind)
        for ray in case["rays"]:
            if ray["eye"] == "southwestStanding":
                print(ray["target"], "exact:", [(h["name"], round(h["distance"], 2)) for h in ray["exactHits"][:2]],
                      "bounds:", [(h["path"], round(h["distance"], 2)) for h in ray["conservativeBoundsHits"][:2]])


if __name__ == "__main__":
    run()
