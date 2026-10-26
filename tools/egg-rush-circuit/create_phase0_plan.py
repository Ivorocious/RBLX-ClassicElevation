"""Generate ER-L03 with frequent jumps along the accepted three-lap route."""

import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/artifacts/egg-rush-circuit"
WIDTH, HEIGHT = 2100, 1160
INK, MUTED, BACKGROUND = "#253A35", "#58685E", "#FBF8EF"
COLORS = {
    "normal": ("#EAF2E3", "#527D43"),
    "expert": ("#FFF0D9", "#AF692C"),
    "checkpoint": ("#DDF0E4", "#287453"),
    "gate": ("#E3EEF2", "#43758A"),
    "context": ("#F5EBCB", "#B69E62"),
    "note": ("#FBF8EF", "#CECBBE"),
    "hazard": ("#FFE3E3", "#D61F2C"),
}


def font(size, bold=False):
    return ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf", size)


def node(page, identity, text, box, kind="normal", size=22, shape="box"):
    page["nodes"].append({"id": identity, "text": text, "box": box, "kind": kind, "size": size, "shape": shape})


def edge(page, source, target, kind="normal", via=None):
    page["edges"].append({"source": source, "target": target, "kind": kind, "via": via or []})


def page(identity, name, title, subtitle):
    return dict(id=identity, name=name, title=title, subtitle=subtitle, nodes=[], edges=[])


