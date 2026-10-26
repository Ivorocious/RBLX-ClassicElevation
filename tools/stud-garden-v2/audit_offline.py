"""Geometry screens for an isolated course build; no Roblox physics is simulated."""
import argparse
import itertools
import json
import math
from pathlib import Path

import numpy as np

from audit_phase2_geometry import hull, intersection, area, inset, separation

BOX = np.array(list(itertools.product((-1, 1), repeat=3)))
WEDGE = np.array([(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)])


def vertices(part):
    cf = part['cf']
    corners = WEDGE if part['class'] == 'WedgePart' else BOX
    return (corners*np.array(part['size'])/2)@np.array(cf[3:]).reshape(3,3).T + np.array(cf[:3])-np.array([9200,80,3500])


def prepare(data):
    for p in data['parts']:
        p['vertices'] = vertices(p)
        p['poly'] = hull(p['vertices'][:,[0,2]])
        p['lo'], p['hi'] = p['vertices'].min(axis=0), p['vertices'].max(axis=0)
    return data


def surface(parts):
    return hull([v for p in parts for v in p['poly']]), max(p['hi'][1] for p in parts)


def connect(a, b):
    ap, ay = surface(a)
    bp, by = surface(b)
    feet = separation(inset(ap,.65), inset(bp,.65))['distance']
    rise = float(by-ay)
    velocity = math.sqrt(2*196.2*7.2)
    reach = 16*(velocity+math.sqrt(max(0,velocity**2-2*196.2*rise)))/196.2 if rise<=7.2 else 0
    return {'edgeGap': separation(ap,bp)['distance'], 'footCenterGap':feet, 'rise':rise,
            'idealRange':reach, 'margin':reach-feet if feet is not None and rise<=7.2 else None}


def groups(data):
    result = {}
    for m in data['models']:
        name = m['path']
        if not m.get('family') and '.Stake_' not in name:
            continue
        parts = [p for p in data['parts'] if p['path'].startswith(name+'.') and p['collide'] and p['role'] in ('Walk','Refuge')]
        if any(p['name'].startswith('RootCrownFacet') for p in parts):
            parts = [p for p in parts if p['name'].startswith('RootCrownFacet')]
        if parts:
            result[name] = parts
    return result


