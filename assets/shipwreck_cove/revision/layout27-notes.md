# SC_MAP_27 / SC27_FINAL_04 layout notes

`layout27.py` derives from `layout26.py` and preserves the owner-approved cave shell, 16 cave stones, checkpoint/gate positions and three-lap structure. Run it to regenerate layout27.json, layout.json, Layout.luau and Kit.luau. Source placement counts include repeated meshes.

- Three red dock cargo sweeps; four grounded wreck cargo obstacles and two additional moving ship bars.
- Fifteen narrow rib caps and eleven narrow supported spars. Twenty-six staggered cliff ledges include three wider pockets and six added rock shoulders. Separate walking colliders define their top surfaces.
- Six fixed stalactites attach at their ceiling origins. Four falling spikes use center pivots with measured roof anchors. Five coconut lanes use the new palm crowns. See grounding27.json for measured mounts.
- The approved 16-stone cave is unchanged. Two crests cross ahead of a trailing flood. FINAL_04 keeps the flood at least 1.25 studs above the crossing floor during the active surge; the collision height uses the same water top. Raised refuges remain outside the tide volume. The waiting sign sits beside the approach rather than over its sightline.
- Curved opaque grass replaces triangle clumps; eleven shore palms use the new segmented asset. Eighteen reused 92-triangle distant ridge meshes layer the horizon. Course-only ambience hides and restores the lobby/palette on the client.

Generated placements: 479 meshes, 32,880 placed mesh triangles, 144 walking surfaces. FINAL_03 live accounting: 945 BaseParts, 493 MeshParts, 48 unique meshes, 33,852 attributed mesh triangles including runtime crests/droppers, five lights. FINAL_04 changes sign placement, water color and flood height only; refresh its live receipt. Working ceilings: 1,200 parts, 35,000 placed mesh triangles, 48 unique meshes, six lights. Primitive-part triangles, avatars and UI are additional.

Continuous R15 movement fixtures passed ribs, spars, cliff, cave and wreck with timed hazards off. Controlled hazard fixtures passed eight checks. Combined active-hazard traversal is being checked separately. These checks do not establish human difficulty, complete three-lap timing, mobile performance or 20-player flow.
