from pathlib import Path
from http.server import BaseHTTPRequestHandler, HTTPServer
import hashlib,json
root=Path(__file__).resolve().parents[1]
backup=root/'backups/city-run-owner-edits-2026-09-13-c14'
art=root/'docs/artifacts/city-run'
files={'/before.rbxm':backup/'city-run-before-c14.rbxm','/before.json':art/'C14-before-native-audit.json','/layout.json':art/'C14-live-layout.json','/review.json':art/'C14_05-review-resume-audit.json','/final.rbxm':backup/'city-run-c14-reviewed.rbxm','/final.json':art/'C14_05-reviewed-final-native-audit.json'}
class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args):pass
    def reply(self,status,data):
        self.send_response(status);self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
    def do_GET(self):
        path=files.get(self.path)
        if path is None or not path.is_file():self.reply(404,b'{}');return
        self.reply(200,path.read_bytes())
    def do_POST(self):
        path=files.get(self.path);length=int(self.headers.get('Content-Length','0'))
        if path is None or path.suffix not in ('.json','.rbxm') or not 1<=length<=48*1024*1024:self.reply(400,b'{}');return
        data=self.rfile.read(length)
        if len(data)!=length:self.reply(400,b'{}');return
        if path.suffix=='.rbxm' and not data.startswith(b'<roblox!'):self.reply(400,b'{}');return
        if path.suffix=='.json':json.loads(data)
        if path.exists() and path.read_bytes()!=data:self.reply(409,b'{"error":"Existing file differs"}');return
        if not path.exists():
            with path.open('xb') as f:f.write(data)
        receipt={'file':path.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
        if path.suffix=='.rbxm':path.with_suffix('.rbxm.receipt.json').write_text(json.dumps(receipt,indent=2))
        self.reply(200,json.dumps(receipt).encode())
server=HTTPServer(('127.0.0.1',0),Handler)
print(json.dumps({'port':server.server_port,'scope':'C14 whitelisted backup and audit files'}),flush=True)
server.serve_forever()