def pages():
    flow = page("er-l01-route", "01 Route and choices", "EGG RUSH CIRCUIT / THE LAP", "ER-B11 / ER-L03 · Frequent jumps on small platforms · Same route, three laps and neon-red hazards · Schematic")
    node(flow, "gate", "LAP GATE\n20-racer start\n+0 studs", (55, 300, 155, 130), "gate", 21)
    junctions = [250, 535, 820, 1105, 1390, 1675, 1960]
    checkpoints = {1: "CP1", 2: "CP2", 4: "CP3", 5: "CP4"}
    for index, x in enumerate(junctions):
        checkpoint = checkpoints.get(index)
        radius = 22 if checkpoint else 7
        node(flow, f"j{index}", checkpoint or "", (x-radius, 365-radius, radius*2, radius*2), "checkpoint" if checkpoint else "normal", 17, "ellipse")
    stages = [
        ("S1 / NESTYARD", "Small nest hops\nRed-bar transfers\n+0 to +8 studs"),
        ("S2 / EGG ROLLERS", "Small crate hops\nTwo egg bands\n+8 to +12 studs"),
        ("S3 / SHELLWORKS", "Short shell hops\nUnfolding lips\n+12 to +20 studs"),
        ("S4 / INCUBATOR", "Small tray hops\nMoving side transfer\n+20 to +36 studs"),
        ("S5 / ROOKERY", "Small perch hops\nTail-band jumps\n+36 to +18 studs"),
        ("S6 / RETURN", "Short downhill hops\nRed-bar + gate turn\n+18 to +0 studs"),
    ]
    experts = {
        0: "E1 / RIM SPRINT\nTight, angled transfers\nCuts the outer weave",
        1: "E2 / CHUTE CUT\nSmall turning islands\nCrosses BOTH egg bands",
        2: "E3 / SHELL CROWN\nMoving lip transfers\nRetains shell gaps",
        4: "E4 / ROOST CUT\nLong descending turns\nRetains tail crossing",
    }
    edge(flow, "gate", "j0")
    for index, (title, detail) in enumerate(stages):
        x = 290 + 285 * index
        node(flow, f"s{index+1}", title + "\n" + detail, (x, 285, 215, 160), size=21)
        edge(flow, f"j{index}", f"s{index+1}")
        edge(flow, f"s{index+1}", f"j{index+1}")
        if index in experts:
            node(flow, f"e{index}", experts[index], (x, 540, 215, 175), "expert", 21)
            edge(flow, f"j{index}", f"e{index}", "expert")
            edge(flow, f"e{index}", f"j{index+1}", "expert")
        else:
            text = "SHARED ENCOUNTER\nEveryone completes\nthe tray transfer" if index == 3 else "SHARED FINISH\nShort jump chain\nSafe lap gate"
            node(flow, f"shared{index}", text, (x, 560, 215, 145), "note", 21)
    edge(flow, "j6", "gate", via=[(2025, 365), (2025, 810), (132, 810)])
    node(flow, "reading", "Read left to right. Green is the Normal/shared route; amber branches are optional Expert choices. Every branch rejoins before the next required checkpoint.", (65, 170, 1960, 62), "note", 24, "text")
    node(flow, "laps", "GATE → CP1 → CP2 → CP3 → CP4 → GATE     /     Complete three laps. The final valid return finishes the race.", (250, 830, 1740, 68), "note", 25, "text")
    node(flow, "timing", "PLANNING TARGETS    20 racers    |    Normal 4–6 min total    |    Expert 2–3 min total\nWorking allocation: 100 s / 54 s per lap = 5:00 / 2:42 over three laps. These are design budgets, not measured runs.", (65, 925, 1960, 100), "context", 25)
    node(flow, "rules", "Jump most of the route; short landings. Wider pads only for waits, transfers, recovery, merges and gate. Keep eggs, shells, tray, tail and red hazards.", (65, 1050, 1960, 52), "note", 23, "text")

    space = page("er-l01-space", "02 Placement and heights", "EGG RUSH CIRCUIT / THE HATCHERY", "ER-L03 · Same clockwise loop · Short landing chains with real gaps · North is up")
    node(space, "central", "CENTRAL HATCHERY\nEnormous incubating egg\nNursery windows + pipes\nA landmark seen\nthroughout the lap", (650, 420, 430, 255), "context", 25, "ellipse")
    node(space, "courtyard", "OPEN FRONT COURT\nPassing room + finish view", (640, 720, 430, 110), "context", 24)
    node(space, "gate", "LAP GATE / +0\nStart + finish below the egg", (570, 965, 380, 95), "gate", 24)
    node(space, "s1", "01 / NESTYARD\nSmall nest jump chains\n+0 to +8", (95, 760, 350, 135), size=26)
    node(space, "s2", "02 / EGG ROLLERS\nCrate hops + two egg lanes\n+8 to +12", (110, 335, 370, 135), size=26)
    node(space, "s3", "03 / SHELLWORKS\nShort moving shell lips\n+12 to +20", (675, 185, 365, 140), size=26)
    node(space, "s4", "04 / INCUBATOR RISE\nSmall pads + side transfer\n+20 to +36", (1210, 350, 360, 140), size=25)
    node(space, "s5", "05 / GUARDIAN ROOKERY\nSmall perches + tail band\n+36 to +18", (1210, 715, 360, 145), size=24)
    node(space, "s6", "06 / SHELL SPILL RETURN\nShort jumps + red bar\n+18 to +0", (1110, 960, 400, 115), size=23)
    for source, target, via in [
        ("gate", "s1", [(440, 1010), (280, 965)]),
        ("s1", "s2", [(65, 675), (65, 520)]),
        ("s2", "s3", [(490, 240)]),
        ("s3", "s4", [(1210, 245)]),
        ("s4", "s5", [(1595, 570), (1595, 640)]),
        ("s5", "s6", []),
        ("s6", "gate", []),
    ]:
        edge(space, source, target, via=via)
    for identity, text, box in [
        ("e1", "E1\nRim cut", (470, 780, 150, 90)),
        ("e2", "E2\nChute cut", (505, 365, 130, 100)),
        ("e3", "E3\nShell crown", (780, 330, 180, 75)),
        ("e4", "E4\nRoost cut", (1020, 845, 165, 90)),
    ]:
        node(space, identity, text, box, "expert", 23)
    node(space, "orientation", "N ↑\nW ←   → E\nS ↓", (105, 175, 180, 120), "note", 23, "text")
    node(space, "height", "PLAYABLE HEIGHTS\n\nGate        +0\nNestyard    +0 → +8\nEgg lanes   +8 → +12\nShellworks  +12 → +20\nIncubator   +20 → +36\nRookery     +36 → +18\nReturn      +18 → +0\n\nAll dimensions are\nstarting study targets.", (1680, 190, 340, 460), "note", 25)
    node(space, "hazard-legend", "NEON RED = LETHAL", (1680, 655, 340, 42), "hazard", 20)
    node(space, "traffic", "WIDER PADS ONLY FOR\n\n20-racer launch\nHazard waits\nPassing / branch merges\nTray boarding / receiving\nSeparate respawn pads\nSafe lap/finish gate", (1680, 700, 340, 350), "note", 24)
    node(space, "disclaimer", "Relative placement, not build geometry. Expert cuts remain inside their own districts. The central egg is a landmark, not a shortcut between checkpoints.", (65, 1095, 1970, 45), "note", 22, "text")
    return [flow, space]


