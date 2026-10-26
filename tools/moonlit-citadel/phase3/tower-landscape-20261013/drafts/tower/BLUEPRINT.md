# Main keep grandeur proposal

The Source43 day/night pictures show a broad flat keep capped by a small crown screen. The rear machinery house reaches roughlyY167 while the keep's destination sits atY150. Bright repeated masonry bands and side windows also divide the main tower into similar small layers. A taller main silhouette, attached vertical supports and quieter uninterrupted wall surfaces should make the keep the clear landmark.

This draft changes Phase3World only. Source43's accepted course, contact skins, arch undersides,19arrows, original crown emblem, finish, runtime and Phase1 libraries remain exact. Nothing was changed in production or native Studio. Implementation authors do not grade the result.

## Shape and hierarchy

Replace the eight repeated KeepTier shell units with four closed full-height masonry walls. Four attached tapered buttresses create strong vertical shadows. They attach two studs into the south/north wall faces throughout their lower shaft; they are not freestanding156-stud sticks.

Build one closed northern apse from the rocky ground to the keep storey. Its stepped Gothic pinnacle rises toY237.8: roughly71studs higher than the competing mechanism roof. Two shorter south corner pinnacles rise toY187.8. The existing crown terrace remains a useful open balcony between these volumes, with its original emblem, supported screens and clear east arrival. Main and flanking peaks vary deliberately; supporting gate/outer buildings remain low.

The main pinnacle has a24 ×20 base, a broad lower storey, a sloping shoulder, a narrower octagonal upper drum, an octagonal slate roof and a final thin taper. Five dark pointed slits add readable vertical detail without more glowing panes. Side pinnacles have the same family of shapes at a smaller scale. The grounded apse joins the tall main module into the keep's mass.

## Precise course-local positions

All positions are relative to course Origin. These values use the unchanged FinishPoint(-8,150,-30).

| Edit unit | Pivot or occupied bounds |
| --- | --- |
| Four new walls | South X[-46,30],Z[-20,-12]; west X[-46,-38],Z[-48,-20]; north X[-38,30],Z[-48,-40]; east X[22,30],Z[-40,-20]. Each wall spansY[-30,125.8]. Existing upper storey startsY125.8. |
| Four buttresses | South pivots(-39,-30,-14) and(23,-30,-14), yaw0. North pivots(-39,-30,-46) and(23,-30,-46), yawπ. Local rear attachment faceZ0; outward extentZ12 at foot,8 at middle,5 at head. |
| Northern apse | Closed boundsX[-23,7],Z[-73,-46],Y[-30,125.8]. Exported as counts.additionalGroundRoots for landscape seating. |
| Central main pinnacle | Pivot(-8,125.8,-60), scale(1.25,1,1.15), placed dimensions30 ×112 ×23. PeakY237.8. Its broadened base rests fully on the30 ×27 apse. |
| Lower flanking pinnacles | Pivots(-37,125.8,-14),(21,125.8,-14), scale1, dimensions12 ×62 ×12. PeakY187.8. Both sit on joined keep upper walls; each overlaps an attached south buttress head. |

The initial southern apse intersected the accepted second gallery band. The complete apse/pinnacle group moved north; the final proposal has no standing, jump, transfer, catch, boarding, car, weight, swing, camera or landing-sight conflicts in the existing protection screen. The source43 east crown portal X[12,43],Y[137,168],Z[-68,-34] remains untouched. The main pinnacle starts west of that portal and north of the crown contact. No new roof covers or mimics an accepted jump landing.

## Small Blender kit

`BlenderTowerRecipe.py` contains a lead-run `build_tl01()` entry point. It creates a new collection without deleting or editing existing Blender content. The helper has not executed it in Blender. The lead uses the accepted export/import workflow and native normalized-part convention.

Each asset has exactly three material meshes: Stone,StoneLight,Slate. Base pivot is(0,0,0). Roblox front is+Z. The author recipe converts Roblox(X,Y,Z) to Blender(X,-Z,Y). Check the importer's actual handedness against the occupied proxies before assembly; the earlier AR01 correction must not be copied blindly to unrelated new meshes.

| New module | Size | Authored triangles | Construction |
| --- | --- | ---: | --- |
| MC_TL_GrandPinnacle |24 ×112 ×20 |284 | PlinthY0..8,lower body8..46,weathered shoulder46..50,upper drum50..70,cornice70..73,slate roof73..103,finial103..112. Closed pointed slits project.035stud from the body faces. |
| MC_TL_FlankPinnacle |12 ×62 ×12 |180 | Base0..4,octagonal body4..32,cornice32..35,slate35..59,finial59..62. Two tall trim ribs and one closed dark slit. |
| MC_TL_SteppedButtress |8 ×156 ×12 |96 | Broad foot0..26,slope26..33,middle33..116,slope116..126,narrow head126..156. Three short caps; no repeated trim tiers. |

