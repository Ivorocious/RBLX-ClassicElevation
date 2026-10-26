"""Focused geometric checks, not a substitute for character or crowd playtests."""
import math
import json
from pathlib import Path
import layout

surfaces={s["name"]:s for s in layout.SURFACES}
g=layout.MOVEMENT["gravity"];speed=layout.MOVEMENT["walkSpeed"]
v=math.sqrt(2*g*layout.MOVEMENT["jumpHeight"])
failures=[];records=[];lengths={}
for name,keys in layout.ROUTES.items():
    distance=0
    for a,b in zip(keys,keys[1:]):
        a,b=surfaces[a],surfaces[b]
        dx,dz=abs(b["p"][0]-a["p"][0]),abs(b["p"][2]-a["p"][2])
        rise=b["p"][1]-a["p"][1]
        distance+=math.dist(a["p"],b["p"])
        gapx=max(0,dx-(a["size"][0]+b["size"][0])/2)
        gapz=max(0,dz-(a["size"][2]+b["size"][2])/2)
        gap=math.hypot(gapx,gapz)
        reachable=speed*(v+math.sqrt(max(0,v*v-2*g*rise)))/g if rise<=7.2 else 0
        ok=rise<=7.2 and gap+.6<reachable
        if not ok:failures.append((a["name"],b["name"],gap,rise,reachable))
        records.append(dict(route=name,start=a["name"],end=b["name"],gap=round(gap,3),rise=round(rise,3),ballisticRange=round(reachable,3),passGeometry=ok))
    lengths[name]=round(distance,1)

car=layout.HAZARDS["cars"]
car_gap=min(car["intervals"])-(car["size"][0]+16)/car["speed"]
car_cross_time=(178-150)/speed
assert car_gap>car_cross_time+1
train=layout.HAZARDS["train"]
train_front_arrival=(train["crossing"][0]-6-train["size"][0]/2-train["startX"])/train["speed"]
last_entry_clearance=(layout.CHECKPOINTS[7][2]-(-26))/speed
assert train_front_arrival-train["warningTime"]>last_entry_clearance+1

# Wait pockets on each side and the expert center perch stay outside both complete ball sweeps.
perches=[(-92,82,-244),(-65,82,-257),(-20,82,-257),(19,82,-257),(66,82,-257),(-1,82,-231),(116,82,-244)]
for p in perches:
    assert all(abs(p[0]-ball["pivot"][0])>ball["radius"]+5.5 for ball in layout.HAZARDS["balls"])
ball_clearance=[]
for ball in layout.HAZARDS["balls"]:
    for z in (-257,-231):
        theta=math.asin((z-ball["pivot"][2])/ball["length"])
        bottom=ball["pivot"][1]-ball["length"]*math.cos(theta)-ball["radius"]
        assert abs(theta)<ball["amplitude"] and bottom<87
    minimum=math.inf
    for i in range(561):
        angle=-ball['amplitude']+2*ball['amplitude']*i/560
        center=(ball['pivot'][0],ball['pivot'][1]-ball['length']*math.cos(angle),ball['pivot'][2]-ball['length']*math.sin(angle))
        for s in layout.SURFACES:
            if s['section']!='Roof':continue
            c=(s['p'][0],s['p'][1]-.6,s['p'][2]);half=(s['size'][0]/2,.7,s['size'][2]/2)
            distance=math.sqrt(sum(max(0,abs(center[k]-c[k])-half[k])**2 for k in range(3)))
            minimum=min(minimum,distance-ball['radius'])
    # The margin exceeds the maximum center travel between adjacent sweep samples.
    assert minimum>2*ball['amplitude']*ball['length']/560,(ball['name'],minimum)
    ball_clearance.append(dict(name=ball['name'],minimumPlatformClearance=round(minimum,3)))

report=dict(status="pass" if not failures else "fail",movement=layout.MOVEMENT,
    routeLengths=lengths,failures=failures,jumps=records,
    carGuaranteedGapSeconds=round(car_gap,2),carCrossSeconds=round(car_cross_time,2),
    trainFrontArrivalSeconds=round(train_front_arrival,2),lastEntryTravelSeconds=round(last_entry_clearance,2),
    ballPlatformClearance=ball_clearance,
    limitation="Ballistic geometry only; actual character, collision, checkpoint recovery, timing and multiplayer tests remain required.")
out=Path(__file__).resolve().parents[2]/"docs/artifacts/city-run/layout-checks.json"
out.write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!="jumps"},indent=2))
assert not failures,failures
