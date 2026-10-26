import pathlib
import re
import xml.etree.ElementTree as ET

package = pathlib.Path(".tools/robloxstudio-mcp/node_modules/@chrrxs/robloxstudio-mcp")
root = ET.parse(package / "studio-plugin/MCPPlugin.rbxmx").getroot()
blocks = []
for item in root.iter("Item"):
    properties = item.find("Properties")
    if properties is None:
        continue
    fields = {field.attrib.get("name"): field.text or "" for field in properties}
    source = fields.get("Source", "")
    if fields.get("Name") != "TestHandlers":
        continue
    for match in list(re.finditer(r"StudioTestService:", source)):
        blocks.append(source[max(0, match.start() - 600):match.start() + 900])
print("\n\n".join(blocks)[:10000])
