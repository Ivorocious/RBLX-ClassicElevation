# Shipwreck Cove Phase 1 — resource and evidence review

Reviewed frozen study `SC_P1_03` with kit `SC_KIT_02`. Scope: asset cost, resource evidence and the supplied `views-03` player-facing studies. This is not a full-map or target-device performance review.

## Score: 8.5 / 10

The kit is convincingly simple and economical in the close player views. It keeps the ship, cannon, cave, ribs and spars readable with broad forms, while avoiding the fine repeated details that the brief rejected. The new evidence closes the earlier file/receipt mismatch: the current `ShipwreckCove_Kit02.fbx` hash is `d134551c622e6a46d35f7b98a8d5af26cda94f8fdc2a6f8c16becfd74d429ed1`, which matches both the fresh evaluated-FBX export report and the completed upload receipt for asset `100187332333895` under user `86069177`.

The evaluated re-import reports 35 unique meshes and 1,462 source triangles. The Phase 1 study places 87 visual meshes for 3,052 visual triangles: dock/wreck is 51 and 2,048, cave is 19 and 444, and ribs/spars is 17 and 560. The live inventory records 90, 41 and 34 descendants respectively, so every group is below its 95, 45 and 60 working instance ceiling. The complete fixture has 129 BaseParts, 168 instances, 42 simple colliders, zero lights, touch listeners, scripts, transparent visuals and collidable visual meshes. Import evidence also shows the one shared texture asset across the kit; the local atlas is 128 by 128 pixels.

The cost is therefore strong for the stated low-poly Phase 1 purpose. The kit's estimated repeated-placement total is 10,080 triangles, well below the 115,000 working course target and 140,000 hard planning ceiling. Those are planning limits, not a prediction for an assembled course.

## What keeps this below a higher score

- The screenshots remain isolated fit studies. City Run/lobby content is visible in several backgrounds, so the images do not establish the final course's visual density, streaming, or culling behavior.
- The five-second desktop Studio sample has a 16.30 ms median frame interval and 20.24 ms p95, with automatic graphics settings and a mixed existing place. It is useful smoke evidence only. It does not prove FPS, memory, loading, mobile/lower-end behavior, or 20-player performance. The reported 3,326.5 MB is mixed-place total memory and cannot be assigned to this kit.
- The working budget file retains an older `SC_P1_01` header. Its numerical limits are met by the frozen inventory, but the header should be renamed or explicitly superseded before this evidence is packaged as final documentation.
- The provided fit results pass all 13 checks, including the cannon, cave refuge, ramp, interior, ribs and spars. They validate this fixture only; they do not establish final hazard scripting, multiplayer queueing, touch controls, checkpoint integration or a complete three-lap circuit.

## Decision

Accept the Phase 1 kit as a low-cost, adequately evidenced asset and fit-study delivery. Carry the resource limits forward as working limits. Do not use this score or the desktop sample to claim full-map performance, target-device readiness, or 20-player readiness.
