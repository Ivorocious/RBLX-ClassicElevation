"""Short-lived loopback receiver for this course's verified recovery files."""
import argparse
import hashlib
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import re
import threading

DIRECTORY = Path(__file__).resolve().parents[4] / 'docs/artifacts/moonlit-citadel/phase3/closeout-20261014/before'


class Receiver(BaseHTTPRequestHandler):
    def reply(self, status, data):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        name = self.path.removeprefix('/')
        if name == 'status':
            self.reply(200, b'{"ownedReceiver":"moonlit_closeout_20261014"}')
        elif re.fullmatch(r'closeout_[a-z0-9_]+\.json', name) and (DIRECTORY / name).is_file():
            self.reply(200, (DIRECTORY / name).read_bytes())
        else:
            self.reply(404, b'{}')

    def do_POST(self):
        name = self.path.removeprefix('/')
        if name == "quit":
            self.reply(200, b'{"stopping":true}')
            threading.Thread(target=self.server.shutdown, daemon=True).start()
            return
        length = int(self.headers.get('Content-Length', '0'))
        if not re.fullmatch(r'closeout_[a-z0-9_]+\.(rbxm|json)', name) or not 0 < length <= 30_000_000:
            self.reply(400, b'{"error":"invalid recovery request"}')
            return
        data = self.rfile.read(length)
        target = DIRECTORY / name
        if len(data) != length or target.exists():
            self.reply(409, b'{"error":"recovery file incomplete or already exists"}')
            return
        with target.open('xb') as output:
            output.write(data)
        receipt = {'name': name, 'bytes': length, 'sha256': hashlib.sha256(data).hexdigest()}
        encoded = json.dumps(receipt).encode()
        target.with_name(target.name + '.receipt.json').write_bytes(encoded)
        self.reply(200, encoded)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, required=True)
    parser.add_argument('--ttl', type=int, default=1200)
    args = parser.parse_args()
    DIRECTORY.mkdir(parents=True, exist_ok=True)
    server = HTTPServer(('127.0.0.1', args.port), Receiver)
    timer = threading.Timer(args.ttl, server.shutdown)
    timer.daemon = True
    timer.start()
    print(json.dumps({'ready': True, 'port': args.port, 'directory': str(DIRECTORY)}), flush=True)
    try:
        server.serve_forever()
    finally:
        timer.cancel()
        server.server_close()
