from pathlib import Path
p=Path('assets/city_run/v3/build_stage2_installer.py')
s=p.read_text().replace('if node then\n  for _,p in node:GetDescendants() do','if node then\n  assert(not node:IsA("BasePart") or not node.CanCollide,"Protected collision root: "..path)\n  for _,p in node:GetDescendants() do')
s=s.replace('local removedParts=0','-- Validate the full replacement set before changing even the detached candidate.\nfor _,path in plan.replacePaths do assert(resolve(path),"Required source missing: "..path) end\nlocal removedParts=0')
p.write_text(s)
