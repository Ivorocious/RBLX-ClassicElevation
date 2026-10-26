# Readable hazards and articulated chicken source

`candidate_a01` is Blender-authored editable source for six native Part templates. `ReadableKit.luau` is generated from inspected solid boxes; no mesh upload is needed.

- Four hazards: 19 parts, 11 visible red lethal pieces. Large red silhouettes replace tiny hot inserts inside pale housings. Fixed bases and motors are charcoal.
- Body: 16 fixed decorative parts, with wings, coral feet and a stationary tail fan. Local pivot matches course `(78,18,40)`; front faces +X.
- Head: 14 parts facing local -Z. Beak ends at `(0,-1,-10)`; neck attaches at `(0,-3,2.5)`. Only its red beak has `ERLethal=true`; the peck runtime controls when contact is active.
- Two articulated neck links are supplied by the course assembly, not this kit.

`Create(parent, key, frame, scale?)` uses keys `ScorchedShell`, `HeatGrate`, `FeederPaddle`, `FeatherPinch`, `Body`, `Head`. Models contain anchored, noncolliding native Parts. All queryable lethal Parts are visible red Neon; nonlethal housing is not queryable. The course supplies motion, warning markers and recovery behavior.

Blender generation inspected finite, closed, positive-volume solids and orthonormal native transforms. The saved scene is checked separately. The offline API check created 24 models and checked 196 parts at default, uniform and nonuniform scales. Those checks do not prove native gameplay or appearance. The board is a source preview of the four hazards, not a Studio screenshot.
