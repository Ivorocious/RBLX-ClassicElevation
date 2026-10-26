# draw.io MCP

Installed official `@drawio/mcp` version 1.5.0 under `.tools/drawio-mcp`.
The global `C:\Users\ivorr\.codex\config.toml` entry is named `drawio` and runs
the package directly with `C:\Program Files\nodejs\node.exe`.
The connection depends on this project folder staying in its current location.

The optional routing-cache postinstall crashed on this Windows machine. Installing
with `--ignore-scripts` worked; the vendor explicitly permits that. Normal diagram
tools were verified without optional automatic connector routing.

The installed Codex CLI cannot parse the existing `features.context_management`
table. Only the new MCP entry was appended; existing settings were preserved.
Existing tasks may need a reload before their tool lists include the server.

Verified on 2026-09-08: MCP initialization, seven advertised tools, reading the
local kit plan with `list_pages` and `get_page`, and generating an editor URL with
`open_drawio_xml`. The server's automatic browser-open message is not proof that
a browser window appeared; use its returned URL when necessary.

```powershell
& '.tools/blender-mcp-env/Scripts/python.exe' tools/check_drawio_mcp.py
```

Course planning should save editable `.drawio` files under `docs/artifacts`.
Use written dimensions as authority. Diagrams without dimensions are schematic.
Generate inspiration art only after the plan settles, aligned with that plan.

References: [official draw.io server](https://github.com/jgraph/drawio-mcp/tree/main/mcp-tool-server),
[Codex MCP configuration](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).
