# Upper keep surface correction draft

The changing outer pale bands have actual competing stone faces. The saved assembled geometry places the main body and both pale jamb strips on the same front and back planes. One existing StoneLight mesh receives a 4% depth increase, creating 0.368 studs of relief at the jamb faces while preserving its centre and the complete window pair.

## Actual face evidence

`actual-assembled-keep.json` exports the saved assembled vertices and original polygon indices. `face-overlap-proof.json` compares those actual polygons; it does not substitute authored boxes for the material faces.

- Main body Stone polygons 6 and 7 occupy course-local Z approximately -69.2 and -50.8. StoneLight polygons 30/36 and 31/37 share these planes, respectively.
- The two jamb strips span Y133.800003–171.800003, with X intervals approximately [-19.875, -18.125] and [2.125, 3.875]. Their front/back overlap totals 266 square studs across 16 triangle-pair intersections.
- Source51 has 32 same-facing intermaterial triangle overlap pairs. Twenty-two overlap polygons cannot be proven wholly buried in another actual closed component.
- The historical 2% trial clears the vertical overlaps but leaves six cap overlap polygons not wholly buried. Their reported candidate area includes buried portions and is not measured visible cap area.
- The selected 4% correction removes the vertical overlaps. All 16 remaining horizontal overlap polygons are wholly buried in actual convex closed stone components, verified against their original faces and an outward probe of 0.001 studs. No convex hull fill is accepted for a component whose original faces do not lie on its hull boundary.

This establishes a concrete material-surface conflict matching the changing jamb area. Native movement checks still determine whether all observed changes are resolved.

## Exact placement adjustment

Only `GrandRearCentralPinnacle`, asset `MC_TL_GrandPinnacle`, library `TL01`, material part `MC_TL_GrandPinnacle__StoneLight` receives:

```luau
partLocalScaleOverrides = {
    MC_TL_GrandPinnacle__StoneLight = Vector3.new(1, 1, 1.04),
}
```

The multiplier acts on the native MeshPart local size axes after the existing unit author scale. Size changes from (28.75, 104, 20.69999885559082) to approximately (28.75, 104, 21.527998). The saved native template and Vector3 oracle produce Z21.527997970581055; the mathematical double-precision product is 21.527998809814454. The original CFrame, its rotation and its placement formula remain exact.

The actual TL01 native rotation has local Z direction approximately (-8.742277657e-8, 0, -1). Saved Blender raw mesh Y maps to this native depth direction. The isolated derivative therefore postmultiplies the object's Blender matrix by diag(1, 1.04, 1, 1), leaving its centre unchanged. Blender world Z is height and is not the adjusted axis.

The pale coping's half depth becomes 9.36 asset studs; the existing Stone base has half depth 10. The total tower bounding envelope stays inside its existing base footprint. The jamb depth grows from 8 to 8.32 asset studs. The focused clearance oracle must account for the actual increased material extents rather than retaining the narrower old jamb proxy.

## Boundaries and handoff

The two draft modules preserve every existing Source51 crown revision and addition. WorldAssembly accepts only the named unit, asset, library, part and factor, requires exactly one StoneLight MeshPart match, and applies no part translation or unit transform change. The verified library template, Stone/Slate meshes, all six upper keep window edit units, glass appearance and all protected course objects remain unchanged. Resource changes are zero units, zero parts and zero triangles.

`render01` compares Source51 and the candidate at two actual camera frames from the saved native movement trace. These are unretouched Blender images with approximate night lighting. Preservation hashes and actual window surface rays accompany the images. They are geometry/composition evidence; final native temporal rendering remains the root's verification step.

The four renders show continuous raised jamb trim in both candidate camera views. Actual window surface probes total 27,014 per camera, including occluded rear and internal faces. Before/after hit outcomes are identical at both cameras, so this is a preservation comparison rather than a claim that every sampled face is visible. Exact geometry digests preserve all 717 protected objects, all 638 other world material parts and all 14 upper keep window material parts. Both LF source drafts compile successfully.

The independent focused check in `verification52/part-override52-focused-check.json` passes the corrected native material-part bounding box against 32 route choices and 1,586 unique protected volumes. It reports no blocking, headroom, camera, sight or contact-flag failures. The final integrated Source52 plan is not yet bound in that focused report; root owns the combined staging and native checks.

No Studio, live Blender, production source, import library, FBX or upload is changed by this draft.
