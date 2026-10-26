from pathlib import Path
HERE=Path(__file__).resolve().parent
text=(HERE/'PrepareArtProposal.py').read_text(encoding='utf8')
text=text.replace('MC_ART_REPAIR_20261019_A01','MC_ART_REPAIR_20261019_A02').replace("'proposal01'","'proposal02'")
text=text.replace('proposal01/art-plan.json','proposal02/art-plan.json').replace('proposal01/ArtRepairPlan.luau','proposal02/ArtRepairPlan.luau')
text=text.replace('12.35/24','10.55/24').replace('11.95/24','10.35/24')
text=text.replace('ending below the accepted floor','ending below the accepted floor and standing sight corridor')
exec(compile(text,str(HERE/'PrepareArtProposal02.py'),'exec'))
