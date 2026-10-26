# Roblox MCP connections

## Installed on September 18, 2026

Both connections are enabled in `C:\Users\ivorr\.codex\config.toml`:

| Codex server name | Purpose |
| --- | --- |
| `Roblox_Studio` | Official Studio tools, everyday inspection, editing, asset generation, and playtesting. |
| `Roblox_Studio_Chrrxs` | Chrrxs tools for multiplayer sessions, runtime inspection, per-client logs, screenshots, and profiling. |

Chrrxs is pinned to **3.1.5**, installed in `.tools/robloxstudio-mcp/`. Its matching local Studio plugin is `%LOCALAPPDATA%\Roblox\Plugins\MCPPlugin.rbxmx`. Node 24.13.0 satisfies its Node 22+ requirement. The official MCP and Rojo plugin remain in place.

The bridge uses `127.0.0.1:58741` with HTTP authentication enabled. The local token is in `%USERPROFILE%\.robloxstudio-mcp\auth-token`; do not print it, commit it, or paste it into messages. Normal Codex connections use stdio and do not need a token in config.

## Starting after a reboot

1. Open Codex and this project. Codex starts the configured MCP processes when it loads their connections. If a newly added connection is missing, reload/restart Codex to refresh the tool list.
2. Open the intended Studio place. The Chrrxs plugin and server must have matching versions; fully reopen Studio after plugin installation or upgrades.
3. Confirm the Chrrxs plugin reports Connected and the official Studio MCP is enabled in Studio's Assistant settings.
4. In the startup task, check `Roblox_Studio.list_roblox_studios` and `Roblox_Studio_Chrrxs.get_connected_instances`. Match the place ID/name independently: the two servers use different instance IDs.
5. Run `./tools/start_rojo.ps1` for Rojo 7.7.1 on `localhost:34872` and confirm its matching Studio plugin is connected. Keep only the local Rojo plugin enabled; disable the Marketplace duplicate in Manage Plugins. An MCP connection does not replace Rojo.

Use the existing **Project Startup — Rojo & MCP** task for this sequence. Never claim the setup is fully ready from an HTTP health check alone; verify an actual Studio response through each connection.

## Switching between the connections

Both may remain enabled. Ask for "official MCP", "Chrrxs MCP", or let the agent choose the appropriate tools. No reinstall or manual connection toggle should be necessary after both have loaded.

- Use one task to control a given Studio window at a time. Coordinate before starting/stopping Play, changing cameras, or sending input. Two tasks may each own a different window; see "Two Studio windows for parallel agents" below.
- Before switching, finish any outstanding operation and re-read Studio's current state through the destination connection.
- Keep a multiplayer test under the connection that started it until the test ends.
- After a timed-out mutation, inspect state or Chrrxs request status before retrying through either connection. A timeout does not prove the change failed.
- Edit durable scripts in the repository and sync with Rojo. Studio-only changes are not automatically written back to source.

## Two Studio windows for parallel agents

Added October 27, 2026. Repository files are never the bottleneck: two agents in this folder can edit different files at once and Rojo pushes both sets of changes into Studio. The bottleneck is the single Studio window, which has one Play session, one camera and one set of screenshots. To let two agents playtest at the same time, give each one its own window and its own Rojo server.

| Lane | Rojo start | Port | Studio window |
| --- | --- | --- | --- |
| Primary | `./tools/start_rojo.ps1` | 34872 | The real place; the only window that saves or publishes |
| Second | `./tools/start_rojo_second.ps1` | 34873 | A disposable copy; close without saving |

Both scripts run the same `default.project.json` from this folder, so both windows receive every script change. `start_rojo.ps1` also accepts `-Port` directly; the wrapper only pins 34873 so the lanes stay predictable. Each port has its own supervisor lock and its own `supervisor-<port>.log` under `.tools/rojo-runtime/`.

Setup:

1. Start both Rojo scripts as background commands, each in its own terminal.
2. In the primary window, save a local copy of the place as `.rbxl` (for example `.tools/second-window.rbxl`; it is ignored by Git). Roblox's place-files page names the File menu entries **Save to File** and **Download a Copy**; there is no "Save to File As" in current Studio, and the Save to File entry is reported missing in some places, in which case use Download a Copy. A `rojo build` output is not a substitute: it lacks the Studio-authored lobby and courses. Open the copy in a second Studio window by double-clicking the file. Opening a copy means nothing done in the second window can overwrite the real place.
3. In the second window, open the Rojo plugin, change the port to `34873` and connect. The primary window stays on `34872`.
4. Each agent finds its own window before touching Studio: `Roblox_Studio.list_roblox_studios` and `Roblox_Studio_Chrrxs.get_connected_instances` list every open window. Match by place name and ID; the two servers use different instance IDs for the same window. Pass that instance ID on every call. Never pick a window by "the first one in the list".
5. Record the lane in the job's starter or task file (window, port, both instance IDs) so the agent does not drift to the other window.

Rules:

