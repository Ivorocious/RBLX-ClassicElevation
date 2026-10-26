"""City Run route source. Coordinates are Roblox studs: east, up, south."""
import math

REVISION = "C02"
MOVEMENT = {"walkSpeed": 16, "jumpHeight": 7.2, "gravity": 196.2}
CHECKPOINTS = [
    (-170, 8, 250), (-170, 12, 182), (-150, 29, 80), (-150, 69, -125),
    (-92, 82, -244), (116, 82, -244), (205, 82, -38),
    (205, 82, 14), (205, 86, 57), (195, 132, 184),
]
SURFACES, ROUTES, STAIRS = [], {}, []


def surface(name, p, size, section, style="roof", checkpoint=None):
    item = dict(name=name, p=list(p), size=list(size), section=section, style=style)
    if checkpoint is not None:
        item["checkpoint"] = checkpoint
    SURFACES.append(item)
    return name


for index, p in enumerate(CHECKPOINTS):
    size = (28, 1, 32) if index == 0 else (24, 1, 20)
    surface(f"CP{index:02}", p, size, ["Market", "Market", "Climb", "Climb", "Roof", "Roof", "Rail", "Rail", "Station", "Station"][index], "checkpoint", index)


def chain(name, points, section, width=10, gap=4.4, length=15, style="roof"):
    """Place axis-aligned landings with real gaps; turns get full shared landings."""
    route = []
    for leg, (a, b) in enumerate(zip(points, points[1:])):
        dx, dz = b[0]-a[0], b[2]-a[2]
        assert abs(dx) < .001 or abs(dz) < .001, (name, a, b)
        distance = abs(dx+dz)
        count = max(1, round(distance/(length+gap)))
        pitch = distance/count
        span = pitch-gap
        assert span > 2.5, (name, span)
        for i in range(count+1):
            if leg and i == 0:
                previous=next(s for s in SURFACES if s["name"]==route[-1])
                axis=0 if dx else 2
                previous["size"][axis]=max(previous["size"][axis],span)
                continue
            t = i/count
            p = [a[j]+(b[j]-a[j])*t for j in range(3)]
            sz = [span, 1, width] if dx else [width, 1, span]
            if i in (0, count):
                sz[0] = max(sz[0], width)
                sz[2] = max(sz[2], width)
            key = f"{name}_{leg:02}_{i:02}"
            surface(key, p, sz, section, style)
            route.append(key)
    ROUTES[name] = route


def walk(name, a, b, width, section, style="roof"):
    dx, dz = b[0]-a[0], b[2]-a[2]
    assert abs(dx) < .001 or abs(dz) < .001
    p = [(a[i]+b[i])/2 for i in range(3)]
    assert abs(a[1]-b[1]) < .001
    surface(name, p, (abs(dx)+width, 1, abs(dz)+width), section, style)
    return name


def stairs(name, a, b, width, section):
    count = max(1, math.ceil(abs(b[1]-a[1])/.65))
    dx, dz = b[0]-a[0], b[2]-a[2]
    assert abs(dx) < .001 or abs(dz) < .001
    names=[]
    for i in range(count+1):
        p=[a[j]+(b[j]-a[j])*i/count for j in range(3)]
        size=(abs(dx)/count+.2 if dx else width, 1, abs(dz)/count+.2 if dz else width)
        names.append(surface(f"{name}_{i:02}",p,size,section,"stair"))
    ROUTES[name]=names


# Loading decks spread the starting pack before the traffic decision.
chain("Loading", [CHECKPOINTS[0], (-170, 12, 205), CHECKPOINTS[1]], "Market", 15, 4, 15, "deck")
walk("CarCrossing", (-170, 12, 182), (-170, 12, 146), 16, "Market", "road")
surface("CarExit", (-170, 12, 146), (26, 1, 18), "Market", "checkpoint")
chain("Awnings", [(-170, 12, 146), (-105, 20, 146), (-105, 24, 80), CHECKPOINTS[2]], "Market", 10, 4.2, 15, "awning")

