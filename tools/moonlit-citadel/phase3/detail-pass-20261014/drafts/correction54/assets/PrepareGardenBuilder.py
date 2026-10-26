from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'default.project.json').exists())
source=(ROOT/'tools/moonlit-citadel/phase3/detail-pass-20261014/drafts/assets/r01/BuildDetailKit.py').read_text(encoding='utf8')
source=source.replace("BUILD='MC_P3_DETAIL_DT01_R01'","BUILD='MC_P3_GARDEN_DG01'")
source=source.replace("HERE/'DetailRecipes.py'","HERE/'GardenRecipe.py'")
source=source.replace("paths.extend(p for p in out.parent.iterdir() if p.is_file())", "paths.extend([ROOT/'docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/FINAL_FREEZE53.json', ROOT/'assets/moonlit_citadel/phase3/detail-pass-20261014/dt01/r01/manifest.json'])")
source=source.replace("len(assets)==8", "len(assets)==1")
source=source.replace("'MC_DETAIL_KIT_DT01.fbx'","'MC_WALL_GARDEN_DG01.fbx'").replace("'MC_DETAIL_KIT_DT01.blend'","'MC_WALL_GARDEN_DG01.blend'")
source=source.replace("'DT01_Authored_Base_Pivot_Units'","'DG01_Authored_Base_Pivot_Units'").replace("'DT01_Export_Material_Parts'","'DG01_Export_Material_Parts'")
start=source.index('def previews(');end=source.index('\n\ndef main():',start)
preview='''def previews(authored,root,out,palette,a):
    scene=bpy.context.scene;display=bpy.data.collections.new('DG01_Preview_Only');root.children.link(display)
    for original in authored.objects:
        obj=original.copy();obj.data=original.data;obj.name='Preview_'+original.name;display.objects.link(obj)
    wallmat=bpy.data.materials.new('DG01_Preview_Wall');wallmat.use_nodes=True
    rgba=tuple(a._linear(channel) for channel in (193,196,195))+(1,)
    wallmat.diffuse_color=rgba;wallmat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=rgba
    preview_palette=dict(palette,PreviewWall=wallmat)
    wall=a._Mesh();wall.box((0,.48,8),(33,.68,21),'PreviewWall')
    a._object(display,'PreviewOnly_ExistingWall',wall,preview_palette,0,'Excluded from FBX')
    scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
    scene.render.resolution_x=1440;scene.render.resolution_y=960;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
    scene.world=bpy.data.worlds.new('DG01_Daylight');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.38,.46,.57,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
    sun_data=bpy.data.lights.new('DG01_Sun','SUN');sun=bpy.data.objects.new('DG01_Sun',sun_data);display.objects.link(sun)
    sun.rotation_euler=(math.radians(28),math.radians(-22),math.radians(-27));sun_data.energy=2.4;sun_data.angle=.18
    scene.view_settings.view_transform='AgX'
    views=[('01-supported-wall-garden',(27,-40,20),(0,-1.95,5),34),
           ('02-sloped-earth-and-rooting',(27,-21,15),(0,-1.95,5.3),29),
           ('03-planted-depth',(15,-28,13.5),(0,-1.95,6.2),27)]
    records=[]
    for name,point,target,scale in views:
        scene.camera=camera(display,name,point,target,scale);scene.render.filepath=str(out/(name+'.png'))
        print('RENDER_START '+name,flush=True);bpy.ops.render.render(write_still=True)
        path=out/(name+'.png');records.append({'file':path.name,'sha256':sha(path),'bytes':path.stat().st_size,
            'dimensions':[1440,960],'camera':list(point),'target':list(target),'orthographicScale':scale,'originalBlenderRender':True,
            'boundary':'Kit geometry inspection only; not a route-height installed-map or native appearance result'})
    return records
'''
source=source[:start]+preview+source[end:]
(HERE/'BuildGardenKit.py').write_text(source,encoding='utf8',newline='')
print('Prepared one-asset DG01 builder with frozen52/53 input guards')
