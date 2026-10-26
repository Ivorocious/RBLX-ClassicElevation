# Crown refinement — one rendered candidate

The proposed view is from course-local **(6,155.5,-18)** toward **(38,85,106)**. That standing point is four studs inside the accepted floor's eastern edge and two studs inside its southern edge, with the same 5.5stud eye height. World camera **(4006,455.5,2582)**, target **(4038,385,2706)**, vertical FOV70.

The Source50 Blender baseline shows a pale foreground apron hiding most of the lower architecture. The proposed render exposes several overlapping gallery roofs and the actual course/hazards/arrow at the left, framed by the existing open stone/iron arches with wooded hills behind. Compare the original unretouched renders:

- `render02/baseline50-southeast-standing-night.png`
- `render02/candidate-southeast-standing-night.png`
- `render02/candidate-southeast-standing-day.png`

`render02/candidate-finish-centre-night.png` is a separate exact centre view. The accepted floor still dominates its lower foreground. The hero payoff is explicitly the southeast standing point within that floor, not a claim of a new unobstructed centre panorama.

## Exact changes relative to Source50

1. Lower `CrownBaseUnifiedShell` 12studs. All three coherent material parts move together; no mesh topology or asset content is changed.
2. Lower `CrownSouthJoinedScreen` 3studs. Its four existing material parts and open arches stay together. The west screen stays exact.
3. Add ten inert units from the already verified corrected ER01 masonry template: one carrier inside the accepted floor footprint, four south screen feet, four west screen feet and one lower pier for the unchanged crown badge mount. The floor, skin, finish, approach, badge, main keep/window and rear pinnacle retain their original transforms and geometry.

The installed smaller flank turrets stay at the Source50 scales. `SceneryRevisions.luau` includes their existing scale rule for compatibility with root's Source49-based wrapper; it does not lower them further.

The carrier's outer footprint is X[-25.5,9.5], Z[-43.52,-16.48], wholly inside the accepted floor X[-26,10], Z[-44,-16]. Its top is Y148.6 below the accepted Y150 top. The new supports bridge to the existing lower structure and provide separate feet under the screen posts; no broad new walking rim is added.

**Resource delta:** 10units /30mesh parts /1320placed triangles. Combined Source50 result becomes **243units /639scenery meshes /198722placed triangles**, before any later root-only changes.

## Blocker faces and rendered evidence

The independent original `source50_01_edges/edge-view-and-face-report.json` identifies the actual assembled mesh polygons:

- Crown shell StoneLight face267: east apron at Y147.8; proposed Y135.8.
- Crown shell StoneLight faces277/278: south apron at Y149.6; proposed Y137.6.
- South screen StoneLight bottom sill face355: top Y150.7; proposed Y147.7.

The exact southeast focus ray originally hits the south sill after9.95studs. In the proposed assembled candidate its first visible hit becomes `GalleryRearGreatHall` after142.34studs. A nearby ray originally hits the apron after12.43studs; afterward it reaches `Gallery3SeatedRoof` after133.78studs. Another lower ray reaches `Gallery2SeatedRoof` after110.64studs. These supporting measurements accompany the actual render comparison; they are not used alone as composition acceptance.

One westward ray still hits a screen member at11.81studs. From the centre, the steep low-gallery ray still hits the unchanged protected crown floor at12.48studs. Both facts remain in `refinement-report.json`.

## Verification and boundary

`focused-checks.json` passes all32branch/lift combinations, 1581distinct reserves and118occupied rows with zero movement, mechanism, headroom, camera, landing-sight or flag findings. The added units account exactly for the30mesh/1320triangle ledger.

`cap-join-check.json` finds zero raw exposed same-facing horizontal cap candidates involving the12 changed/new units relative to Source50 at0.002stud tolerance. This is a focused authored cap screen; native moving-render stability still belongs to root's final verification.

Blender used the complete saved Source50 assembly:609world material parts,600protected visible meshes and117protected visible primitives. The candidate adds30world parts. The protected collection's geometry/transform digest is identical before and after. The original source `.blend` and233unit plan hashes are preserved. `render02/MC_CROWN_REFINEMENT_CANDIDATE.blend` is an editable candidate copy.

The Blender lighting is approximate and the pictures are unretouched. They demonstrate the proposed geometry and framing, not Roblox lighting parity, gameplay, performance, the five-reviewer gate or owner acceptance. No Studio, live Blender, production source, new asset or upload was touched by this author. Root must inspect the same standing pose in the integrated native map, verify arrival and day/night views, and retain the protected-course checks.

`render01` is the preserved empty attempt that stopped on an unavailable preview preference before rendering or modifying geometry. The completed `render02` save emitted a thumbnail-write warning for Blender's external thumbnail cache, then saved and hash-verified the owned candidate `.blend`; that warning did not alter the source files or protected objects.
