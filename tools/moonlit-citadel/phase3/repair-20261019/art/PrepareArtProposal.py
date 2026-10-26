"""Stage absolute art-only replacements without changing production source."""
import hashlib,json,math
from pathlib import Path

ROOT=Path.cwd()
HERE=Path(__file__).resolve().parent
SOURCE=ROOT/'docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/combined-plan54.json'
FRESH=ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/before/native-snapshot54.json'
plan=json.loads(SOURCE.read_text(encoding='utf8'))
old={row['name']:row for row in plan['units']}
edits={}
retired={name:'Remove duplicated small gallery overlay; original54 art and source are retained in recovery.' for name in (
    'GalleryHeraldry1','GalleryHeraldry2','GalleryOneShrub','GalleryTwoShrub','GalleryThreeShrub')}

def edit(name,point=None,scale=None,yaw=None,asset=None,library=None,reason=''):
    before=old[name]
    row=json.loads(json.dumps(before))
    if point is not None:row['localCF'][:3]=point
    if yaw is not None:
        c,s=math.cos(yaw),math.sin(yaw)
        row['localCF'][3:]=[c,0,s,0,1,0,-s,0,c]
    if scale is not None:row['scale']=scale
    if asset is not None:row['asset']=asset
    if library is not None:row['library']=library
    edits[name]={'before':before,'after':row,'reason':reason}

for index in range(1,4):
    edit('LanternWallBracket'+str(index),scale=[.55,.35,1],
         reason='Compact the decorative corbel above the pointed window while its arm retains the fixed accepted header pivot.')
edit('CrownWestJoinedScreen',point=[-31,146.6,-26.5],
     reason='Match the southern arcade spring/top level; retain open arches above the joined apron.')
edit('CrownSouthScreenFoot1',point=[-8,137.25,-10],scale=[36/25,12.35/24,.18],
     reason='Reuse the first foot as a continuous shallow apron rooted0.35 into the unchanged shell and ending below the accepted floor.')
for index,x in enumerate((-26,-8,10),2):
    edit('CrownSouthScreenFoot'+str(index),point=[x,137.25,-10],scale=[1.6/25,11.95/24,2.65/13],
         reason='Engaged exterior pilaster projects from the apron with no coplanar front face.')
edit('CrownWestScreenFoot1',point=[-31,137.25,-26.5],scale=[39/25,12.35/24,.18],yaw=-math.pi/2,
     reason='Reuse the first west foot as one joined apron at the same floor-relative level.')
for index,z in enumerate((-46,-26.5,-7),2):
    edit('CrownWestScreenFoot'+str(index),point=[-31,137.25,z],scale=[1.6/25,11.95/24,2.65/13],yaw=-math.pi/2,
         reason='Engaged west exterior pilaster; all upper viewing arches remain open.')
edit('CrownEmblemLowerPier',point=[-8,137.25,-10],scale=[6.8/25,18.35/24,2.6/13],
     reason='A narrow continuous central pier supports the fixed crest backplate instead of a broad disconnected wall slab.')
edit('CrownEmblemStoneMount',point=[-8,155.6,-9.4],scale=[8.4/25,5.6/24,1.8/13],
     reason='Trim the blank exterior backplate around the unchanged accepted crest and close its measured0.17stud backing gap.')

for band,cx,base in ((1,-36,54),(2,18,58),(3,72,62)):
    for suffix,side in (('-1',1),('1',-1)):
        x=cx+23*side
        name=f'Gallery{band}PlanterShelf{suffix}'
        edit(name,point=[x,base-1.2,57.8],scale=[6.4/25,.05,4/13],
             reason='Centre the planted plinth on the real jamb and reduce its projection and width.')
        label='Left' if side==1 else 'Right'
        edit(f'Gallery{band}{label}CarvedBasin',point=[x,base-.06,57.8],
             reason='Keep the carved planted pocket, embed its bottom0.06 into the shelf and avoid coincident bottom/top faces.')
        edit(f'Gallery{band}{label}Fern',point=[x,base+.624-.06,57.8],
             reason='Carry the existing rooted fern with its pocket; avoid a second overlaid shrub/bowl.')
        banner=f'GalleryMoonBanner{band}{suffix}'
        edit(banner,point=[x,base+11.15,59.52],scale=[.7,.7,.7],
             asset='MC_DT_HeraldicBanner',library='DT01',
             reason='Reuse one smaller bracketed banner per jamb, with its actual wall mount and clear separation from planting and carved crest.')
        edits[banner]['after']['materialRole']='AdditiveDetail'
        edits[banner]['after']['supportUnit']=f'Gallery{band}EnclosedBody'

