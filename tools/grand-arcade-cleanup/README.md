# Grand Arcade cleanup evidence

One-time tools for the owner-requested October 6, 2026 cleanup. They are outside Rojo and do not run in the game.

- `archive_sources.py` archived and compared the six original sources.
- `BackupBefore.luau` created the original binary. Its initial comparison identified three omitted empty engine Status containers.
- `Fingerprint.luau` and `VerifyBackup.luau` record the final comparison with those three exact exclusions and all cross-root recovery links preserved.
- `Apply.luau` contains the guarded, already-applied cleanup.
- `StartupQA.luau` ran as a temporary ordinary server Script to observe actual service startup and display rendering.
- `ArchiveFinal.luau` saved and reopened the cleaned stage and walkway, with no exclusions.

Do not rerun the one-time cleanup against a changed scene. Use the [recovery guide](../../archives/grand-arcade/cleanup-20261006/README.md) and [completed report](../../docs/artifacts/grand-arcade-cleanup-20261006/REPORT.md).
