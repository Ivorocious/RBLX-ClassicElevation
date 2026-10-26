"""Verify saved Source43 evidence and prepare a compact physical baseline and cost ledger."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / 'default.project.json').is_file())
SAVED = ROOT / 'docs/artifacts/moonlit-citadel/phase3/art-repair-20261013/source43/final'
PACKET = '81ba6fdb12b23d4a4abee5795dece2a1994b146c93dc528b4b8b4198e3a2f0cb'

def read(name):
    return json.loads((SAVED / name).read_text(encoding='utf-8-sig'))

def output(name, data):
    (HERE / name).write_text(json.dumps(data,indent=2,ensure_ascii=True)+'\n',encoding='utf-8')

def main():
    saved = read('artrepair_final_source43_sources.json')
    layout = read('artrepair_final_source43_layout.json')
    attrs = layout['attrs']
    assert attrs['SourceRevision']==43 and attrs['BuildRevision']==37 and attrs['SourcePacketHash']==PACKET
    receipts=[]
    for row in saved['files']:
        file=SAVED/row['name']
        data=file.read_bytes()
        actual=hashlib.sha256(data).hexdigest()
        assert actual==row['sha256'] and len(data)==row['bytes'], 'Saved recovery receipt mismatch: '+row['name']
        receipts.append({'name':row['name'],'bytes':len(data),'sha256':actual,'verified':True})
    sources=[]
    for row in saved['sources']:
        native_hash=hashlib.sha256(row['source'].encode('utf-8')).hexdigest()
        assert native_hash==row['sha256'],'Saved native source hash mismatch: '+row['instancePath']
        candidates=[ROOT/('src/'+row['instancePath']+suffix) for suffix in ['.luau','.server.luau','.client.luau']]
        matches=[path for path in candidates if path.is_file()]
        assert len(matches)==1,'Ambiguous or missing filesystem source: '+row['instancePath']
        name=str(matches[0].relative_to(ROOT)).replace('\\','/')
        current=matches[0].read_text(encoding='utf-8-sig')
        sources.append({'path':name,'savedHash':native_hash,'currentTextMatchesSaved':current==row['source']})
    protected=[]
    art=[]
    for row in layout['parts']:
        if row['path']=='Decoration.Phase3World' or row['path'].startswith('Decoration.Phase3World.'):
            art.append(row)
        else:
            protected.append(row)
    arrows=[row for row in protected if row.get('attrs',{}).get('GuidanceKind')=='SolidMeshArrow']
    assert len(arrows)==19,'Saved Source43 must retain the selected 19 mesh arrows'
    output('source43-saved-physical-baseline.json',{'schema':'saved-export-physical-only','identity':attrs,
           'parts':protected,'arrowPaths':sorted(row['path'] for row in arrows),
           'limitations':['Saved part export is not a full Model/GUI/attachment/script capture.',
                          'Use fresh schema2 native captures for the actual before/after comparison.']})
    source_report={'savedIdentity':attrs,'receipts':receipts,'sources':sources,'protectedPhysicalParts':len(protected),
                   'phase3ArtParts':len(art),'selectedMeshArrows':len(arrows),'liveStudioChecked':False}
    output('source43-saved-verification.json',source_report)

    # These are existing measured totals and bounded proposals supplied by their authors.
    stages={
        'source43Architecture':{'units':247,'meshParts':643,'triangles':319824},
        'source43Environment':{'units':103,'meshParts':162,'triangles':37578},
        'towerReplacementArchitecture':{'units':210,'meshParts':558,'triangles':216460},
        'landscapeReplacementUpperBound':{'units':72,'meshParts':156,'triangles':53286},
    }
    limits={'units':350,'meshParts':900,'triangles':420000}
    combined={key:stages['towerReplacementArchitecture'][key]+stages['landscapeReplacementUpperBound'][key] for key in limits}
    baseline={key:stages['source43Architecture'][key]+stages['source43Environment'][key] for key in limits}
    ledger={'scope':'Draft accounting only; actual integrated/native counts still required','stages':stages,
            'source43Combined':baseline,'candidateCombinedUpperBound':combined,'hardLimits':limits,
            'remaining':{key:limits[key]-combined[key] for key in limits},
            'deltaFromSource43':{key:combined[key]-baseline[key] for key in limits},
            'withinCurrentLimits':all(combined[key]<=limits[key] for key in limits),
            'rules':['Retire only named Phase3World units, preserving recovery first.',
                     'Charge every retained and new unit against the same combined ledger.',
                     'Require measured asset part/triangle receipts before replacing provisional upper bounds.',
                     'Do not trim a plan silently or keep an arbitrary first N placements.',
                     'Leave explicit finishing room under current caps; no FPS/device claim follows from counts.']}
    output('resource-ledger.json',ledger)
    print(json.dumps({'savedSourceEntries':len(sources),'currentMatches':sum(row['currentTextMatchesSaved'] for row in sources),
                      'savedProtectedPhysicalParts':len(protected),'savedPhase3ArtParts':len(art),'arrows':len(arrows),
                      'candidateUpperBound':combined,'remaining':ledger['remaining'],'withinLimits':ledger['withinCurrentLimits']}))

if __name__=='__main__':
    main()
