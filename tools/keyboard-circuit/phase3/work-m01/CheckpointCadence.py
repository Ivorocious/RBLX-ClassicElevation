from pathlib import Path
import json

root = Path(__file__).resolve().parents[4]
folder = root / 'docs/artifacts/keyboard-circuit/phase3'
runs = {}
for route in ('normal', 'expert'):
    data = json.loads((folder / f'P3-M01-{route}-two-lap-01.json').read_text())
    origin = data['continuousServerStartedAt']
    events = [{'checkpoint': 'F00', 'lap': 1, 'elapsed': 0}]
    events += [{'checkpoint': row['checkpoint'], 'lap': row['lap'], 'elapsed': row['at'] - origin} for row in data['midpointReceipts']]
    events += [{'checkpoint': row['id'], 'lap': row['lap'], 'elapsed': row['after']['at'] - origin} for row in data['checkpoints'] if row['id'] != 'F01']
    events.sort(key=lambda row: row['elapsed'])
    gaps = [{'from': a['checkpoint'], 'to': b['checkpoint'], 'lap': b['lap'], 'seconds': b['elapsed']-a['elapsed']} for a,b in zip(events,events[1:])]
    assert len(events) == 17 and all(row['seconds'] > 0 for row in gaps)
    runs[route] = {'events': events, 'gaps': gaps, 'maximumCleanSecondsBetweenSaves': max(row['seconds'] for row in gaps)}
result = {'candidate': data['candidate'], 'revision': data['prototypeRevision'], 'passed': True, 'runs': runs,
          'boundary': 'Observed clean automated intervals between accepted permanent saves, including next-lap F00. They estimate replayed route segments, not human retry cost, crowd capacity or typical-player duration.'}
(folder / 'P3-M01-checkpoint-cadence-01.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({route: rows['maximumCleanSecondsBetweenSaves'] for route,rows in runs.items()}))
