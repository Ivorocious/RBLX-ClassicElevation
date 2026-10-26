# Moonlit Phase 3 night integration recipe

Draft only. Apply after the lead finishes daylight movement and true fork/landing checks. Use the existing original Obby Tournament Studio and existing lighting controller. This helper inspected exact current source and made no production or Studio changes.

## Current source and smallest edit set

ClassicAscentAmbience.client.luau already owns course-profile selection, baseline Lighting/Sky/Atmosphere/effect restoration, locally hidden-root restoration, a half-second activation check and destruction cleanup. Moonlit is not currently in its four-profile list. The prepared modules are not installed in ReplicatedStorage. WorldAssembly currently records NewLights=0 and leaves placed glass materials unchanged. RouteBuilder currently has WorkLighting="Daylight" and no MoonlitNightAmbience attribute.

After the daylight gate, make these five scoped changes:

1. Copy MoonlitCitadelAmbienceConfig.Prepared.luau to src/ReplicatedStorage/Config/MoonlitCitadelAmbienceConfig.luau.
2. Copy AmbienceGate.Prepared.luau to src/ReplicatedStorage/Shared/MoonlitCitadelAmbienceGate.luau. This is a pure activation check, not another lighting controller.
3. Add the config and gate call to the existing ClassicAscentAmbience.client.luau.
4. Add clone-only window glow and six lights to the existing WorldAssembly.luau.
5. Set the required builder attribute only after successful world assembly.

default.project.json already syncs both folders. Do not change its daylight Lighting, Sky or Atmosphere, the accepted BL02 templates, the editor camera, geometry, colliders, bounds, runtime, sounds or play driver. Preserve the prior candidate/native recovery before a fresh rebuild.

## Existing client controller: three small hooks

Near the existing ConfigFolder declaration, use:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfigFolder = ReplicatedStorage.Config
local MoonlitAmbienceGate = require(ReplicatedStorage.Shared.MoonlitCitadelAmbienceGate)
```

Append ConfigFolder.MoonlitCitadelAmbienceConfig to the existing module list. Keep the four current profiles and archive-lighting ownership branches unchanged.

Append one clause to the existing active condition, after its ActivationDistance check:

```luau
and MoonlitAmbienceGate.Allows(course, config, root.Position, humanoid)
```

The prepared gate returns true immediately for profiles without UseCourseBounds, preserving their existing activation behavior. For Moonlit it requires a live humanoid; a Model named RaceCourse; CourseId="moonlit_citadel"; MoonlitCourse=true; RuntimeActiveCourse=true; MoonlitNightAmbience=true; and the live root position inside the existing BoundsCenter/BoundsSize. Keep the existing ArrivalOpen, lobby exclusion and start-distance conditions as well. Missing metadata, dead/missing character, inactive candidate or an out-of-bounds root yields the existing setActive(nil) restoration path within the half-second check.

Keep HideWorkspaceRoots={"MoonlitCitadelPhase1_BL02"} from the prepared config. The existing hideOutOfBounds/restoreHidden code changes LocalTransparencyModifier and visual Enabled/Visible/Transparency properties on that accepted sample locally, then restores their saved values. It does not change its colliders or template. CourseService already moves the editable Course_MoonlitCitadel copy into ServerStorage during Play, before spawning the RaceCourse clone; do not add a second broad hiding system.

The prepared night profile uses ClockTime=.15, Brightness2, ExposureCompensation.15, cool Ambient/OutdoorAmbient, low-density haze, moon/star sky and modest bloom. Use it as the first integrated candidate, then adjust only a property whose actual night view exposes a readability problem. The client controller never touches CurrentCamera.

## WorldAssembly: new clones only

Inside the existing descendant loop, immediately before its decorative-flag assertion, add:

```luau
if data.asset == "MC_WindowGlass" then
    part.Material = Enum.Material.Neon
