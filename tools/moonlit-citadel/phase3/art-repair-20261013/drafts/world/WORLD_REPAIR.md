# Connected citadel draft

This is an implementation proposal for the accepted Source 38 / Build 32 course. It replaces only Phase3World scenery. It preserves the accepted course, Phase 1 libraries, other Decoration including ArchUndersides and CrownEmblem, signs and the 19 arrows. The lead integrates and verifies the actual map; this note does not grade Phase 3.

## Build contract

Load `WorldPlan`, `BaselineWorldPlan` and `AssetGeometry` together. `WorldPlan.Get(layout, {representative=true})` selects the central gallery/keep sample. `Get(layout)` includes the complete gate, west cloister, machinery and connecting wings. `counts.fullMapPending` is true for the sample and false only for that full continuation. Optional `clearance` and `config` arguments run the protection helper against occupied geometry.

AR01 placements use `MoonlitCitadel_P3ArtRepair_AR01Library`; P3 and BL02 assets reuse their verified libraries. Apply every placement relative to the same course origin. All art must be anchored and have CanCollide, CanQuery and CanTouch false. Move an entire named cell or joined wing when checking clearance; independently relocating its wall, foundation or roof breaks the design. Use the occupied boxes for hollow bodies rather than their whole enclosing bounds.

The lead corrected the imported AR01 handedness after a native sample exposed the closed rear toward the course. These drafts describe the corrected convention: front +localZ, rear -localZ. Use the corrected native library; do not add another placement rotation to compensate for the old importer result.

AR01 true dimensions are 47.6 × 26 × 23.2 for GalleryBody46, 48.18 × 9.12 × 25.2 for its closed roof, 48 × 40 × 24 for its foundation, 12 × 24 × 12 for TowerBase and 25 × 24 × 13 for MasonryMass. All use base pivots. The body and roof centers are 11 studs behind their front origin. A roof sits at body-local Y26, with its closed eave overlapping the coping. The foundation ends at the body's base and starts at ground Y-30. Foundation width stays broad; the height/nominal-width ratio is below 3.3. Turret bases are at most 48 studs tall.

## Exact placement and volume decisions

Values below are course-local and derive from the current accepted Layout. Runtime uses that Layout instead of hardcoded copies of route coordinates. The placement list is `complete-plan.json`; supporting ledges, joined-cell anchors, portal and screen results are in `check-report.json.complete`.

| Region | Connected construction |
| --- | --- |
| Lantern gallery | Three cells at X -36, 18, 72; base Y50, 54, 58; front Z59.6, yaw π. Accepted band spacing is 54, so bodies/foundations/roofs use X scale54/46. Their coping overlaps at cell boundaries. The stepped bases preserve the route's ascent. Each body has a real rear and both side walls. |
| Gallery/keep wing | Broad west return X[-36,-24] and east return X[24,36], both Z[-12,59.6], Y[-30,38]. One closed roof spans their width and length. Its ridge stays below the nearby low swing volume. |
| Keep roof storey | Six explicit solids span X[-46,30], Z[-48,-12], Y[125.8,147.8]. Full-height west/south/northwest returns meet the retained lower keep. The northeast/east approach sills stop at Y136.8. |
| Crown portal | Deliberate open volume X[12,43], Y[137,168], Z[-68,-34]. It protects the accepted east approach, jump, camera and receiving-lip view. No solid portal patch or shortcut wall crosses it. |
| Crown destination | Exact accepted 36 × 28 terrace footprint receives a stone underfloor seat Y145..147.8. South and west curbs support joined crown screens. A stone backing supports the unchanged original emblem. Two small corner turrets sit on 24-stud buttressed bases resting at the keep storey Y125.8. |
| Gate court | Closed chamber base(-144,-6,174), yawπ; broad foundation to Y-30, seated roof. Two12 ×48 buttressed tower bases at X-172/-116, Z182 rest on the ground mass and support compact .65 turrets. |
| West cloister | Three46-wide enclosed cells, front X-235 yawπ/2, centers Z-96/-50/-4, bases Y26/36/36. The whole row moved22 west to protect the accepted west catch. Low closed courtyard wings connect its south end to the gate; foundations remain broad and continuous. |
| Machinery | Six46-wide enclosed cells front X189 yaw-π/2, centers Z-146/-100/-54/-8/38/84. First three basesY100, last threeY66. Broad foundations, side closures and seated roofs replace isolated panels and dangling supports. |
| Gallery/machinery corner | Two further54-wide service cells X126/180, baseY60/62, frontZ59.6 connect the gallery to the east machinery row. The last cell overlaps the enclosing row at the outer corner, so no detached filler return is needed. |
| Rear mechanism house |59.8-wide cell front(112,132,-197), yaw0, foundation to-30. The complete house moved14 farther behind the accepted machinery to clear Expert camera and landing-view rays. Its substantial stone wall supplies a readable night backdrop. |

