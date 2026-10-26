from pathlib import Path

here=Path(__file__).resolve().parent
out=here/'r01';out.mkdir(exist_ok=True)
recipes=(here/'DetailRecipes.py').read_text(encoding='utf8')
assert recipes.count('295-230*i/18')==1
recipes=recipes.replace('295-230*i/18','267-174*i/18')
(out/'DetailRecipes.py').write_text(recipes,encoding='utf8',newline='')
builder=(here/'BuildDetailKit.py').read_text(encoding='utf8').replace("BUILD='MC_P3_DETAIL_DT01'","BUILD='MC_P3_DETAIL_DT01_R01'")
builder=builder.replace("    hashes={str(p.relative_to(ROOT)).replace('\\\\','/'):sha(p) for p in paths}",
                        "    paths.extend(p for p in out.parent.iterdir() if p.is_file())\n    hashes={str(p.relative_to(ROOT)).replace('\\\\','/'):sha(p) for p in paths}")
assert 'paths.extend(p for p in out.parent.iterdir() if p.is_file())' in builder
(out/'BuildDetailKit.py').write_text(builder,encoding='utf8',newline='')
contour=(here/'CheckBadgeContour.py').read_text(encoding='utf8').replace('295-230*i/18','267-174*i/18')
(out/'CheckBadgeContour.py').write_text(contour,encoding='utf8',newline='')
print('Prepared R01: only crescent inner contour tip span corrected; original DT01 preserved')
