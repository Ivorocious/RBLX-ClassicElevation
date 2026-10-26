"""Author clear red contact hazards and a separable block chicken in Blender."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import math
from pathlib import Path
import time

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
OUT = HERE / "candidate_a01"
MODULE = REPO / "src/ServerStorage/CourseBuilders/EggRush/RestartP2/ReadableKit.luau"
BUILD = "ER_P2_R03_A01"
spec = importlib.util.spec_from_file_location("hazard_tools", HERE.parent / "revision_r02/hazards/build_hazard_kit.py")
kit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kit)
kit.PALETTE = {
    "Cream": (255, 240, 202), "Coral": (246, 125, 96),
    "Iron": (47, 52, 61), "Hot": (255, 20, 35), "Ink": (33, 38, 48),
}
B = kit.block

TEMPLATES = {
    "ScorchedShell": [
        B("CharcoalCradle", (6,.3,2), (0,.15,0), "Iron"),
        B("HotShellLeft", (1.6,2.1,1.85), (-1.65,1.22,0), "Hot", -19),
        B("HotShellCrown", (1.65,2.65,1.85), (0,1.57,0), "Hot"),
        B("HotShellRight", (1.6,2.1,1.85), (1.65,1.22,0), "Hot", 19),
    ],
    "HeatGrate": [
        B("CharcoalBase", (5,.3,2.4), (0,.15,0), "Iron"),
        B("CharcoalFrontRail", (5,.5,.25), (0,.3,-1.15), "Iron"),
        B("CharcoalBackRail", (5,.5,.25), (0,.3,1.15), "Iron"),
        B("HotBarLeft", (1.75,.65,2.05), (-1.17,.58,0), "Hot"),
        B("HotBarRight", (1.75,.65,2.05), (1.17,.58,0), "Hot"),
    ],
    "FeederPaddle": [
        B("CharcoalMotorFoot", (1.9,.45,2.1), (0,.225,0), "Iron"),
        B("CharcoalMotor", (1.2,1.5,1.65), (0,1.1,0), "Iron"),
        B("CharcoalHub", (1.5,.9,1.95), (0,1.6,0), "Iron"),
        B("HotShaft", (4.65,.75,1.25), (2.5,1.6,0), "Hot"),
        B("HotPaddle", (1.65,1.8,3.1), (5.55,1.6,0), "Hot"),
    ],
    "FeatherPinch": [
        B("CharcoalFoot", (5.7,.35,2.2), (0,.175,0), "Iron"),
        B("HotFeatherLeft", (1.7,2.6,1.95), (-1.65,1.64,0), "Hot", -15),
        B("HotFeatherRight", (1.7,2.6,1.95), (1.65,1.64,0), "Hot", 15),
        B("HotFeatherTipLeft", (1.65,.6,1.95), (-1.27,2.86,0), "Hot", 15),
        B("HotFeatherTipRight", (1.65,.6,1.95), (1.27,2.86,0), "Hot", -15),
    ],
    "Body": [
        B("Torso", (31,20,29), (0,12,0), "Cream"),
        B("Breast", (18,24,23), (13,15,0), "Cream"),
        B("BackStep", (17,8,24), (-6,21,0), "Cream"),
        B("TailCenter", (5,16,8), (-19,19,0), "Cream", -12),
        B("TailCoralLeft", (5,13,6), (-18,17,-6), "Coral", -18),
        B("TailCoralRight", (5,13,6), (-18,17,6), "Coral", -18),
    ],
    "Head": [
        B("HeadBlock", (13,11,13), (0,0,0), "Cream"),
        B("BrowStep", (11.2,1.2,6.5), (0,5.7,-2.2), "Cream"),
        B("CrownBase", (3.2,1.1,9.5), (0,6.65,.2), "Coral"),
        B("CombFront", (3,3,2.5), (0,8,-3), "Coral"),
        B("CombMiddle", (3,4.2,2.5), (0,8.6,0), "Coral"),
        B("CombBack", (3,3.3,2.5), (0,8.15,3), "Coral"),
        B("Beak", (6,2,4), (0,-1,-8), "Hot"),
        B("Wattle", (1.7,3,1.7), (0,-3.5,-6.2), "Coral"),
    ],
}
for side in (-1, 1):
    TEMPLATES["Body"].extend([
        B(f"Wing_{side}", (24,12,5), (-1,15,side*16), "Cream"),
        B(f"WingPanel_{side}", (19,7,1), (-2,15.2,side*18.65), "Coral"),
        B(f"Foot_{side}", (13,3,8), (10,1,side*8), "Coral"),
        B(f"ToeA_{side}", (5,2.5,2.4), (17,0.75,side*8-2.3), "Coral"),
        B(f"ToeB_{side}", (5,2.5,2.4), (17,0.75,side*8+2.3), "Coral"),
    ])
    TEMPLATES["Head"].extend([
        B(f"SleepEyeBase_{side}", (.16,.65,3.2), (side*6.57,.55,-2.5), "Ink"),
        B(f"SleepEyeFront_{side}", (.16,1.4,.6), (side*6.57,1.4,-3.8), "Ink"),
        B(f"SleepEyeBack_{side}", (.16,1.4,.6), (side*6.57,1.4,-1.2), "Ink"),
    ])


def main():
    started = time.perf_counter()
    OUT.mkdir(parents=True, exist_ok=True)
    assert not (OUT / "readable_kit.blend").exists(), "Choose a fresh candidate folder."
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = BUILD
    mats = {name: kit.material(name,rgb,name=="Hot",name=="Iron") for name,rgb in kit.PALETTE.items()}
    placements = {"ScorchedShell": (-5,4,0), "HeatGrate": (5,4,0),
                  "FeederPaddle": (-7,-4,0), "FeatherPinch": (5,-4,0),
                  "Body": (-35,40,0), "Head": (10,40,40)}
    records = {}
    for key, definitions in TEMPLATES.items():
        root = bpy.data.objects.new(key,None)
        scene.collection.objects.link(root)
        root.location = placements[key]
        root["TemplateKey"] = key
        parts = [kit.create_box(scene,root,p,mats) for p in definitions]
        bpy.context.view_layer.update()
        exported, corners = [], []
        for part in parts:
            row, points = kit.inspect_part(part)
            exported.append(row)
            corners.extend(points)
        low = kit.rounded(min(v[i] for v in corners) for i in range(3))
        high = kit.rounded(max(v[i] for v in corners) for i in range(3))
        assert all(math.isfinite(v) for v in low+high)
        records[key] = {"partCount":len(parts), "lethalPartCount":sum(p["lethal"] for p in exported),
                        "boundsRoblox":[low,high], "parts":exported}
    kit.export_module(MODULE,records)
    content = MODULE.read_text(encoding="utf8").replace("HazardKit","ReadableKit").replace(
        "revision_r02/hazards/build_hazard_kit.py", "revision_r03/build_readable_kit.py")
    MODULE.write_text(content,encoding="utf8")
    manifest = {"build":BUILD,"blenderVersion":bpy.app.version_string,"templates":records,
                "palette":kit.PALETTE,"axes":"Roblox X,Y,Z -> Blender X,-Z,Y",
                "checks":{"finite":True,"closedManifold":True,"positiveVolume":True,
                          "nondegenerateFaces":True,"orthonormalFrames":True},
                "contactRule":"Hot red pieces are visible ERLethal geometry; charcoal housing is not lethal.",
                "chicken":"Body pivot matches course(78,18,40); Head independent, faces local -Z.",
                "beakTip":[0,-1,-10],"headNeck":[0,-3,2.5],
                "nativeProof":"Source kit only. No native Studio/gameplay proof from Blender."}
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf8")
    # Preview only the four hazards; the full-size chicken remains editable in the source scene.
    for obj in scene.objects:
        if obj.parent and obj.parent.name in {"Body","Head"}: obj.hide_render=True
    kit.make_preview(scene,OUT,{k:placements[k][:2] for k in list(TEMPLATES)[:4]})
    scene.render.engine="BLENDER_EEVEE"
    scene.render.resolution_x,scene.render.resolution_y=1200,800
    scene.render.filepath=str(OUT/"hazard_board.png")
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"readable_kit.blend"))
    bpy.ops.render.render(write_still=True)
    report={"build":BUILD,"templates":len(records),"parts":sum(v["partCount"] for v in records.values()),
            "lethalParts":sum(v["lethalPartCount"] for v in records.values()),
            "seconds":round(time.perf_counter()-started,3),
            "sha256":{str(p.relative_to(REPO)):hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in [MODULE,OUT/"manifest.json",OUT/"readable_kit.blend",OUT/"hazard_board.png"]}}
    (OUT/"build_report.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf8")
    print("READABLE_KIT_BUILD "+json.dumps(report))


if __name__=="__main__": main()