Planter shelves are real7.6 ×1.2 ×6 stone ledges at gallery-local X±18.7826, Y2.8, Z1.4. The six supplied planting mounts sit at their topY4 and identify the corresponding supportName. EnvironmentPlan must use these anchors, with no floating fallback pedestals. Quiet secondary lancets attach to the rear exterior at localZ-23.3; banners attach to front masonry piers, and ivy attaches to west walls. No tree or scenery contact becomes a route surface.

## Eight review issues

| Finding | Authored response | Actual evidence still required |
| --- | --- | --- |
| 1 Separate scenery panels | Whole gallery, gate, cloister and machine cells; connected low courtyard/service wings; retained lower keep enclosed by a joined upper storey. Old unrelated Phase3World panels retire. | Full-map front, side and rear views after integration; inspect the stepped cell joins. |
| 2 Thin overextended supports | Broad closed foundations instead of elongated posts; fixed12 ×24 or12 ×48 buttressed turret bases, small roof turrets seated on real keep/gate masses. | Ground/player-height views confirm terrain meets the bases and no old long posts remain. |
| 3 Incomplete roof/arch joins | AR01 supplies complete side/rear walls, coping, closed gables and roof soffits. Roof seatY26 overlaps the wall coping; each stepped cell has its own end closure. | Low-angle native views inspect eaves, side returns, corners and undersides. |
| 4 Detached roof/crown | Named joined keep-storey solids, exact underfloor seat, seated screen curbs, unchanged original emblem with physical stone backing and integrated corner towers. | Crown arrival plus keep-east/rear views confirm convincing joins and preserved east portal. |
| 5 Flat unfinished base | Architecture now ends atY-30 on broad foundations; Environment author seats faceted rocky skirt/islands and visible restrained planting on these actual roots and six ledges. | Integrated ground-edge/player-height views. Landscape alone is not included in this WorldPlan. |
| 6 Dark background/machinery | Rear mechanism house and nearby broad machine gallery give stone backdrops behind the rails; dedicated SlateRoof/StoneStructure roles permit quieter readable surfaces. | Lead's final night profile, day/night machinery pictures and restoration outside Moonlit. No lighting lifecycle is changed here. |
| 7 Material/window imbalance | Keep only the hero main lancet; secondary lancets scale .34/.28 with subdued SecondaryWindow role. Roofs, stone and attached accents have separate roles. | Lead applies the quiet palette to scenery clones only and checks native night contrast; giant bright secondary panes must not return. |
| 8 Scattered generic detail | Attached gate/gallery/machine banners, west ivy and six supported gallery planting groups. Crown uses architectural screens/emblem, machinery uses a substantial service house. | Player-height district identity and detail support checks; no isolated filler props. |

Recommended scenery response: clean restrained stone, darker slate, warm muted secondary glass, restrained metal. The accepted main window remains the focal warm accent. Tune new scenery clones without modifying the accepted source asset libraries.

## Focused source check

`CheckWorldPlan.luau` loads the true current Config and Layout through the existing Lune runtime, compiles all draft modules, and checks the proposal against accepted standing/jump/transfer/catch/boarding/car/counterweight/swing envelopes and advisory camera/landing-view rays. It asserts inert flags and fails on any listed conflict. It does not alter production or inspect native geometry.

Latest results: representative69 units/197 meshes/87,880 triangles; complete159 units/437 meshes/163,736 triangles. Both have zero blocking, headroom, camera and visibility findings and zero invalid contact flags. The full plan retires243 old Phase3World units. The counts include preserved lower keep and contact fascia but exclude separate EnvironmentPlan art. This is within the existing world350-unit/900-mesh/420,000-triangle budget.

Integration still needs actual imported-part placement/occupied-shape agreement, native inert flags, the final source/native protection comparison, clear doorway orientation, full-map day/night views, focused moving-camera checks at the repaired joins, terrain seating and final independent judgments. These source results are not native movement, FPS, multiplayer or owner-acceptance evidence.
