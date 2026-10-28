"""Toon preview contact sheet (EEVEE, cel ramp + inverted-hull outline), background only.
Usage: blender -b --python tools/render_toon_sheet.py -- <root> <out.png> <cols> [--front|--side|--back] id ...
"""
import bpy, os, sys, math
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
ROOT, OUT, COLS = argv[0], argv[1], int(argv[2])
VIEW = "front"
IDS = []
for a in argv[3:]:
    if a.startswith("--"):
        VIEW = a[2:]
    else:
        IDS.append(a)
CH = os.path.join(ROOT, "assets/characters")
bpy.ops.wm.read_factory_settings(use_empty=True)
outline_mat = bpy.data.materials.new("Outline")
outline_mat.use_nodes = True
nt = outline_mat.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
em = nt.nodes.new("ShaderNodeEmission"); em.inputs[0].default_value = (0.04, 0.03, 0.06, 1)
out = nt.nodes.new("ShaderNodeOutputMaterial")
nt.links.new(em.outputs[0], out.inputs[0])
outline_mat.use_backface_culling = True

def toonify(mat):
    if mat is None or not mat.use_nodes or mat.name.startswith("Outline") or mat.get("toon"):
        return
    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None:
        return
    base_link = bsdf.inputs["Base Color"].links[0].from_socket if bsdf.inputs["Base Color"].links else None
    base_col = tuple(bsdf.inputs["Base Color"].default_value)
    for n in list(nt.nodes):
        if n.type not in ("TEX_IMAGE",):
            nt.nodes.remove(n)
    diff = nt.nodes.new("ShaderNodeBsdfDiffuse")
    s2r = nt.nodes.new("ShaderNodeShaderToRGB")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.62, 0.58, 0.75, 1)
    ramp.color_ramp.elements[1].position = 0.12
    ramp.color_ramp.elements[1].color = (1, 1, 1, 1)
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"; mix.inputs[0].default_value = 1.0
    emit = nt.nodes.new("ShaderNodeEmission")
    outn = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(diff.outputs[0], s2r.inputs[0])
    nt.links.new(s2r.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], mix.inputs[6])
    if base_link:
        nt.links.new(base_link, mix.inputs[7])
    else:
        mix.inputs[7].default_value = base_col
    nt.links.new(mix.outputs[2], emit.inputs[0])
    nt.links.new(emit.outputs[0], outn.inputs[0])
    mat["toon"] = True

spacing = 1.25
row_h = 2.15
for i, cid in enumerate(IDS):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(CH, cid + ".glb"))
    new = [o for o in bpy.data.objects if o not in before]
    r, c = divmod(i, COLS)
    for o in new:
        if o.parent is None:
            o.location = Vector((c * spacing, 0, -r * row_h))
            if VIEW == "side":
                o.rotation_euler = (o.rotation_euler[0], o.rotation_euler[1], math.radians(90))
            elif VIEW == "back":
                o.rotation_euler = (o.rotation_euler[0], o.rotation_euler[1], math.radians(180))
        if o.type == "MESH":
            for slot in o.material_slots:
                toonify(slot.material)
            o.data.materials.append(outline_mat)
            mod = o.modifiers.new("outline", "SOLIDIFY")
            mod.thickness = 0.008
            mod.offset = 1.0
            mod.use_flip_normals = True
            mod.material_offset = len(o.data.materials) - 1
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 1800
rows = (len(IDS) + COLS - 1) // COLS
scene.render.resolution_y = int(1800 * (rows * row_h + 0.3) / (COLS * spacing + 0.3))
world = bpy.data.worlds.new("W"); scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.72, 0.8, 0.9, 1)
sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
sun.data.energy = 4.0
sun.rotation_euler = (math.radians(50), math.radians(15), math.radians(-30))
bpy.context.collection.objects.link(sun)
cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = (COLS * spacing + 0.3)
bpy.context.collection.objects.link(cam)
cam.location = Vector(((COLS - 1) * spacing / 2, -20, -(rows - 1) * row_h / 2 + 0.9))
cam.rotation_euler = (math.radians(90), 0, 0)
scene.camera = cam
scene.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print("SHEET", OUT)
