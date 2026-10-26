"""Create the MC-L02 editable blueprint and previews from the same layout data."""

from collections import defaultdict
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

from create_initial_plan import font


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/artifacts/moonlit-citadel"
WIDTH, HEIGHT = 1900, 1300
BG, INK, MUTED = "#F5F3EE", "#243149", "#586477"
PALETTE = {
    "normal": ("#E2ECEF", "#28717A"),
    "expert": ("#F2E3D6", "#A75A2D"),
    "checkpoint": ("#E0EBDF", "#4A7753"),
    "hazard": ("#E9E2F2", "#715388"),
    "finish": ("#F2E9CE", "#8E732F"),
    "context": ("#E7E7E6", "#A1A6AE"),
    "note": ("#F5F3EE", "#D0D4D9"),
}


def node(items, identity, text, box, kind="normal", size=22, align="center"):
    items.append(dict(id=identity, text=text, box=box, kind=kind, size=size, align=align))


def edge(items, source, target, kind="normal", via=None):
    items.append(dict(source=source, target=target, kind=kind, via=via or []))


def make_pages():
    nodes, edges = [], []
    node(nodes, "start", "START / S0\nGate court · 20 racers", (110, 200, 420, 95))
    node(nodes, "h1_intro", "H1 · STONE-ARCH CLIMB\nShared curved supports\nFirst turns and rising landings", (110, 355, 420, 120), "hazard")
    node(nodes, "cp01", "CP01 · Arch rest terrace", (140, 535, 360, 60), "checkpoint")
    node(nodes, "arch_n", "NORMAL\nLonger outer turns\nBroader landings", (65, 675, 225, 125))
    node(nodes, "arch_e", "EXPERT E1\nDiagonal inner arches\nTighter turning jumps", (355, 675, 245, 125), "expert", 21)
    node(nodes, "cp02", "CP02 · Gallery entrance\nBoth arch lines rejoin", (140, 865, 360, 85), "checkpoint")

    node(nodes, "h2_entry", "H2 · LANTERN PENDULUMS\nOne gallery / three swing bands\nBoth lines face the same lanterns", (730, 355, 430, 120), "hazard", 21)
    node(nodes, "lantern_n", "NORMAL\nOffset wall ledges\nLarger safe recesses\nOne swing at a time", (680, 565, 245, 150), size=21)
    node(nodes, "lantern_e", "EXPERT E2\nCentral stone islands\nLonger aimed transfers\nSmaller safe perches", (990, 565, 245, 150), "expert", 21)
    node(nodes, "cp03", "CP03 · Machinery entrance\nClear of both swing and lift travel", (750, 840, 390, 90), "checkpoint", 21)
    node(nodes, "gallery_note", "Every lantern has a readable approach.\nWaiting places stay outside its full sweep.\nFalls or contact return to the saved CP.", (680, 980, 555, 85), "note", 20)

    node(nodes, "h3_lower", "H3 · COUNTERWEIGHT ASCENT\nShared lower lift stage\nParallel boarding bays / fixed exits", (1370, 205, 430, 120), "hazard", 21)
    node(nodes, "cp04", "CP04 · Mid-ascent cross-gallery\nShared fixed landing", (1400, 385, 370, 85), "checkpoint", 21)
    node(nodes, "counter_n", "NORMAL\nUpper balcony transfers\nBroader boarding ledges\nLonger ride and approach", (1320, 555, 250, 150), size=20)
    node(nodes, "counter_e", "EXPERT E3\nRaised brace approach\nBoard later / exit earlier\nPrecise moving transfer", (1630, 555, 230, 150), "expert", 20)
    node(nodes, "upper_merge", "Shared upper exit\nBoth lines complete the upper lift", (1400, 785, 370, 85), "normal", 21)
    node(nodes, "finish", "S4 · CROWN APPROACH + FINISH\nShort final climb / open crown terrace\nOne lap ends here", (1370, 960, 430, 110), "finish", 21)

    for a, b in [("start", "h1_intro"), ("h1_intro", "cp01"), ("cp01", "arch_n"),
                 ("arch_n", "cp02"), ("h2_entry", "lantern_n"), ("lantern_n", "cp03"),
                 ("h3_lower", "cp04"), ("cp04", "counter_n"), ("counter_n", "upper_merge"),
                 ("upper_merge", "finish")]:
        edge(edges, a, b)
    for a, b in [("cp01", "arch_e"), ("arch_e", "cp02"), ("h2_entry", "lantern_e"),
                 ("lantern_e", "cp03"), ("cp04", "counter_e"), ("counter_e", "upper_merge")]:
        edge(edges, a, b, "expert")
    edge(edges, "cp02", "h2_entry", via=[(635, 907), (635, 415)])
    edge(edges, "cp03", "h3_lower", via=[(1280, 885), (1280, 265)])

    node(nodes, "pacing", "NOMINAL PLANNING BUDGET     Gate 20s / 10s     ·     Arches 90s / 45s     ·     Lanterns 70s / 30s     ·     Counterweights 100s / 50s     ·     Crown 20s / 15s",
         (60, 1130, 1780, 60), "note", 20)
    node(nodes, "timing_total", "Average / Expert totals: 5:00 / 2:30. Targets, not measured runs. All eight branch combinations retain the three signatures and CP01 → CP02 → CP03 → CP04.",
         (60, 1200, 1780, 40), "note", 19)
    flow = dict(id="mc-l02-flow", name="01 Route and choices", nodes=nodes, edges=edges,
                title="MOONLIT CITADEL  /  PHASE 0 BLUEPRINT",
                subtitle="MC-B04 / MC-L02 · Proposed route details · 20 racers · Point-to-point / one lap · Schematic, not to scale",
                headings=[("GATE + STONE ARCHES", 90), ("STAINED-GLASS GALLERY", 700), ("COUNTERWEIGHTS + CROWN", 1335)])

    nodes, edges = [], []
    node(nodes, "keep", "MAIN GOTHIC KEEP\nLarge illuminated south window\nCrown terrace above", (355, 380, 315, 350), "context", 21)
    node(nodes, "gate", "S0 · GATE COURT\nSouthwest / lowest\n20-racer starting space", (195, 930, 305, 115), size=21)
    node(nodes, "arches", "S1 / H1 · ARCHES\nWest side / rising\nCP01 halfway up", (90, 485, 235, 155), "hazard", 21)
    node(nodes, "gallery", "S2 / H2 · GALLERY\nSouth / east face\nCP02 entry → CP03 exit", (570, 765, 335, 115), "hazard", 21)
    node(nodes, "counter", "S3 / H3 · COUNTERWEIGHTS\nEast / northeast side\nCP04 at mid-ascent", (640, 230, 335, 120), "hazard", 20)
    node(nodes, "crown", "S4 · CROWN FINISH\nAbove the central keep\nLook back toward the start", (380, 400, 270, 115), "finish", 20)
    node(nodes, "south_refuge", "Raised front gallery\nConnects arches to lanterns", (90, 790, 420, 75), "note", 20)
    edge(edges, "gate", "arches", via=[(70, 990), (70, 560)])
    edge(edges, "arches", "gallery", via=[(205, 745), (510, 745), (510, 825)])
    edge(edges, "gallery", "counter", via=[(990, 825), (990, 290)])
    edge(edges, "counter", "crown", via=[(810, 185), (515, 185)])
    node(nodes, "compass", "NORTH ↑\nEAST →", (95, 220, 175, 70), "note", 20)
    node(nodes, "placement_note", "LEFT: relative placement from above. Overlapping boxes represent different heights.\nRoutes wrap around the keep; no direct gate-to-crown connection is planned.",
         (70, 1090, 930, 85), "note", 20)

    bands = [
        ("band4", "CROWN  +140 to +150\nShort final climb / finish", 220, "finish"),
        ("band3", "COUNTERWEIGHTS  +72 to +140\nCP04 at +106 / two lift stages", 395, "hazard"),
        ("band2", "LANTERN GALLERY  +52 to +72\nCP02 at entrance / CP03 at exit", 610, "hazard"),
        ("band1", "STONE ARCHES  +12 to +52\nCP01 near +28 / catch ledges", 785, "hazard"),
        ("band0", "GATE COURT  +0 to +12\nBroad start / opening rise", 960, "normal"),
    ]
    for identity, text, y, kind in bands:
        node(nodes, identity, text, (1130, y, 650, 105), kind, 23)
    for a, b in [("band0", "band1"), ("band1", "band2"), ("band2", "band3"), ("band3", "band4")]:
        edge(edges, a, b)
    node(nodes, "traffic", "20-RACER SPACE TO RESERVE\nBroad launch area · passing terraces · separate respawn pockets\nParallel lift boarding · fixed waits outside motion · clear branch merges",
         (1080, 1115, 730, 90), "note", 20)
    node(nodes, "height_note", "RIGHT: proposed height bands in studs above the start. Envelope: about 220 × 190 studs, with 150 studs of playable rise. All dimensions are starting study targets.",
         (70, 1225, 1740, 40), "note", 19)
    spatial = dict(id="mc-l02-space", name="02 Placement and height", nodes=nodes, edges=edges,
                   title="MOONLIT CITADEL  /  PLACEMENT + HEIGHT",
                   subtitle="MC-L02 · Central keep / climbing perimeter · Proposed dimensions · No reachability, crowding or race-time proof",
                   headings=[("CASTLE ARRANGEMENT", 100), ("STARTING HEIGHT STUDY", 1130)])
    return [flow, spatial]


