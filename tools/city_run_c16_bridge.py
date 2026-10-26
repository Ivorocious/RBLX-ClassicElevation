from pathlib import Path
from http.server import BaseHTTPRequestHandler,HTTPServer
import base64,json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/artifacts/city-run/c16'
OUT.mkdir(parents=True,exist_ok=True)
READ={
'/manifest':ROOT/'assets/city_run/manifest_C16.json',
'/patch':ROOT/'src/ServerStorage/CourseBuilders/CityRun/C16Patch.luau',
'/conveyor':ROOT/'src/ServerStorage/CourseBuilders/CityRun/Conveyors.luau',
'/runtime':ROOT/'src/ServerStorage/CourseBuilders/CityRun/Runtime.luau',
'/physics':ROOT/'tools/run_city_run_c16_physics.luau',
}
class Handler(BaseHTTPRequestHandler):
 def log_message(self,*args):pass
 def send(self,code,data):
  self.send_response(code);self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
 def do_GET(self):
  p=READ.get(self.path)
  if not p or not p.is_file():self.send(404,b'{}');return
  self.send(200,p.read_bytes())
 def do_POST(self):
  n=self.path.lstrip('/');length=int(self.headers.get('Content-Length','0'))
  if not re.fullmatch(r'[A-Za-z0-9_-]+\.(json|png|rbxm)',n) or not 0<length<30*1024*1024:self.send(400,b'{}');return
  d=self.rfile.read(length)
  if n.endswith('.json'):json.loads(d)
  else:d=base64.b64decode(d,validate=True)
  p=OUT/n
  if p.exists() and p.read_bytes()!=d:self.send(409,b'{}');return
  p.write_bytes(d);self.send(200,json.dumps({'path':str(p),'bytes':len(d)}).encode())
server=HTTPServer(('127.0.0.1',0),Handler)
print(server.server_port,flush=True)
server.serve_forever()
