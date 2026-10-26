from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
NEW = Path(__file__).resolve().parent
old = (ROOT / 'tools/keyboard-circuit/phase2/work-i09-03/NativeRecovery.server.luau').read_text()
old = old.replace('KeyboardCircuit_P2_I09_Experience03','KeyboardCircuit_P3_M01_01').replace('KC_P2_I09_03','KC_P3_M01_01')
old = old.replace('KCP2I09ExperienceNativeRecovery03','KCP3M01NativeRecovery01').replace('KCOwnedPhase2Preparation','KCOwnedPhase3Preparation')
old = old.replace('require(fresh.Course).Build','require(fresh.Map).Build').replace('KCP2I09TwoLapNativeExport01','KCP3M01NativeExport01').replace('KCP2I09TwoLapRecoveryReceipt01','KCP3M01RecoveryReceipt01')
old = old.replace('assert(#preserved == 12)', 'assert(#preserved == 13)')
(NEW / 'NativeRecovery.server.luau').write_text(old)
print('Prepared native reopen and fresh-identity Map rebuild checks.')
