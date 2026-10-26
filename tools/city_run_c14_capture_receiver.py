from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import base64, hashlib, json, re
root=Path(__file__).resolve().parents[1]/'docs/artifacts/city-run/c14-final-captures'
root.mkdir(exist_ok=True)
class Handler(BaseHTTPRequestHandler):
 def log_message(self,*args):pass
 def do_POST(self):
  name=self.path.lstrip('/')
  length=int(self.headers.get('Content-Length','0'))
  if not re.fullmatch(r'C14_05_[A-Za-z0-9_]+',name) or not 1<=length<=12*1024*1024:
   self.send_error(400);return
  data=base64.b64decode(self.rfile.read(length),validate=True)
  ext='.png' if data.startswith(bytes([137,80,78,71])) else '.jpg' if data.startswith(bytes([255,216])) else None
  if ext is None:self.send_error(400);return
  path=root/(name+ext)
  if path.exists() and path.read_bytes()!=data:self.send_error(409);return
  if not path.exists():path.write_bytes(data)
  response=json.dumps({'path':str(path),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}).encode()
  self.send_response(200);self.send_header('Content-Length',str(len(response)));self.end_headers();self.wfile.write(response)
server=HTTPServer(('127.0.0.1',0),Handler)
print(json.dumps({'port':server.server_port,'purpose':'Save unchanged C14_05 MCP screenshot bytes'}),flush=True)
server.serve_forever()
