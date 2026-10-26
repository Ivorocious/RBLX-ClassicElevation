# Shipwreck Cove recovery

The final critique candidate is SC28_CANDIDATE_05 (layout SC_MAP_28). It is an editable native model, not a published place.

- `shipwreck-candidate28-05.rbxm`: final native model backup. Its adjacent verification JSON records an independent Lune reopen and class counts.
- `shipwreck-source-c05.zip`: ten scoped runtime/source files plus their build hash list. The rest of this existing project remains required.
- `ShipwreckCove_SC_MAP_28.blend`: editable full assembly; custom meshes also remain in Kit28 and Wave28B Blender files.
- `layout28.py` derives the layout from frozen layout27 and routes28.py. Grounding measurement JSON files preserve measured palm/spike/cargo/support positions.
- The review evidence and exact source hashes are in `docs/artifacts/shipwreck-cove/review28`.

To restore, first save the current place and archive its current Shipwreck model. Insert the final `.rbxm` in Edit mode as `Workspace.Course_ShipwreckCove`, then sync this project's source with Rojo. Use Studio's developer map selector to play Shipwreck Cove. The native model contains no embedded gameplay scripts; its runtime comes from the project source. Do not publish until the owner accepts the result.

Original owner geometry remains separately archived in Studio as `ServerStorage.__SC28OwnerArchived` and `.__ShipwreckOwnerBefore28`; C04 is archived as `.__SC28Candidate04`. A native model backup does not establish that the entire Studio place has been saved.
