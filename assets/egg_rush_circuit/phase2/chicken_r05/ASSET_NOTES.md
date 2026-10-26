# Chicken R05 source kit

This model pass replaces R04's broad rectangular sides with a stepped pear body, tapered belly, overlapping wedge feathers, five upright tail plumes, a faceted cheek and short wedge beak. The matte coral comb and paired wattles remain distinct from the single visible Neon-red lethal Beak. Gold feet retain the R04 geometry and placement. No route, target, lap, timing, account or place state is changed by this asset generator.

Current candidate `ER_CHICKEN_R05_A02` has 57 exported parts: Body 25, Head 22 and Feet 10. Fifteen are true native WedgeParts; the others are native Block Parts. The two runtime neck links bring the assembled art to 59 parts. The generator exports `RestartP2/ChickenKit.luau` with the existing `Create(parent,key,frame,scale?)` API. There is no mesh upload.

The angular feather ends are deliberate classic Roblox geometry. All current template bounds remain inside R04 A02's envelope. The body is carved within that envelope; the same whole-template bounds alone do not prove motion clearance.

## Fixed attachment contract

- Body and Feet face local +X; Head faces local -Z.
- Body-local Shoulder is `(18,25,0)`.
- Head-local BeakTip is `(0,-2,-10)` and HeadNeck is `(0,-5,3)`.
- Neck links stay 6 studs each and 9 studs wide.
- Course hip stays `(91,18,40)`; preview home Head is body-local `(27,31,0)` facing +X.

The Beak is a `6x3x3` WedgePart centered at `(0,-0.5,-8.5)`. Its broad back is at Z -7; its lower front edge is at Z -10, Y -2. BeakTip lies on that real edge. This preserves the tip contract while removing the previous blunt rectangular nose. Native Studio checks must still confirm the engine's wedge orientation and contact behavior.

## Source verification

One background Blender process with two threads generated A02 and three isolated views in 29.127 seconds, then reopened the saved scene. It exited after completion. Readback passed all 57 closed, positive-volume solids, including exact six-vertex/eight-triangle topology and half-box volume for all 15 wedges, with exact saved manifest parity. The source scene was not modified by readback. A01 is preserved; A02 only moves the brows and eye glints outward so their surfaces are visible.

The offline API check passed 12 model cases, 228 part checks, 60 wedge instances and four lethal Beak instances. It verifies native primitive classes, transforms, scalar/vector scales, colors, materials, contact flags and the physical wedge tip attachment.

`tests/ChickenMotion.luau` uses the A02 manifest and passed 41,538 attachment/pose checks plus 1,815 sampled full-rig poses against 98 landing-centered player boxes, with no unexpected overlaps. Head/Neck contact with the selected pad is excluded only during Pecking, Impact and Recovering; Rest and Warning are checked against that pad too. These are conservative box calculations, not native collision or player-camera proof. `tests/ChickenPeck.luau` passed 54 mocked binding, continuity, Beak-only contact, warning and restoration checks.

`candidate_a02/` holds the editable scene, manifest, receipts and three new views. `build_report.json` points to the preserved R04 A02 views, which use the same cameras for comparison. All three A02 views were inspected; the compact chicken silhouette, visible eye expression and distinct feather layering remain readable. The isolated views are source reconstructions, not native Studio screenshots or animation/contact proof. The floor and neck preview assembly are marked preview-only and are excluded from exported templates.