end
```

Here `part` is the current loop variable in the inspected source. Only newly placed Phase3World MC_WindowGlass models change material. Retain all three accepted amber mesh colors, geometry and flags. Do not alter the BL02 library, accepted Phase1 sample, unrelated warm/brass materials or every material named Amber. MC_P3_CrownScreen currently has only StoneLight/Stone/Iron/Brass exports; it is not a glass target.

After the placement loop and mesh-count assertion, add the following fixed six-light list and loop. All parents already exist. This creates six PointLights, zero BaseParts, zero attachments and no extra mesh/geometry placements:

```luau
local lights = {
    {"MoonlitWarmGate", "Gate", "GateCourt", .65, 24},
    {"MoonlitWarmCP01", "SharedArches", "CP01Terrace", .70, 24},
    {"MoonlitWarmCP02", "Gallery", "CP02Terrace", .75, 26},
    {"MoonlitWarmCP03", "Lifts", "CP03Terrace", .70, 24},
    {"MoonlitWarmCP04", "Lifts", "CP04Terrace", .75, 24},
    {"MoonlitWarmCrown", "Crown", "CrownTerrace", .85, 26},
}
for _, data in lights do
    local contact = course.Obstacles[data[2]][data[3]].Contact
    assert(contact:IsA("BasePart") and contact:GetAttribute("MCWalkable") == true)
    assert(not contact:FindFirstChild(data[1]), "World light already exists")
    local light = Instance.new("PointLight")
    light.Name, light.Color = data[1], Color3.fromRGB(255, 188, 75)
    light.Brightness, light.Range, light.Shadows = data[4], data[5], false
    light.Enabled = true
    light:SetAttribute("MoonlitWorldLight", true)
    light.Parent = contact
