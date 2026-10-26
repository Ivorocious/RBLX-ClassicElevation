# Small Phase 3 visibility proposal

Implementation helper proposal for the daylight Build03 evidence. This is not a final reviewer judgment or a native playtest result. No production source or Studio state was edited.

Inspected actual pixels in day-e1-fork-build03.jpg, day-e1-landing-build03.jpg, day-e2-fork-build03.jpg, day-e3-fork-build03.jpg, day-gate-build02.jpg and day-overview-build02.jpg. Read current Layout, ExpertRoutes, RouteBuilder, DecorativeClearance, VisualAssembly, Wayfinding, WorldPlan, WorldAssembly, the photo script and accepted BL02 arch/pier authoring. The current PHASE3_START commission supersedes the older Phase 2 boundary.

## What the evidence supports

- E1's old photo eye (-150,35,-128) faces east/south toward the keep. It is on the far side of CP01, looking away from the incoming southeast-to-northwest route. It cannot represent a first-arrival decision. Large underside arch faces still dominate the actual fork/landing photos and mix later route surfaces into the immediate decision.
- E2 has useful close window architecture and visible narrow rail/lanterns. Its broad branch lies north (-Z), while the Expert entry runs east (+X). The old sign only names broad/narrow demands; it does not identify their entrances. Incoming racers arrive northwards from the cloister before turning to inspect the eastward gallery.
- E3's old eye (110,113,-66) is nearly aligned with the Lower Bay1 guide at x=111,z=-70. The actual photo is heavily blocked by that black guide. This is direct evidence of a bad authored photo eye, not enough evidence to relocate signature machinery. Capture from each bay center x=103/x=121 first.
- The Gate court has a clear keep landmark and visible red encounter ahead. Keep its existing floor, red obstacles and deliberate challenge.

## Exact art change

Omit only the three long decorative underside arches on the next fresh rebuild. Their horizontal spans are 118, 84 and 96 studs:

| Model under Decoration/ArchUndersides | Authored endpoints |
| --- | --- |
| ArchNormal_ArchSupport_3 | (-216,32,-141) to (-216,36,-23) |
| ArchNormal_ArchSupport_5 | (-188,39,-9) to (-188,42,75) |
| ArchNormal_ArchSupport_9 | (-156,48,131) to (-156,50,35) |

The current other ten authored arch supports have spans below 72. A small maximum-span 72 check before DecorativeClearance.Suggest therefore produces the same current omission set, while retaining the existing clearance check for every placed arch. Prefer the explicit names if later layouts legitimately add other long spans.

This removes the most stretched stone faces and reveals the existing west arcade bays, keep windows, piers and south cloister as actual local settings. Preserve the accepted MC_StoneArch template and all current course floors. Do not move gameplay contacts to accommodate these decorative arches. Do not change the three signatures, GuideIron, red gate openings, moving apparatus or their colliders to improve a photograph. No new world placements are proposed.

The photos do not uniquely identify every mesh visible in a crowded frame. These are a narrow source-derived candidate omission set, followed by affected native views; they are not claimed to explain every visible face.

## Replace the same three signs

All values below are course-local; add Origin (4000,300,2600). Construct each board with CFrame.lookAt(center,faceTarget). Preserve noncolliding, nonquerying, nontouching decorative settings and the existing three-sign count. Replace the original two-line generic legend; do not add signs or graphic arrow symbols. Keep the existing seven floor-arrow IDs unchanged.

| Fork | Board center | Face target | Size | Front text |
| --- | --- | --- | --- | --- |
| E1 Stone Arch | (-146,32.4,-127) | (-149,32.4,-108) | (11,3.4,.15) | NORMAL: LEFT · WEST ARCADES / EXPERT: RIGHT · RISING RAILS |
| E2 Lantern | (-24,56.4,114.5) | (-50,56.4,108) | (11,3.4,.15) | NORMAL: LEFT · WIDE GALLERY / EXPERT: AHEAD · NARROW RAILS |
| E3 Upper Lift | (112,110.4,-94.55) | (112,110.4,-83) | (12,3.4,.15) | NORMAL: RIGHT · EAST GALLERY / EXPERT: BOTH SIDES · STEPS |

Use the existing warm Normal and purple Expert lettering. The explicit draft includes separate back lettering without LEFT/RIGHT/AHEAD, because repeating an approach-relative direction on the reverse face would be misleading. Keep the existing trim at the new width.

- E1: canonical arrival from (-188,24,-46) toward CP01 (-144,28,-112) faces roughly (+X,-Z). The Normal departure (-156.63,28,-124) is left of that facing direction; InnerTakeoff (-129,28,-112) is right. Its following rise runs +Z, so RIGHT names the first commitment rather than implying the full route stays east.
- E2: the sign faces the eastward inspection stance inside CP02. From that +X facing direction, the -Z broad gallery is left and the +X EntryRail is ahead. The separate Arrival view documents the real northward arrival and its turn; the sign is not presented as a compass-independent direction.
- E3: the sign mounts .20 studs in front of the existing UpperFrontWall's south face (wall center z=-95.5, depth1.5; south face -94.75). Facing -Z from CP04, Normal GateTakeoff (142,106,-68) is to the right and the Expert first steps (139,110,-81)/(85,110,-81) occupy both sides. The board does not depend on the CP04 recovery-pocket location. Do not mount at z=-97.1: the wall would hide it.

E1 board stays beyond CP01's north edge and away from its northwest Normal launch. E2 board is outside CP02's east edge, with its near edge more than three studs south of the Expert entry rail's z=106 edge. E3 uses the existing solid wall. These are placement checks from authored coordinates, not measured native camera/body-clearance proof.

## Focused photo eyes

VisualReadabilityProposal.luau contains sixteen optional views. Start with E1Arrival, E1NormalFork, E1ExpertLanding, E2Arrival, E2Fork, E3Bay1Arrival, E3Bay2Arrival and E3NormalCommit. Use the reverse and mirrored Expert views only when the affected forward view still leaves a specific uncertainty. Eyes are six to seven studs above the relevant approach surface, with receiving lips in the target.

Important replacements:

| View | Eye | Target |
| --- | --- | --- |
| E1 true arrival | (-161,35,-91) | (-144,29.5,-112) |
| E1 Normal commitment | (-141,35,-107) | (-177,29.5,-142) |
| E1 first Expert landing | (-130,35,-122) | (-129,33,-91) |
| E2 true arrival | (-44,59,122) | (-39,54,100) |
| E2 gallery fork | (-56,59,108) | (-24,54,102) |
| E3 Bay1 arrival | (103,113,-72) | (117,109,-85) |
| E3 Bay2 arrival | (121,113,-72) | (136,109,-81) |
| E3 Normal departure | (124,113,-87) | (142,108,-68) |

These are targeted inspection cameras, not a change to the game camera. Retain the prior views as historical evidence. Keep one original Obby Tournament session under the lead's control.

## Checks and limits

The draft is data-only. The local Lune compile check could not start inside the restricted process because it could not canonicalize the workspace current directory. A read-only host retry did not complete before it was cancelled; no compile pass is claimed. The lead can run CheckVisualReadabilityProposal.luau with the known working Lune invocation.

After integration, check only the changed E1 fork/landing views, three board faces and E3 bay-center views first. Retain the same seven native ArrowIds, three boards, 21 real on-course red contact obstacles and invisible FallY277 recovery. No motion, floor, route connection, accepted template or runtime change is in this proposal. Ordinary human pacing, 20-racer movement, final-night comfort and performance remain separate.