- One controller per window, not per machine. An agent may use Play, camera, input and edits in its own window while another agent does the same in the other window.
- Durable changes still go through repository files and Rojo. Studio-side edits in the second window (terrain, placed models, properties) are lost when it closes, so the second window is for testing code-built courses and features, not for scene authoring.
- Only the primary window saves or publishes. The second window is closed with Don't Save.
- Blender is still a single shared tool: one controller at a time across all sessions.
- Shared docs (`docs/TASKS.md`, `docs/DECISIONS.md`, `docs/BUGS.md`, `docs/PLAYTEST_NOTES.md`) are the usual file collision. Give each agent its own task folder for working notes, and let one agent or the owner merge into the shared docs.

### Research notes, October 27, 2026

- **Official Studio MCP** supports several open Studio windows from one client. Since Roblox's August 19, 2026 update every tool call carries a `studio_id`; `set_active_studio` is gone, and `list_roblox_studios` returns name, instance ID and place ID so two windows with the same name can be told apart. Edit-mode tools fail in a window while that window is in Play, which is per window and does not affect the other one.
- **Chrrxs MCP** accepts several open places on one bridge; `get_connected_instances` lists them and `instance_id` picks one. Its plugin can silently drop its registration (issue 95); if a window is missing from the list, Disconnect and Connect the Chrrxs plugin in that window.
- **Rojo's sync lock is per place, not per server.** The plugin creates `ServerStorage > __Rojo_SessionLock` only inside Team Create and refuses to connect when another collaborator holds it, even to a different port. Outside Team Create (a local copy) there is no lock, so the two-port setup above works. Inside Team Create only one window can run Rojo; the other receives scripts through Team Create replication instead.
- **Team Create with one account in two windows** is unverified. DevForum reports from 2020 describe the second window fighting the first for the session; Roblox marked that ticket resolved in 2021 but did not say the case is supported. If it works, a Team Create variant would be: window 1 on Rojo 34872, window 2 with no Rojo, scripts arriving through Team Create, and both windows autosaving to the real place, which removes the "disposable copy" safety net. Test it before adopting it.

Verified on October 27, 2026: `start_rojo_second.ps1` served this project on 34873 alongside the primary on 34872, with its own lock and logs, and stopped cleanly. Not yet verified: a second Studio window connected to 34873, both MCP connections listing two windows, and concurrent Play. The setup above matches each server's multi-instance tools, but the first run should be treated as a trial. If one connection only ever lists one window, note it here.

## Verification and current limitations

Installation, matching-plugin deployment, both enabled Codex registrations, the Chrrxs initialization handshake, all 48 advertised tool definitions, and the authenticated local bridge passed. A disposable baseplate connected with matching plugin/server 3.1.5. A read-only Luau query and starting solo Play passed. The test was returned to Edit and verified not running.

The user authorized Studio repair. Roblox's signed installer reported success for `version-574ecee7ee2b4e60`; the executable's Roblox signature and nonempty `AppSettings.xml` were verified. These limitations remain:

- Chrrxs automatic launch rejects a zero-byte `.crdownload` marker even after the installer reports success. Do not delete the marker to force discovery.
- Supplying the verified executable to `manage_instance` reaches a separate Windows helper error: `Invalid Studio test worker job name`. Opening the disposable place with Studio's normal executable succeeded. Prefer normal Studio launch until this upstream helper is fixed.
- `solo_playtest` start passed, but stop reported a teardown acknowledgement failure. Executing `game:GetService("RunService"):Stop()` through Chrrxs's Edit context succeeded; a subsequent query confirmed Edit mode and the runtime peers disappeared. For real project tests, coordinate ownership and inspect state before any fallback; this was a blank disposable place.
- Follow-up verification: the official MCP subsequently discovered the same disposable baseplate as Chrrxs. Read-only queries through both returned the identical place name, place ID 0, and running=false. Both connections can coexist and sequential reads through either worked; no additional Studio toggle was needed at that point. This verifies the disposable session, not the main project or concurrent playtest control.
- The current Codex task has not loaded the new native Chrrxs tool namespace. Verification used its authenticated local bridge and a separate stdio MCP client. Reload Codex to load the registered connection.

Gameplay, multiplayer, screenshot, and profiler behavior remain unverified. Do not describe every advertised tool or seamless switching as tested.

The separately installed npm Codex CLI could not parse the desktop app's current `features` settings. Registration succeeded with the desktop app's bundled `codex.exe`; no existing feature settings were changed.

## Maintenance

The installation is pinned so server and plugin versions remain consistent. Update them together deliberately. A timestamped `config.toml.before-chrrxs-*.bak` backup exists beside the Codex configuration.

To restore the pinned package and plugin from this project directory:

```powershell
& 'C:\Program Files\nodejs\npm.cmd' install --prefix '.tools\robloxstudio-mcp' --save-exact --ignore-scripts --no-fund --no-audit '@chrrxs/robloxstudio-mcp@3.1.5'
& 'C:\Program Files\nodejs\node.exe' '.tools\robloxstudio-mcp\node_modules\@chrrxs\robloxstudio-mcp\dist\index.js' --install-bundled-plugin
```

References: [Chrrxs setup](https://github.com/Chrrxs/robloxstudio-mcp), [bridge configuration](https://github.com/Chrrxs/robloxstudio-mcp/blob/main/docs/configuration.md), [Codex MCP configuration](https://developers.openai.com/codex/mcp).
