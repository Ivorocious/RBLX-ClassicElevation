# Second Rojo lane for a second Studio window, so two agents can playtest at
# the same time. Serves the same project folder as start_rojo.ps1 on port 34873.
# See docs/ROBLOX_MCP_SETUP.md, "Two Studio windows for parallel agents".
param([ValidateRange(0, 20)][int]$MaxRestarts = 5)

& (Join-Path $PSScriptRoot 'start_rojo.ps1') -Port 34873 -MaxRestarts $MaxRestarts
