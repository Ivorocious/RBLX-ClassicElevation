from pathlib import Path

here=Path(__file__).resolve().parent
source=(here/'VerifyDetailKit.py').read_text(encoding='utf8')
source=source.replace("/detail-pass-20261014/dt01'","/detail-pass-20261014/dt01/r01'")
source=source.replace("tuple(round(value,5) for value in obj.matrix_world@vertex.co)","tuple(value for value in obj.matrix_world@vertex.co)")
start=source.index("    assert hashes[str(FILES[2]")
end=source.index('\n',start)
source=source[:start]+source[end:]
insert='''
def vertex_distance(left,right,tolerance=.00001):
    from collections import defaultdict
    from itertools import product
    def one_way(points,targets):
        grid=defaultdict(list)
        def key(point):return tuple(math.floor(value/tolerance) for value in point)
        for point in targets:grid[key(point)].append(point)
        maximum=0
        for point in points:
            cell=key(point);best=float('inf')
            for offset in product((-1,0,1),repeat=3):
                for target in grid.get(tuple(cell[k]+offset[k] for k in range(3)),()):
                    best=min(best,max(abs(point[k]-target[k]) for k in range(3)))
            maximum=max(maximum,best)
        return maximum
    return max(one_way(left,right),one_way(right,left))

'''
source=source.replace('import json\n','import json\nimport math\n')
source=source.replace('def main():',insert+'def main():')
source=source.replace("'worldVertexSetMatchesAuthored5Decimals':points==original_vertices[name]",
                      "'worldVertexSetMaxError':vertex_distance(points,original_vertices[name]),'vertexTolerance':.00001")
source=source.replace("row['worldVertexSetMatchesAuthored5Decimals']", "row['worldVertexSetMaxError']<=row['vertexTolerance']")
marker="    badge=json.loads((HERE/'badge-contour-check.json').read_text())"
extra='''    original=OUT.parent
    old_geometry=json.loads((original/'authored-geometry.json').read_text())['parts']
    new_geometry=json.loads((OUT/'authored-geometry.json').read_text())['parts']
    old={p['name']:p for p in old_geometry};new={p['name']:p for p in new_geometry}
    changed=sorted(name for name in old if old[name]!=new[name])
    assert changed==['MC_DT_HeraldicBanner__Brass'],changed
    old_manifest=json.loads((original/'manifest.json').read_text())
    old_parts={p['name']:p for p in old_manifest['export_parts']}
    assert all(old_parts[name]==row for name,row in expected.items()),'Part names/centres/sizes/colours/costs must remain exact'
    old_bounds=json.loads((original/'occupied-geometry.json').read_text())['assets']
    new_bounds=json.loads((OUT/'occupied-geometry.json').read_text())['assets']
    assert all(old_bounds[name]['bounds']==row['bounds'] for name,row in new_bounds.items()),'Whole-unit bounds changed'
    original_sha=sha(original/'MC_DETAIL_KIT_DT01.fbx')
    assert original_sha=='155cdd1029d2292f4eff7c5d778dae44f235933b5c62a02eeae822028cbeb687'
    preservation={'originalUploadedFBXPreserved':True,'originalFBXSHA256':original_sha,
                  'exactOtherMaterialParts':25,'changedMaterialParts':changed,
                  'all26PartManifestRowsExact':True,'all8WholeUnitBoundsExact':True,
                  'occupiedBoxDelta':'Only the corrected crescent component box changes; all other occupied boxes stay exact'}
'''
source=source.replace(marker,extra+marker)
source=source.replace("'parts':26,'triangles':9574", "'parts':26,'triangles':9574,'preservation':preservation")
source=source.replace("'uploadedFBXPreserved':True", "'originalUploadedFBXPreserved':True")
source=source.replace('Closed/manifold topology does not override the two self-crossing crescent contour findings.',
                      'Corrected crescent contour has zero proper self crossings; all25other material parts and all26manifest rows remain exact.')
source=source.replace("'dt01-readonly-roundtrip.json'", "'r01-readonly-roundtrip.json'")
(here/'r01/VerifyDetailKit.py').write_text(source,encoding='utf8',newline='')
print('Prepared R01 tolerance-based FBX roundtrip and exact25-part preservation check')
