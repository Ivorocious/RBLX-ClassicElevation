"""Keep the global diagnostic grouped and distinguish exact overlaps from near surfaces."""
from collections import defaultdict
import hashlib
import json
from pathlib import Path

import numpy as np

OWN=Path(__file__).resolve().parent
objects=json.loads((OWN/'surface-objects54-bound.json').read_text(encoding='utf8'))['objects']
report=json.loads((OWN/'visible-overlap-findings.json').read_text(encoding='utf8'))
proposal=json.loads((OWN/'physical-separation-proposal.json').read_text(encoding='utf8'))
triangles=np.load(OWN/'surface-triangles54.npz')['triangles']
groups=defaultdict(list)
labels={
 'floor':('Repeated floor-stone vertical edge bands',1,'Candidate: native Floor material SizeX/Z minus0.08, local top plane/thickness and CFrame unchanged; minimum measured separation0.03980.'),
 'windows':('Window-frame jamb and cap returns',2,'Candidate: main Stone substrate SizeX/Y minus0.12; depth and all glass/detail parts unchanged; minimum measured separation0.048999.'),
 'west':('West wing material bands against neighbouring wing bodies',3,'Candidate: WestArchMiddleWing whole scenery unit localX minus0.08; minimum measured separation0.079985; recheck mounted support/appearance.'),
 'crown':('Crown shell/main keep joint and crown side trim',4,'Pictured-area author already owns this. Front/back wall planes at Z-12/-20 coincide; side trim also has a0.016 gap. Keep floor and main geometry acceptance separate.'),
 'brackets':('Four wheel-support Iron/Stone faces',5,'Candidate: four Iron decorative parts local-worldZ plus0.06; native matrices/sizes are bound; minimum measured separation0.06.'),
 'masonry':('Small repeated masonry strap/body seams',6,'Secondary: inspect actual moving view before preparing a shared template correction; no blanket mass change proposed.'),
 'roofjoins':('Upper machinery roof/bay and northwest court/roof joins',7,'UpperMachineWindowBay1 is0.018 from the Slate wall at X193.4; consider its decorative backing localX plus0.08 only if native view confirms instability. Northwest coplanar trim is separate.'),
 'chimneys':('Two new chimney crown bands',8,'Separated by0.0144, rather than exact overlap. Native moving check first; a measured cap lift could increase physical separation if required.'),
 'galleryrejoin':('Two adjacent gallery-rejoin skin interfaces',9,'Low-area visual skins overlap at the accepted rejoin. Hold contact geometry exact; do not turn this into a route-spacing change.'),
 'metal':('Small car/weight cosmetic metal seams',10,'Low-area material seams only. Do not modify carry, collider, movement or runtime state; native view first.'),
 'roofstripes':('Two tiny roof stripe/edge interfaces',11,'Each projected overlap is about0.012stud2. No change proposed without actual visible flashing.'),
 'postskins':('Two tiny brass-post/floor-skin interfaces',12,'About0.024stud2 each with0.0154gap; no hazard/contact movement proposed.'),
}
for row in report['pairs']:
 if not row['differentNativeAppearance']:continue
 p=row['paths'];s='|'.join(p)
 if all('MC_FloorStone__'in x for x in p):key='floor'if p[0].rsplit('/',1)[0]==p[1].rsplit('/',1)[0]else'galleryrejoin'
 elif all('MC_WindowFrame__'in x for x in p):key='windows'
 elif all('MC_ER_SteppedWing__'in x for x in p):key='west'
 elif 'MC_ER_CrownBaseShell__'in s:key='crown'
 elif 'MC_ER_LanternBracket__'in s:key='brackets'
 elif all('MC_AR_MasonryMass__'in x for x in p):key='masonry'
 elif 'MC_DT_ChimneyVent__'in s:key='chimneys'
 elif 'MC_AR_GalleryRoof46__'in s:key='roofstripes'
 elif 'MC_GuideIron__'in s:key='postskins'
 elif any(part in s for part in ('MC_CarIronBrass__','MC_WeightIron__','MC_WeightStone__')):key='metal'
 else:key='roofjoins'
 groups[key].append(row)
out=[]
for key,rows in sorted(groups.items(),key=lambda item:labels[item[0]][1]):
 label,priority,action=labels[key]
 examples=[]
 for row in rows[:3]:
  witness=row['visibleWitnesses'][0];proof=witness['faceWitness'];i,j=proof['triangleIndices']
  examples.append({'paths':row['paths'],'totalPairProjectedOverlapArea':row['area'],'minimumGap':row['minimumGap'],
                   'visibleWitnessProjectedArea':proof['area'],'point':witness['point'],'normal':witness['normal'],
                   'supportedEye':witness['eye'],'eyeSupport':witness['support'],'savedPolygonIndices':proof['faces'],
                   'triangleVerticesA':triangles[i].tolist(),'triangleVerticesB':triangles[j].tolist()})
 out.append({'id':key,'priority':priority,'label':label,'pairs':len(rows),
             'geometricallyCoincidentPairsWithinBindingTolerance':sum(row['minimumGap']<.0005 for row in rows),
             'totalPairProjectedOverlapArea':sum(row['area']for row in rows),
             'minimumGap':min(row['minimumGap']for row in rows),'maximumGap':max(row['maximumGap']for row in rows),
             'partPaths':sorted({path for row in rows for path in row['paths']}),'examples':examples,'proposal':action})
compact={'scope':'Global actual-surface diagnosis for current Source54, grouped by visible material collision family',
         'visibleObjects':1598,'nativeMeshes':1481,'nativeBlockPrimitives':117,'triangles':374804,
         'routeEyes':report['routeEyes'],'visibilityRays':report['rays'],'nearCoplanarPartPairs':report['candidatePairs'],
         'differentAppearanceVisiblePairs':report['differentAppearancePairs'],'sameAppearancePairsNotPrioritized':report['visiblePairs']-report['differentAppearancePairs'],
         'pairsWithoutVisibleTestWitness':report['candidatePairs']-report['visiblePairs'],
         'doubleSidedNativeMeshCount':sum(row.get('nativeDoubleSided')is True for row in objects),
         'groups':out,'physicalProposal':{'file':'physical-separation-proposal.json','existingVisiblePairsChecked':len(proposal['pairChecks']),
                                          'pass':proposal['pass'],'families':proposal['families']},
         'boundaries':['Only same-facing near-coplanar triangles with positive projected overlap were compared; maximum gap0.02 and normal buckets0.001',
                       'Visibility uses up to8 largest overlap witnesses per part pair and24 nearby supported eyes per witness; unobserved does not prove invisible',
                       'Areas sum all measured triangle intersections in a part pair and include hidden sections; examples separately report the actual visible witness area',
                       'Native fresh CFrame/Size tight bounds agree within0.0004272stud; scene triangles are preserved authored/verified-template geometry',
                       'Physical corrections are proposals checked against existing witnesses, not full new-intersection clearance or native moving-render acceptance'],
         'studioTouched':False,'productionChanged':False,'liveBlenderTouched':False}
assert sum(row['pairs']for row in out)==report['differentAppearancePairs']
(OWN/'credible-overlap-map.json').write_text(json.dumps(compact,indent=2)+'\n',encoding='utf8')
print(json.dumps({'groups':[(row['id'],row['pairs'])for row in out],
                  'doubleSidedNativeMeshCount':compact['doubleSidedNativeMeshCount'],'physicalPairChecks':len(proposal['pairChecks'])}))
