# SC_KIT_04 asset catalog

Counts are evaluated FBX triangles. Estimated reuse is a planning allowance, not a built map. Dimensions are normalized Roblox X/Y/Z studs. Colliders are separate from visual meshes.

| Asset | Family | Triangles / ceiling | Dimensions | Estimated copies | Placed triangles | Collider boxes |
|---|---|---:|---|---:|---:|---:|
| SC_DockDeck | dock | 48 / 120 | 12.00 × 1.23 × 10.00 | 12 | 576 | 1 |
| SC_DockRefuge | dock | 48 / 120 | 18.00 × 1.23 × 16.00 | 6 | 288 | 1 |
| SC_ShipDeck | deck | 48 / 350 | 12.00 × 1.23 × 16.00 | 14 | 672 | 1 |
| SC_DockPost | post | 12 / 60 | 1.50 × 10.00 × 1.50 | 40 | 480 | 0 |
| SC_TimberBeam | spar | 12 / 180 | 12.00 × 1.60 × 1.60 | 24 | 288 | 0 |
| SC_BoardingRamp | deck | 12 / 350 | 12.00 × 6.30 × 8.00 | 4 | 48 | 1 |
| SC_CargoCrate | crate | 72 / 100 | 4.00 × 4.00 × 4.24 | 10 | 720 | 1 |
| SC_CargoBarrel | barrel | 92 / 180 | 3.26 × 4.40 × 3.26 | 8 | 736 | 0 |
| SC_CannonCover | cover | 36 / 120 | 8.30 × 7.20 × 4.65 | 4 | 144 | 2 |
| SC_HarborGate | gate | 48 / 240 | 22.50 × 16.00 × 2.41 | 1 | 48 | 3 |
| SC_HullSide | hull | 36 / 900 | 12.90 × 18.00 × 16.00 | 12 | 432 | 0 |
| SC_HullBow | hull | 84 / 900 | 25.60 × 25.11 × 22.79 | 1 | 84 | 0 |
| SC_SternTransom | hull | 36 / 900 | 24.00 × 18.00 × 1.60 | 1 | 36 | 0 |
| SC_PlayableRib | rib | 48 / 100 | 14.09 × 19.58 × 3.60 | 9 | 432 | 1 |
| SC_BrokenDeck | deck | 24 / 350 | 12.00 × 1.20 × 16.00 | 6 | 144 | 2 |
| SC_BrokenSpar | spar | 24 / 180 | 16.00 × 1.88 × 2.80 | 8 | 192 | 1 |
| SC_MastYard | mast | 24 / 120 | 24.09 × 31.05 × 1.50 | 2 | 48 | 0 |
| SC_TornSail | sail | 40 / 40 | 23.00 × 18.00 × 0.12 | 2 | 80 | 0 |
| SC_CliffMass | cliff | 32 / 1200 | 28.00 × 32.00 × 19.92 | 20 | 640 | 0 |
| SC_CliffShoulder | cliff | 32 / 1200 | 22.00 × 15.00 × 17.32 | 16 | 512 | 0 |
| SC_GroundingRock | cliff | 32 / 1200 | 12.00 × 7.00 × 8.66 | 16 | 512 | 0 |
| SC_RockLedge | cliff | 32 / 1200 | 12.00 × 3.00 × 8.66 | 20 | 640 | 1 |
| SC_RefugeShelf | cliff | 32 / 1200 | 18.00 × 5.00 × 13.86 | 4 | 128 | 1 |
| SC_CavePortal | cave | 44 / 2400 | 32.00 × 25.00 × 8.00 | 2 | 88 | 3 |
| SC_CaveRoof | cliff | 36 / 1200 | 36.00 × 8.00 × 20.00 | 6 | 216 | 1 |
| SC_CaveWall | cliff | 20 / 1200 | 18.00 × 22.00 × 12.00 | 10 | 200 | 1 |
| SC_SurgeCrossing | cliff | 12 / 1200 | 16.00 × 1.00 × 12.00 | 1 | 12 | 1 |
| SC_LocalSurge | water | 12 / 24 | 12.00 × 0.30 × 22.00 | 1 | 12 | 0 |
| SC_FoamRibbon | foam | 28 / 80 | 12.00 × 0.12 × 2.00 | 6 | 168 | 0 |
| SC_CoveWater | water | 12 / 24 | 100.00 × 0.20 × 100.00 | 4 | 48 | 0 |
| SC_Cannon | cannon | 244 / 450 | 8.20 × 4.37 × 3.96 | 2 | 488 | 0 |
| SC_Cannonball | cannon | 76 / 450 | 1.60 × 1.60 × 1.60 | 2 | 152 | 0 |
| SC_DangerStripe | cue | 12 / 80 | 8.00 × 0.16 × 1.00 | 8 | 96 | 0 |
| SC_MuzzleCue | cue | 12 / 80 | 1.10 × 0.24 × 1.10 | 2 | 24 | 0 |
| SC_Palm | palm | 66 / 350 | 16.28 × 22.07 × 17.12 | 12 | 792 | 0 |

