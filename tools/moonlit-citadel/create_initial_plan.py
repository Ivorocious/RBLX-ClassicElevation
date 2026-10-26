"""Create the first editable course proposal and matching schematic previews."""

from pathlib import Path
import json
import math
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/artifacts/moonlit-citadel"
WIDTH, HEIGHT = 1600, 1120
FONT_DIR = Path("C:/Windows/Fonts")
COLORS = {"normal": "#287683", "expert": "#AC6434", "checkpoint": "#42765D", "hazard": "#A14954"}


def font(size, bold=False):
    return ImageFont.truetype(str(FONT_DIR / ("segoeuib.ttf" if bold else "segoeui.ttf")), size)


def add_node(nodes, node_id, text, box, kind="section"):
    nodes.append({"id": node_id, "text": text, "box": box, "kind": kind})


def make_pages():
    nodes = []
    rows = [
        ("start", "START\nGate approach", 100, "start"),
        ("s1", "S1 · Gatehouse\nCounterweight bridge", 220, "hazard"),
        ("cp1", "CP01 · Gate exit", 340, "checkpoint"),
        ("s2", "S2 · Lantern courtyard\nTerraces / turning jumps", 460, "section"),
        ("cp2", "CP02 · Gallery entry", 580, "checkpoint"),
        ("s3", "S3 · Stained-glass gallery\nStaggered balconies", 700, "section"),
        ("cp3", "CP03 · Roof entry", 820, "checkpoint"),
    ]
    for node_id, label, y, kind in rows:
        add_node(nodes, node_id, label, (130, y, 450, 88), kind)
    for node_id, label, y, kind in [
        ("s4", "S4 · Rooftops\nDirectional ridge sequence", 100, "section"),
        ("merge2", "Shared bell refuge\nBoth routes rejoin here", 340, "checkpoint"),
        ("bell", "S4 · Bell crossing\nRead swing / wait / cross", 460, "hazard"),
        ("cp4", "CP04 · Tower exit", 580, "checkpoint"),
        ("s5", "S5 · Crown approach\nHigh arcade / final ascent", 700, "section"),
        ("finish", "FINISH · Crown terrace\nSafe panoramic outlook", 820, "finish"),
    ]:
        add_node(nodes, node_id, label, (940, y, 520, 88), kind)
    add_node(nodes, "e1", "E1 · Fountain rim\nPrecision diagonal\nRejoin before CP02", (630, 455, 250, 124), "expert")
    add_node(nodes, "e2", "E2 · Roof shortcut\nNarrow turning ridges", (1180, 220, 280, 88), "expert")
    add_node(nodes, "normalroof", "Normal roof line\nLonger / broader", (850, 220, 280, 88), "section")
    edges = [(a, b, "normal") for a, b in zip([r[0] for r in rows], [r[0] for r in rows][1:])]
    edges += [("s2", "e1", "expert"), ("e1", "cp2", "expert"), ("cp3", "s4", "normal"),
              ("s4", "normalroof", "normal"), ("normalroof", "merge2", "normal"),
              ("s4", "e2", "expert"), ("e2", "merge2", "expert"),
              ("merge2", "bell", "normal"), ("bell", "cp4", "normal"),
              ("cp4", "s5", "normal"), ("s5", "finish", "normal")]
    flow = {"id": "mc-l01-flow", "name": "Route and branches", "nodes": nodes, "edges": edges,
            "title": "MOONLIT CITADEL  /  ROUTE AND BRANCHES",
            "subtitle": "MC-L01 · Point-to-point ascent · Proposed mechanics · Schematic, not to scale",
            "footer": "Teal: main route   ·   Ochre: expert branch   ·   Green: checkpoint/refuge   ·   Red: moving encounter\nCP03 continues to the top of the right column. Both branches retain the required section and shared hazards."}

    nodes = []
    add_node(nodes, "s1", "S1 · GATEHOUSE\nLowest arrival\nBridge over moat", (140, 760, 330, 145), "hazard")
    add_node(nodes, "s2", "S2 · LANTERN COURTYARD\nFountain / terraces / arcades\nOpen central space", (470, 510, 390, 170))
    add_node(nodes, "s3", "S3 · GALLERY\nEast wing / rising balconies\nOpen arches toward court", (1070, 510, 390, 170))
    add_node(nodes, "s4", "S4 · ROOFS + BELL TOWER\nNortheast / higher\nShared bell after roof routes", (1040, 180, 420, 170), "hazard")
    add_node(nodes, "s5", "S5 · CROWN TERRACE\nNorthwest / highest\nFinish + view back over journey", (330, 180, 440, 170), "finish")
    add_node(nodes, "e1", "E1 · Fountain rim\nWithin S2", (520, 700, 260, 90), "expert")
    add_node(nodes, "e2", "E2 · Roof ridges\nWithin S4\nBefore shared bell", (790, 370, 250, 105), "expert")
    add_node(nodes, "valley", "OPEN VALLEY\nWest + south\nDistant scenery beyond castle", (60, 430, 320, 150), "context")
    edges = [("s1", "s2", "normal"), ("s2", "s3", "normal"), ("s3", "s4", "normal"), ("s4", "s5", "normal")]
    spatial = {"id": "mc-l01-spatial", "name": "Castle relationships", "nodes": nodes, "edges": edges,
               "title": "MOONLIT CITADEL  /  CASTLE RELATIONSHIPS",
               "subtitle": "North ↑ · West ← · MC-L01 · Relative arrangement and height only; no stud dimensions",
               "footer": "Camera A: southwest toward northeast, elevated three-quarter view. The castle rises around the court.\nMoon / clouds / stars: future Sky imagery. Nearby walls / roofs / gardens: physical scenery. PNG is a source-data preview."}
    return [flow, spatial]


