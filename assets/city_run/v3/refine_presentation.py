from pathlib import Path
p=Path('assets/city_run/v3/build_asset_kit.py');s=p.read_text()
s=s.replace("def gable(self,w,d,h,tile='roof_tile'):","def gable(self,w,d,h,tile='terracotta'):")
needle=' def finish(self,name,family,tier=\'Close\',notes=\'\'):'
blob=""" def blob(self,p,scale,tile):
  x,y,z=p;sx,sy,sz=scale;n=8;vs=[(x,y,z-sz)]
  for j in range(1,4):
   t=math.pi*j/4
   for i in range(n):a=i*math.tau/n;vs.append((x+sx*math.sin(t)*math.cos(a),y+sy*math.sin(t)*math.sin(a),z-sz*math.cos(t)))
  vs.append((x,y,z+sz));fs=[(0,1+(i+1)%n,1+i)for i in range(n)]
  for j in range(2):
   for i in range(n):fs.append((1+j*n+i,1+j*n+(i+1)%n,1+(j+1)*n+(i+1)%n,1+(j+1)*n+i))
  fs.extend((25,17+i,17+(i+1)%n)for i in range(n));self.add(vs,fs,tile)
"""
s=s.replace(needle,blob+needle)
s=s.replace("g.cyl((-2,0,2.3),1.6,1.8,'leaf',7,.7);g.cyl((1.5,0,2.3),1.8,2.2,'leaflight',7,.9)","g.blob((-2,0,3.2),(1.8,1.3,1.3),'leaf');g.blob((1.5,0,3.4),(2,1.3,1.6),'leaflight')")
s=s.replace("g.cyl(p,r,h,tile,7,.4)","g.blob((p[0],p[1],p[2]+h*.25),(r,r*.8,h*.6),tile)")
s=s.replace("sun.energy=2.4;sun.angle=.08", "sun.energy=2.4;sun.color=(1.0,.86,.71);sun.angle=.14")
p.write_text(s)
p=Path('assets/city_run/v3/render_gallery.py');s=p.read_text()
s=s.replace("baseMat.diffuse_color=(.34,.39,.38,1)","baseMat.diffuse_color=(.34,.39,.38,1);baseMat.use_nodes=True;baseMat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.32,.34,.30,1)")
s=s.replace("markMat.diffuse_color=(.8,.65,.35,1)","markMat.diffuse_color=(.8,.65,.35,1);markMat.use_nodes=True;markMat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.8,.65,.35,1)")
s=s.replace("(0,3.3,12)","(0,3.3,9.8)")
p.write_text(s)
