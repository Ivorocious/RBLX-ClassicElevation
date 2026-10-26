from pathlib import Path

HERE=Path(__file__).resolve().parent
text=(HERE/'PrepareArtProposal.py').read_text(encoding='utf8')
text=text.replace('MC_ART_REPAIR_20261019_A01','MC_ART_REPAIR_20261019_A03')
text=text.replace("'proposal01'","'proposal03'").replace('proposal01/art-plan.json','proposal03/art-plan.json').replace('proposal01/ArtRepairPlan.luau','proposal03/ArtRepairPlan.luau')
text=text.replace('12.35/24','10.55/24').replace('11.95/24','10.35/24')
text=text.replace('ending below the accepted floor','ending below the accepted floor and standing sight corridor')
text=text.replace('units=[]', '''west_names=['WestArchMiddleWing']+[r['name'] for r in plan['units'] if r.get('supportUnit')=='WestArchMiddleWing']+['WestMiddleEaveCornice']
assert len(west_names)==9 and len(set(west_names))==9
for name in west_names:
    point=old[name]['localCF'][:3]
    point[0]-=.08
    edit(name,point=point,reason='Carry the complete west middle wing and its eight attached roof/facade units together by local X minus0.08 to separate the measured reciprocal bands; relative support transforms remain exact.')

units=[]''')
text=text.replace('len(edits)==47','len(edits)==56')
exec(compile(text,str(HERE/'PrepareArtProposal03.py'),'exec'))
