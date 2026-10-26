# Window and roof-edge draft

This is an independent saved-source proposal. It has not touched Rojo source, Studio, Blender, or a native model. Native day/night composition and the final combined preservation checks remain root's work.

`WindowFinishingPlan.Apply(plan, layout)` updates the nine model placements making the three existing gallery windows, then appends 32 finishing units. Return values include exact replacements, additions, occupied rows, resource delta and each window's complete pointed-top height. No building transforms, terrain seats, original main window, crown screens, contacts, signs, arrows or mechanisms are changed.

For integration, add the returned resource delta to architecture counts and update district counts from `additions`. Regenerate final architecture occupied rows from the finished plan: the Source 49 rows contain the obsolete positions for the reseated gallery windows. Root must bind final checks to the integrated plan with crown and cliff changes, rather than using this independent check as the complete candidate proof.

## Gallery seating

The existing window bases remain at Y52, Y56 and Y60. Their X positions and scales remain exact. Each moves from Z79.3 to Z72.9, ahead of both the new hall's north roof edge at Z74.4 and the original gallery backing/eave. Their authored-facing rotation remains yaw pi.

Each receives a narrow stone-backed bay from Z73.0 to Z79.8 and a small slate cap. The frame back penetrates its stone seat, while glass and lead stay ahead of stone. The pointed tops remain at Y71.714, Y75.714 and Y79.714. These are gallery/player-height details, rather than distant roof decoration. No hall removal or relocation is proposed.

The two west windows are separated along the climb. The high-wing window sits on a solid jamb. The middle-wing window uses a small stone seat in the central facade, avoiding the adjoining wing that otherwise conceals the side jamb. The medium pair beside upper machinery uses matched backed roof bays, ahead of the large route-facing slate pitch. This avoids the upper-story faces that are hidden by the lower roof. Two narrower keep windows finish the existing rear pinnacle's south face; bases at Y151 keep the accepted Y150 crown floor from masking their bottoms.

Three shaped stone cornices finish the high west, middle west and upper machinery eaves. The original verified slate and masonry assets supply all bay caps and backing. No new asset upload is required. The existing main keep window remains substantially larger than every addition: its installed frame is about 26.4 by 73.06 studs, versus west windows 12 by 28.99, machinery 11.04 by 26.67, and upper keep 6.72 by 16.23.

## Authored facing

BL02's `architecture.py` describes facade front as Blender -Y. The verified conversion is Roblox (X,Z,-Y), so the ornate front is Roblox **+Z**. The bright frame moldings and lead tracery are ahead of the glass on that side. `Model.LookVector` points the opposite way; using it as the rendered front would reverse the ornate face.

This draft keeps original gallery yaw pi, uses yaw +pi/2 for east-facing west windows, -pi/2 for west-facing machinery windows, and yaw zero for south-facing upper keep windows. The original window's three matching assets share the same origin and scale.

## Evidence boundary

`focused-window-check.json` passes the original static clearance helper's 32 route and lift combinations against 1,586 unique protected volumes under this check's exact frame/size/reason deduplication. There are no movement, jump headroom, follow-camera, landing sight or invalid contact-flag findings in the proposed occupied geometry.

Each of the nine complete pointed-window silhouettes has 1,333 visibility samples, no farther than one unscaled asset stud apart, including the precise top. All pass against occupied boxes for current Source 49 architecture, proposed finishing and accepted static course contacts. The grid is evidence of unobstructed sampled geometry from real waiting/checkpoint/route standing positions; it is not a raster visibility test or gameplay run. The gallery checks use points three studs toward the left side of each actual NormalWaitBefore terrace to avoid the decorative lantern wall bracket crossing the sight line. That is a meaningful gallery view but does not claim every position on the terrace sees every frame edge.

The full high west window is proved from the normal climb landing after CP01, at local (-188,37.5,-112), rather than the CP01 centre, where accepted climb stones hide portions of its bottom. The middle west window is proved from the shared climb landing at (-128,25.5,0). Both machinery windows are proved from the CP04 centre at (112,111.5,-86), and both upper keep windows from the actual crown centre at (-8,155.5,-30). These offsets are eye height above accepted surfaces; they do not alter the route or move its floors.

Use the listed player-height cameras as a starting point for native full-window captures. Confirm frame, lower panes, lead divisions and pointed tip in each completed day/night view. Root should decide `SecondaryWarmWindow` appearance from those views; the proposed six use that new role without changing existing glass roles or adding lights.

Known added cost: 32 units, 84 mesh parts, 36,040 triangles. Existing nine gallery placements are replaced without changing resource cost. Source 49 combined totals plus this proposal alone are 210 units, 571 mesh parts, 191,186 known triangles, before the other finite closeout drafts.