# The long balcony route winds around a tall mural courtyard. X01 cuts its edge.
stairs("ClimbStairs", CHECKPOINTS[2], (-225,36,80),10,"Climb")
chain("ClimbMain", [(-225, 36, 80), (-225, 43, 5), (-120, 50, 5),
    (-120, 55, -55), (-215, 61, -55), (-215, 65, -125), CHECKPOINTS[3]], "Climb", 10, 4.3, 16, "balcony")
chain("X01", [CHECKPOINTS[2], (-150,33,52), (-110,37,52), (-110,65,-125), CHECKPOINTS[3]], "Climb", 3.8, 5.8, 7.8, "sign")

chain("DistrictRoofs", [CHECKPOINTS[3], (-220, 73, -125), (-220, 78, -202),
    (-155, 82, -202), (-155, 82, -244), CHECKPOINTS[4]], "Roof", 11, 4.5, 16, "roof")

# Both routes cross x=-42 and x=42 within the same z swing range.
chain("RoofMainEntry", [CHECKPOINTS[4], (-92,82,-297), (-65,82,-297), (-65,82,-257)], "Roof", 11, 4.3, 15, "work")
walk("BallA_Main", (-65,82,-257), (-20,82,-257), 11, "Roof", "work")
chain("RoofMainMiddle", [(-20,82,-257), (-20,82,-305), (19,82,-305), (19,82,-257)], "Roof", 11, 4.3, 14, "work")
walk("BallB_Main", (19,82,-257), (66,82,-257), 11, "Roof", "work")
chain("RoofGarden", [(66,82,-257), (66,84,-306), (116,84,-306), CHECKPOINTS[5]], "Roof", 11, 4.3, 15, "roof")
chain("X02", [CHECKPOINTS[4], (-92,82,-231), (116,82,-231), CHECKPOINTS[5]], "Roof", 3.5, 6.4, 6.8, "work")

chain("DepotAccess", [CHECKPOINTS[5], (165,82,-244), (165,82,-210)], "Rail", 11, 4.3, 15, "work")
chain("StationaryTrains", [(165,82,-210), (165,82,-96)], "Rail", 10, 4.7, 26, "train")
walk("DepotTransfer",(165,82,-96),(205,82,-96),10,"Rail","work")
chain("DepotExit",[(205,82,-96),CHECKPOINTS[6]],"Rail",10,4.4,15,"work")
walk("TrainCrossing", CHECKPOINTS[6], CHECKPOINTS[7], 12, "Rail", "crossing")
stairs("StationEntry", CHECKPOINTS[7], CHECKPOINTS[8], 12, "Station")
chain("StationMain", [CHECKPOINTS[8], (330,95,57), (330,106,220),
    (245,116,220), (245,125,184), CHECKPOINTS[9]], "Station", 10, 4.4, 15, "stone")
chain("X03", [CHECKPOINTS[8], (195,86,57), CHECKPOINTS[9]], "Station", 3.8, 5.7, 7.3, "scaffold")
walk("FinishApproach", CHECKPOINTS[9], (195,132,226), 24, "Station", "stone")
surface("FinishTerrace", (195,132,242), (74,1,34), "Station", "stone")

HAZARDS = {
    "cars": {"crossing": [-170,12,164], "size":[16,6,7], "speed":40,
        "startX":-350, "endX":50, "intervals":[4.6,5.4,6.1,4.9,5.8], "checkpoint":1},
    "balls": [{"name":f"Ball{c}","pivot":[x,123,-244],"length":38,"radius":6.5,
        "amplitude":.70,"period":6.4,"phase":p,"checkpoint":4} for c,x,p in [("A",-42,0),("B",42,1.1)]],
    "train": {"crossing":[205,82,-12],"size":[114,10,12],"speed":105,
        "startX":-467,"endX":690,"openTime":7,"warningTime":2,"clearanceTime":3.8,"checkpoint":6},
}


def manifest():
    return dict(revision=REVISION, coordinates="Roblox: X east, Y up, Z south", movement=MOVEMENT,
        checkpoints=CHECKPOINTS, surfaces=SURFACES, routes=ROUTES, hazards=HAZARDS,
        finish=[195,132,232], origin=[3500,0,0])


if __name__ == "__main__":
    import json
    print(json.dumps(manifest(), indent=2))
