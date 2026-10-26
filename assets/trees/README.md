# Stylized oak

For the prepared direct-upload workflow, see
[Blender to Roblox without computer use](../../docs/BLENDER_ROBLOX_UPLOAD.md).

Direct upload was verified on 2026-09-06: asset `105751216627858` was inserted
through Studio MCP as `Workspace.StylizedOakApiTest`, then configured with
`finish_api_test.luau`. This comparison copy rests at `(4, 17, -140)` and the original
tree remains unchanged. Upload, insertion and screenshots used no computer use.

Created through Blender MCP on 2026-09-06 and imported into Project Classic
Elevation, place ID `85558151074819`.

- `StylizedOak.blend`: editable tree scene; the original default scene is preserved.
- `StylizedOak.fbx`: 14 mesh objects for Roblox's 3D importer.
- `create_stylized_tree.py`: Blender construction and export source.
- `finish_studio_import.luau`: one-time Edit-mode scale, color, and placement step.

The current Studio model is `Workspace.StylizedOak`, beside the lobby spawn at
approximately `(30, 17, -137)`. Its height is 16 studs. All pieces are anchored;
only the trunk collides. The importer uploaded the meshes to the signed-in Roblox
account. The place itself was not published or saved by this task.

To repeat the import, import the FBX as a model with Add to Workspace and Set Pivot
to Scene Origin enabled, then run `finish_studio_import.luau` in Edit mode.
Studio's default FBX import produced 100x geometry and gray colors; the finishing
script normalizes the height and restores the palette. This asset is not mapped
into Rojo; its authoring sources are stored here and the assembled model lives in
Studio. Save the Studio place to retain that placement.

Verification: visually inspected in Blender and Roblox. Studio checks confirmed
14 anchored mesh parts, one collider, no scripts, 16-stud height, and bottom Y=17.
Manual check: enter Play, walk around the lobby tree, and check trunk collision.
Gameplay playtesting was not run for this decorative addition.

Blender MCP 1.9.1 is installed in `.tools/blender-mcp-env` and registered globally
as `blender` in Codex. The Blender add-on is enabled and serves localhost:9876.
The connection was tested with MCP initialization and successful scene-read and
modeling tool calls. This task used a local MCP client because its initial tool
list did not include the newly registered server. Restart Codex if Blender tools
do not appear in subsequent tasks. Keep this tools folder while using that config.

Setup references: [Blender MCP](https://github.com/ahujasid/blender-mcp) and
[Codex MCP configuration](https://developers.openai.com/codex/mcp/).