def boundary(box, target):
    x, y, w, h = box
    cx, cy = x + w/2, y + h/2
    dx, dy = target[0] - cx, target[1] - cy
    scale = min(w/(2*abs(dx)) if dx else math.inf, h/(2*abs(dy)) if dy else math.inf)
    return cx + dx*scale, cy + dy*scale


def points(item, lookup):
    first, last = lookup[item["source"]]["box"], lookup[item["target"]]["box"]
    a, b = (first[0]+first[2]/2, first[1]+first[3]/2), (last[0]+last[2]/2, last[1]+last[3]/2)
    via = item["via"]
    return [boundary(first, via[0] if via else b), *via, boundary(last, via[-1] if via else a)]


def lines(draw, text, chosen_font, width):
    result = []
    for paragraph in text.split("\n"):
        current = ""
        for word in paragraph.split():
            candidate = (current + " " + word).strip()
            if current and draw.textlength(candidate, font=chosen_font) > width:
                result.append(current)
                current = word
            else:
                current = candidate
        result.append(current)
    return result


def render(current, filename):
    image = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((65, 32), current["title"], font=font(42, True), fill=INK)
    draw.text((65, 98), current["subtitle"], font=font(24), fill=MUTED)
    draw.line((65, 145, WIDTH-65, 145), fill="#D7D8C8", width=2)
    lookup = {item["id"]: item for item in current["nodes"]}
    for item in current["edges"]:
        route = points(item, lookup)
        color = COLORS[item["kind"]][1]
        for a, b in zip(route, route[1:]):
            if item["kind"] == "expert":
                length = math.dist(a, b)
                for start in range(0, math.ceil(length), 20):
                    p, q = min(start/length, 1), min((start+12)/length, 1)
                    draw.line((a[0]+(b[0]-a[0])*p, a[1]+(b[1]-a[1])*p, a[0]+(b[0]-a[0])*q, a[1]+(b[1]-a[1])*q), fill=color, width=4)
            else:
                draw.line((*a, *b), fill=color, width=5)
        a, b = route[-2:]
        angle = math.atan2(b[1]-a[1], b[0]-a[0])
        draw.polygon([b, (b[0]-17*math.cos(angle-.45), b[1]-17*math.sin(angle-.45)), (b[0]-17*math.cos(angle+.45), b[1]-17*math.sin(angle+.45))], fill=color)
    for item in current["nodes"]:
        x, y, w, h = item["box"]
        fill, stroke = COLORS[item["kind"]]
        if item["shape"] == "ellipse":
            draw.ellipse((x, y, x+w, y+h), fill=fill, outline=stroke, width=3)
        elif item["shape"] != "text":
            draw.rounded_rectangle((x, y, x+w, y+h), radius=14, fill=fill, outline=stroke, width=2)
        if not item["text"]:
            continue
        chosen = font(item["size"])
        rows = lines(draw, item["text"], chosen, w-20)
        step = item["size"] + 7
        assert len(rows)*step <= h+6, f"Text overflows {current['id']}/{item['id']}"
        top = y + (h-len(rows)*step)/2
        for index, row in enumerate(rows):
            width = draw.textlength(row, font=chosen)
            draw.text((x+(w-width)/2, top+index*step), row, font=chosen, fill=INK)
    image.save(filename)


