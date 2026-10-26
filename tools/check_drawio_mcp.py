"""Verify the installed draw.io server with a local editable diagram."""
import asyncio
import json
from pathlib import Path

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

ROOT = Path(__file__).resolve().parents[1]
DIAGRAM = ROOT / "docs/artifacts/classic-stud-kit/style-plan.drawio"


async def main():
    server = ROOT / ".tools/drawio-mcp/node_modules/@drawio/mcp/src/index.js"
    params = StdioServerParameters(command=r"C:\Program Files\nodejs\node.exe", args=[str(server)])
    async with stdio_client(params) as (reader, writer):
        async with ClientSession(reader, writer) as session:
            init = await session.initialize()
            tools = await session.list_tools()
            print(json.dumps({"server": init.serverInfo.model_dump(), "tools": [t.name for t in tools.tools]}))
            for name, arguments in [
                ("list_pages", {"path": str(DIAGRAM)}),
                ("get_page", {"path": str(DIAGRAM), "page": "0"}),
                ("open_drawio_xml", {"content": DIAGRAM.read_text(encoding="utf-8"), "dark": "false"}),
            ]:
                result = await session.call_tool(name, arguments)
                assert not result.isError, result
                output = ROOT / f"docs/artifacts/classic-stud-kit/drawio-{name}.json"
                output.write_text(result.model_dump_json(indent=2), encoding="utf-8")
                print(f"{name}: OK ({output.name})")


if __name__ == "__main__":
    asyncio.run(main())
