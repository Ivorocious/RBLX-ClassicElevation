from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import argparse
import hashlib
import json
import re
import time

parser = argparse.ArgumentParser()
parser.add_argument('--phase', type=int, choices=(2, 3), default=2)
phase = parser.parse_args().phase
output = Path(__file__).resolve().parents[3] / f'docs/artifacts/moonlit-citadel/phase{phase}'
output.mkdir(parents=True, exist_ok=True)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, status, data):
        self.send_response(status)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def path_for(self):
        name = self.path.lstrip('/')
        return output / name if re.fullmatch(rf'MC_P{phase}_[a-zA-Z0-9_-]+\.(rbxm|json)', name) else None

    def do_GET(self):
        path = self.path_for()
        self.reply(200, path.read_bytes()) if path and path.is_file() else self.reply(404, b'{}')

    def do_POST(self):
        path = self.path_for()
        length = int(self.headers.get('Content-Length', '0'))
        if not path or not 0 < length <= 24 * 1024 * 1024:
            self.reply(400, b'{}')
            return
        data = self.rfile.read(length)
        if len(data) != length or (path.suffix == '.rbxm' and not data.startswith(b'<roblox!')):
            self.reply(400, b'{}')
            return
        if path.suffix == '.json':
            try:
                json.loads(data)
            except ValueError:
                self.reply(400, b'{}')
                return
        if path.exists() and path.read_bytes() != data:
            self.reply(409, b'{"error":"Preserve existing evidence"}')
            return
        if not path.exists():
            path.write_bytes(data)
        receipt = {'path': str(path), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        path.with_suffix(path.suffix + '.receipt.json').write_text(json.dumps(receipt, indent=2))
        self.reply(200, json.dumps(receipt).encode())


server = HTTPServer(('127.0.0.1', 0), Handler)
server.timeout = 1
print(json.dumps({'port': server.server_port, 'directory': str(output)}), flush=True)
deadline = time.monotonic() + 900
try:
    while time.monotonic() < deadline:
        server.handle_request()
finally:
    server.server_close()
