# Blender to Roblox without computer use

## Status

Live upload, Studio MCP insertion and visual verification passed on 2026-09-06,
without computer use. Seven offline tests also pass. The existing Blender-exported
FBX was uploaded as asset `105751216627858`; this test did not rebuild the geometry.

Studio inspection confirmed user/creator `86069177` and place `85558151074819`.
The existing `Workspace.StylizedOak` is unchanged. The verified API-imported copy is
`Workspace.StylizedOakApiTest`, with bottom center `(4, 17, -140)`. It has 14 anchored
meshes, matching colors, height 16 studs and trunk-only collision. Studio MCP's
screen capture confirmed the rendered result. No place save/publish or gameplay
playtest was performed. Save the Studio place to retain the comparison tree.

The key reader trims the encrypted file's trailing newline and prefers the current
`pwsh.exe` runtime to avoid Windows PowerShell module-loading failures. Run the
uploader under the same Windows user as key setup; the restricted Codex sandbox
could not decrypt the user-bound key, while the approved user-context run succeeded.

## One-time key setup

1. Open [Roblox API Keys](https://create.roblox.com/dashboard/credentials).
2. Create `Blender asset uploads` with **Assets: Read and Write** permissions.
   Use the minimum resource access the dashboard offers for your own assets.
3. In a local PowerShell window, run:

```powershell
& 'C:\Users\ivorr\RobloxDevelopment\ProjectClassicElevation\tools\set_roblox_upload_key.ps1'
```

Paste the key at the hidden prompt. The script saves it using Windows user
encryption in `.tools/roblox-upload-key.dpapi`, which Git ignores. It does not
print the key or put it in a command argument. Do not paste the key into chat.
Return to this task and say `key saved`.

The uploader decrypts it under the same Windows user. It also accepts the process
environment variable `ROBLOX_OPEN_CLOUD_API_KEY` if already supplied securely.
Do not invoke the setup script's internal `-ReadKey` switch manually: it is for
the uploader to capture the decrypted value privately.

## Agent workflow

1. Build/export the FBX to this repository using the [Blender build guidance](BLENDER_BUILD_WORKFLOW.md). Prefer a saved Python builder in a separate Blender process for substantial/repeated work; use connected Blender MCP for live inspection or targeted edits when useful. Preserve manual changes and check the candidate files before uploading.
2. Validate the upload locally from the repository root:

```powershell
python tools/upload_roblox_model.py assets/trees/StylizedOak.fbx --user-id 86069177 --name StylizedOakApiTest --receipt .tools/uploads/stylized-oak-api.json
```

3. Add `--upload` to perform the authorized test upload. The script sends to the
   official Roblox Assets API and checks status every three seconds for about
   60 seconds. Requests have a 45-second network timeout. No browser or Studio dialog is used.
4. If status is `pending`, rerun the same command to resume checking. If status
   is `complete`, read the `assetId` from the receipt.
5. Reinspect the connected Studio session. Insert that asset ID through Studio
   MCP's `insert_asset` as `StylizedOakApiTest`, initially under `ServerStorage`
   for inspection. The upload is a Model/package, not a single Mesh asset.
6. Inspect the imported hierarchy, geometry and colors. For this test, run
   `assets/trees/finish_api_test.luau` after confirming its names and structure.
   Check scale, anchoring, colors and collision; use Studio MCP screenshots when
   displaying it. Keep the existing lobby tree intact. Do not publish the place.

Receipts bind the file hash, owner and metadata to an upload operation. A completed
receipt is reused without uploading again. An uncertain submission stops rather
than retrying the POST: inspect Roblox before intentionally starting a new receipt.
Successful upload processing is not proof of moderation approval or Studio access;
insertion and visual verification are separate checks.

## Checks

```powershell
python -m unittest discover -s tests -p test_roblox_upload.py -v
```

Tests cover multipart content, repeat protection, uncertain submission, resuming
pending operations, changed input, credential destination restrictions and server
processing failures. They mock network responses; they are not live API evidence.

References: [Assets API guide](https://create.roblox.com/docs/cloud/guides/usage-assets)
and [API key setup](https://create.roblox.com/docs/cloud/auth/api-keys).
