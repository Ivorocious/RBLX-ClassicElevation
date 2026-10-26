import sys, base64, pathlib
parts = []
for line in sys.stdin:
    if line.strip() == 'C18_END':
        break
    parts.append(line.strip())
name = sys.argv[1] if len(sys.argv) > 1 else 'original-before-optimization.rbxm'
assert pathlib.Path(name).name == name
p = pathlib.Path('docs/artifacts/city-run/c18') / name
p.parent.mkdir(parents=True, exist_ok=True)
p.write_bytes(base64.b64decode(''.join(parts)))
