"""Receive native Studio model backups on loopback and verify their file hashes."""
import argparse
import hashlib
import json
import re
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', type=Path, required=True)
    parser.add_argument('--port', type=int, default=8768)
    args = parser.parse_args()
    root = args.directory.resolve()
    root.mkdir(parents=True, exist_ok=True)

    class Handler(BaseHTTPRequestHandler):
        def respond(self, code, data, content_type='application/json'):
            self.send_response(code)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def file_path(self):
            name = self.path.removeprefix('/')
            if not re.fullmatch(r'[a-z0-9-]+\.rbxm', name):
                return None
            return root / name

        def do_POST(self):
            path = self.file_path()
            length = int(self.headers.get('Content-Length', '0'))
            if path is None or length < 32 or length > 512 * 1024 * 1024:
                self.respond(400, b'{}')
                return
            data = self.rfile.read(length)
            if len(data) != length or not data.startswith(b'<roblox!'):
                self.respond(400, b'{}')
                return
            if path.exists():
                if path.read_bytes() != data:
                    self.respond(409, b'{"error":"existing backup differs"}')
                    return
            else:
                with path.open('xb') as output:
                    output.write(data)
            receipt = {'file': path.name, 'bytes': length,
                       'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
            path.with_suffix('.receipt.json').write_text(json.dumps(receipt, indent=2)+'\n')
            self.respond(200, json.dumps(receipt).encode())

        def do_GET(self):
            path = self.file_path()
            if path is None or not path.is_file():
                self.respond(404, b'{}')
                return
            self.respond(200, path.read_bytes(), 'application/octet-stream')

    print(f'Backup receiver: {root}', flush=True)
    HTTPServer(('127.0.0.1', args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