def border_point(box, toward):
    x, y, w, h = box
    cx, cy = x + w / 2, y + h / 2
    dx, dy = toward[0] - cx, toward[1] - cy
    factor = min(w / (2 * abs(dx)) if dx else math.inf,
                 h / (2 * abs(dy)) if dy else math.inf)
    return cx + factor * dx, cy + factor * dy


def route_points(item, lookup):
    a, b = lookup[item["source"]]["box"], lookup[item["target"]]["box"]
    ac, bc = (a[0] + a[2] / 2, a[1] + a[3] / 2), (b[0] + b[2] / 2, b[1] + b[3] / 2)
    via = item["via"]
    return [border_point(a, via[0] if via else bc), *via, border_point(b, via[-1] if via else ac)]


def dashed_line(draw, points, color, width):
    for a, b in zip(points, points[1:]):
        length = math.dist(a, b)
        for offset in range(0, int(length), 19):
            p = min(offset / length, 1)
            q = min((offset + 11) / length, 1)
            draw.line((a[0] + (b[0] - a[0]) * p, a[1] + (b[1] - a[1]) * p,
                       a[0] + (b[0] - a[0]) * q, a[1] + (b[1] - a[1]) * q), fill=color, width=width)


def render(page, target):
    canvas = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(canvas)
    draw.text((60, 30), page["title"], font=font(34, True), fill=INK)
    draw.text((60, 83), page["subtitle"], font=font(22), fill=MUTED)
    draw.line((60, 125, WIDTH - 60, 125), fill="#C7CED5", width=2)
    for label, x in page["headings"]:
        draw.text((x, 145), label, font=font(24, True), fill=INK)
    lookup = {n["id"]: n for n in page["nodes"]}
    # The keep is a background relationship marker, so routes remain visible above it.
    for n in page["nodes"]:
        if n["kind"] == "context":
            draw_node(draw, n)
    for item in page["edges"]:
        points = route_points(item, lookup)
        color = PALETTE[item["kind"]][1]
        if item["kind"] == "expert":
            dashed_line(draw, points, color, 5)
        else:
            draw.line(points, fill=color, width=5)
        a, b = points[-2:]
        angle = math.atan2(b[1] - a[1], b[0] - a[0])
        draw.polygon([b, (b[0] - 17 * math.cos(angle - .48), b[1] - 17 * math.sin(angle - .48)),
                      (b[0] - 17 * math.cos(angle + .48), b[1] - 17 * math.sin(angle + .48))], fill=color)
    for n in page["nodes"]:
        if n["kind"] != "context":
            draw_node(draw, n)
    canvas.save(target)


