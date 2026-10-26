# Crown finish draft — two scenery scales only

The selected draft reduces the two close `GrandFlankPinnacle-1` / `GrandFlankPinnacle1` units to scale `(0.9, 0.3, 0.9)` at their exact existing roots. Their tips fall from local Y187.8 to Y144.4, below the unchanged crown floor at Y150. The rear central pinnacle remains at its original height and position; the two new upper keep windows can use its exact existing face.

`SceneryRevisions.luau` is the only integration module. SHA256 `50f851d6b275bc716e87946b1288b9828d11b709005ec70a46c9f16a6a06b20f`.

## Integration

Apply `Crown.Revise(data)` before WorldPlan calculates metadata, occupied rows and resource counts. `Crown.Additions()` returns an empty list. Both open screens, the coherent crown base, main keep shell, emblem mount, accepted floor/skin/finish/approach and all gameplay pieces retain their original data.

There are zero added units, meshes or triangles. Before the independent window/cliff finishing work, the source49 totals remain 178units /487scenery meshes /155146placed triangles. Six existing mesh parts receive scale changes.

## View to inspect after installation

The primary camera is **the actual finish centre**, course-local `(-8,155.5,-30)`, looking toward `(172,124,4)`, at the established FOV70. World coordinates are `(3992,455.5,2570)` looking toward `(4172,424,2604)`. This looks east and slightly southeast: machinery and upper course at the left, the eastern fortress layer, then the lower southeast wooded saddle.

The four `*Corridor` rays in `crown-rays.json` start at that exact centre. In source49 they strike the eastern flank turret after 27.28–29.45studs. All four clear after only the turret scale change; they have no further exact authored scenery intersections or conservative native part-bound intersections before their endpoints. These are open view corridors, not a claim that the endpoint itself is a rendered roof or tree.

Check natural arrival from the last accepted approach stone and the turn back across the completed climb. The additional southwest standing view is a companion at `(-23.5,155.5,-18.5)`; it is inside the unchanged floor footprint and is explicitly not the centre proof. The low western route cannot be fully visible from the centre because the accepted floor itself hides steep downward sight lines. The tall forward gate also legitimately hides structures behind it. Those blocked rays remain in the report.

## Verification

- `focused-checks.json`: 32branch/lift combinations, 1581distinct movement/mechanism/headroom/camera/landing reserves, eight occupied rows for the two changed units, zero findings.
- `cap-join-check.json`: focused horizontal cap audit against the coherent fortress/crown and the existing screen/tower recipes at 0.002stud tolerance. Sixteen raw same-facing candidates inside the original flank top bands are fully buried. The whole overlap polygon and an outward probe fit inside actual closed convex band components; every component face is checked against its convex boundary. There are zero unproved exposed candidates involving the two modified units. This extends the geometry screen only; native temporal evidence remains root's responsibility.
- `luau-changed-plan.json` binds the tested Luau poses, while `candidate-unit-plan.json` and `crown-rays.json` bind the independent geometric ray analysis.
- No Studio, live Blender, Rojo source, accepted course or asset upload was touched by this author.

## Historical alternative

`PreparedRaisedRimAlternative.luau` records the explored 12stud crown-base lowering, internal carrier and screen-footing option. It is **not selected and must not be integrated**. It does not improve the four chosen centre corridors over the smaller turret-only draft and would add unnecessary support units. The comparative `loweredRim` case is retained in the ray report for the same reason.

Native day/night composition and a real moving-render check still need to be judged on root's final integrated candidate. This draft is not a five-reviewer verdict or owner acceptance.
