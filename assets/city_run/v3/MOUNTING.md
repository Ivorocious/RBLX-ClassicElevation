# Visual kit mounting rules

All coordinates below are Roblox coordinates relative to the normalized source pivot. Positive Z is the front, Y is up. These recipes are visual assembly examples, not player colliders. They do not establish gameplay clearance.

| Pair | Child pivot relative to parent | Intended contact |
|---|---|---|
| Coral_Wide + GableRoof_Wide | (0,48,0), yaw0 | Roof bottom meets wall top, 0 vertical gap; roof overhang is intentional |
| Coral_Wide + Awning_12 | (0,10,13.8), yaw0 | Rear brackets reach front wall at Z10; allowed 0.2 stud embed |
| Coral_Wide + Sign_Market | (0,14,10.35), yaw0 | Sign back is Z10.075, 0.075 stud face separation to avoid flicker |
| Coral_Wide + Balcony | (0,12,12.1), yaw0 | Back edge reaches wall at Z9.6, intended 0.4 embed; never copy to gameplay floor |
| Coral_Wide + Ledge_Long | (0,11,11.2), yaw0 | Back edge reaches wall at Z9.7, intended 0.3 embed |
| TerminalColonnade + BarrelRoof | (0,13.25,-7), yaw0 | Roof bottom meets cap top; depth span is backed by terminal building in fixture |
| Skyline or sign | yaw0 faces +Z, 90 faces +X,180 faces -Z,270 faces -X | Detailed face aims toward intended camera; opaque side/back is deliberate simplification |

Use source-bound contact-offsets.json for bottom placement, not mesh-center placement. The per-asset manifest front/back/top sockets refer to bounds. A visible wall accessory must be supported by its intended shell; do not treat source pivot as a universal wall mount.

The two current awning modules are scenery skins. During Pass2 mount them below the preserved gameplay landing surface and check the actual avatar clearance. Vehicles, train, crane cable and wrecking-ball collisions stay owned by existing gameplay assemblies; align skins to those verified runtime pivots.

The recipes above define initial contacts from authored geometry. They are not a claim that every module/rotation has been tested in Studio. Current native evidence demonstrates representative joins only.

## District add-on and final study contacts

These five meshes have lowest vertices at Y=0 after normalization. Place their source pivot at the intended floor height; do not subtract half their height again. Stock clusters are asymmetric around the pivot; use bounds rather than centering by eye.

| Asset | Contact recipe in normalized local coordinates | Tolerance / support |
|---|---|---|
| V3_LoadingFacade | Plain back is Z=-0.5. For wall front Z=0, place pivot at Z=0.3; front faces +Z. | 0.2 stud embed into an opaque wall. Back the full 24 x 14 panel with a shell; it is an overlay. |
| V3_ServiceCanopy | Pivot Y=0; footplates X=+/-10, Z=+/-4; plates 1.2 x 1.2, Y=0 to 0.6. | Four floor supports. Roof Y=10.75 to 11.25; self-supported, no side-wall embed. Keep posts outside the route. |
| V3_ServiceStock | Pivot Y=0; dumpster feet X=+/-3, Z=+/-1.4; pallet feet X=4.5,8.5. | Ground contact, no intended floor embed. X extent -3.75 to 9.0. |
| V3_WorksiteHoarding | Pivot Y=0; footplates X=+/-7.5, Z=0, spanning Z=+/-1.3. | Ground contact. Plates support posts; lower sheet edge intentionally above floor. |
| V3_MaterialsStock | Pivot Y=0; pallet feet X=-5,-1; steel bases X=2.4,3.5,4.6, length 8 along Z. | Ground contact, no intended floor embed. X extent -5.5 to 5.0. |

The study LoadingFacade at (12.4,0,-18), yaw -90, meets ServiceRear at (13.7,0,-30), yaw -90, with 0.2 stud embed where they overlap. BrickBroad supplies the surrounding building. For reuse, align wall-panel extents with the loading overlay or provide continuous backing; this fixture is not a universal snapping rule.

Final market mounting, relative to study origin: AtelierHall (-26,0,-34), yaw90; Shopfront (-14.4,0,-34), yaw90; Awning_12 (-10.85,10,-34), yaw90; Balcony (-12.35,20,-34), yaw90; Planter (-12,0,-42), yaw90. Atelier main front plane is X=-15. Shopfront back X=-14.9 has 0.1 stud face separation; atelier trim bridges that seam. Awning rear and balcony back reach X=-14.85. These 0.15 stud offsets avoid coplanar flicker; projecting atelier trim supports the visible joins. Balcony braces extend below the pivot, so its pivot height is not a gameplay landing surface.

Native close contact evidence: docs/artifacts/city-run/v3/studio10/contacts (loading front/reverse, stock feet, hoarding plates, canopy feet/underside, balcony underside). This supplements unchanged final10 scenes. Visual contacts only; preserved course colliders and avatar clearance remain Stage2 work.
