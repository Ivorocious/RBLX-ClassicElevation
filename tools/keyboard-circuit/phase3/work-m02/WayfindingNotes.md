# M02 signs and checkpoint presentation

`Wayfinding.Build(course, origin, template)` runs after the environment builder and returns `course.MapEnvironment.Wayfinding`. A second call returns the same group.

- Eight numbered save stations reuse the original flag, pole and checkpoint panel. Start also reuses its course title. R1 and R3 place both existing Normal/Expert panels inside the same station. F01 has a separate lap-finish station that says to return to start; it has no save identity. All 31 original decorative parts remain present.
- Dark metal cases, broad silver edges, family inserts and large cream/dark text replace the flat boards. Numbers show 00 at start and 01–07 at the saves. Normal says wide keys/full route; Expert says small keys/shorter/harder jumps. Actual departure positions supply “ahead/back, left/right” wording, so choosing a route does not depend on color.
- Low colored collars and chunky socket corners identify the existing permanent landing banks. They stay below pressed key height. Any trim that overlaps another bank's body/head space is omitted and counted in `OmittedTrimForHeadroom`. No overhead checkpoint bars cross the route.
- Choice arrows point toward the actual first Expert contact and next Normal entry contact. They sit below and beyond the bank edge, with no supporting collision. The sign panels also store their `DepartureTarget`.
- Mount selection checks the entire case against bank body/head space and existing artwork, then checks five approach/bank views toward the sign face. The fallback moves the station farther out or changes sides. A missing clear mount raises an error instead of hiding the sign.

The module changes only presentation parts. New and reused artwork is anchored, noncolliding, nontouching, nonquerying and `Pressable=false`. Gates, keycaps, contacts, routes, recovery attributes, spawn frames and progress scripts are not edited. No per-frame work, listeners or remotes are added.

Verification: the module compiled in the existing Lune interpreter. A standalone build reached the choice panels and exposed Lune's missing `BasePart.Position` default; target reads now use `CFrame.Position`. The integrated M02 audit belongs to the lead. No native Studio changes or playtesting were performed here.

Focused integration checks: count eight saves and two choice stations; preserve all gameplay/contact attributes and 116 recovery footprints; include rehoused panels and case parts in artwork motion, headroom, camera and sign-occlusion audits; verify both departure directions and all seven displayed ordinals; inspect text at normal player distance and a small viewport. Mount checks are geometric checks, not a claim of human readability or crowd capacity.
