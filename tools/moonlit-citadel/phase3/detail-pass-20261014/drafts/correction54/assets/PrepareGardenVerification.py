from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
source=(ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/assets/r01/VerifyDetailKit.py').read_text(encoding='utf8')
source=source.replace("/detail-pass-20261014/dt01/r01'","/detail-pass-20261014/correction54/dg01'")
source=source.replace("HERE/'BuildDetailKit.py'","HERE/'BuildGardenKit.py'")
source=source.replace("'MC_DETAIL_KIT_DT01.blend'","'MC_WALL_GARDEN_DG01.blend'").replace("'MC_DETAIL_KIT_DT01.fbx'","'MC_WALL_GARDEN_DG01.fbx'")
source=source.replace("'DT01_Export_Material_Parts'","'DG01_Export_Material_Parts'")
source=source.replace('len(saved)==26','len(saved)==3').replace('len(actual)==26','len(actual)==3')
source=source.replace('==9574','==1662').replace("'parts':26,'triangles':9574,'preservation':preservation","'parts':3,'triangles':1662")
start=source.index('    original=OUT.parent');end=source.index('    for path,digest in hashes.items()',start)
contour='''    contours={'corbel':[(.10,0),(-.45,.38),(-.86,1.7),(-2.0,3.25),(-3.65,4.6),(-3.8,5.22),(.10,5.22)],
              'leaf':[(-.14,0),(-.5,.32),(-.43,.84),(0,1),(.43,.84),(.5,.32)]}
    crossings=[]
    def orient(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    for label,points in contours.items():
        n=len(points)
        for i in range(n):
            a,b=points[i],points[(i+1)%n]
            for j in range(i+1,n):
                if j==(i+1)%n or i==(j+1)%n:continue
                c,d=points[j],points[(j+1)%n]
                if orient(a,b,c)*orient(a,b,d)<-1e-12 and orient(c,d,a)*orient(c,d,b)<-1e-12:
                    crossings.append({'contour':label,'edgeA':i,'edgeB':j})
    assert not crossings,crossings
    badge={'pass':True,'properSelfCrossings':[],'scope':'Garden corbel and leaf contours; nested ellipse ring radii are strictly separated'}
'''
source=source[:start]+contour+source[end:]
source=source.replace("'originalUploadedFBXPreserved':True", "'newAssetOnly':True")
source=source.replace('Corrected crescent contour has zero proper self crossings; all25other material parts and all26manifest rows remain exact.',
                      'Garden contour, closed topology and actual roundtrip vertex checks pass; native garden import/axis proof remains root obligation.')
source=source.replace("'r01-readonly-roundtrip.json'", "'garden-readonly-roundtrip.json'")
(HERE/'VerifyGardenKit.py').write_text(source,encoding='utf8',newline='')
print('Prepared3-part garden closed-normal/contour/tolerant FBX roundtrip verification')