def native(current):
    model = ET.Element("mxGraphModel", grid="1", gridSize="10", guides="1", page="1", pageScale="1", pageWidth=str(WIDTH), pageHeight=str(HEIGHT), adaptiveColors="auto")
    root = ET.SubElement(model, "root")
    ET.SubElement(root, "mxCell", id="0")
    ET.SubElement(root, "mxCell", id="1", parent="0")
    decorations = [
        dict(id="page-title", text=current["title"], box=(65, 32, 1970, 60), kind="note", size=42, shape="text"),
        dict(id="page-subtitle", text=current["subtitle"], box=(65, 98, 1970, 36), kind="note", size=24, shape="text"),
    ]
    for item in decorations + current["nodes"]:
        fill, stroke = COLORS[item["kind"]]
        shape = "ellipse;" if item["shape"] == "ellipse" else "rounded=1;arcSize=12;"
        if item["shape"] == "text":
            shape, fill, stroke = "text;", "none", "none"
        style = f"{shape}whiteSpace=wrap;html=0;fillColor={fill};strokeColor={stroke};fontColor={INK};fontFamily=Segoe UI;fontSize={item['size']};spacing=8;"
        cell = ET.SubElement(root, "mxCell", id=item["id"], value=item["text"], style=style, vertex="1", parent="1")
        x, y, w, h = item["box"]
        ET.SubElement(cell, "mxGeometry", x=str(x), y=str(y), width=str(w), height=str(h), attrib={"as": "geometry"})
    for index, item in enumerate(current["edges"]):
        color = COLORS[item["kind"]][1]
        style = f"edgeStyle=none;rounded=0;endArrow=block;strokeWidth=3;strokeColor={color};dashed={int(item['kind']=='expert')};"
        cell = ET.SubElement(root, "mxCell", id=f"edge-{index}", edge="1", parent="1", source=item["source"], target=item["target"], style=style)
        geometry = ET.SubElement(cell, "mxGeometry", relative="1", attrib={"as": "geometry"})
        if item["via"]:
            points_node = ET.SubElement(geometry, "Array", attrib={"as": "points"})
            for x, y in item["via"]:
                ET.SubElement(points_node, "mxPoint", x=str(x), y=str(y))
    ids = {cell.attrib["id"] for cell in root}
    assert len(ids) == len(root)
    for item in current["edges"]:
        assert item["source"] in ids and item["target"] in ids
    return model


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    plans = pages()
    document = ET.Element("mxfile", host="app.diagrams.net", type="device")
    for current, filename in zip(plans, ["route-preview.png", "spatial-preview.png"]):
        diagram = ET.SubElement(document, "diagram", id=current["id"], name=current["name"])
        diagram.append(native(current))
        render(current, OUT / filename)
    ET.indent(document, space="  ")
    ET.ElementTree(document).write(OUT / "egg-rush-circuit.drawio", encoding="utf-8", xml_declaration=True)
    report = {"layout": "ER-L03", "priorRouteOrder": "ER-L01 unchanged", "ownerAmendment": "Frequent jumping on multiple smaller platforms; preserve real gaps and neon-red kill blocks", "ordinaryLandingRule": "Short forward length, brief alignment, then another jump; no routine 1-2-second walking slabs", "widerPadPurposes": ["start/finish", "hazard wait", "tray transfer", "recovery", "passing/merge"], "killBlockSections": ["S1", "S3", "S4", "S6"], "pages": [{"name": item["name"], "nodes": len(item["nodes"]), "edges": len(item["edges"])} for item in plans], "previewSource": "Shared generator data, not a draw.io editor render", "acceptedLaps": 3, "routeAcceptanceDate": "2026-10-20", "normalSecondsPerLap": 100, "expertSecondsPerLap": 54, "normalTotalSeconds": 300, "expertTotalSeconds": 162, "runtimeEvidence": False}
    (OUT / "plan-checks.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
