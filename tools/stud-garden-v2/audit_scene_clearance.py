"""Conservative whole-scene overhead and scenery-contact screen from offline solids."""
import argparse
import itertools
import json
from pathlib import Path

from audit_offline import prepare, groups, surface, connect
from audit_phase2_geometry import hull, inset, intersection, area, separation


def run(data):
    supports=groups(data)
    supports={k:v for k,v in supports.items() if k!='H2_Fruit' and not any(x in k for x in ('PlantedContext','SeedShopLandmark','FestivalLandmark','RaccoonBank','RaccoonPerch','TippedFruitCrate'))}
    overhead=[];wall_mounted=[]
    for name,parts in supports.items():
        foot,y=surface(parts)
        if y<2.4: continue
        foot=inset(foot,.65)
        if not foot: continue
        body=hull([(x+dx,z+dz) for x,z in foot for dx,dz in itertools.product((-.85,.85),repeat=2)])
        for p in data['parts']:
            if p['transparency']>=.99 or p['path'].startswith(name+'.') or p['lo'][1]<=y+5.3 or p['lo'][1]>=y+12.5: continue
            region=intersection(body,p['poly']);overlap=area(region)
            if overlap>.04:
                row={'support':name,'part':p['path'],'visible':True,'collide':p['collide'],'clearance':float(p['lo'][1]-y),'overlapArea':overlap}
                walls=[q['path'] for q in data['parts'] if q['collide'] and q['lo'][1]<=y+.5 and q['hi'][1]>=y+5.3 and area(intersection(region,q['poly']))>=overlap-.005]
                if walls: wall_mounted.append(dict(row,standingWall=walls))
                else: overhead.append(row)
    stalls=[]
    for prefix,route in [('Obstacles.G1_SeedShop.SeedShopLandmark',['OpeningCart_1','OpeningCart_2','CommonPottingDeck']),('Obstacles.G5_HarvestFestival.FestivalLandmark',['HarvestFork','BasketTable','BasketFloor','LongHarvestWagon'])]:
        a=[p for p in data['parts'] if p['path'].startswith(prefix+'.') and p['transparency']<.99]
        b=[p for p in data['parts'] if any('.'+name+'.' in p['path'] for name in route) and p['transparency']<.99]
        for p,q in itertools.product(a,b):
            if min(p['hi'][1],q['hi'][1])-max(p['lo'][1],q['lo'][1])>.02 and area(intersection(p['poly'],q['poly']))>.02:
                stalls.append({'stall':p['path'],'route':q['path']})
    scenery=[p for p in data['parts'] if p['collide'] and p['hi'][1]>=2.4 and any(x in p['path'] for x in ('LowerVineLandmark','CandyBlossom_','PlantedContext'))]
    scenery_links=[]
    route_names=('GroveRoot_','EntryRoot','ForkRoot','HarvestRoot','VineRefuge','OpeningLeaf_','BroadTurnLeaf_','ExpertTendril_','ExitLeaf_','VineChoice','VineMerge','FestivalRefuge','BambooWest','BambooTurn','BambooSouth','BambooReturn','BambooNorth','Stake_','MergeRefuge')
    relevant={k:v for k,v in supports.items() if any(k.split('.')[-1].startswith(x) for x in route_names)}
    for p in scenery:
        links=[]
        for name,parts in relevant.items():
            a=connect(parts,[p]);b=connect([p],parts)
            if a['margin'] is not None and a['margin']>=0:
                links.append({'route':name,'toSceneryMargin':a['margin'],'fromSceneryMargin':b['margin']})
        if links: scenery_links.append({'part':p['path'],'top':float(p['hi'][1]),'links':links})
    return {'candidate':data['candidate'],'offline':True,'overheadCandidates':overhead,'wallMountedDecoration':wall_mounted,'stallOverlapCandidates':stalls,'sceneryConnectionCandidates':scenery_links,
            'limits':'Conservative transformed-box and wedge geometry. Mesh visuals use their bounds. Support unions use a convex outline; tilted and curved scenery is bounded by its full top extent. Candidates require shape/approach review, not automatic failure. No controller, moving hazard, collision-response, crowd or timing proof.'}


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('input',type=Path);parser.add_argument('output',type=Path);args=parser.parse_args()
    result=run(prepare(json.loads(args.input.read_text())));args.output.write_text(json.dumps(result,indent=2))
    print(json.dumps({'candidate':result['candidate'],'overheadCandidates':result['overheadCandidates'],'stallOverlapCandidates':result['stallOverlapCandidates'],'accessibleSceneryCandidates':result['sceneryConnectionCandidates']},indent=2))
