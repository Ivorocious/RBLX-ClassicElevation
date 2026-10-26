from pathlib import Path

root = Path(__file__).resolve().parents[4]
previous = root / 'tools/keyboard-circuit/phase3/work-m01'
current = Path(__file__).resolve().parent
for name in ('CompileFixtures.luau', 'OfflineGeometry.luau', 'MotionClearance.luau', 'VisibilityAudit.luau', 'NativeRecovery.server.luau', 'ExportScene.server.luau', 'Setup.client.luau', 'FocusedHeldPress.client.luau', 'FocusedDevControl.client.luau', 'Driver.client.luau'):
    content = (previous / name).read_text(encoding='utf-8')
    content = content.replace('work-m01', 'work-m02').replace('M01', 'M02')
    if name == 'NativeRecovery.server.luau':
        content = content.replace('assert(#preserved == 13)', 'assert(#preserved == 14)')
    (current / name).write_text(content, encoding='utf-8')

brief = root / 'docs/artifacts/keyboard-circuit/COURSE_BRIEF.md'
lines = brief.read_text(encoding='utf-8').splitlines()
changes = {
    '- **Status:**': '- **Status:** M02 is being prepared for the owner\'s latest visual corrections: ASCII progress HUD, disjoint bracket-key grids, rebuilt signs and checkpoint sites, larger floating hardware scenery, and stronger warnings driven by the existing mechanism states. M01 and all its frozen evidence remain preserved; its old scores do not apply to M02.',
    '- **Creator chat:**': '- **Creator chat:** `01a1129b-7643-7cb2-a70a-6b84c8c9777f`, local. The owner now explicitly authorizes parallel implementation helpers to shorten the work. Three helpers own separate files; the lead integrates and verifies.',
    '- **Reviewers:**': '- **Reviewers:** the owner now requests three independent reviewers. Each final M02 judgment must score at least 8.5/10 with zero blockers on the same frozen candidate. No average or inherited score substitutes for an individual pass.',
    '- **Review assignments:**': '- **Review assignments:** three overall reviews emphasize (1) visual quality, signs and checkpoint sites, (2) warnings, route experience and visibility, and (3) engineering, preservation and performance. Helpers implement; reviewers judge independently.',
    '- **Permissions:**': '- **Permissions:** scoped Phase 3 artwork/source, parallel helpers, isolated preparation, relevant native tests, recoverable exports/installation and archival of superseded Keyboard Circuit candidates are authorized. Preserve unrelated maps, palette, accepted gameplay/assets and owner placement. Computer control, whole-place save, publication, stored-player-data, economy, monetization and security changes remain outside scope.',
    '- **Next action:**': '- **Next action:** finish the M02 visual corrections, verify the bracket geometry and HUD in native Play plus scenery/motion/recovery clearances, and obtain three fresh reviews before returning the testable map to the owner.',
}
for index, line in enumerate(lines):
    for prefix, replacement in changes.items():
        if line.startswith(prefix):
            lines[index] = replacement
brief.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print('M02 focused checks prepared; current brief updated.')
