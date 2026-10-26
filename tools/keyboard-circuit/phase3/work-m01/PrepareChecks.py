from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OLD = ROOT / 'tools/keyboard-circuit/phase2/work-i09-03'
NEW = Path(__file__).resolve().parent
text = (OLD / 'OfflineGeometry.luau').read_text(encoding='utf-8')
text = text.replace('phase2/work-i09-03/', 'phase3/work-m01/').replace('sources.Course).Build', 'sources.Map).Build')
text = text.replace('roblox.Vector3.new(22500, 330, -1600)', 'roblox.Vector3.new(2222, 330, -1158)')
text = text.replace('I09-preview.rbxm', 'M01-preview.rbxm').replace('phase2/P2-I09-offline-geometry-03.json', 'phase3/P3-M01-offline-geometry-01.json')
text = text.replace('report.normalEdges, report.branchCount', 'report.artParts, report.artCaps = 0, 0\nfor _, part in root.MapEnvironment:GetDescendants() do\n if part:IsA("BasePart") then\n  report.artParts += 1\n  assert(not part.CanCollide and not part.CanTouch and not part.CanQuery and not part:GetAttribute("Pressable"))\n  if part:IsA("MeshPart") then report.artCaps += 1 end\n end\nend\nreport.normalEdges, report.branchCount')
(NEW / 'OfflineGeometry.luau').write_text(text, encoding='utf-8')
print('Prepared scoped map build and artwork physics check.')
