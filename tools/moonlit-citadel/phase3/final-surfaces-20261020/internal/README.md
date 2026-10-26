# Final within-asset surface diagnosis

The final physical proposal is `proposal03/operations.json`. Earlier proposals are diagnostic history and must not be integrated. No production source, native Studio model, camera, live Blender scene or original asset library was changed by this analysis.

Root verified the reconstructed Source56 geometry against live Edit: 1,763 non-veil BaseParts and all 1,586 visible objects match at 0.00001 quantization. The original ER01 floor is present; 12 transparent mist anchors are omitted from rendered-triangle analysis. Binding is `docs/artifacts/moonlit-citadel/phase3/final-surfaces-20261020/reconstructed56-binding.json`, full canonical SHA256 `784deaac536a2aaa75bdd53800909c517fd22d83e39349ebb413dea9c3204dcd`, visible canonical SHA256 `137111fc79d078309b1484ea735db2837ec4ca989bf8e12f5d9692c92bb33516`.

## Fresh scan

`surface-triangles56.npz` contains 363,518 actual authored triangles rebound to current native CFrame/Size, with no visible object omitted. Maximum native local bounds error is 0.0004272 stud. New geometry for six converted banners is taken from the same exact MeshId's previously verified triangle geometry and rebound to its current native pose. This is a fresh triangle scan, not reuse of the old 184 witnesses.

`internal-candidates56.json` scans same-facing triangles within the same native asset instance, positive projected overlap above 0.01 square studs, plane distance at most 0.035 stud and near-parallel normal buckets. It finds 371 part pairs: 235 self-part and 136 different-appearance pairs. Opposite facing surfaces and every possible nonparallel shallow intersection are outside this scan.

`internal-visible56.json` tests up to 12 large overlap witnesses per part pair from up to 32 nearby supported eyes (677 player-height eyes total). 46,637 finite first-surface rays find 214 visible candidate pairs: 35 different-appearance and 179 self-part pairs. A global pair minimum can refer to a buried surface; prioritize the actual visible face-witness gap. This distinction ruled out several apparent high-priority crown, machine-window, cornice and car-body cases.

## Final 12-part physical proposal

All 12 parts are anchored, noncollidable, nonqueryable and nontouchable. Flags, MeshId, source asset/material, silhouette trim, contacts, hazards, arrows, original floor and veil are unchanged. The manifest supplies exact current before and proposed after native Size/CFrame guards.

| Parts | Native Size delta | Course position delta | Purpose |
| --- | --- | --- | --- |
| Four GrandKeep stepped-buttress Stone bodies | (-0.16, -0.24, -0.48) | Zero | Recess all stepped body planes under the unchanged light trim |
| NorthEastRaisedCourt Slate | (0, 0, -0.16) | Zero | Recess coincident roof/stone end face |
| Two Junction seated-roof SlateBand parts | Zero | (+0.08, 0, 0) | Increase current band relief; total authored correction becomes +0.14 X |
| Three GalleryInteriorQuietLancet Stone substrates | (0, -0.16, 0) | Zero | Separate lower cap-return surfaces after the existing correction |
| Two UpperKeepWarmLancet Stone substrates | (0, -0.16, 0) | Zero | Separate small-scale cap-return surfaces after the existing correction |

The final fresh within-asset rescan finds 355 pairs, 16 fewer than the current state, with no new part pair. All four complete buttress Stone/Light pairs are absent from the 0.035-stud scan. Fresh focused buttress rays (128) find no visible remaining buttress candidate; the remaining tiny Slate/Light coincidences are unchanged and unobserved from those tested eyes. A full Proposal02 ray pass established the other eight target corrections; Proposal03 changes only the four buttress Z sizes further. Root's integrated full-neighbour rescan remains necessary for combined candidate clearance.

The twelve originally observed material conflicts now have geometric plane separation of at least 0.0599999 stud (court 0.08, roof bands 0.08450, gallery windows 0.06620, upper keep windows 0.07819). Three lantern Brass/Iron underside gaps of 0.0235901 are held: those Brass meshes have CanQuery=true, so altering them would cross the physical/query preservation boundary.

## Same-part assessment

`self-surface-assessment56.json` distinguishes 40 parts with exposed exact same-facing polygon overlap from 139 parts with nonzero close relief. Exact families: 6 gallery body materials, 7 bracket materials, 20 guide Iron parts, 4 weight Iron parts, 2 small gable materials and 1 main window Lead tracery. These are distinct source polygon IDs with positive overlap, not mere shared edges. None of the chosen triangle witnesses is an entirely identical triangle: partial coplanar overlap needs polygon union/subtraction, not arbitrary whole-triangle deletion. Moving or scaling the whole material MeshPart preserves the exact coincidence.

The other 139 parts contain nonzero bevel, relief or leaf spacing (including floor edges). A geometric close candidate alone does not establish visible temporal flashing. UVs and custom per-vertex normals were not included in the archived triangle export, so this analysis does not claim equal texture mapping or shading across overlaps. The separate offline mesh-cleanup author owns any polygon repair and its silhouette/material proof.

No continuous native moving-render acceptance, whole-route traversal, multiplayer, FPS or full asset topology guarantee is claimed here.
