"""Render a thick diamond key, warm bag outline and brighter compass badge."""
from pathlib import Path
import bpy
import sys

folder = Path(__file__).resolve().parent
source = (folder / 'generate_icons_r3.py').read_text().split('\nfor name,build in ')[0]
source = source.replace("('Blue lower bevel','Blue',.84", "('Blue lower bevel','Blue',.90")
source = source.replace("('Cyan face','Cyan',.68", "('Cyan face','Cyan',.78")
source = source.replace("x*.83-.023,(z-.55)*.83+.585", "x*.94-.023,(z-.55)*.94+.585")
source = source.replace("x*1.2-.023,(z-.55)*1.2+.585", "x*1.03-.023,(z-.55)*1.03+.585")
source = source.replace("root.rotation_euler.y=.30", "root.rotation_euler.y=.10")
source = source.replace("poly(name,pts,m[mat],y,.13,.027).parent=root", "ob=poly(name,pts,m[mat],y,.13,.027);ob.parent=root;ob.rotation_euler.y=.24")
source = source.replace("bevel(ob,.025);ob.parent=root", "bevel(ob,.045);ob.parent=root")
source = source.replace("(0,.67),(.145,.165),(.63,.02)", "(0,.70),(.13,.165),(.67,.02)")
source = source.replace("(0,-.61),(-.145,-.125),(-.63,.02)", "(0,-.65),(-.13,-.125),(-.67,.02)")
scope = {'__file__': str(folder / 'generate_icons_r3.py')}
exec(compile(source, str(folder / 'generate_icons_r3.py'), 'exec'), scope)

names = ['coin-r4', 'key-r4', 'shop-bag-r4']
if '--' in sys.argv:
    names = sys.argv[sys.argv.index('--')+1:]
    assert names and all(name in ['coin-r4', 'key-r4', 'shop-bag-r4'] for name in names)
for name in names:
    mats = scope['setup']()
    if name == 'coin-r4':
        bpy.data.objects['Large upper left'].data.energy = 180
        mats['Amber'] = scope['scope']['material']('Warm amber', 'E89105', .15, .32, .18)
        scope['coin'](mats)
    elif name == 'key-r4':
        scope['key'](mats)
    else:
        mats['Navy'] = scope['scope']['material']('Warm bag edge', '812A24', 0, .5, .25)
        scope['scope']['bag'](mats)
    bpy.context.scene.render.filepath = str(folder / (name + '.png'))
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / (name + '.blend')))
    bpy.ops.render.render(write_still=True)
    print('ICON_COMPLETE ' + name, flush=True)
