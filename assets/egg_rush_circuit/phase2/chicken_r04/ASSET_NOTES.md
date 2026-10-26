# Chicken R04 source kit

Owner request: one pass solely on the chicken, correcting the swan silhouette. This kit changes no track, target, lap, hazard placement or account state.

Current candidate is `ER_CHICKEN_R04_A02`. `build_chicken.py` authors three editable native-block templates in Blender: Body 17 parts, Head 15 and Feet 10, for 42 exported parts. The two runtime neck links make 44 visible rig parts. It exports `RestartP2/ChickenKit.luau` with the existing `Create(parent,key,frame,scale?)` API. Only the visible Neon-red Beak has `ERLethal=true`; comb and paired wattles are matte coral. All art is anchored, noncolliding and touch-disabled. There is no mesh upload.

The body has a wide stepped pear mass, raised breast, layered folded wings and five upright fan feathers. The wider head uses one angled eye per side, a five-lobed comb, paired wattles and a short beak. Gold feet have three visible toes each. Low forward breast volume is deliberately cut back to leave nearby Expert landings clear while bowing. A02 carves the head underside and trims the wattles so the visible red beak leads the impact. It preserves the forehead, comb and cheek shape while removing the projecting brow pieces.

## Attachment contract

- Body and Feet face local +X. Course hip is `(91,18,40)` and the resting body faces course +Z.
- Shoulder is body-local `(18,25,0)`.
- Head faces local -Z, with `BeakTip=(0,-2,-10)` and `HeadNeck=(0,-5,3)`. The tip matches the center of the Beak's front face.
- Isolated preview head home is body-local `(27,31,0)` facing +X.
- The preview includes two 6-stud neck links with 9-stud width. They are runtime-built parts, not additional exported kit templates.

Native template bounds are Body `(-29.00259,1,-18.7)` to `(15,35.5835,18.7)`, Head `(-9.5617,-7.21,-10)` to `(9.5617,17.15,7)`, and Feet `(-2.5,-2,-12.27928)` to `(18.5,7.15,12.27928)`. The main head block is `16x10x14` centered at `(0,2,0)`; its cheek is `14.4x4x8` centered at `(0,-4,3)`.

The motion helper/root controls the final body bow/yaw and head trajectory. Source attachment data does not establish continuous collision clearance.

## Verification

One background Blender process with two threads generated A02 and rendered three isolated views in 28.317 seconds. It exited after completion. Generation checks passed for all 42 exported objects: closed, positive-volume solids with finite geometry and orthonormal transforms. The saved readback helper follows the current source output folder. It ran at the start of the lead's combined course-render process, reopened A02 and passed all 42 closed positive solids with exact saved manifest parity; it did not modify the saved scene.

`verify_chicken_kit.luau` passed 12 model cases and 168 part checks across default, scalar and vector scales, translated/rotated placement, color/material/contact flags. It also checks the 42-part A02 contract, short-neck anchors, the Head's front direction and transformed BeakTip. All four instantiated lethal pieces are the Head's Beak.

`candidate_a02/` contains the editable `chicken_kit.blend`, manifest, build/API/saved-readback receipts and three isolated PNGs. `candidate_a01/` remains preserved. The A02 profile, front and three-quarter views were visually inspected: the compact neck, comb, paired wattles, fuller body, fan tail and feet still read as a chicken after the underside carve. These are source-kit reconstructions, not Studio screenshots or gameplay/animation proof. The floor and short-neck preview assembly are explicitly marked preview-only and are not exported into the kit.