def draw_node(draw, item):
    x, y, w, h = item["box"]
    fill, stroke = PALETTE[item["kind"]]
    if item["kind"] != "note":
        draw.rounded_rectangle((x, y, x + w, y + h), radius=13, fill=fill, outline=stroke, width=3)
    lines, size = item["text"].splitlines(), item["size"]
    line_height = size + 8
    top = y + (h - len(lines) * line_height) / 2
    assert top >= y, f"Too many lines: {item['id']}"
    for i, line in enumerate(lines):
        face = font(size, i == 0 and item["kind"] != "note")
        bounds = draw.textbbox((0, 0), line, font=face)
        text_width = bounds[2] - bounds[0]
        assert text_width <= w - 16, f"Text exceeds {item['id']}: {line}"
        tx = x + (w - text_width) / 2 if item["align"] == "center" else x + 12
        draw.text((tx, top + i * line_height), line, font=face, fill=INK)


def native_page(container, page):
    diagram = ET.SubElement(container, "diagram", id=page["id"], name=page["name"])
    graph = ET.SubElement(diagram, "mxGraphModel", dx=str(WIDTH), dy=str(HEIGHT),
                          grid="1", gridSize="10", page="1", pageScale="1",
                          pageWidth=str(WIDTH), pageHeight=str(HEIGHT), background=BG)
    root = ET.SubElement(graph, "root")
    ET.SubElement(root, "mxCell", id="0")
    ET.SubElement(root, "mxCell", id="1", parent="0")
    text_nodes = [
        dict(id="title", text=page["title"], box=(60, 28, 1770, 48), kind="note", size=34, align="left"),
        dict(id="subtitle", text=page["subtitle"], box=(60, 80, 1770, 40), kind="note", size=22, align="left"),
    ]
    for i, (label, x) in enumerate(page["headings"]):
        text_nodes.append(dict(id=f"heading-{i}", text=label, box=(x, 140, 530, 40), kind="note", size=24, align="left"))
    for n in text_nodes + page["nodes"]:
        fill, stroke = PALETTE[n["kind"]]
        style = (f"rounded=1;whiteSpace=wrap;html=0;fillColor={fill};strokeColor={stroke};"
                 f"strokeWidth=2;fontFamily=Segoe UI;fontSize={n['size']};fontColor={INK};"
                 f"align={n['align']};verticalAlign=middle;")
        if n["kind"] == "note":
            style += "fillColor=none;strokeColor=none;"
        cell = ET.SubElement(root, "mxCell", id=n["id"], value=n["text"], vertex="1", parent="1", style=style)
        ET.SubElement(cell, "mxGeometry", **dict(zip(("x", "y", "width", "height"), map(str, n["box"]))), **{"as": "geometry"})
    lookup = {n["id"]: n for n in page["nodes"]}
    for i, item in enumerate(page["edges"]):
        points = route_points(item, lookup)
        a, b = lookup[item["source"]]["box"], lookup[item["target"]]["box"]
        exit_x, exit_y = (points[0][0] - a[0]) / a[2], (points[0][1] - a[1]) / a[3]
        entry_x, entry_y = (points[-1][0] - b[0]) / b[2], (points[-1][1] - b[1]) / b[3]
        style = (f"rounded=0;html=0;endArrow=block;endFill=1;strokeWidth=3;"
                 f"strokeColor={PALETTE[item['kind']][1]};dashed={int(item['kind'] == 'expert')};"
                 f"exitX={exit_x};exitY={exit_y};entryX={entry_x};entryY={entry_y};")
        cell = ET.SubElement(root, "mxCell", id=f"edge-{i}", source=item["source"], target=item["target"],
                             edge="1", parent="1", style=style)
        geometry = ET.SubElement(cell, "mxGeometry", relative="1", **{"as": "geometry"})
        if item["via"]:
            array = ET.SubElement(geometry, "Array", **{"as": "points"})
            for x, y in item["via"]:
                ET.SubElement(array, "mxPoint", x=str(x), y=str(y))


