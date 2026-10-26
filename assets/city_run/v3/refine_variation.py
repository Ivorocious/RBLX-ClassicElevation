from pathlib import Path
p=Path('assets/city_run/v3/build_asset_kit.py');s=p.read_text();s=s.replace("BUILD='V3_KIT_02'","BUILD='V3_KIT_03'")
extra='''# Sparse service faces and stepped shop silhouettes break the repeating residential grid.
g=Geo(); outline=[(-12,-10),(6,-10),(12,-4),(12,10),(-12,10)];n=len(outline)
g.add([(x,y,z) for z in (0,36) for x,y in outline],[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],'ochre')
for z in (1,13,35):
 for i in range(n):a=outline[i];b=outline[(i+1)%n];g.beam((a[0],a[1],z),(b[0],b[1],z),.65,'cream')
for z in (7,21,30):
 for x in (-7,1):g.window(x,-10.05,z,5,8,'shop_glass' if z==7 else 'window_brown')
 for y in (1,7):g.window(12.05,y,z,4.5,8,'window_plain',math.pi/2)
 g.window(9.05,-7.05,z,6,8,'arch_glass',math.pi/4)
g.box((-2,-12,10.5),(19,4,.6),'stripes_cream');g.box((-2,-14,10),(19,.3,1),'gold')
g.window(-2,-10.08,16,14,3,'sign_market');g.finish('V3_CornerCafe','Architecture','Close','Chamfered corner, diagonal entrance and sparse upper shop floors. Closed shell.')

g=Geo();g.box((0,0,24),(24,2,48),'sage')
for x,z,w,h in [(-7,8,8,12),(5,32,9,15),(-5,43,12,7)]:g.box((x,-1.02,z),(w,.025,h),'stone' if z==32 else 'ochre')
for x,z in [(-7,24),(6,42),(-7,40)]:g.window(x,-1.06,z,4,5,'window_brown')
g.window(5,-1.06,5,6,9,'wood_plank')
for x,z in [(-7,11),(6,24)]:
 g.box((x,-1.6,z),(5,1.2,3),'slate')
 for j in range(3):g.box((x,-2.23,z-.8+j*.8),(4,.12,.18),'iron')
g.beam((10,-1.4,0),(10,-1.4,45),.3,'iron');g.beam((10,-1.4,45),(6,-1.4,45),.3,'iron');g.finish('V3_ServiceRear','Openings','Mid','Sparse rear-wall panel with broad paint repairs, two vents and a drainpipe.')

g=Geo()
for x,h,col,tile in [(-10,11,'coral','stripes_cream'),(0,15,'sage','stripes_teal'),(10,12.5,'ochre','stripes_cream')]:
 g.box((x,0,h/2),(10,8,h),col);g.box((x,0,h),(10.2,8.2,.7),'slate');g.window(x,-4.05,4.8,8,8,'shop_glass')
 g.box((x,-5.5,9.3),(9.7,3,.45),tile);g.box((x,-7,8.8),(9.7,.2,.8),'cream');g.window(x,-4.06,h-1.5,7,1.8,'sign_market')
 for xx in (x-4.5,x+4.5):g.box((xx,-4.1,4.5),(.3,.3,9),'cream')
g.finish('V3_UnevenShopRow','Street','Close','Three compact shop bays with stepped roofline, built-in awnings and opaque glazing.')

g=Geo()
for x,y,w,d,h,col in [(-12,3,15,15,41,'sky'),(1,0,12,16,62,'sage'),(11,4,13,14,49,'stone')]:
 g.box((x,y,h/2),(w,d,h),col);g.box((x,y,h+.5),(w+.7,d+.7,1),'slate')
 for z in range(9,h-4,14):g.window(x,y-d/2-.05,z,w*.65,5,'window_plain')
g.box((2,0,65),(7,10,6),'sage');g.finish('V3_SkylineCluster','Skyline','Distant','Asymmetric depth-stepped distant cluster; opaque backing, no tiny trim.')

'''
s=s.replace('# Export every unique mesh once;',extra+'# Export every unique mesh once;');p.write_text(s)
p=Path('assets/city_run/v3/render_gallery.py');s=p.read_text();s=s.replace("name=['V3_Coral_Wide','V3_Ochre_Narrow','V3_Sage_Wide']", "name=['V3_CornerCafe','V3_Ochre_Narrow','V3_Sage_Wide']")
s=s.replace("instance('V3_MarketStall',(-9,0,0));", "instance('V3_UnevenShopRow',(-18,49,0),math.pi/2);instance('V3_Crate',(-8,4,0));instance('V3_Crate',(-11,6,0));instance('V3_MarketStall',(-9,0,0));")
s=s.replace("else:\n   instance('V3_GardenPortal'", "else:\n   instance('V3_ServiceRear',(15,58,0),math.pi/2)\n   instance('V3_GardenPortal'")
s=s.replace("for side in (-1,1):instance('V3_Brick_Broad',(side*28,28,0));instance('V3_FlatRoof_Broad',(side*28,28,48))", "for side in (-1,1):instance('V3_Brick_Broad',(side*32,28,0));instance('V3_FlatRoof_Broad',(side*32,28,48));instance('V3_ServiceRear',(side*32,14.9,0))")
s=s.replace("for x in (-12,12):\n   for z", "for x in (-12,):\n   for z")
s=s.replace("instance('V3_CraneTruss',(0,17,24));", "instance('V3_CraneTruss',(0,17,24));")
s=s.replace("# Five-and-a-half stud height marker", "# Human-sized marker")
s=s.replace("for p,size in [((-4,-3,2.5)", "for side in (-1,1):instance('V3_SkylineCluster',(side*36,110,0),side*.2)\n for p,size in [((-4,-3,2.5)")
p.write_text(s)
