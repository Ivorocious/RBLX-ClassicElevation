# ER01 geometry preparation

This is implementation evidence, not a final review. No production source, Studio, Blender session, import, camera, lighting or security system was changed by this author. The current commission freezes accepted Phase1/Phase2; the lead owns native recovery/integration and all camera evidence.

## Connected retained keep

`MainKeepShell.py` adds `MC_ER_MainKeepShell` to ER01. It replaces the four old main-keep walls and GrandRearApseFoundation, preserving their combined core footprint and court void. Place at `(FinishPoint.X,-38,FinishPoint.Z)` with identity rotation/unit scale. Preserve all original separate pinnacles, buttresses and focal window poses.

The canonical exterior is extracted only beside empty grid cells. It is one connected, closed, welded exterior with volume377,050.8. Coping footprints expand each core rectangle by1 at Y0..3 and160.8..163.8. Coplanar grid tiles merge into rectangles; their edges split at all neighbouring vertices before triangulation, preventing hanging vertices or internal cell faces. Its separate exact whole-exterior check has348 triangles.

Material separation needs closed parts. Export uses one Stone core union at Y2.99..160.81 (108triangles), plus two closed StoneLight bands at Y0..3 and160.8..163.8 (216triangles total). Covered core caps are buried .01 inside the bands on different planes. This gives2parts/324triangles, with no exposed internal/coplanar cap faces. It adds no independent overlapping wall/cornice boxes to the exterior.

Outer bounds are X[-39,39],Y[0,163.8],Z[-44,19]. The void stays empty at the origin; exact15 rectangle volumes represent the occupied solid without filling the courtyard. Body court boundary is X[-30,30],Z[-10,10]; coping narrows this opening by1. MainKeepShell plus the two AR replacements total8parts/1,584triangles. `authored-vertices.json` includes the canonical exterior test and exact solid rectangles; these are proven solid regions, unlike a hollow shell's overall bounding box.

## Crown mass and curb union

`CrownBaseShell.py` adds `MC_ER_CrownBaseShell`, replacing exactly these agreed9 scenery units: RoofDrumWestReturn, RoofDrumSouthReturn, RoofDrumNorthWestReturn, EastApproachLowSill, RoofDrumEastSouthReturn, EastApproachPortalFoot, CrownUnderfloorSeat, SouthScreenSeatedCurb and WestScreenSeatedCurb. CrownEmblemStoneMount, both joined screens, accepted emblem/signs/arrows and contacts stay separate at their accepted poses. `crown-inputs.json` freezes the9 original draft transforms and99 fixed-family closed solid boxes before retirement; do not regenerate that snapshot after those source units have been removed.

The recipe unions each material's solid volumes, removing overlapping same-role caps and join-strip surfaces. Stone closures remain buried inside Light coping on different planes. Every material part is individually closed/outward. The whole occupied exterior independently forms one closed connected component, with union volume32,935.3397928. The strips are preserved rather than simplified: exported cost is Stone460 + StoneDark2,368 + StoneLight404 =3,232 triangles/3parts. All four ER01 assets total11parts/4,816triangles.

Vertices are course-local Roblox coordinates; use identity CFrame and unit scale. Bounds are (-46,125.8,-48)..(30,149.60001,-7). The99 exact solid boxes preserve the actual east approach void. Source endpoints are rounded to a1e-5stud weld grid, with measured maximum corner displacement4.9483e-6stud, preventing tiny source float slivers at nominally equal planes. This is declared authored rounding, not a claim of bit-identical replacement vertices. Accepted gameplay geometry does not change. Empty-space probes at(20,145,-38),(-8,150,-30) and(-8,156.5,-30) pass; these are focused geometric checks, not native traversal proof.

## Assets and exterior

The new library is `MC_P3_ENCLOSURE_REPAIR_ER01`. Its two asset names stay `MC_AR_MasonryMass` and `MC_AR_FoundationBay46`, so only their selected templates need replacing. Old AR01 and accepted kits remain intact. Run the recipe in a clean isolated Blender file; it refuses existing objects with these names.

| Asset | Closed stone height, Blender Z | Footer / coping height | Exact mesh parts / triangles | Conservative occupied box, Roblox local |
|---|---|---|---|---|
| MasonryMass | 1.29..22.91 | 0..1.3 / 22.9..24 | 3 / 132 | (-12.5,0,-6.5)..(12.5,24,6.5) |
| FoundationBay46 | 1.59..39.01 | 0..1.6 / 39..40 | 3 / 1,128 | (-24,0,-23)..(24,40,1.3) |