Unique: **1478 triangles / 35 meshes**. Estimated repeated scenery: **10176 triangles**.

## Mounting notes

- **SC_DockDeck**: Local bottom at zero; deck faces align by their top height. No scaling across width.
- **SC_DockRefuge**: Local bottom at zero; deck faces align by their top height. No scaling across width.
- **SC_ShipDeck**: Local bottom at zero; deck faces align by their top height. No scaling across width.
- **SC_DockPost**: Ground bottom; support deck underside. Vertical scaling 0.5-2 allowed.
- **SC_TimberBeam**: Beam centerline X; simple box collider only if a deliberate playable spar.
- **SC_BoardingRamp**: Rise5.3 over12 run. Lower walking face atZ1, upper atZ6.3; mount bottom one stud below lower landing.
- **SC_CargoCrate**: Four-stud cargo jump or cover dressing; collision owned by simple box.
- **SC_CargoBarrel**: Eight-sided silhouette; no individual staves or metal rivets.
- **SC_CannonCover**: Seven-stud solid cover with low return on waiting side; entire avatar pocket must be outside shot/impact bounds.
- **SC_HarborGate**: 17.6-stud opening, underside14. Place shared visual R0 gate after forward merge; keep functional triggers separate.
- **SC_HullSide**: One 16-stud half-shell bay with a sloping broken upper rail. Rotate paired placements; retain open keel/ends for joins.
- **SC_HullBow**: Tapered bow closes the shell end; no tiny splinters. Module join at local Y0.
- **SC_SternTransom**: Transom closes paired half-shells; use with high stern deck, not a second complete bow.
- **SC_PlayableRib**: Chunky rib reaches keel; authored top3.2x3.6. Add simple cap collider; avoid changing its width to fake difficulty.
- **SC_BrokenDeck**: Five-stud real center gap. Separate box colliders per surviving strip; never fill hole with bounding collider.
- **SC_BrokenSpar**: 16-stud supported spar; keep2.8-stud width, use separated placements for real jumps.
- **SC_MastYard**: One mast and yard, no rope strand meshes; base socket on deck.
- **SC_TornSail**: Three broad silhouette tears; thickness0.12. Separate from mast for practical fitting; no cloth simulation.
- **SC_CliffMass**: Large flat facets. Uniform scaling0.75-1.5; overlap foundations under ground, retain clear playable shelf colliders.
- **SC_CliffShoulder**: Large flat facets. Uniform scaling0.75-1.5; overlap foundations under ground, retain clear playable shelf colliders.
- **SC_GroundingRock**: Large flat facets. Uniform scaling0.75-1.5; overlap foundations under ground, retain clear playable shelf colliders.
- **SC_RockLedge**: Large flat facets. Uniform scaling0.75-1.5; overlap foundations under ground, retain clear playable shelf colliders.
- **SC_RefugeShelf**: Large flat facets. Uniform scaling0.75-1.5; overlap foundations under ground, retain clear playable shelf colliders.
- **SC_CavePortal**: 20-stud opening and19-stud center roof clearance. Use three simple boundary colliders; do not cap opening.
- **SC_CaveRoof**: Roof underside at local Z0; maintain minimum12-stud clear height over standing surface.
- **SC_CaveWall**: Broad supporting cave wall, muted shaded stone; do not obstruct refuge/daylight sightline.
- **SC_SurgeCrossing**: Flat low crossing for H02, flood cue visually distinct from ordinary water. Simple box collider.
- **SC_LocalSurge**: One local solid-color water slab, moved/raised by fixture; no full-ocean simulation or permanent transparency.
- **SC_FoamRibbon**: One broad opaque foam silhouette, use only near local surge/impact. No particle field.
- **SC_CoveWater**: Flat opaque surface; instances only where visible, no overlapping transparent ocean layers.
- **SC_Cannon**: Eight-sided low barrel; muzzle points local-X. Local shot centerZ3.1. Base aligns with deck, body is not a route collider.
- **SC_Cannonball**: Diameter1.6. Whole sphere must clear cover and water impact; shot height3.1 above deck requires real jump test.
- **SC_DangerStripe**: Red marks real hazard footprint; never use it for safe route arrows.
- **SC_MuzzleCue**: Small local warning cue. One controller, no new PointLight; final audio scope separate.
- **SC_Palm**: Five broad leaves, three trunk segments. Soil/rock socket required; canopy away from takeoffs.