def palette(kind):
    return {
        "section": ("#E5EAF3", "#566884"), "expert": ("#F2E4D8", COLORS["expert"]),
        "checkpoint": ("#E3EDE5", COLORS["checkpoint"]), "hazard": ("#F1E1E5", COLORS["hazard"]),
        "start": ("#E1EAED", COLORS["normal"]), "finish": ("#EFE8CC", "#8B7633"),
        "context": ("#E9E7E2", "#87847D"),
    }[kind]


def endpoints(a, b):
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    ac, bc = (ax + aw / 2, ay + ah / 2), (bx + bw / 2, by + bh / 2)
    dx, dy = bc[0] - ac[0], bc[1] - ac[1]
    ta = min(aw / (2 * abs(dx)) if dx else float("inf"), ah / (2 * abs(dy)) if dy else float("inf"))
    tb = min(bw / (2 * abs(dx)) if dx else float("inf"), bh / (2 * abs(dy)) if dy else float("inf"))
    return (ac[0] + ta * dx, ac[1] + ta * dy), (bc[0] - tb * dx, bc[1] - tb * dy)


def render(page, path):
    canvas = Image.new("RGB", (WIDTH, HEIGHT), "#F7F5EF")
    draw = ImageDraw.Draw(canvas)
    draw.text((55, 25), page["title"], font=font(29, True), fill="#26324A")
    draw.text((55, 65), page["subtitle"], font=font(20), fill="#5C6572")
    lookup = {n["id"]: n for n in page["nodes"]}
    for source, target, kind in page["edges"]:
        a, b = endpoints(lookup[source]["box"], lookup[target]["box"])
        if source == "cp3" and target == "s4":
            a, b = (355, 908), (1460, 144)
            points = [a, (355, 940), (1510, 940), (1510, 144), b]
        else:
            points = [a, b]
        draw.line(points, fill=COLORS[kind], width=5)
        angle = math.atan2(b[1] - points[-2][1], b[0] - points[-2][0])
        arrow = [b, (b[0] - 15 * math.cos(angle - .5), b[1] - 15 * math.sin(angle - .5)),
                 (b[0] - 15 * math.cos(angle + .5), b[1] - 15 * math.sin(angle + .5))]
        draw.polygon(arrow, fill=COLORS[kind])
    for node in page["nodes"]:
        x, y, w, h = node["box"]
        fill, stroke = palette(node["kind"])
        draw.rounded_rectangle((x, y, x + w, y + h), radius=12, fill=fill, outline=stroke, width=3)
        lines = node["text"].splitlines()
        size = 22 if w > 300 else 20
        top = y + (h - len(lines) * (size + 5)) / 2
        for i, line in enumerate(lines):
            chosen = font(size, i == 0)
            bbox = draw.textbbox((0, 0), line, font=chosen)
            if bbox[2] - bbox[0] > w - 20:
                raise ValueError(f"Label does not fit {node['id']}: {line}")
            draw.text((x + (w - bbox[2]) / 2, top + i * (size + 5)), line, font=chosen, fill="#293347")
    draw.line((55, 975, WIDTH - 55, 975), fill="#D3D1C9", width=2)
    draw.multiline_text((55, 995), page["footer"], font=font(20), spacing=9, fill="#535C68")
    canvas.save(path)