The coping alone owns the exterior top; the footer alone owns the exterior bottom. The body remains closed, with its covered faces buried .01 stud inside trim. Body and trim side faces lie on different planes. Join strip backs also penetrate the stone .01 instead of leaving a .005 gap; their exterior projects .05 beyond the stone. Footer/coping widths, asset pivots, sculpted lancets, overall silhouette and occupied boxes remain unchanged. Foundation outer authored bounds are slightly narrower than its existing conservative occupied proxy: X[-24,24],Y[0,40],Z[-23,1].

Closed components are checked separately, not merely by aggregate volume. Foundation costs are Stone12, StoneLight660, StoneDark456 triangles; Masonry costs are Stone12, StoneLight24, StoneDark96. The two AR replacements total6 parts/1,260 triangles. The standalone recipe corrects inward source-prism winding. No material part has an open cap. The established Blender exporter still performs its own cleanup/manifold/triangle checks; actual exported/native vertices remain pending lead verification.

## Compact commands

From the workspace root:

```powershell
python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/VerifyRecipe.py
python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/TestAudit.py
python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/AuditCaps.py
python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/ProtectedSources.py compare
```

Lead-only isolated Blender command, using a fresh output directory:

```powershell
blender --background --factory-startup --python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/BlenderEnclosureRepairKit.py -- --output tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/er01-export
```

After actual export, audit authored meshes plus the integrated proposed placements and manifest:

```powershell
python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/AuditCaps.py --authored tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/er01-export/authored-vertices.json --manifest tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/er01-export/manifest.json --placements tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/proposed-placements.json --output tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/proposed-cap-audit.json
```

Placement JSON shape: `{"placements":[{"id":"district/unit","asset":"MC_AR_MasonryMass","cf":[x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22],"scaleRoblox":[sx,sy,sz]}]}`. CFrame is the asset-origin transform; scale uses Roblox axes. Do not pass the recentered material MeshPart transform as the asset origin. Native extraction reverses the old Stone part center/scale to recover that origin from the saved Source48 chunks. The script accepts nonfamily rows but reports omissions explicitly; it never treats a missing family as a checked one.

## Findings and limits

Source48 reconstruction contains25 MasonryMass and16 FoundationBay46 placements. The focused regression finds external same-instance cap conflicts in all41 old assets (309 triangle-pair intersections); ER01 reduces that same-instance count to zero. This includes both top and bottom surfaces. These counts describe geometry, not separately reproduced flashes.

The same repaired AR assets placed in the unchanged Source48 plan still produce44 cross-instance material-pair candidate groups (453 triangle-pair intersections). Most are StoneLight trims and StoneDark strips where neighbouring foundations, keep corners and crown curbs overlap. Examples include CrownUnderfloorSeat versus RoofDrumSouthReturn/NorthWestReturn, SouthScreenSeatedCurb versus WestScreenSeatedCurb, adjacent machine foundations and keep wall corners. The grouped entries in `cap-audit.json` give exact names, planes and summed triangle-overlap area. The16 older cuboid findings are a starting inspection set, not an exhaustive triangle list. Triangle-pair counts can change with diagonal/ear triangulation; grouped surfaces and areas matter more than that count.

Therefore the two replacement meshes alone do not close all joined-building flashing. The integrated plan must remove visible overlap, use a purpose-built closed union at that joint, or bury the contested plane inside a thicker connected masonry return with a different exterior plane. A tiny vertical shift of an entire building is not a coherent general joint repair. Do not ignore same-material overlap merely because the color agrees. Keep course contacts fixed while adjusting scenery.

The audit clips projected horizontal triangles exactly. It identifies cuboids from eight-corner closed components, then proves a whole convex overlap polygon buried only when it lies inside one exact transformed cuboid. It labels opposed outward normals separately as interior contacts. It does not assume a MeshPart bounding box is solid, and noncuboid/nonfamily geometry is not accepted as an occluder. Thus uncertain partially covered candidates remain conservative flags. Scope is horizontal caps; vertical wall/roof faces still need the targeted native view inspection. `render_reproduced` remains false for every analytic candidate.

