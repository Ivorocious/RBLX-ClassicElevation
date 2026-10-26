"""Produce a small actionable diagnosis from the fresh finite scan."""
from collections import Counter
import hashlib
import json
from pathlib import Path

OWN=Path(__file__).resolve().parent
ROOT=next(p for p in OWN.parents if(p/'default.project.json').exists())
raw=json.loads((OWN/'inter-unit-visibility56.json').read_text(encoding='utf8'))
objects=json.loads((OWN/'current56-objects.json').read_text(encoding='utf8'))['objects']


def family(pair):
    paths=pair['paths'];joined=' '.join(paths)
    if '/RouteHazards/'in joined:return 'hazard-guide-mounts'
    if '/MovingCars/'in joined:return 'moving-car-materials'
    if '/BraceSkin/'in joined:return 'brace-to-floor-side-skins'
    if all('/StoneSkin/'in p for p in paths):return 'overlapping-floor-return-recovery-skins'
    if '/CrownArrival/'in joined:return 'crown-and-keep-material-joints'
    if '/LanternPendulums/'in joined:return 'gallery-body-and-plinth-neighbors'
    if '/DT_'in joined:return 'mounted-facade-detail-neighbors'
    if '/FortressRamparts/'in joined:return 'neighboring-rampart-faces'
    if '/SteppedFortressWings/'in joined:return 'court-or-stepped-wing-faces'
    return 'other'


rows=[]
for pair in raw['pairs']:
    if pair['state']!='supported-route-visible':continue
    witnesses=[w for w in pair['visibleWitnesses'] if w['witness']['gap']<.025]
    if not witnesses:continue
    rows.append({'family':family(pair),'paths':pair['paths'],'units':pair['units'],'areaAcrossCandidateTriangles':pair['area'],
                 'minimumVisibleWitnessGap':min(w['witness']['gap']for w in witnesses),'differentNativeAppearance':pair['differentAppearance'],
                 'inPrior184PartPairList':pair['previous184'],'visibleWitnesses':witnesses})