def run(data):
    g = groups(data)
    crop = 'Obstacles.G2_CropGarden.PlayableObjects.'
    grove = 'Obstacles.G3_CandyGrove.'
    vine = 'Obstacles.G4_LowerVine.'
    routes = {
        'crop_main':['H1_Sprinkler.DryExitAndChoice']+[crop+x for x in ('BambooWest','BambooTurn','BambooSouth','BambooReturn','BambooNorth','MergeRefuge')],
        'crop_expert':[crop+'BambooWest']+[crop+f'ExpertStakes.Stake_{i}' for i in range(1,5)]+[crop+'MergeRefuge'],
        'grove_entry':['Obstacles.G2_ToolGardenExit.GroveRefuge']+[grove+x for x in ('EntryRoot','ForkRoot','HarvestRoot')]+['H2_Fruit.EntryRefuge'],
        'grove_roots':['H2_Fruit.ExitRefuge']+[grove+f'GroveRoot_{i}' for i in range(1,9)]+[grove+'VineRefuge'],
        'vine_entry':[grove+'VineRefuge']+[vine+f'OpeningLeaf_{i}' for i in range(1,5)]+[vine+'VineChoice'],
        'vine_main':[vine+'VineChoice']+[vine+f'BroadTurnLeaf_{i}' for i in range(1,7)]+[vine+'VineMerge'],
        'vine_expert':[vine+'VineChoice']+[vine+f'ExpertTendril_{i}' for i in range(1,6)]+[vine+'VineMerge'],
        'vine_exit':[vine+'VineMerge',vine+'ExitLeaf_1',vine+'ExitLeaf_2',vine+'FestivalRefuge']
    }
    measured = {name:[dict(a=a,b=b,**connect(g[a],g[b])) for a,b in zip(names,names[1:])] for name,names in routes.items()}
    stations=[]
    for cp in data['checkpoints']:
        marker=next(p for p in data['parts'] if p['path']=='Checkpoints.'+cp['name'])
        floor=marker['cf'][1]-80-3
        possible=[p for p in data['parts'] if p['transparency']<.99 and p['hi'][1]>floor+.25 and p['lo'][1]<floor+13 and area(intersection(marker['poly'],p['poly']))>.02]
        cf=cp['spawn']; rot=np.array(cf[3:]).reshape(3,3)
        center=np.array(cf[:3])-[9200,85,3500]
        across,along=cp['area']
        cols,rows=max(1,int((across-3)//4.5)+1),max(1,int((along-3)//4.5)+1)
        slots=[]
        for z in range(rows):
            for x in range(cols):
                p=center+rot@np.array([(x-(cols-1)/2)*4.5,0,(z-(rows-1)/2)*4.5])
                feet=hull([(p[0]+dx,p[2]+dz) for dx,dz in itertools.product((-.75,.75),repeat=2)])
                support_area=sum(area(intersection(feet,q['poly'])) for q in data['parts'] if q['collide'] and abs(q['hi'][1]-p[1])<.35)
                body=hull([(p[0]+dx,p[2]+dz) for dx,dz in itertools.product((-1.5,1.5),repeat=2)])
                hits=[q['path'] for q in possible if q['collide'] and q['lo'][1]<p[1]+5.3 and area(intersection(body,q['poly']))>.01]
                slots.append({'supported':support_area>2.1,'obstructions':hits})
        stations.append({'name':cp['name'],'slots':len(slots),'unsupported':sum(not s['supported'] for s in slots),'blockedSlots':sum(bool(s['obstructions']) for s in slots),
                         'wholePlotVisibleOrSolidCandidates':[{'path':p['path'],'collide':p['collide'],'bottom':float(p['lo'][1]),'top':float(p['hi'][1])} for p in possible]})
    cross={}
    crop_others=['H1_Sprinkler.DryWait','H1_Sprinkler.DryExitAndChoice']+routes['crop_main'][1:]
    crop_stakes=[crop+f'ExpertStakes.Stake_{i}' for i in range(1,5)]
    pairs=[(a,b) for stake in crop_stakes for other in crop_others for a,b in ((stake,other),(other,stake))]
    pairs += [(a,b) for i,a in enumerate(crop_stakes) for j,b in enumerate(crop_stakes) if abs(i-j)>1]
    cross['crop']=[dict(a=a,b=b,**connect(g[a],g[b])) for a,b in pairs]
    pairs=[(a,b) for a in routes['vine_expert'][1:-1] for b in routes['vine_main'][1:-1]]
    pairs += [(b,a) for a,b in pairs]
    pairs += [(a,b) for route in ('vine_expert','vine_main') for i,a in enumerate(routes[route]) for j,b in enumerate(routes[route]) if j>i+1]
    cross['vine']=[dict(a=a,b=b,**connect(g[a],g[b])) for a,b in pairs]
    cp9=vine+'FestivalRefuge'
    late=[name for name in g if name.startswith('Obstacles.G5_HarvestFestival.') and any(x in name for x in ('Basket','LastTrowel','FinishRunoff','FinalRoot','HarvestFork'))]
    cross['festival']=[dict(a=cp9,b=b,**connect(g[cp9],g[b])) for b in late]
    tool_overlaps=[]
    for name,parts in g.items():
        if not any(x in name for x in ('Trowel','ForkCrossing','StoredFork','HarvestFork')): continue
        for a,b in itertools.combinations(parts,2):
            if a['class']!='Part' or b['class']!='Part' or a['shape']!='Block' or b['shape']!='Block': continue
            if abs(a['hi'][1]-b['hi'][1])<.001 and area(intersection(a['poly'],b['poly']))>.015:
                tool_overlaps.append({'group':name,'a':a['name'],'b':b['name']})
    return {'candidate':data['candidate'],'offline':True,'parts':len(data['parts']),'routes':measured,'checkpoints':stations,'crossConnections':cross,'toolBoxTopOverlaps':tool_overlaps,
            'limits':'Offline geometry only. Curved parts use bounding boxes; compound support uses a convex outline, so handle holes must be reviewed separately. Jump model speed16/jump7.2/gravity196.2 ignores run-up, steering, collision and controller behavior. Checkpoint plots screen all visible parts to13studs; slots screen3x5.3 bodies. These are not native traversal, crowd or timing results.'}


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('input',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();data=prepare(json.loads(args.input.read_text())); result=run(data)
    args.output.write_text(json.dumps(result,indent=2))
    print(json.dumps({'candidate':result['candidate'],'parts':result['parts'],'routeMinMargins':{k:round(min(p['margin'] or 0 for p in v),3) for k,v in result['routes'].items()},'checkpoints':result['checkpoints'],'possibleCrossConnections':{k:[dict(a=p['a'].split('.')[-1],b=p['b'].split('.')[-1],margin=round(p['margin'],3)) for p in v if p['margin'] is not None and p['margin']>=0] for k,v in result['crossConnections'].items()},'toolBoxTopOverlaps':result['toolBoxTopOverlaps']},indent=2))
