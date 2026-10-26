from pathlib import Path

HERE = Path(__file__).resolve().parent
text = (HERE / 'BuildGardenKit.py').read_text(encoding='utf8')
text = text.replace('GardenRecipe.py', 'GardenHoistRecipe.py').replace('MC_P3_GARDEN_DG01', 'MC_P3_GARDEN_HOIST_DG02')
text = text.replace('MC_WALL_GARDEN_DG01', 'MC_GARDEN_HOIST_DG02').replace("'DG01_", "'DG02_")
text = text.replace('assert len(assets)==1', 'assert len(assets)==2')
text = text.replace("paths.extend([ROOT/", "paths.extend([HERE/'GardenRecipe.py', ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/assets/r01/DetailRecipes.py', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01/manifest.json', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/correction54/dg01/authored-geometry.json', ROOT/")
start = text.index('def previews(')
end = text.index('\n\ndef main():', start)
text = text[:start] + '''def previews(authored,root,out,palette,a):
    scene=bpy.context.scene;display=bpy.data.collections.new('DG02_Preview_Only');root.children.link(display)
    copies=[]
    for original in authored.objects:
        obj=original.copy();obj.data=original.data;obj.name='Preview_'+original.name;display.objects.link(obj);copies.append(obj)
    wallmat=bpy.data.materials.new('DG02_Preview_Wall');wallmat.use_nodes=True
    rgba=tuple(a._linear(channel) for channel in (193,196,195))+(1,)
    wallmat.diffuse_color=rgba;wallmat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=rgba
    wall=a._Mesh();wall.box((0,.48,4),(33,.68,24),'PreviewWall')
    a._object(display,'PreviewOnly_ExistingWall',wall,dict(palette,PreviewWall=wallmat),0,'Excluded from FBX')
    scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
    scene.render.resolution_x=1440;scene.render.resolution_y=960;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.world=bpy.data.worlds.new('DG02_Daylight');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.38,.46,.57,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
    sun_data=bpy.data.lights.new('DG02_Sun','SUN');sun=bpy.data.objects.new('DG02_Sun',sun_data);display.objects.link(sun)
    sun.rotation_euler=(math.radians(28),math.radians(-22),math.radians(-27));sun_data.energy=2.4;sun_data.angle=.18
    scene.view_settings.view_transform='AgX'
    views=[('01-supported-garden','MC_DG_WallGarden24',(27,-40,20),(0,-1.95,5),34),
           ('02-wall-hoist-front','MC_DG_WallHoist',(18,-24,10),(0,-2.6,-.2),14),
           ('03-wall-hoist-rooting','MC_DG_WallHoist',(13,-8,4),(0,-2.8,-.4),12)]
    records=[]
    for name,asset,point,target,scale in views:
        for obj in copies:obj.hide_render=not obj.name.endswith(asset)
        scene.camera=camera(display,name,point,target,scale);scene.render.filepath=str(out/(name+'.png'))
        print('RENDER_START '+name,flush=True);bpy.ops.render.render(write_still=True)
        path=out/(name+'.png');records.append({'file':path.name,'asset':asset,'sha256':sha(path),'bytes':path.stat().st_size,
            'dimensions':[1440,960],'camera':list(point),'target':list(target),'orthographicScale':scale,'originalBlenderRender':True,
            'boundary':'Kit geometry inspection only; not installed-map or native appearance proof'})
    return records
''' + text[end:]
(HERE / 'BuildGardenHoistKit.py').write_text(text, encoding='utf8', newline='\n')
