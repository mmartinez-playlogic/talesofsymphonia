"""Blender (background) script: turn VesperiaTools OBJ+DDS dumps into reference GLBs with our toon look,
and measure proportions so build_characters.py can imitate the Vesperia style.

Usage: blender -b --python tools/vesperia_ref.py -- <project_root> [name ...]
Reads  assets/ref/vesperia/<name>/all.obj (+ *.DDS in the same folder)
Writes assets/ref/vesperia/glb/<name>.glb  and  assets/ref/vesperia_style.json
Research only: nothing from assets/ref/ is used in the shipped game.
"""
import bpy, os, sys, json, glob
from mathutils import Vector

ROOT = sys.argv[sys.argv.index("--") + 1]
NAMES = sys.argv[sys.argv.index("--") + 2:]
REF = os.path.join(ROOT, "assets/ref/vesperia")
OUT = os.path.join(REF, "glb")
os.makedirs(OUT, exist_ok=True)
TARGET_HEIGHT = 1.75

if not NAMES:
    NAMES = [d for d in sorted(os.listdir(REF)) if os.path.isfile(os.path.join(REF, d, "all.obj"))]

style = {}
for name in NAMES:
    folder = os.path.join(REF, name)
    obj_path = os.path.join(folder, "all.obj")
    if not os.path.isfile(obj_path):
        print("no all.obj for", name)
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=obj_path)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        continue
    # normalize: feet on the floor, height TARGET_HEIGHT
    pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    height = max(hi.z - lo.z, 1e-6)
    s = TARGET_HEIGHT / height
    for o in meshes:
        o.location = (o.location - Vector((0, 0, lo.z))) * s
        o.scale = o.scale * s
    # texture: first DDS found becomes the albedo of every submesh (good enough for a look reference)
    dds = sorted(glob.glob(os.path.join(folder, "*.DDS")) + glob.glob(os.path.join(folder, "*.dds")))
    mat = bpy.data.materials.new(name + "_ref")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if dds and bsdf:
        try:
            img = bpy.data.images.load(dds[0])
            tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
            tex.image = img
            mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        except Exception as e:
            print("texture load failed", dds[0], e)
    for o in meshes:
        o.data.materials.clear()
        o.data.materials.append(mat)
    # proportions: head ≈ top 1/N of the height. Measure width profile in 20 horizontal slices.
    verts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    slices = 20
    prof = [0.0] * slices
    for v in verts:
        i = min(slices - 1, int((v.z / TARGET_HEIGHT) * slices))
        prof[i] = max(prof[i], abs(v.x))
    # head: from the top, find where the half-width stops shrinking (neck)
    neck = slices - 1
    for i in range(slices - 2, slices // 2, -1):
        if prof[i] > prof[i + 1] * 1.25:
            neck = i
            break
    head_ratio = (slices - neck) / slices  # fraction of height that is head
    shoulder_w = max(prof[int(slices * 0.72):int(slices * 0.85)] or [0]) * 2
    style[name] = {"head_fraction": round(head_ratio, 3), "heads_tall": round(1.0 / max(head_ratio, 0.05), 2),
                   "shoulder_width": round(shoulder_w, 3), "textures": [os.path.basename(d) for d in dds]}
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), use_selection=True, export_yup=True)
    print("ref glb:", name, style[name])

with open(os.path.join(ROOT, "assets/ref/vesperia_style.json"), "w") as f:
    json.dump(style, f, indent=1)
print("style summary ->", os.path.join(ROOT, "assets/ref/vesperia_style.json"))
