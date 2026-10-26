# Q01 trim integration

This is a decorative add-on for the current A01 stage. It has no floor or collision changes. Do not replace the stage model or move its bay/slot/display/presenter positions. Render images combine the original A01 shell with the candidate; they are Blender review evidence only.

1. Import `Q01/GrandArcade_Q01_Trim.fbx` into a separate model. Preserve the imported source in AssetImports with an explicit Q01 name.
2. Use the four `Q01Marker...__Navy` meshes to calibrate exactly as the existing A01 import. Scale factor is `10 / (Right.Position - Origin.Position).Magnitude`. Scale the import once, then reread marker positions. Right and Up define the source coordinate basis. Forward should be ten studs in the intended forward direction after transformation.
3. Form `source = CFrame.fromMatrix(origin, right.Unit, up.Unit, right.Unit:Cross(up.Unit))`. For every decorative part use `currentStage:GetPivot() * source:ToObjectSpace(part.CFrame)`; do not use the older Config origin. Confirm alignment from the final native player view.
4. Parent the clone under a clearly owned `GrandArcade.QualityTrimQ01` model. Set every part Anchored true; CanCollide/CanTouch/CanQuery false; calibration parts Transparency 1. Set color/material from suffix and the candidate's existing A01 palette. Geometry is static and needs no lights, emitters or scripts.
5. No native label or artwork should be obscured. Minimum artwork aperture is 13.62 × 13.40 studs versus the existing 13.5 × 13.2 panel. Podium cap ledges remain below existing round caps; feet remain at the original slot elevation. Rank/player/name labels stay native and require a long-name test.
6. Preserve originals. If the addon is rejected, remove only the owned Q01 clone; the original A01 stays usable. Do not hide an entire original color mesh to remove a keystone without separately preserving/restoring its other geometry.

The saved edit scene `GrandArcade_Q01_Trim.blend` contains only the added geometry. `trim-manifest.json` gives exact mesh counts, triangles and calibration names. No FPS or device performance is inferred from those counts.
