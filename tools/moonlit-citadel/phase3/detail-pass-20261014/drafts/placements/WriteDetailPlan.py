"""Write the measured additive plan and its real occupied components for native staging."""
import hashlib
import itertools
import json
from collections import Counter
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
source=HERE/'detail-placement-plan.json'
report=json.loads(source.read_text())
assert report['supportVerified'] and len(report['units'])==78
metadata_path=ROOT/report['metadataPath']
metadata=json.loads(metadata_path.read_text())['assets']
assert hashlib.sha256(metadata_path.read_bytes()).hexdigest()==report['metadataSHA256']


def num(value):
    return format(value,'.12g')


def vector(values):
    return 'v('+','.join(map(num,values))+')'


lines=['--!nonstrict','local DetailPlan={}','local v=Vector3.new','local Units={']
rows=[]
for unit in report['units']:
    lines.append(' {district='+json.dumps(unit['district'])+',name='+json.dumps(unit['name'])+',asset='+json.dumps(unit['asset'])+
                 ',library="DT01",localCF=CFrame.new('+','.join(map(num,unit['localCF']))+'),scale='+vector(unit['scale'])+
                 ',materialRole="AdditiveDetail",supportUnit='+json.dumps(unit['support']['unit'])+'},')
    cf,scale=unit['localCF'],unit['scale']
    for index,box in enumerate(metadata[unit['asset']]['occupiedBoxes'],1):
        centre=[(box['low'][a]+box['high'][a])*.5*scale[a] for a in range(3)]
        size=[(box['high'][a]-box['low'][a])*scale[a] for a in range(3)]
        translated=[cf[a]+sum(cf[3+a*3+b]*centre[b]for b in range(3))for a in range(3)]
        rows.append({'path':unit['district']+'/'+unit['name']+'/Occupied'+str(index),'unit':unit['name'],
                     'district':unit['district'],'frame':translated+cf[3:],'size':size,
                     'anchored':True,'collide':False,'query':False,'touch':False,'transparency':0})
lines += ['}','local Costs={']
for key,meta in sorted(metadata.items()):
    lines.append(' ['+json.dumps(key)+']={parts='+str(meta['meshParts'])+',triangles='+str(meta['triangles'])+'},')
lines += ['}','function DetailPlan.Get()',' local units={}',' local counts={units=0,meshParts=0,triangles=0,artCanCollide=false,artCanQuery=false,artCanTouch=false}',
          ' for _,unit in Units do','  local cost=assert(Costs[unit.asset])','  table.insert(units,table.clone(unit))',
          '  counts.units+=1;counts.meshParts+=cost.parts;counts.triangles+=cost.triangles',' end',' return units,counts','end','DetailPlan.AssetCosts=Costs','return DetailPlan','']
(HERE/'DetailPlan.luau').write_text('\n'.join(lines))
(HERE/'detail-occupied-rows.json').write_text(json.dumps({'metadataSHA256':report['metadataSHA256'],'planSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),'rows':rows},indent=2)+'\n')
counts=Counter(unit['asset']for unit in report['units'])
ledger={key:{'units':count,'meshParts':metadata[key]['meshParts']*count,'triangles':metadata[key]['triangles']*count}for key,count in counts.items()}
(HERE/'detail-cost-ledger.json').write_text(json.dumps({'counts':report['counts'],'combined':report['combined'],'architectureOwnUnits':254,'ledger':ledger,'occupiedRows':len(rows)},indent=2)+'\n')
print(json.dumps({'module':'DetailPlan.luau','units':len(report['units']),'occupiedRows':len(rows),'counts':report['counts']}))