end
world:SetAttribute("NewLights", #lights)
```

Replace the existing NewLights=0 assignment; do not leave a later assignment that overwrites six. The emitters sit at their existing Contact centers, slightly below the floor tops; Shadows=false prevents these parents from creating a new shadow budget. Their six parent positions are tied to existing floor contacts, not the CP04 recovery-pocket location.

| Light | Existing floor top, course-local | Emitting Contact center |
| --- | --- | --- |
| Gate | (-144,0,146) | (-144,-1,146) |
| CP01 | (-144,28,-112) | (-144,27,-112) |
| CP02 | (-44,52,104) | (-44,51,104) |
| CP03 | (112,72,-52) | (112,71,-52) |
| CP04 | (112,106,-86) | (112,105,-86) |
| Crown | (-8,150,-30) | (-8,149,-30) |

Expected course count: six new tagged shadowless lights plus the three unchanged existing lantern AmberLights = nine PointLights. NewLights remains six, not nine. These small warm pools complement the global cool light; they are not evidence of measured GPU/device performance. Keep their shared authored Enabled=true for both comparison states; day/night pairs differ only in the client profile. The normal Studio editor retains its daytime global Lighting.

## Required builder attribute

At the existing end of RouteBuilder.Build, immediately after WorldAssembly.Apply(course,Layout), add:

```luau
assert(course.Decoration.Phase3World:GetAttribute("NewLights") == 6)
course:SetAttribute("MoonlitNightAmbience", true)
```

Do not set RuntimeActiveCourse on authored/library models: CourseService already sets it on the runtime RaceCourse clone. Preserve WorkLighting="Daylight" because authoring stays in daylight and the client supplies night only while active. The required attribute lets the controller reject historical/daylight-only candidates without special names or controller duplication.

## Focused restoration checks

Use one original Studio Play session. Before entry, record the actual client baseline for every prepared Lighting key, existing Sky and Atmosphere keys, Bloom/SunRays properties/existence, CourseColor.Enabled, and accepted Phase1 sample local visual values. Record the editor Lighting/camera separately before Play. Baseline means current native values, not an assumption that all properties match default.project.json.

| Check | Trigger | Expected evidence |
| --- | --- | --- |
| Gate stays off | Alive in bounds but MoonlitNightAmbience=false on the live clone | Actual baseline lighting; CourseColor disabled; accepted P1 local visuals unchanged |
| Entry | Required attribute true, correct active RaceCourse, live root inside bounds, ArrivalOpen=false | Config values apply; six added lights remain shadowless; accepted P1 sample hidden locally; no second controller |
| Exit | Move root outside bounds or return to lobby | Within the existing check interval, all touched Lighting/Sky/Atmosphere/effect values restored; created profile effects removed; existing effects restored; CourseColor disabled; accepted P1 visuals restored |
| Re-entry | Return alive to the active course | Night reapplies from the same recorded baseline, without accumulated effects/lights/connections |
| Death/respawn | Humanoid.Health reaches zero; later respawn inside the active course | Death restores baseline; live in-bounds respawn reapplies night; no stale hidden P1 state |
| Required attribute/course gone | Temporarily turn MoonlitNightAmbience false or remove only the runtime test clone through existing flow | Baseline restoration, then normal reactivation only after valid course/attribute returns |
| Stop | Stop the same Play session | Original editor/day Lighting, Sky, Atmosphere, accepted P1 state and camera remain intact; no night written into Edit mode |

Reuse setActive's existing save/restore and script.Destroying cleanup. It intentionally leaves its one pre-existing CourseColor instance disabled after deactivation; do not count its disabled presence as an unremoved night effect. Avoid a second death handler, lighting owner, per-frame loop or new permanent diagnostic UI. Preserve the Keyboard Circuit ownership/yield branches; their code is outside this change.

## Exactly six paired final scene views

Capture these six scene pairs from the same integrated candidate, same camera pose/FOV70, unchanged architecture/materials/lights, and the same live in-bounds owner character. Add Origin(4000,300,2600) to both points. Night activation follows the character position, not these inspection cameras; an aerial eye must not disable night. Use the existing photo controller and restore its original camera/UI state afterward.

| Pair/file stem | Eye | Target | Acceptance question |
| --- | --- | --- | --- |
| overview | (-410,260,360) | (-15,77,0) | Complete crown/spire framing, connected castle layers, three signatures and restrained warm windows |
| gate | (-150,8,160) | (-117,5,146) | First playable route and real red hazards remain readable against the keep |
| e1-arrival | (-161,35,-91) | (-144,29.5,-112) | Actual incoming fork shows Normal departure, first Expert receiving lip/gate and sign after the solid parapet repair |
| e2-fork | (-56,59,108) | (-24,54,102) | Normal left/Expert forward are obvious; timed lanterns, waits and gaps remain readable |
| e3-bay1-arrival | (103,113,-72) | (117,109,-85) | True bay-center arrival avoids the old guide-aligned eye and shows the Upper Normal/Expert commitment |
| crown-arrival | (-29,157,-19) | (-8,153,-30) | Player-height final landing, crown destination and earlier layers are readable |

For each pose: capture day with only the runtime MoonlitNightAmbience attribute false; set it true, wait for actual night config to apply, then capture night at the identical pose. Restore the true attribute afterward. Keep an alive root within the course and ArrivalOpen=false throughout. Confirm actual ClockTime/Exposure/Atmosphere before saving each image; a requested pose or Night flag is not proof the image rendered correctly. Name day-<stem>-buildXX.jpg and night-<stem>-buildXX.jpg. These six pairs are the final presentation set; reuse the earlier affected E1/E3 reverse/landing and Bay2 checks rather than rerunning a wide camera suite.

Judge lips, red contact faces, silhouettes and sign text from pixels. If a board or receiving lip disappears at night, first adjust the implicated profile/light property and recheck that pair; do not compensate with more signs, arrows, geometry, invisible walls or extra lights. Exactly21 on-course red contact units, seven floor-arrow IDs, three decision boards, four checkpoints and separate invisible FallY277 recovery remain unchanged.

## Completion limits

This is an integration plan, not installed lighting or a native night/restoration pass. Source compilation and the focused native checks belong to the lead after the daylight gate. The current six-light values are a bounded starting point. Human pacing, 20-racer behavior, camera comfort on actual controls and device performance remain separate from these visual and lifecycle checks.
