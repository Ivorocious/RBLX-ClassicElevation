# Cave26 tide sequence

H02 now runs a 14-second cycle: 6 seconds dry, 2.5 seconds warning, 4 seconds surge, and 1.5 seconds drain. The first crest crosses the cave during the early surge and leaves a continuous flooded hazard behind it. The second crest starts before the first finishes, crosses the already flooded passage, and raises the water to its full surge height. The pool remains hazardous through the drain; the raised refuge route remains outside the unchanged tide bounds.

The runtime reuses the authored wave and foam ribbon, cloning each once for the second crest. It adds no tide particles or new collision parts. `SurgeBounds` exposes `Phase`, `WaveNumber` (0, 1, or 2), and `WavePhase` for inspection. The existing cannon and crumble handlers are unchanged.

Verification needed in Studio: watch a complete cycle from player height at both cave refuges; check that both crests are distinct, the water remains connected to the cave bed through drain, a racer in the flooded passage recovers, and racers on raised refuges remain safe. Then run a full-race pass through the cave and verify checkpoint recovery. Source-level checks alone do not prove Studio visuals or contact behavior.
