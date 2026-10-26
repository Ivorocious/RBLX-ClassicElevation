# HUD and duplicated Clacky rows

The active StarterPlayer preview contained literal `Â·` and `â€¦` text. Both the M02 preview and durable StarterPlayer preview now use ASCII readiness strings and a two-line progress panel: `Lap 1 / 2` above `Checkpoints 4 / 7`. The F00 state says `Return to start to finish lap`; completion says `Course complete` above the finished lap count. The panel is 58 pixels tall and at most 320 pixels wide. Progression attributes and server behavior are unchanged.

Image 2's duplicated rows are authored O05 bracket geometry. `BracketLeft.TopArm` overlaps `BracketLeft`, and `BracketRight.BottomArm` overlaps `BracketRight`. Each main bank is 10.4 by 13 studs; each old arm is 13 by 5.2 studs, centered at local `(2.25, 0, -4.5)` or its mirror. Eight arm caps overlap each main bank's footprint (16 total); the nearest duplicate cap centers are 1.123 studs apart. Those offset full rows match the owner's screenshot. The root agent is correcting the arms in `StaticPatterns.luau`.

Read-only Edit inspection found one active course mount, a disabled snapshot preview, no extra nearby MeshParts outside the course, and zero misplaced or extra keys across 2,971 grid keys in 102 banks. Both feedback implementations follow each original's current CFrame, create visuals per occupied key, and destroy them on release/Stop. There is no visual pool or cached rest transform. The feedback files remain unchanged, preserving the 0.45-stud held depression, contact detection, audio, original colliders, and local cleanup.

Changed files:

- `sources/KeyboardCircuitPhase2Preview.client.luau`
- `src/StarterPlayer/StarterPlayerScripts/KeyboardCircuitPhase2Preview.client.luau`

Checks: both preview files contain only ASCII and have matching SHA256 hashes. Studio remained in Edit throughout this helper's work. Root is running the combined compilation and native integration checks; gameplay has not been verified by this helper.

Focused native checks: inspect both O05 bracket arms for a single aligned cap grid; hold an ordinary and a moving key long enough to observe the full 0.45-stud depression, then leave and confirm restoration and local clone cleanup; confirm the two-line HUD during checkpoint progress, F00 return, lap change, and completion, including a narrow viewport.
