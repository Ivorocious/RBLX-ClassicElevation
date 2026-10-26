# Continuous fortress landscape draft

This is an implementation draft for the enclosure commission around the unchanged Source48 course. It replaces the previous Environment.Get output: oval groves, low meadow island, bedrock display plinths, meadow drifts and ground lamps. The lead integrates and inspects the real map. No production, native Studio, Blender, imports, accepted course or final-judge reports were changed or used by this helper.

The reference review's start, upper machinery, crown outward and whole-setting pictures show the specific gap: all greenery is below the upper climb, with sky between isolated display hills. Historical Shipwreck31 bow, cliff and cave views demonstrate the needed relationship between nearby framing, larger middle landforms and a closing skyline. This design translates that structure into a rocky rural fortress valley; it does not copy tropical scenery or claim those pictures show current Shipwreck33.

## Authored landform

Five unique sectors form one continuous heightfield across localX[-390,390],Z[-355,350]. They use one global height function and exactly identical boundary sampling grids. They are separate import units, not repeated hill templates. All five sector placements use identity CFrame and scale1 relative to Origin[4000,300,2600]; their vertices already contain course-local positions.

The inner route setting is an excavated rock ravine rather than a green floor. Broken slopes descend to roughlyY-90, with the closed geology extending toY-130. Narrow near banks rise behind the fortress. Middle wooded cliffs rise roughly180–285; the irregular north skyline reachesY327.263. East/southeast low saddles around105–150 preserve a crown view over the complex and countryside, bounded by higher northern/western silhouettes. Inner grass surfaces are absent. Higher grass/soil occurs on the enclosing slopes outside the route field.

| Sector | Footprint | Highest authored point | Terrain triangles |
| --- | --- | ---: | ---: |
| InnerRavine |X[-276,246],Z[-228,228] |121.744 |30,716 |
| WestWoodedCliff |X[-390,-276],Z[-228,228] |274.648 |4,300 |
| EastPanoramaSlope |X[246,390],Z[-228,228] |271.904 |5,824 |
| NorthHighRidge |X[-390,390],Z[-355,-228] |327.263 |6,492 |
| SouthValleyRidge |X[-390,390],Z[228,350] |290.435 |4,942 |

Every sector is a closed outward-facing mesh. Surface triangles cover adjacent areas once; no top area is duplicated. Material changes select existing faces, rather than layered skin slabs. Shared top-edge vertices/heights are exact. Closed vertical sector-boundary faces overlap only internally beneath the joined surface and are buried; they are not exposed decorative joins. Outside boundary faces form the deep inaccessible rock skirt. Bottom caps use nondegenerate center fans.

InnerRavine has adjacent RockA/RockB top bands plus existing Rock for the buried boundary/bottom. All use identical RGB100/112/116 and Rock appearance. Each material mesh is below15,000 triangles. Splitting materials adds no vertices or competing surface area. Earth100/86/68 and Grass91/119/75 give subdued slope transitions; the lead should map these roles explicitly in the scenery palette.

## Fortress seating

FortressSeats.json is the frozen copy of the fortress author's38 exact ground footprints. It includes the final NorthEastRaisedCourt pivot(248,-94,-216), seven bastions, deep wings, ramparts, courts, forward gate and hood, plus the retained keep/gallery/low returns. It is a data input to EnclosureRecipes.py and must travel with that recipe.

Deep roots atY-94 receive rock recesses atY-90, giving4studs of burial. Raised halls, retained gallery/returns and the main keep root atY-38 receive rock atY-34. Twenty-four-stud sloped excavation shoulders join those recesses to the high cliffs. Higher overlapping terraces bury deeper basements further; they do not leave floating feet. The retained main keep's real footprint has priority over nearby deep recesses.

The three raised halls remain visible at player height: EastUpperDeepWing(241,-38,-100),RearMachineSteppedHall(111,-38,-221),GalleryRearGreatHall(18,-38,122). The NW bastion's relocated root(-282,-94,-154) gets its own cliff excavation. This avoids burying most of the new fortress beneath the original uncut ridge. These changes preserve every building top/body/roof pose supplied by its author.

Footprint edge coordinates are sampled explicitly and snapped to.001stud to avoid thin float-precision slivers. Footing-check.json records nine actual triangulated samples per footprint and verifies no ground foot floats, within.03stud tolerance. The separate geometry helper can prove exact trim-polygon burial against the full top-triangle metadata. Neither check relies only on a nominal soil height.

## Woodland and player views