for name,x,base in (('GalleryOneNorthNiche',-59,54),('GalleryTwoSouthNiche',41,58),
                    ('GalleryThreeNorthNiche',49,62),('GalleryThreeSouthNiche',95,62)):
    edit(name,point=[x,base+2.25,59.52],
         reason='Place the carved crest above its centred planting, with readable negative space.')
for name,x,base in (('GalleryOneCornice',-59,54),('GalleryThreeCornice',95,62)):
    edit(name,point=[x,base+9.3,59.52],scale=[.95,.18,.65],
         reason='Compress the disconnected heavy rectangle into a connected projected cap over the niche.')
for name,x,base in (('GalleryIvy1',-59,54),('GalleryIvy2',-5,58),('GalleryIvy3',49,62)):
    edit(name,point=[x-2,base+1.25,59.67],scale=[.45,.6,.65],
         reason='Keep climbing growth on one outer edge rather than covering the centred crest/banner.')

units=[]
for row in plan['units']:
    if row['name'] in retired:continue
    units.append(edits.get(row['name'],{}).get('after',row))
report={'candidate':'MC_ART_REPAIR_20261019_A01','baseSource':54,'currentNativeGeometryMatchesFrozen54':True,
        'basePlanPath':str(SOURCE.relative_to(ROOT)).replace('\\','/'),
        'basePlanSHA256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'freshSnapshotPath':str(FRESH.relative_to(ROOT)).replace('\\','/'),
        'freshSnapshotSHA256':hashlib.sha256(FRESH.read_bytes()).hexdigest(),
        'replacements':list(edits.values()),'retired':[{'before':old[name],'reason':reason} for name,reason in retired.items()],
        'units':units,'counts':{'units':315,'meshes':869,'triangles':271658,'architecture':248,'meshDelta':-12,'newAssets':0},
        'protectedAcceptedGeometryEdited':False,'productionEdited':False,'nativeInstalled':False,
        'boundary':'Offline proposal; lead must bind native current state and actual overlap/route/camera checks before installation.'}
assert len(units)==315 and len(edits)==47
(HERE/'proposal01').mkdir(exist_ok=True)
(HERE/'proposal01/art-plan.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
lines=['--!nonstrict','local Art = {}','local edits = {']
for name,record in edits.items():
    row=record['after'];cf=','.join(f'{v:.12g}' for v in row['localCF']);sc=','.join(f'{v:.12g}' for v in row['scale'])
    lines.append(f' [{json.dumps(name)}]={{beforeAsset={json.dumps(record["before"]["asset"])},beforeLibrary={json.dumps(record["before"]["library"])},asset={json.dumps(row["asset"])},library={json.dumps(row["library"])},materialRole={json.dumps(row.get("materialRole","WorldArt"))},supportUnit={json.dumps(row["supportUnit"]) if row.get("supportUnit") else "nil"},localCF=CFrame.new({cf}),scale=Vector3.new({sc})}},')
lines.extend(['}','local retired = {'])
for name in retired:lines.append(f' [{json.dumps(name)}]=true,')
lines.extend(['}','function Art.Apply(plan)',' local result, found = {}, {}',' for _, data in plan do',
 '  if retired[data.name] then found[data.name]=true; continue end','  local edit=edits[data.name]',
 '  if edit then','   assert(data.asset==edit.beforeAsset and data.library==edit.beforeLibrary,"Art repair unit identity changed")',
 '   local copy=table.clone(data);copy.asset=edit.asset;copy.library=edit.library;copy.materialRole=edit.materialRole;copy.supportUnit=edit.supportUnit;copy.localCF=edit.localCF;copy.scale=edit.scale;data=copy;found[data.name]=true',
 '  end','  table.insert(result,data)',' end',' for name in edits do assert(found[name],"Missing art repair unit "..name) end',
 ' for name in retired do assert(found[name],"Missing retired gallery overlay "..name) end',' return result','end','return Art'])
(HERE/'proposal01/ArtRepairPlan.luau').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(json.dumps({'replacements':len(edits),'retired':len(retired),'units':len(units),'counts':report['counts']}))