`TowerGeometry.luau` defines conservative occupied boxes per real segment. Pointed slits are closed.06-thick prisms, including their small forward projection in the proxy. Same-outline segment joints overlap.01stud instead of sharing identical vertices so the accepted exporter's global1e-6 vertex merge does not fuse sealed caps into nonmanifold edges. Overall bounds remain exact. `VerifyRecipe.py` runs locally with a bpy stub and examines authored vertices/faces only. It confirms the exact dimensions, every edge used twice, opposite winding on shared edges, positive signed volume for each material mesh and no coincident vertices across the material groups. This checks closed authored components, not a final Blender export or uploaded asset.

Native import must confirm nine material MeshParts, authored pivots, dimensions and geometry orientation. Replace the recipe metadata with verified import measurements if the export triangulation or material grouping differs. The library name in the proposal is MoonlitCitadel_TowerLandscape_TL01Library; the lead may integrate these assets into another explicitly verified Phase3 library while preserving the authored contract.

## Budget and materials

The new WorldPlan is a candidate wrapper around the frozen Source43WorldPlan. Its dependencies are Source43WorldPlan,BaselineWorldPlan,AssetGeometry,TowerGeometry. It preserves all gallery/outer architecture while retiring49 named units: old striped keep shells, old crown corner turrets, repetitive keep side/rear windows and the second foundation lancet on paired gallery/service windows. It adds12 coherent units. The primary warm main window remains.

| Stage | Units | Meshes | Known authored triangles |
| --- | ---: | ---: | ---: |
| Source43 architecture |247 |643 |319,824 |
| Grand keep architecture draft |210 |558 |215,348 |
| Draft plus unchanged Source43 environment |313 |720 |252,926 |
| Remaining within existing350/900/420,000 cap |37 |180 |167,074 |

The remaining allowance gives the landscape author room for visible trees, soft hills and larger planted groups through replacement/reallocation. Keep the new apse foot embedded in the keep's hill atY-30; do not expose it as another floating platform. Budget figures describe source assets and include the exact authored TL01 recipe counts; native imported counts still need confirmation.

Apply GrandStone response to new keep clones: Stone RGB124/134/149,StoneLight185/190/193,StoneDark80/96/116. Use Slate43/60/86 with restrained SlateBand64/83/110. Cleaner darker stone and longer quiet vertical planes should distinguish the main keep from pale outer galleries. Leave the accepted asset libraries unchanged. Current WorldAssembly does not implement a GrandStone material-policy table or TL01 library branch; the lead must add that scoped scenery mapping and library selection during integration. Keep the main window's warm focus; avoid more point lights or Neon slits.

## Focused views and protection concerns

Capture both installed day and production night. Suggested cameras are course-local; add the actual Origin. Preserve the usual navigation camera in additional views so grandeur is assessed from the race, not only from a presentation angle.

1. Start court: camera(-144,7.5,145),look(-8,160,-30). The central silhouette must rise cleanly above the gallery roof. Also repeat Source43's ordinary gate-facing route view to check hazard/arrow visibility.
2. Gallery player height: camera(-60,57,30),look(-8,137,-35). The main window, broad buttress shadows and tapered top should read as one tower. Repeat the ordinary forward gallery view(-60,57,30)→(8,60,30) to confirm the new masonry has not hidden lantern timing or next landing.
3. Crown approach: camera(42,148,-60),look(-8,170,-30), then the ordinary arrival look(-8,153,-30). Check the east portal and landing edge while the peak frames the arrival. Standing on the finish, turn north toward(-8,195,-60) to inspect the apse/pinnacle seating and south toward the unchanged emblem to inspect the flanks.
4. Whole map: camera(290,330,390),look(-10,105,0), plus rear camera(-225,260,-280),look(-10,115,-17). The keep must dominate the silhouette from both sides, with its base visibly belonging to the landscape and machinery remaining readable.

After importing, run exact protection comparisons for all accepted content and the19arrows; verify inert scenery flags and true occupied geometry. Inspect the main module's base/cornice/slate joins, side flanks, north apse ground connection and changed material scale. Perform focused moving-camera checks at the gallery/crown approach without reopening the accepted difficulty pass. Static source clearance, mesh closure and resource counts do not prove native camera comfort, art quality, FPS, multiplayer or owner acceptance.
