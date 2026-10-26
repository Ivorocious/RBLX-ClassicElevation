import re
from pathlib import Path

HERE=Path(__file__).resolve().parent
for name in ('REVIEW_PACKET53.md','FINAL_HANDOFF_SOURCE53.md'):
    path=HERE/name;text=path.read_text(encoding='utf8')
    lines=[]
    for line in text.splitlines():
        pieces=re.split(r'(\[[^\]]*\]\([^\)]*\)|`[^`]*`)',line)
        for index,piece in enumerate(pieces):
            if piece.startswith('[') or piece.startswith('`'):continue
            piece=re.sub(r'\b(Source|Build|Phase)(\d)',r'\1 \2',piece)
            piece=re.sub(r'([A-Za-z])(\d)',r'\1 \2',piece)
            piece=re.sub(r'(\d)([A-Za-z])',r'\1 \2',piece)
            piece=piece.replace('MC_P 3_DETAILS_DT 01','MC_P3_DETAILS_DT01').replace('DT 01','DT01').replace('R 01','R01').replace('P 1','Phase 1')
            piece=re.sub(r'([A-Za-z])([,:;])(?=\d)',r'\1\2 ',piece)
            pieces[index]=piece
        lines.append(''.join(pieces))
    path.write_text('\n'.join(lines)+'\n',encoding='utf8')
print('Polished two Source53 drafts; links and exact code/hash tokens preserved')
