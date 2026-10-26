# Fortress implementation draft

This is an implementation packet for the enclosure repair commission, not final review or native appearance proof. All files are inside the assigned fortress draft folder. No production source, Studio, Blender scene, accepted route, mechanism behavior, signs or arrows were edited.

## Composition

- Forward arrival: the 132-wide, 53-deep gate is at (-144,-94,106), facing the Start's negative-Z journey. Its stepped pointed opening is84 wide and has at least50 studs of headroom above course origin; roof peak206. Two large arrival bastions frame the approach. The former chamber behind Start is retired.
- Stone climb: three deep west wings, a224-high northwestern bastion and stepped curtains form a close stone district. The recovery corridor remains clear. The northwest keep wing connects the accepted main keep and apse to the north fortress.
- Lantern court: keep the three accepted gallery bodies/roofs, six planting ledges, banners and selected interior lancets. The rear great hall adds depth and a second roof level. Three wall brackets extend the accepted header ends into the gallery. The real open court beneath the jumps stays open.
- Machinery: a joined open hall frames both lift stages. Its solid side houses stand outside the car/counterweight corridors; its iron beam is atY172 and roof peak216. Four reused brackets behind the wheel faces connect the accepted mechanisms to this hall. Deep east/rear wings have visible walls and roofs reaching upper-route height, with roof peaks185.2. Upper waiting, car travel, receiving contacts and approach views remain clear.
- Crown reveal: keep the original crown screens, emblem, focal keep window, four buttresses and three pinnacles. The lead's MainKeepShell and CrownBaseShell replace adjoining cap-bearing bodies with exact solid unions. Main peak237.8 stays above the224.08 secondary bastions. The eastern/southeastern buildings remain lower, leaving a framed valley panorama; the terrain helper closes the background with connected wooded ridges.
- Raised courts: these are outside reachable course space, bounded by substantial parapets and seated in excavated rock. The northeastern court's nearest high wall is at least27 studs from the upper normal receiving contact. They are scenery, not recovery platforms. There is no new playable floor.

## Integration interface

WorldPlan.Get(layout, options) returns the usual plan and counts. It requires PreviousWorldPlan (a byte-for-byte Source48 WorldPlan snapshot), FortressGeometry, and the existing Source43WorldPlan/BaselineWorldPlan/AssetGeometry/TowerGeometry dependencies. The new ER01 library must supply all MC_ER_* assets and the repaired MC_AR_MasonryMass/MC_AR_FoundationBay46 assets. Legacy P1/P3/TL01 art remains in its existing verified libraries.

FortressGeometry includes measured metadata for the seven owned recipes plus the lead geometry helper's shared cap/keep/crown assets. MeasureRecipes.py refreshes this from geometry/recipe-check.json. The lead's CrownBaseShell is course-local authored geometry placed at identity CFrame, not at FinishPoint; MainKeepShell is placed at (-8,-38,-30). Do not move either template's pivot during import.

BlenderFortressRecipe.py exports PALETTE and recipes(a,e) using the established mesh/export adapter. The seven owned templates total23 material meshes/1,416 nominal triangles; maximum source dimension310 studs. All are closed as assembled and per material. Bastion caps overlap only inside adjacent color sections, about0.01 stud; there are no competing exposed band caps. Gate/hall opening proxies contain only real jamb or stepped arch solids. Roof boxes conservatively enclose the closed roof slopes.

placement-plan.json gives every exact placement, local CFrame12, scale and library. occupied-plan.json contains actual solid boxes with noncollision/query/touch flags. ground-seats.json gives38 footprints and roots: most new scenery atY-94 with proposed rock seat-90; main keep, three high halls, three gallery foundations and two low junction returns atY-38 with rock seat-34. The terrain helper must verify these against the actual terrain mesh; nominal seat heights alone do not close the remaining root-cap audit.

The three gallery foundation and two junction return roots were extended fromY-30 to-38 with their exact old tops retained. Their gallery body, roof, planter, banner and window transforms stay unchanged. Counts.assemblies exposes the new foundationBase-38.

retire-map.json lists every Source48 retirement and the earlier Source43 retire names. The five old keep wall/apse masses and nine old roof/underfloor/curb masses map to their lead union replacements. Repeated west/east/rear service facades and behind-start arrival are replaced by the fortress. ContactFascia5_-1 and ContactFascia28_-1 are retired because their pre-existing decorative bounds crossed recovery/headroom/camera reserves. Protected contacts, StoneSkin, signatures, hazards, branches, recovery, signs and 19 arrows are unchanged.

## Focused checks

The upper representative was checked before the full map. CheckFortress.luau then sampled all32 branch/lift choices, all fixed contacts/transfers, free jump headroom, follow cameras, receiving-lip visibility, both car sweeps and three lantern sweeps. It also explicitly reserves the actual upper west counterweight atXoffset-46. Final full draft:111 units,330 meshes,69,188known triangles;1,581 unique protected volumes;0 movement/mechanism, headroom, camera, visibility or invalid-flag findings. Geometry's pure welded-edge check is 0 for each template and each material; Blender manifold/export and native import remain lead checks.

The lead geometry helper has also audited inter-placement caps. Its current remaining non-base/root planes require the joined terrain's exact burial proof; do not assume they are hidden from a nominal Y value. The blueprint in massing-plan.svg supports composition review and is not a render.

## Native checks still required

Inspect the complete representative upper hall first, then Start, CP01–04, upper exit and crown at player height in day and final night. Specifically confirm the deep hall walls frame CP03/04, the lantern headers visibly join their brackets, wheel faces remain readable, all raised courts look inaccessible, and the crown's selected openings reveal the distant wooded landscape. Inspect joins while translating the camera, including the saved crown A/B positions with shadows both on and off. Check the retired fascia edges remain visually finished by the accepted floor skins. Protected native/course/source comparison, actual terrain seating, final unit/mesh/triangle ledger, saved recovery and independent review remain lead-owned.
