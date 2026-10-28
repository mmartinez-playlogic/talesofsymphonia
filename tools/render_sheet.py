"""Render a contact sheet of character GLBs with Blender Workbench (background, no window).
Usage: blender -b --python tools/render_sheet.py -- <project_root> <out.png> [id ...]
"""
import bpy, os, sys, math
from mathutils import Vector
ROOT = sys.argv[sys.argv.index("--") + 1]
OUT = sys.argv[sys.argv.index("--") + 2]
IDS = sys.argv[sys.argv.index("--") + 3:]
CH = os.path.join(ROOT, "assets/characters")
if not IDS:
    IDS = sorted(f[:-4] for f in os.listdir(CH) if f.endswith(".glb"))
bpy.ops.wm.read_factory_settings(use_empty=True)
cols = 6
spacing = 1.3
for i, cid in enumerate(IDS):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(CH, cid + ".glb"))
    new = [o for o in bpy.data.objects if o not in before]
    roots = [o for o in new if o.parent is None]
    r, c = divmod(i, cols)
    for o in roots:
        o.location = Vector((c * spacing, 0, -r * 2.2))
        o.rotation_euler = (0, 0, math.radians(180)) if any(k in cid for k in ()) else o.rotation_euler
scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
sh = scene.display.shading
sh.light = 'STUDIO'
sh.color_type = 'MATERIAL'
sh.show_object_outline = True
sh.show_shadows = False
scene.render.resolution_x = 1800
scene.render.resolution_y = 1200
scene.render.film_transparent = False
scene.world = bpy.data.worlds.new("W")
scene.world.color = (0.55, 0.6, 0.7)
rows = (len(IDS) + cols - 1) // cols
cam_data = bpy.data.cameras.new("Cam")
cam_data.type = 'ORTHO'
aspect = scene.render.resolution_x / scene.render.resolution_y
cam_data.ortho_scale = max(cols * spacing + 0.5, (rows * 2.2 + 0.6) * aspect) * 1.02
cam = bpy.data.objects.new("Cam", cam_data)
bpy.context.collection.objects.link(cam)
cx = (cols - 1) * spacing / 2
cz = -(rows - 1) * 2.2 / 2 + 0.95
cam.location = Vector((cx, -20, cz))
cam.rotation_euler = (math.radians(90), 0, 0)
scene.camera = cam
scene.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print("SHEET", OUT, IDS)
