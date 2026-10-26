"""Export authored mesh coordinates for the native axis comparison."""
import json
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[4]
parts = {}
for obj in bpy.data.collections["MC_P3_TOWER_LANDSCAPE_TL01_Export"].objects:
    parts[obj.name] = [[v.co.x, v.co.z, -v.co.y] for v in obj.data.vertices]
path = ROOT / "docs/artifacts/moonlit-citadel/phase3/tower-landscape-20261013/authored-vertices.json"
path.write_text(json.dumps(parts, separators=(",", ":")), encoding="utf-8")
print(json.dumps({"parts": len(parts), "vertices": sum(len(v) for v in parts.values())}))