`PrepareCombinedAudit.py --keep-swap --crown-swap` reads the current fortress `placement-plan.json` and seven pure fortress recipes, then replaces the agreed old keep/crown units in an analytic input only. It writes `combined-authored.json` and `combined-placements.json` in this folder. Follow it with AuditCaps using those inputs and `--output .../geometry/combined-cap-audit.json`. The final snapshot checks53 authored placements and explicitly omits58 retained nonfamily meshes. CrownBaseShell has zero external cap candidates. There are11 non-base material-pair groups, all at localY-38; `combined-nonbase-candidates.json` isolates them. They involve gallery footers, two Junction return roots, the MainKeepShell root, and raised new wing roots. The final exact terrain proof below confirms their burial. The localY-94 base-plane flags are likewise proven buried. They are not rendered flashing reports. This is a frozen authored proposal snapshot; repeat it if the integrated stage changes.

`ProveTerrainBurial.py` consumes this cap audit, `landscape/terrain-metadata.json` and `landscape/landscape-plan.json`. It requires identity/unit terrain placement, clips every contested cap polygon against the actual top triangles, verifies complete projected-area coverage, and checks the minimum linear surface height over every clipped fragment. It also requires the cap to lie above the terrain bottom. This proves burial across the whole overlap polygon rather than sampling a few points or trusting nominal seatY. All input hashes are stored in `terrain-burial-proof.json`, and the tool refuses inputs that change during calculation. All288 candidates are proven buried with minimum4stud clearance. The landscape author confirmed the final frozen terrain metadata SHA `17b37e616ecb81137d7c45fc82459fdc75f2a650487a4cbfb0da0d0cdeb968c2`, matching the proof input; its final FortressSeats SHA is `0b6707b17e4668cde1d71163390d80b6b404759eda886b414f2acc5d07c3727b`. Native mesh parity and moving-camera evidence remain separate requirements.

## Actual imported vertex parity

`CompareNativeVertices.py` compares the lead's exported53-part authored pointsets to actual EditableMesh pointsets, already normalized by the lead into authored library coordinates. It applies no coordinate transformation or data edits. Its SciPy cKDTree backend measures exact nearest-point distances in both directions; an exact bounding-box KD tree is available with `--backend kd` when SciPy is unavailable. Duplicate normal/UV vertices are counted but do not require one-to-one pairing. Missing/unexpected/duplicate part names, empty pointsets or any error above.001stud fail the comparison. All outlier points, per-part maxima, worst pairs, counts and immutable input hashes are recorded.

The actual Source49 import comparison passes all53 parts. Authored32,398 vertices and native103,026 vertices each reduce to the same32,398 unique positions. Maximum error is0.00012302029034879378stud, on `MC_EC_NorthHighRidge__Rock`; no missing/unexpected parts or outliers. Authored SHA `3a079acf56ce3ed5f32b0c98d530e0e31418185f878b90b347939fe76ad1a0ac`; native SHA `10da46e53127ed4b8ce8bf8a851145f0118a8ca570463643b6338e5ec0d94e0f`. `native-vertex-comparison49.json` is the complete evidence. A64-query fixture checks the fallback against a small exact loop, duplicate position handling and outlier multiplicity; its maximum distance difference is zero. This proves vertex coordinate parity only, not normals/materials, final visual quality or gameplay.

```powershell
python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/CompareNativeVertices.py
python tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/TestNativeComparison.py
```

## Focused native camera evidence, lead only

Use the saved review camera definitions, not a new aerial beauty view. Capture the crown pair at both daylight14.5 and final night19.2, with GlobalShadows on and then off: A camera(4025,457,2552), aim(4015,447.8,2572); B moves both X coordinates+.15. This is eight paired-result stills. Record actual visible behavior in each pair, rather than inferring flashing from pixel differences between changed viewpoints.

Then do one continuous slow lateral/dolly traverse in day and one in final night, linking saved gallery A/B views through affected machine foundations and crown joins. Begin gallery camera(4048,348,2710), aim(4008,331,2670), crossing its+.15 X counterpart; include saved gallery route(3940,357,2630)→aim(4020,361,2630), upper machine(4165,414,2496)→aim(4100,423,2480), and crown A/B. Maintain ordinary route-level views through the transitions. Stop at unresolved grouped audit surfaces for a short forward/backward pass. Show mounts, roof/wall joints and lower footer edges where accessible. No extra gameplay campaign is needed.

Before diagnostics save camera, Lighting properties, Sky/effects, local lights, and the historical2820 sample visibility. Restore them afterward, especially GlobalShadows. Capture/report actual restoration. Verify frozen current native P1/P2 and both course models, behavior sources, contacts, catches, fall zones, mechanism configurations/transforms, signs and19 arrows with the lead's current baseline. `ProtectedSources.py` compares38 filesystem entries only; it cannot replace native geometry or owner-edit comparisons.
