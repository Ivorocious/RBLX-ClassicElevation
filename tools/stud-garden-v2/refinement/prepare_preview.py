from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'docs/artifacts/stud-garden-v2/refinement-20261005/r01'
data=json.loads((OUT.parent/'owner-baseline-geometry.json').read_text())
manifest=json.loads((OUT/'botanical-manifest.json').read_text())
removed=set(manifest['replaceMeshes'])
data['parts']=[p for p in data['parts'] if not (p['path'].startswith('Phase3Art.') and p['name'] in removed) and not p['path'].startswith('ClosingScenery.GreatTwistingBeanstalk.')]
for m in manifest['meshes']:
    lo,hi=m['exportBoundsRoblox']
    center=[(lo[i]+hi[i])/2 for i in range(3)]
    data['parts'].append({'path':'BotanicalRefinement.'+m['name'],'name':m['name'],'class':'MeshPart','shape':'MeshPart','cf':[center[i]+[1563,257,-1053][i] for i in range(3)]+[-1,0,0,0,1,0,0,0,-1],'size':[hi[i]-lo[i] for i in range(3)],'color':[int(m['hex'][i:i+2],16)/255 for i in (1,3,5)],'transparency':0,'collide':False,'role':'Decoration','attributes':{}})
data['attributes']['CandidateId']='SGV2_Refinement_R01_ArtPreview'
(OUT/'art-preview-geometry.json').write_text(json.dumps(data))
renderer=(ROOT/'tools/stud-garden-v2/closing/render_preview.py').read_text()
renderer=renderer.replace("[root/'docs/artifacts/stud-garden-v2/phase3/f04/SGV2_Phase3_F04.blend']", "[root/'docs/artifacts/stud-garden-v2/phase3/f04/SGV2_Phase3_F04.blend',root/'docs/artifacts/stud-garden-v2/refinement-20261005/r01/SGV2_Botanical_R01.blend']")
renderer=renderer.replace("scene.render.resolution_x=1600;scene.render.resolution_y=1000", "scene.render.resolution_x=1280;scene.render.resolution_y=800")
renderer=renderer.replace("scene.cycles.samples=16", "scene.cycles.samples=8")
(ROOT/'tools/stud-garden-v2/refinement/render_preview.py').write_text(renderer)
views=[{'name':'01-art-overview','eye':[-315,255,315],'target':[0,40,0],'ortho':510},
       {'name':'02-display','eye':[-74,31,59],'target':[-128,24,1],'lens':29},
       {'name':'03-display-player','eye':[-68,10,29],'target':[-129,25,-4],'lens':25},
       {'name':'04-grand-beanstalk','eye':[219,110,165],'target':[108,75,43],'lens':27}]
(OUT/'art-preview-views.json').write_text(json.dumps(views))
print({'parts':len(data['parts']),'views':len(views)})