world=[r for r in rows if r['paths'][0].startswith('Decoration/')]
summary={'pass':True,'scope':'Independent filesystem-only diagnosis of current retained-floor Source56. No production edit or native render/temporal claim.',
 'sourceInputs':[{ 'path':str(p.relative_to(ROOT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in(
 ROOT/'tools/moonlit-citadel/phase3/repair-20261019/overlap/surface-triangles54.npz',
 ROOT/'tools/moonlit-citadel/phase3/repair-20261019/overlap/surface-objects54-bound.json',
 ROOT/'tools/moonlit-citadel/phase3/repair-20261019/art/proposal03/art-plan.json',
 ROOT/'tools/moonlit-citadel/phase3/repair-20261019/overlap/expected-native-patch-manifest.json',
 ROOT/'docs/artifacts/moonlit-citadel/phase3/repair-20261019/final/native-snapshot55.json',
 ROOT/'docs/artifacts/moonlit-citadel/phase3/veil-20261020/native-install-check56.json')],
 'geometryObjects':len(objects),'sceneryMeshes':869,'sceneryTriangles':271658,'allVisibleTriangles':363518,
 'candidatePartPairs':len(raw['pairs']),'rays':raw['rays'],'supportedEyes':raw['routeEyes'],'states':raw['states'],
 'supportedVisiblePairsBelow025':len(rows),'beyondPrior184':sum(not r['inPrior184PartPairList']for r in rows),
 'worldPairsBelow025':len(world),'families':dict(Counter(r['family']for r in rows)),
 'rows':rows,'limits':[
 'Finite sampled witnesses, not every-frame or every-camera proof; source-bound real meshes, not a bounding-box-only intersection count.',
 'Near-parallel normals share quantized0.001 normal bins and must dot>=1-1e-6; normal-bin-edge and meaningfully angled surface intersections are not included.',
 'Same-facing and double-sided pairs are considered.434 single-sided opposed joins were excluded because only one outward face can render from a given eye.',
 'Positive projected overlap>=0.01stud2, maximum vertex-to-plane gap<=0.06stud. The small actionable set uses an actual visible witness gap<0.025stud.',
 'At most40 spatial/normal witness representatives per part pair and16 nearest eligible route eyes per witness; an unobserved witness is not a global absence proof.',
 'Twelve mist anchors are invisible/inert and excluded. Current restored ER01 floor is retained exactly. Mist particle opacity is not simulated in these rays.',
 'Appearance equality does not prove no flashing because mesh UV orientation and normal interpolation can still differ. Equal-material broad architectural overlaps remain medium-priority candidates.',
 'Area is a sum of intersecting triangle pair areas and can double-count; do not interpret it as unique visible screen area.',
 'Four moving cars are inspected in the recorded Edit pose. Runtime trajectory and occlusion need root native verification.',
 'Original54 triangles and200 operations bind most final55 native bounds below0.005; final56 proof preserves1760 otherparts and restores original3ravine parts. Root owns fresh current-native parity.'
 ]}
(OWN/'NEIGHBOR_DIAGNOSIS56.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf8')
lines=['# Current retained-floor neighbor diagnosis','',
 'A fresh actual-triangle scan finds **134 supported-view material/skin pairs with gap below0.025stud**, including **127 part pairs beyond the previous184 list**. This is a geometry risk diagnosis, not134 observed flashing events.',
 '',f"The scan covers1,586 visible mesh/primitive objects and363,518triangles.869scenery meshes contribute271,658triangles. It uses677 supported course-height eyes and13,077 first-surface rays.434opposed single-sided internal joins are excluded;140other pairs have a diagnostic local outward view but no supported-route witness, and61have no exposed sample.",
 '', '## Highest-priority world conflicts','',
 '- **Crown shell against keep:** CrownBaseUnifiedShell StoneLight still shares its localX=-46 side plane with GrandKeepUnifiedShell Stone (gap0.0000038). The earlierZ-only move separated a front face but left this side. NativeSizeX+0.16 on CrownBase StoneLight is a minimal candidate: it moves both side planes0.08 while retaining the existingZ correction.',
 '- **Gallery-body strips:** Gallery1/2 andGallery2/3 reciprocal Stone/StoneDark strip pairs shareZ59.6, with0.000004–0.000011 gaps. Four supported pairs, each about14.5summed triangle-overlapstud2. Candidate: allthree gallery-body StoneDark materials shift localZ-0.08, creating deliberate inset relief. Keep Stone, gameplay, canopy, window and plant positions fixed. Whole-candidate rescan is required to catch other band faces.',
 '- **New crown apron/pier/feet:**8supported part pairs around joined apron edges, engaged post bottoms and narrow emblem pier have0–0.024gaps. Candidate: lower-pier Stone thicknessSizeZ-0.16 separates its front/rear from the apron andFoot3. The two broad apron StoneLight parts need all relevant side/bottom faces separated, rather than a single axis translation. Native localSizeX/Y/Z-0.16 is a candidate only after support/attachment and whole-scene checks.',
 '- **Mounted niches:** WestArrivalNorthJambNiche StoneLight sharesZ27.3 with WestArrivalWing Stone; WestHighJambNiche StoneLight lies0.0099 from WestArchMiddleWing Slate. Candidate outward offsets areZ+0.08 andX+0.08, respectively, for those visible material pieces. Check the attached material groups before adopting.',
 '- **Two planter plinths:** Gallery1/2PlanterShelf-1 StoneLight top sharesY54/58 with the next gallery foundation. Increasing the plinth material height0.16 gives0.08top relief and keeps its planted basin embedded. Simply lowering the plinth would risk an unsupported basin gap.',
 '- **Large same-material neighbors:** NWcourt/NWstepped hall, east gallery/upper deep wings and adjacent west ramparts share exposed wall planes. These are medium-priority despite matching native materials because UV/shading differences can still flash. Any whole-unit move must carry attached art; a visible-material relief/inset should be globally rescanned.',
 '', '## Route cosmetic families for integration','']
for name,count in summary['families'].items():lines.append(f'- {name}: {count}visible sampled part pairs.')
lines+=['', 'Hazard-guide contacts have about0.0213 gaps, four moving-car Brass/Iron groups retain0.02gaps on other faces after the earlierZ-only move, return/recovery floor skins overlap at0.012/0.024, and brace/floor side skins contain exact same-facing faces. Preserve all actual RedContact/Contact/arrow geometry and alter only inert visible skins.',
 '', 'All exact paths and supported-eye witnesses are in[NEIGHBOR_DIAGNOSIS56.json](NEIGHBOR_DIAGNOSIS56.json). Full candidate/classification data are in[inter-unit-visibility56.json](inter-unit-visibility56.json). Proposed edits above are uninstalled candidates and require whole-scene rescan plus native readback.',
 '', '## Limits','']
lines += ['- '+s for s in summary['limits']]
(OWN/'NEIGHBOR_DIAGNOSIS56.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in summary.items()if k not in('rows','sourceInputs','limits')},indent=2))
