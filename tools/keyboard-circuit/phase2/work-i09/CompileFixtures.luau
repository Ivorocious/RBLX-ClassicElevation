local fs, luau = require("@lune/fs"), require("@lune/luau")
local root = "tools/keyboard-circuit/phase2/work-i09/"
local files = {
 "Setup.client.luau", "Driver.client.luau", "Timing.client.luau", "Race.client.luau", "CreateCandidate.luau", "AlignCandidate.luau",
 "FocusedRecovery.client.luau", "FocusedBypass.client.luau",
 "FocusedHeldPress.client.luau", "FocusedDevControl.client.luau",
 "CheckRecoverySlots.server.luau", "NativeRecovery.server.luau", "FocusedDomino.client.luau", "FocusedExpert.client.luau", "NativeAudit.server.luau",
}
for _,name in files do luau.load(fs.readFile(root..name), {debugName=name}) end
print(#files.." scoped I09 build/traversal/focused-check files compile")
