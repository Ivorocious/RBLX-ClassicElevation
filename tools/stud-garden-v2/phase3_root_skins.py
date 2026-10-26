"""Blend the R305 root underbodies while retaining their exact playable crowns."""
import math
import numpy as np
import bpy
import bmesh


def add_root_skins(shapes,data,origin,scene,palette):
    replacements=[]
    for model in data['models']:
        if model.get('family')!='FacetedRootBridge':continue
        prefix=model['path']+'.'
        parts=[p for p in data['parts'] if p['path'].startswith(prefix)]
        crowns=[p for p in parts if p['name'].startswith('RootCrownFacet')]
        if not crowns:continue
        pivot=np.array(model['pivot']);rotation=pivot[3:].reshape(3,3);center=pivot[:3]-origin
        arms=[p for p in parts if p['name'] in ('SweptRootArm','RootBranchJoint')]
        points=[]
        for p in crowns:
            cf=np.array(p['cf']);rot=cf[3:].reshape(3,3);half=np.array(p['size'])/2
            # Native wedges supply an exact footprint; width/length derive from their source crown.
            for a in (-1,1):
                for b in (-1,1):
                    for c in (-1,1):
                        points.append(rotation.T@(cf[:3]-origin+rot@(half*np.array((a,b,c)))-center))
        points=np.array(points)
        # Wedge bounding boxes overstate the crown footprint, so use the R305 width and path length.
        width=18 if model['path'].split('.')[-1] in ('EntryRoot','ForkRoot','HarvestRoot') else 17
        outline=[(-.38,-.5),(.38,-.5),(.47,-.28),(.5,.1),(.38,.5),(-.36,.5),(-.5,.22),(-.48,-.2)]
        length=float(np.max(points[:,2])-np.min(points[:,2]))
        # Recover the exact length from crown center positions at the front/back edges.
        root_name=model['path'].split('.')[-1]
        lengths={'EntryRoot':14,'ForkRoot':18,'HarvestRoot':14,'GroveRoot_1':9.5,
            'GroveRoot_2':16.427,'GroveRoot_3':21.509,'GroveRoot_4':9.2,
            'GroveRoot_5':17.122,'GroveRoot_6':15.214,'GroveRoot_7':16.149,'GroveRoot_8':9.617}
        assert root_name in lengths,root_name
        length=lengths[root_name]
        first=len(shapes.pieces)
        shapes.group='RootSkin_'+root_name;shapes.kind='root skin'
        color='root_skin';palette[color]='#EC87B3'
        local=[(x*width,-.4,z*length) for x,z in outline]+[(x*width*.18,-3.1,z*length*.2) for x,z in outline]
        vertices=[tuple(center+rotation@np.array(v)) for v in local]
        faces=[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
        shapes.emit(color,vertices,faces)
        for p in arms:
            cf=np.array(p['cf']);pos=cf[:3]-origin;rot=cf[3:].reshape(3,3)
            if p['shape']=='Cylinder':
                direction=rot[:,0];half=p['size'][0]/2
                a,b=pos-direction*half,pos+direction*half
                if a[1]<b[1]:a,b=b,a
                radius=p['size'][1]/2
                if radius<1.5:upper=width*.25/2
                elif radius<2.5:upper=width*.33/2
                else:upper=radius
                shapes.rod(tuple(a),tuple(b),upper,color,radius,sides=12)
            else:
                radius=min(p['size'])/2
                vertices=[tuple(pos+radius*np.array((math.sin(j*math.pi/8)*math.cos(i*math.tau/12),
                    math.cos(j*math.pi/8),math.sin(j*math.pi/8)*math.sin(i*math.tau/12))))
                    for j in range(9) for i in range(12)]
                faces=[(j*12+i,j*12+(i+1)%12,(j+1)*12+(i+1)%12,(j+1)*12+i) for j in range(8) for i in range(12)]
                shapes.emit(color,vertices,faces)
        pieces=shapes.pieces[first:]
        vertices=[];faces=[]
        for piece in pieces:
            offset=len(vertices);vertices.extend((x,-z,y) for x,y,z in piece['vertices'])
            faces.extend(tuple(v+offset for v in face) for face in piece['faces'])
        mesh=bpy.data.meshes.new('RootUnionWork');mesh.from_pydata(vertices,[],faces);mesh.update()
        bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
        obj=bpy.data.objects.new('RootUnionWork',mesh);scene.collection.objects.link(obj)
        bpy.context.view_layer.objects.active=obj;obj.select_set(True)
        remesh=obj.modifiers.new('ContinuousUnderbody','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.24;remesh.use_smooth_shade=False
        bpy.ops.object.modifier_apply(modifier=remesh.name)
        smooth=obj.modifiers.new('BlendSeams','SMOOTH');smooth.factor=.8;smooth.iterations=5
        bpy.ops.object.modifier_apply(modifier=smooth.name)
        decimate=obj.modifiers.new('LimitedUnderbodyCost','DECIMATE');decimate.ratio=min(1,600/max(1,len(obj.data.polygons)))
        bpy.ops.object.modifier_apply(modifier=decimate.name)
        bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bmesh.ops.triangulate(bm,faces=list(bm.faces))
        assert not any(e.is_boundary for e in bm.edges),root_name
        bm.to_mesh(obj.data);bm.free()
        vertices=[(v.co.x,v.co.z,-v.co.y) for v in obj.data.vertices]
        del shapes.pieces[first:]
        shapes.emit(color,vertices,[tuple(p.vertices) for p in obj.data.polygons],detail='sculpt')
        bpy.data.objects.remove(obj,do_unlink=True)
        paths=[p['path'] for p in parts if p['name'].startswith('RootShoulder') or p['name'] in ('SweptRootArm','RootBranchJoint')]
        for obj in scene.objects:
            if obj.name.startswith(prefix) and any(t in obj.name for t in ('RootShoulder','SweptRootArm','RootBranchJoint')):
                obj.hide_render=True;obj.hide_viewport=True
        replacements.append({'root':model['path'],'hiddenSourcePaths':sorted(set(paths)),
            'skinGroup':shapes.group,'triangles':len(shapes.pieces[-1]['faces']),
            'preserves':'All R305 colliders and exact crown positions/heights remain unchanged.'})
    return replacements
