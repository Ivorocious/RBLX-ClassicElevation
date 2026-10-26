# M02 floating hardware and hazard signs

The two visual modules add 17 substantial floating assemblies and 17 large signs to the M01 course. The accepted route, moving objects, gates, ordinary pressed keys, laps and checkpoints stay in their existing modules.

`FloatingDecor.Build(course, origin, template)` adds four assemblies per district and one motherboard beneath the central void. Creamy has a full keyboard, an exploded switch, stacked circuit trays and a circuit raft. Thocky has a controller board, a switch monument, a spring column and capacitors. Clacky has a split keyboard, a large cable connector, a switch tower and a circuit shelf. Clicky has a large rotary encoder, a relay keyboard, stacked boards and a contact connector. Ordinary display caps remain 2.4 by .85 by 2.4 studs; the larger scenery comes from complete housings, switches, boards and connectors. The three keyboards use three labels each.

`HazardIndicators.Build(course, origin)` reads the existing eight mechanisms, links their 16 fixed warning plates to signs, and adds a separate lift exit sign. Every sign has a caution rail, a large phase label, a written action, a drawn arrow or stop mark, and a specific mechanism, lane, drop or panel title. All new geometry is inside `course.MapEnvironment`, anchored and excluded from collision, touch, queries and pressing. Decorative models use `WarningMechanismId` and `IndicatorKind`, which do not add gameplay mechanisms.

Integration uses the existing server runtime:

```luau
local HazardIndicators = require(script.Parent.HazardIndicators)
```

At the end of `visibleWarning`, after its existing attribute writes:

```luau
HazardIndicators.UpdatePlate(plate, warning, admission, message)
```

Immediately after the Seesaws branch writes the unit's `CycleState` as `Rocking`:

```luau
HazardIndicators.UpdateUnit(unit)
```

`UpdateUnit` follows references built with the signs. It does not scan the course. `UpdatePlate` is called by the existing warning flow and updates GUI properties only when the displayed phase or action changes. Neither module starts another timer, heartbeat, event listener or animation loop. Repeating `Build` for the same course returns the existing visual group.

The lift uses the unit's exact `BoardingWindow` and `ExitWindow`; its physical actor's `CycleState` remains `Stopped` during normal operation, so it is deliberately not used as the lift's display state. The shuttle also reads the unit state and the exact docking windows. Disabled slider constraints force both mechanisms' signs to `STOPPED`, including during reset. Fallaway and Shift advertise crossing only when the existing warning call admits it. Foundry signs describe their individual drop zone; Domino signs describe their individual panel. They do not promise that the entire encounter is clear. Resetting panels show an upward arrow and `PANEL RISES NEXT` before movement. The shuttle entry says `STEP ON; RIDE ACROSS`; its exit says `STEP FORWARD ONTO CTRL`.

Root validation should compile and build both modules together, verify 17 scenery assemblies and 17 signs, and check every new BasePart for anchored, noncolliding, nontouching, nonquerying and nonpressable state. Also check that gameplay mechanism IDs still total eight, and compare route contacts, gates and timing values to M01. In Studio, check approach views for each sign, both Fallaway lanes, all three Foundry drops, the lift entry and exit, shuttle docking, Domino reset warnings, both Shift windows, and Stop/reset. Check camera space, route sightlines, moving-object travel and recovery pads against the complete assembled candidate. Geometry counts do not prove device performance, and source review does not prove gameplay behavior.

Only `FloatingDecor.luau`, `HazardIndicators.luau` and this note were authored for this task. Root owns integration, compilation, native installation, visual review and runtime checks.