def native_page(container, page):
    diagram = ET.SubElement(container, "diagram", id=page["id"], name=page["name"])
    model = ET.SubElement(diagram, "mxGraphModel", dx=str(WIDTH), dy=str(HEIGHT), grid="1", gridSize="10",
                          page="1", pageScale="1", pageWidth=str(WIDTH), pageHeight=str(HEIGHT), background="#F7F5EF")
    root = ET.SubElement(model, "root")
    ET.SubElement(root, "mxCell", id="0")
    ET.SubElement(root, "mxCell", id="1", parent="0")
    for label_id, value, y, size in [("title", page["title"], 20, 27), ("subtitle", page["subtitle"], 60, 19),
                                    ("footer", page["footer"], 990, 19)]:
        cell = ET.SubElement(root, "mxCell", id=label_id, value=value, vertex="1", parent="1",
                             style=f"text;html=0;whiteSpace=wrap;align=left;fontSize={size};fontColor=#293347;")
        ET.SubElement(cell, "mxGeometry", x="55", y=str(y), width="1490", height="80" if label_id == "footer" else "38", **{"as": "geometry"})
    for node in page["nodes"]:
        fill, stroke = palette(node["kind"])
        cell = ET.SubElement(root, "mxCell", id=node["id"], value=node["text"], vertex="1", parent="1",
                             style=f"rounded=1;whiteSpace=wrap;html=0;fillColor={fill};strokeColor={stroke};strokeWidth=2;fontSize=22;fontColor=#293347;")
        ET.SubElement(cell, "mxGeometry", **dict(zip(("x", "y", "width", "height"), map(str, node["box"]))), **{"as": "geometry"})
    for i, (source, target, kind) in enumerate(page["edges"]):
        routing = "exitX=0.5;exitY=1;entryX=1;entryY=0.5;" if source == "cp3" and target == "s4" else ""
        cell = ET.SubElement(root, "mxCell", id=f"edge-{i}", source=source, target=target, edge="1", parent="1",
                             style=f"edgeStyle=orthogonalEdgeStyle;rounded=0;html=0;endArrow=block;endFill=1;strokeWidth=3;strokeColor={COLORS[kind]};{routing}")
        geometry = ET.SubElement(cell, "mxGeometry", relative="1", **{"as": "geometry"})
        if routing:
            points = ET.SubElement(geometry, "Array", **{"as": "points"})
            for x, y in [(355, 940), (1510, 940), (1510, 144)]:
                ET.SubElement(points, "mxPoint", x=str(x), y=str(y))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    targets = [OUT / "moonlit-citadel.drawio", OUT / "route-flow-l01.png", OUT / "castle-relationships-l01.png"]
    if any(p.exists() for p in targets):
        raise SystemExit("An initial plan output already exists; preserve manual edits and create a versioned revision.")
    pages = make_pages()
    mxfile = ET.Element("mxfile", host="app.diagrams.net", version="29.0.0")
    for page, png in zip(pages, targets[1:]):
        native_page(mxfile, page)
        render(page, png)
    ET.indent(mxfile, space="  ")
    ET.ElementTree(mxfile).write(targets[0], encoding="utf-8", xml_declaration=True)
    parsed = ET.parse(targets[0])
    summary = []
    for diagram in parsed.findall("diagram"):
        cells = diagram.findall(".//mxCell")
        ids = [cell.attrib["id"] for cell in cells]
        assert len(ids) == len(set(ids)), "Duplicate native IDs"
        edges = [cell for cell in cells if cell.get("edge") == "1"]
        assert all(cell.get("source") in ids and cell.get("target") in ids for cell in edges), "Broken connector"
        summary.append({"page": diagram.get("name"), "nativeCells": len(cells), "connectors": len(edges)})
    print(json.dumps({"pages": summary, "outputs": [str(p) for p in targets], "previewSource": "same generator data; not draw.io editor rendering"}))


if __name__ == "__main__":
    main()
