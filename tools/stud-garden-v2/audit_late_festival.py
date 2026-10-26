"""Screen later festival landings against all subsequent nonadjacent landings."""
import argparse
import json
import math
from pathlib import Path

from audit_offline import prepare, connect
from audit_phase2_geometry import inset, separation


def run(data):
    prefix = 'Obstacles.G5_HarvestFestival.'
    stages = [
        ('BasketTable',),
        ('BasketFloor', 'BasketDisplayStand'),
        ('LastTrowel',),
        ('FinalRoot',),
        ('FinishRunoff', 'HarvestFinish'),
    ]
    surfaces = []
    for names in stages:
        surfaces.append([p for p in data['parts'] if p['collide']
                         and any(p['path'].startswith(prefix+n+'.') for n in names)
                         and p['hi'][1] > 2.4])
    rows = []
    for i, starts in enumerate(surfaces):
        for j in range(i+2, len(stages)):
            candidates = []
            contact_envelopes = []
            for a in starts:
                for b in surfaces[j]:
                    rise=float(b['hi'][1]-a['hi'][1])
                    if rise>7.2:
                        continue
                    velocity=math.sqrt(2*196.2*7.2)
                    reach=16*(velocity+math.sqrt(velocity**2-2*196.2*rise))/196.2
                    edge=separation(a['poly'],b['poly'])['distance']
                    contact_envelopes.append({'fromPart':a['path'],'toPart':b['path'],'rise':rise,
                                              'edgeGap':edge,'idealRange':reach,'margin':reach-max(0,edge-1.3)})
                    if inset(a['poly'],.65) and inset(b['poly'],.65):
                        result = connect([a], [b])
                        if result['margin'] is not None:
                            candidates.append({'fromPart':a['path'], 'toPart':b['path'], **result})
            best = max(candidates, key=lambda p:p['margin']) if candidates else None
            rows.append({'fromStage':stages[i], 'toStage':stages[j], 'checkedPairs':len(candidates),
                         'best':best, 'nonnegative':[p for p in candidates if p['margin'] >= 0],
                         'generousContactEnvelopeBest':max(contact_envelopes,key=lambda p:p['margin']) if contact_envelopes else None,
                         'generousContactEnvelopeNonnegative':[p for p in contact_envelopes if p['margin']>=0]})
    return {'candidate':data['candidate'], 'offline':True, 'checks':rows,
            'limits':'Each colliding part uses its projected wedge or box and maximum height. Includes basket rims, stand, tool supports and finish feet. Inset .65 checks full foot support. The separate generous contact envelope includes thin parts and subtracts1.3 from edge gap for partial foot contact at both ends. Curved/tilted surfaces are conservative bounds, not exact reachable standing surfaces. Normal speed16/jump7.2. These are bounded geometry screens, not native traversal proof.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('geometry', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    result = run(prepare(json.loads(args.geometry.read_text())))
    args.output.write_text(json.dumps(result, indent=2))
    print(json.dumps({'candidate':result['candidate'], 'checks':[
        {'from':x['fromStage'], 'to':x['toStage'], 'bestMargin':x['best']['margin'] if x['best'] else None,
         'nonnegative':len(x['nonnegative']), 'generousMargin':x['generousContactEnvelopeBest']['margin'] if x['generousContactEnvelopeBest'] else None,
         'generousNonnegative':len(x['generousContactEnvelopeNonnegative'])} for x in result['checks']]}))
