from pathlib import Path

HERE=Path(__file__).resolve().parent
text=(HERE/'RenderArtProposal.py').read_text(encoding='utf8')
text=text.replace("'proposal01/art-plan.json'","'proposal03/art-plan.json'").replace("'proposal01'","'proposal03'")
text=text.replace("render('before54')",'''import shutil
previous=json.loads((HERE/'proposal01/art-proposal-report.json').read_text(encoding='utf8'))
assert previous['inputHashes'][str(SOURCE.relative_to(ROOT)).replace('\\\\','/')]==guards[str(SOURCE.relative_to(ROOT)).replace('\\\\','/')]
for record in previous['views']:
    if record['stage']!='before54':continue
    shutil.copy2(HERE/'proposal01'/record['file'],OUT/record['file'])
    assert sha(OUT/record['file'])==record['sha256']
    views.append(dict(record,reusedOriginalFrom='proposal01'))''')
text=text.replace("report={'pass':True", "report={'reusedBeforeViewsFrom':'proposal01 unchanged54 baseline', 'pass':True")
exec(compile(text,str(HERE/'RenderArtProposal03.py'),'exec'))