The draft combines existing verified Rural_BroadleafClump/EvergreenGrove units with two small single-tree variants made from the same Source48 Phase3 tree recipe. Single trees are necessary where a rigid three-tree group cannot match a steep slope. No Phase1 asset is modified. All roots sample the actual triangulated surface, including row/column diagonal parity. Individual roots bury2.65–3.05studs; rigid groups are chosen only where root-height differences are≤6studs and all roots bury into soil. There are no new oval tree pedestals.

| View | Near/middle/distant relationship |
| --- | --- |
| Start(-144,0,146) | Forward monumental gate supplied by the fortress author frames negativeZ. Its excavated rock banks make the space a deep approach, with higher western/northern woodland beyond the architecture. |
| CP01(-144,28,-112),markerY31 | West bastion/cloister and the rising west cliff make a stone enclosure. Northern woods continue behind them; selected gaps reveal the next district instead of bare sky. |
| CP02(-80,52,28) | Retained nearby lantern gallery and keep form the courtyard walls. Ground below the jumps is a deep rocky ravine; outer roofs and wooded ridges supply further depth. |
| CP03(112,72,-52),markerY75 | East upper wing and machine structure provide the close frame. High east/north slopes and trees sit behind the rails, well above the player's eye height. |
| CP04(112,106,-86),markerY109 | Raised rear machine hall and northern bastions form the upper room. The wooded north ridge and skyline remain above this stage. The east landing retains camera/recovery separation. |
| Crown(-8,150,-30) | Close keep/crown stone screens remain. West/north high woods close the background; a lower east/southeast saddle reveals the layered fortress, countryside and farther high shoulders. The rewarded view is composed, rather than an empty horizon. |

Massing-study.png and climb-profiles.png are offline views of the authored triangulated surface and footprint recesses, not native map pictures or gameplay proof. Repeat the saved start, CP01–04 and crown views after integration, and add an east/southeast crown panorama. Inspect normal forward camera views as well as upward architectural views.

## Files and integration

EnclosureRecipes.py exposes build_recipes() in the same pure vertices/faces/material style as the prior LandscapeKitRecipes. Dependencies are Source48TreeRecipes.py and FortressSeats.json. BuildMetadata.py validates manifold edges/winding/positive volume, bounds and per-material triangle ceilings, then writes the metadata and woodland placement files. It does not operate Blender.

EnvironmentPlan.luau requires EnclosureGeometry and WoodlandPlacements. Its Profile and PlaceSolidArrow forward the exact PreviousEnvironment versions in this draft. The lead is inlining the original Profile and unchanged3576-byte arrow tail for production source-guard parity. EC01 library labels are draft labels; the lead will map them to the unified verified ER01 library.

EnclosureGeometry.luau contains compact grids, counts and bounds. A small deterministic generator caches occupied triangle columns once at require time. The corresponding terrain-metadata.json retains full exact top triangles and occupied data for offline/native audit. A triangle solid extends from its three actual top vertices to the shared baseY-130; its AABB is used conservatively for the focused clearance screen. This avoids treating a large hollow/variable landform as one huge box.

WoodlandPlacements.luau and woodland-roots.json record exact poses/root sampling. Physical architectural ledges alone receive the existing six basin/fern compositions; no floating fallback planter or scenery route is added. No new lights or sky lifecycle are proposed.

The final full draft has67units/157meshes/85,958placedtriangles and82trees, under the reserved90/230/90,000 landscape limits. Landscape-check.json records zero movement/headroom/camera/landing-sight/invalid-flag findings across47,182terrain/prop rows. All47,120generated terrain columns and their exact triangle order crossmatch the offline metadata. Recipe-check.json records seven library assets,19material meshes and52,850library triangles. These totals exclude fortress art and are not measured FPS/multiplayer evidence. Keep the final combined350unit/900mesh/420,000triangle cap when integrating both authors' plans.

## Required native follow-through

All art is anchored with collision/query/touch disabled. The accepted contacts, gaps, hazards, wait/landing spaces, mechanisms, recovery,19arrows and fall/reset planeY-23 remain exact. Higher near geology inside the wider fall footprint is screened against actual course spaces, rather than excused by its large distance alone.

The source check compiles the true Config/Layout, crossmatches every generated occupied column/top triangle against the offline metadata and checks standing/jump/transfer/catch/boarding/car/weight/swing/camera/landing-view volumes. Source checks do not establish the finished native presentation. Integration still needs verified imported shape/axis/pivots/materials, exact protected comparisons, true terrain/building joins, no exposed seam walls, readable night woodland/stone, deliberate start/crown openings, focused moving-camera inspection and renewed independent review. Shared masonry flashing remains the geometry/fortress authors' repair, not a claim closed by this landscape.
