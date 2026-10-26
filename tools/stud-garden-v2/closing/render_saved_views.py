"""Render additional cameras from the saved offline candidate without rebuilding it."""
import json
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

blend, views_file, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
bpy.ops.wm.open_mainfile(filepath=str(blend.resolve()))
scene = bpy.context.scene
camera = scene.camera
conversion = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
views = json.loads(views_file.read_text())
output.mkdir(parents=True, exist_ok=True)
for view in views:
    camera.location = conversion @ Vector(view['eye'])
    target = conversion @ Vector(view['target'])
    camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO' if 'ortho' in view else 'PERSP'
    camera.data.lens = view.get('lens', 28)
    if 'ortho' in view:
        camera.data.ortho_scale = view['ortho']
    scene.render.filepath = str((output / (view['name'] + '.png')).resolve())
    bpy.ops.render.render(write_still=True)
    print('CLOSING_VIEW ' + view['name'], flush=True)
(output / 'supplemental-view-manifest.json').write_text(json.dumps({
    'sourceBlend': str(blend), 'offline': True, 'views': views,
    'limits': 'Offline geometry reconstruction. Native camera, GUI, physics and lighting remain unverified.'
}, indent=2))
