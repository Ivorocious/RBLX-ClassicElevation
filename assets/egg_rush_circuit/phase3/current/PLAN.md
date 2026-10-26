# Egg Rush Phase 3 world W02

The accepted R05 race remains the complete movement course. This plan surrounds it with one connected creature hatchery, using the five selected A05/B02/C02/D02/E03 references for appearance. Current R03/R05 geometry, six rolling eggs, two trays, chicken pecks and original start/finish govern placement; the old tail and one-tray drawings do not.

## Composition

- **Nursery courts:** The original destination retains its low intake gallery and original arch proportions. Three closed upper warehouse volumes add broad mint windows and a stepped coral roofline at Y132/144/134, with a central crown reaching Y154. A complete lower west wing supports their wider footprint. Low western nursery pavilions remain.
- **Sorting and loading:** Three deep roofed working bays and two loading canopies form the western industrial district around both egg bands. Coral and mint sorting drums give the two bands a clear relationship without new signs.
- **Shellworks:** Six connected workshops with a higher central monitor and two end towers create a substantial rear roofline. The actual shell crossing remains fully open in front.
- **Incubation:** A complete low hall grounds the central egg. A 72-stud mint tank rises behind it, with two side service rooms and recessed trunks. A tall eastern service wing frames both accepted tray rides without entering their travel corridors.
- **Rookery:** A narrow structural stem fits inside the existing guardian rock footprint. A separate eastern aviary and northern wing give the giant chicken a convincing home, with a high coral roofline behind it.
- **Shell-spill return:** A shell-roof hall reaches Y110 beside a narrower eastern service gallery at Y92. They screen the southern and eastern neighbors while the return arch and low gardens complete the descent. HallBay proportions replace vertical stretching of small nursery-room arches.

The central hall, tall incubation tank, western loading sheds, rear coral skyline and eastern rookery form distinct foreground, middle and distant layers. W01 native views exposed a serious lobby/arcade/gallery leak above the south and east roofs. W02 raises a composed warehouse skyline to screen those views, preserving the lower entrance and using windows, separate coping and a deeper closed upper mass. Final screening and scale still require native views. Large cream surfaces, mint equipment, coral roofs and honey structure carry the identity; violet remains primarily the accepted Expert route. No new sign system or decorative texture clutter is planned.

## Placement contract

`Phase3/WorldPlan.luau` returns reusable `Placements`, `Native`, `Palette`, `UnitSizes`, `Districts`, `Roles` and `ProtectedZones`.

Each placement has `Id`, `District`, `Type`, `Frame`, `Size`, `Color` and `Role`. Frame is **course-local, bottom-centered**, Y up, front toward negative Z. Size is the complete unrotated final bounding size. The controller uses `course:GetPivot() * Frame` and `Size / UnitSizes[Type]` with `WorldKit.build(parent, Type, frame, scale, options)`. Native blocks use `Frame * CFrame.new(0, Size.Y / 2, 0)` as their center.

All architecture has finished backs, sides, roofs and undersides. Lower foundations, collars and recessed service trunks connect the district masses visually. Asset units must retain their complete bounds, including roof overhangs, so the final native overlap audit can use these records conservatively. `options.Accent` recolors the mint/coral accent family while preserving the cream structure, honey framing and dark recesses; cream placements retain the kit's default material palette.

## Contact and preservation rules

No new gameplay contact or recovery floor is introduced by this plan. Every unit has an explicit visual role. Tall rooms are beyond open horizontal gaps or above reachable roofs; low landscape tops are Y -44 to -48, beneath the current lethal floor's Y -18 top. The new guardian stem fits inside the already accepted rock rather than adding a broad new plinth around nearby Expert pads. New architecture cannot replace, move, resize or recolor any accepted route or mechanism.

The controller must inspect actual installed reach, jump, underside, hazard, camera and reverse views. If a finished ledge appears reachable, reposition or reshape that architecture to maintain a clear gap; do not silently leave a phantom platform or add a shortcut contact. Final roof/bank roles and any necessary contact require native inspection.

## Neighbors

Current world origin is `(1544,311,-1134)`. Grand Arcade occupies local X `[-48.5,64.5]`, Y `[38.7,89.8]`, Z `[152.5,251.5]`. The upper south warehouse ends at Z145; its roof coping ends at Z146, leaving 6.5 studs before the arcade. Its lower entrance stays at the original Z136..144. Upper overhangs begin at Y46, above the return's jump and camera space. The lobby begins at Z208.

The gallery occupies X `[179.5,324.5]`, Y `[56,78]`, Z `[87,217]`. The eastern service gallery is X166..174/Z46..194, leaving 5.5 studs of horizontal clearance. Its footing reaches X176 only below the lethal floor. The return hall is X69..141/Z152..186; its roof starts at X68, 3.5 studs beyond the arcade's maximum X64.5. Architecture farther east than X178 stays north of Z75. No global sky or Lighting changes are part of the plan.

## Verification

W01 built natively with 912 world parts, including the 34-part MajorOnly foundation component. W02 adds 17 deliberate native warehouse volumes, windows, mullions and coping pieces while retaining the same 75 reusable-unit placements. The expected total is 929, subject to the next native build's actual count. Source bounds for the changed masses/roofline overlap none of the protected neighbors and intersect none of the measured route-center standing boxes. Total planned local bounds become `(-238,-68,-223)` to `(251,154,208)`.

The modified masses alone cover many conservative rays toward the neighbors' bounding boxes; this is preparation, not proof of horizon closure. Existing geometry, actual window/arch surfaces and the native player-height views determine the result. Recheck incubation, rookery, return and reverse views specifically; reject a giant flat screen or a roofline that overwhelms the chicken.

Source authoring and bounds review are preparation only. The lead must verify first real installed units, final part counts, actual native bounds, preserved accepted geometry, open route and mechanism corridors, player-height enclosure, honest ledge roles and matched occupied-runtime evidence where practical. Final world acceptance remains with the owner. No publication is authorized.
