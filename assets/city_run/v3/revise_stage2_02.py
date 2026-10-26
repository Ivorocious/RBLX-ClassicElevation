from pathlib import Path
p=Path('assets/city_run/v3/plan_stage2.py')
s=p.read_text().replace("[69,28.5,30]","[64,24.5,30]").replace("[3785,103,137],[71,18,122]","[3785,99,137],[66,8,122]")
s=s.replace("result={'build':'V3_STAGE2_01'",'''# Broad mural supplies a courtyard landmark without adding geometry to the jump lane.
add('V3_MuralPanel',[3401.7,55,-95],[26,16,1.06],270,'CourtEastMural',category='Props')
# Low-cost perimeter silhouettes close long views; all remain outside the course footprint.
for i,(x,z,h) in enumerate([(3210,-170,95),(3210,0,85),(3170,170,80),(3380,335,80),(3600,335,100),(3900,300,110),(3960,125,120),(3930,-90,100),(3810,-355,115),(3510,-388,115),(3270,-330,100)]):
 add('V3_Skyline_'+str(i%4+1),[x,0,z],[70,h,45],label='Perimeter_'+str(i),category='Architecture')
result={'build':'V3_STAGE2_02' ''')
p.write_text(s)
