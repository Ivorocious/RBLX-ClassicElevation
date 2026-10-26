from pathlib import Path
from http.server import BaseHTTPRequestHandler,HTTPServer
import hashlib,json
root=Path(__file__).resolve().parents[1]
out=root/'docs/artifacts/city-run/v3/stage2';out.mkdir(parents=True,exist_ok=True)
files={f'/{name}':out/name for name in ['source.json','source.rbxm','candidate01.rbxm','candidate02.rbxm','runtime.json','audit01.json','audit02.json']}
class Handler(BaseHTTPRequestHandler):
 def log_message(self,*args):pass
 def reply(self,status,data):
  self.send_response(status);self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
 def do_GET(self):
  p=files.get(self.path)
  if p is None or not p.exists():self.reply(404,b'{}');return
  self.reply(200,p.read_bytes())
 def do_POST(self):
  p=files.get(self.path);n=int(self.headers.get('Content-Length','0'))
  if p is None or not 0<n<32*1024*1024:self.reply(400,b'{}');return
  b=self.rfile.read(n)
  if p.suffix=='.json':json.loads(b)
  if p.suffix=='.rbxm' and not b.startswith(b'<roblox!'):self.reply(400,b'{}');return
  if p.exists() and p.read_bytes()!=b:self.reply(409,b'{}');return
  if not p.exists():p.write_bytes(b)
  self.reply(200,json.dumps({'bytes':n,'sha256':hashlib.sha256(b).hexdigest()}).encode())
s=HTTPServer(('127.0.0.1',0),Handler);print(json.dumps({'port':s.server_port}),flush=True);s.serve_forever()