def validate(file, pages):
    parsed = ET.parse(file)
    summary = []
    for diagram in parsed.findall("diagram"):
        cells = diagram.findall(".//mxCell")
        identities = [c.get("id") for c in cells]
        assert len(identities) == len(set(identities))
        edges = [c for c in cells if c.get("edge") == "1"]
        assert all(e.get("source") in identities and e.get("target") in identities for e in edges)
        summary.append(dict(page=diagram.get("name"), cells=len(cells), connectors=len(edges)))
    links = defaultdict(list)
    native_edges = parsed.findall("diagram")[0].findall(".//mxCell[@edge='1']")
    expected = {(e["source"], e["target"]) for e in pages[0]["edges"]}
    assert {(e.get("source"), e.get("target")) for e in native_edges} == expected
    for e in native_edges:
        links[e.get("source")].append(e.get("target"))
    paths = []

    def visit(current, chain):
        assert current not in chain, "Route must not loop back into an earlier section."
        chain = chain + [current]
        if current == "finish":
            paths.append(chain)
            return
        assert links[current], f"Route dead end: {current}"
        for next_node in links[current]:
            visit(next_node, chain)

    visit("start", [])
    required = ["h1_intro", "cp01", "cp02", "h2_entry", "cp03", "h3_lower", "cp04", "upper_merge", "finish"]
    assert len(paths) == 8
    for path in paths:
        positions = [path.index(n) for n in required]
        assert positions == sorted(positions)
    assert sum([20, 90, 70, 100, 20]) == 300
    assert sum([10, 45, 30, 50, 15]) == 150
    return dict(pages=summary, branch_combinations=len(paths), required_order=required,
                timing_budget_seconds=dict(average=300, expert=150))


def main():
    files = [OUT / "phase0-blueprint-l02.drawio", OUT / "phase0-route-l02.png", OUT / "phase0-space-l02.png"]
    if any(p.exists() for p in files):
        raise SystemExit("Preserve existing outputs and manual edits; use a new revision for regeneration.")
    pages = make_pages()
    container = ET.Element("mxfile", host="app.diagrams.net", version="29.0.0")
    for page, png in zip(pages, files[1:]):
        native_page(container, page)
        render(page, png)
    ET.indent(container, space="  ")
    ET.ElementTree(container).write(files[0], encoding="utf-8", xml_declaration=True)
    result = validate(files[0], pages)
    result["preview_source"] = "Same generator data; not draw.io editor rendering."
    result["outputs"] = [str(p) for p in files]
    print(json.dumps(result))


if __name__ == "__main__":
    main()
