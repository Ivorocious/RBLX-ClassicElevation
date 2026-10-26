"""Measure support edges and ideal jump ranges without claiming avatar traversal."""
import argparse
import json
import math
import sys
from pathlib import Path
import numpy as np

sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from audit_phase2_geometry import hull, inset, separation

BOX=np.array([(-.5,-.5,-.5),(.5,-.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(-.5,.5,-.5),(.5,.5,-.5),(-.5,.5,.5),(.5,.5,.5)])
WEDGE=BOX[[0,1,2,3,6,7]]
def vertices(p):
    cf=np.array(p['cf']); shape=p['shape']
    if p['class']=='WedgePart': v=WEDGE
    elif shape=='Cylinder':
        size=p['size']
        radius=min(size[1:])/2
        v=np.array([(x,radius*math.cos(i*math.tau/24),radius*math.sin(i*math.tau/24)) for x in (-size[0]/2,size[0]/2) for i in range(24)])
        return v@cf[3:].reshape(3,3).T+cf[:3]
    else: v=BOX
    return (v*np.array(p['size']))@cf[3:].reshape(3,3).T+cf[:3]

def group(data,prefix):
    parts=[p for p in data['parts'] if p['path'].startswith(prefix+'.') and p['collide'] and p['role'] in ('Walk','Refuge')]
    if '.Stake_' in prefix: parts=[p for p in parts if p['name']=='Cap']
    assert parts,prefix
    points=np.concatenate([vertices(p) for p in parts])
    return hull(points[:,[0,2]].tolist()),float(points[:,1].max())

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('geometry',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    data=json.loads(args.geometry.read_text())
    crop='Obstacles.G2_CropGarden.PlayableObjects.'
    vine='Obstacles.G4_LowerVine.'
    routes={
        'crop_main':['H1_Sprinkler.DryExitAndChoice']+[crop+n for n in ['BambooWest','BambooTurn','BambooSouth','BambooReturn','BambooNorth','MergeRefuge']],
        'crop_expert':[crop+'BambooWest']+[crop+f'ExpertStakes.Stake_{i}' for i in range(1,5)]+[crop+'MergeRefuge'],
        'vine_entry':['Obstacles.G3_CandyGrove.VineRefuge']+[vine+f'OpeningLeaf_{i}' for i in range(1,5)]+[vine+'VineChoice'],
        'vine_main':[vine+'VineChoice']+[vine+f'BroadTurnLeaf_{i}' for i in range(1,7)]+[vine+'VineMerge'],
        'vine_expert':[vine+'VineChoice']+[vine+f'ExpertTendril_{i}' for i in range(1,6)]+[vine+'VineMerge'],
        'vine_exit':[vine+n for n in ['VineMerge','ExitLeaf_1','ExitLeaf_2','FestivalRefuge']],
    }
    result={}
    for name,path in routes.items():
        pairs=[]
        for a,b in zip(path,path[1:]):
            pa,ya=group(data,a);pb,yb=group(data,b)
            edge=separation(pa,pb);feet=separation(inset(pa,.55),inset(pb,.55))
            rise=yb-ya;velocity=math.sqrt(2*196.2*7.2)
            reach=16*(velocity+math.sqrt(max(0,velocity**2-2*196.2*rise)))/196.2 if rise<=7.2 else 0
            pairs.append(dict(start=a,end=b,gap=edge['distance'],footGap=feet['distance'],rise=rise,idealRange=reach,margin=reach-feet['distance'] if feet['distance'] is not None else None,launch=feet['a'],landing=feet['b']))
        result[name]=pairs
    args.output.write_text(json.dumps({'candidate':data['attributes'].get('CandidateId'),'routes':result,'limits':'Flat support footprint with 0.55-stud inset. Ideal speed16/jump7.2/gravity196.2. No steering, body sweep, run-up, avatar, timing, hazard or multiplayer simulation.'},indent=2))
    print(json.dumps({name:[{k:round(p[k],2) if p[k] is not None else None for k in ['gap','footGap','rise','margin']} for p in pairs] for name,pairs in result.items()}))

if __name__=='__main__':main()
