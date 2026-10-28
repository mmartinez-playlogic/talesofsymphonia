"""Build humanoid character GLBs + a shared animation GLB from the Quaternius CC0 libraries.

Usage: blender -b --python tools/build_characters.py -- <project_root>
Outputs:
  assets/anim/humanoid_anims.glb   (mannequin + all animations, unified rig "Rig")
  assets/characters/<id>.glb       (colored mannequin + hair + weapons, no animations)
"""
import bpy, bmesh, json, os, sys, math
from mathutils import Vector

ROOT = sys.argv[sys.argv.index("--") + 1]
UAL1 = os.path.join(ROOT, "assets/anim/ual1.glb")
UAL2 = os.path.join(ROOT, "assets/anim/ual2.glb")
OUT_ANIM = os.path.join(ROOT, "assets/anim/humanoid_anims.glb")
OUT_DIR = os.path.join(ROOT, "assets/characters")
os.makedirs(OUT_DIR, exist_ok=True)

# ---------- bone map UE5 -> Rigify DEF ----------
MAP = {"pelvis": "DEF-hips", "spine_01": "DEF-spine.001", "spine_02": "DEF-spine.002", "spine_03": "DEF-spine.003",
       "neck_01": "DEF-neck", "Head": "DEF-head", "root": "root"}
for s, S in (("l", "L"), ("r", "R")):
    MAP.update({f"clavicle_{s}": f"DEF-shoulder.{S}", f"upperarm_{s}": f"DEF-upper_arm.{S}", f"lowerarm_{s}": f"DEF-forearm.{S}",
                f"hand_{s}": f"DEF-hand.{S}", f"thigh_{s}": f"DEF-thigh.{S}", f"calf_{s}": f"DEF-shin.{S}",
                f"foot_{s}": f"DEF-foot.{S}", f"ball_{s}": f"DEF-toe.{S}"})
    for f in ("index", "middle", "ring", "pinky", "thumb"):
        for i in (1, 2, 3):
            MAP[f"{f}_0{i}_{s}"] = (f"DEF-f_{f}.0{i}.{S}" if f != "thumb" else f"DEF-thumb.0{i}.{S}")

def action_fcurves(action):
    """Iterate fcurves of an action across Blender 4.4+/5.x slotted actions, yielding (channelbag, fcurve)."""
    out = []
    if hasattr(action, "layers") and len(action.layers):
        for layer in action.layers:
            for strip in layer.strips:
                for cb in strip.channelbags:
                    for fc in list(cb.fcurves):
                        out.append((cb, fc))
    elif hasattr(action, "fcurves"):
        for fc in list(action.fcurves):
            out.append((action, fc))
    return out

def rename_action_bones(action):
    import re
    for cb, fc in action_fcurves(action):
        m = re.match(r'pose\.bones\["([^"]+)"\]\.(.+)', fc.data_path)
        if not m:
            continue
        bone, prop = m.group(1), m.group(2)
        if bone in MAP:
            fc.data_path = f'pose.bones["{MAP[bone]}"].{prop}'
        else:
            cb.fcurves.remove(fc)
    for g in list(action.groups) if hasattr(action, "groups") else []:
        if g.name in MAP:
            g.name = MAP[g.name]

def add_nla(rig, action, name):
    ad = rig.animation_data or rig.animation_data_create()
    track = ad.nla_tracks.new()
    track.name = name
    fr = action.frame_range
    strip = track.strips.new(name, int(fr[0]), action)
    strip.name = name
    try:
        if hasattr(action, "slots") and len(action.slots):
            strip.action_slot = action.slots[0]
    except Exception as e:
        print("slot assign failed", name, e)
    track.mute = True

def delete_obj(o):
    bpy.data.objects.remove(o, do_unlink=True)

# ---------- 1. load UAL1 (canonical rig) ----------
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=UAL1)
rig = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
rig.name = "Rig"
body = [o for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith("Mannequin")][0]
for o in list(bpy.data.objects):
    if o.name.startswith("Icosphere"):
        delete_obj(o)
actions1 = {a.name: a for a in bpy.data.actions}
# normalize NLA on rig: one muted track per action
ad = rig.animation_data or rig.animation_data_create()
for t in list(ad.nla_tracks):
    ad.nla_tracks.remove(t)
ad.action = None
for name, a in actions1.items():
    add_nla(rig, a, name)
print("UAL1 actions:", len(actions1))

# ---------- 2. load UAL2, retarget by rename, merge ----------
before = set(bpy.data.objects)
before_actions = set(bpy.data.actions)
bpy.ops.import_scene.gltf(filepath=UAL2)
new_objs = [o for o in bpy.data.objects if o not in before]
new_actions = [a for a in bpy.data.actions if a not in before_actions]
for a in new_actions:
    if a.name in actions1:
        continue
    rename_action_bones(a)
    add_nla(rig, a, a.name)
for o in new_objs:
    delete_obj(o)
print("UAL2 actions merged:", len(new_actions))

# ---------- helpers for mesh building ----------
def new_material(name, color):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    return m

def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))

def region_of_vertex(v, groups_by_index):
    """Classify a mannequin vertex into a region by dominant bone weight and position."""
    best, bw = None, 0.0
    for g in v.groups:
        if g.weight > bw:
            bw, best = g.weight, groups_by_index[g.group]
    p = v.co
    if best is None:
        return "top"
    if best in ("DEF-head", "DEF-neck"):
        if p.z > 1.665 or (p.z > 1.595 and p.y > 0.015):
            return "hair"
        return "skin"
    if "hand" in best or "f_" in best or "thumb" in best:
        return "skin"
    if "foot" in best or "toe" in best or ("shin" in best and p.z < 0.25):
        return "boots"
    if "thigh" in best or "shin" in best or best == "DEF-hips":
        return "bottom"
    return "top"

REGIONS = ["skin", "hair", "top", "bottom", "boots", "accent", "metal", "wood", "dark"]

def colorize_body(mesh_obj, colors):
    me = mesh_obj.data
    groups_by_index = {g.index: g.name for g in mesh_obj.vertex_groups}
    me.materials.clear()
    mats = {}
    for r in REGIONS:
        mats[r] = new_material(f"{mesh_obj.name}_{r}", hex_to_rgb(colors.get(r, "#888888")))
        me.materials.append(mats[r])
    vreg = [region_of_vertex(v, groups_by_index) for v in me.vertices]
    for poly in me.polygons:
        counts = {}
        for vi in poly.vertices:
            counts[vreg[vi]] = counts.get(vreg[vi], 0) + 1
        region = max(counts, key=counts.get)
        poly.material_index = REGIONS.index(region)

def skin_to_bone(obj, bone):
    vg = obj.vertex_groups.new(name=bone)
    vg.add([v.index for v in obj.data.vertices], 1.0, 'REPLACE')
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = rig
    obj.parent = rig

def mesh_from_bmesh(name, bm, material):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(material)
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return o

def make_box(name, size, center, material, bone):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2])) + Vector(center)
    o = mesh_from_bmesh(name, bm, material)
    skin_to_bone(o, bone)
    return o

def make_sphere(name, radius, center, material, bone, scale=(1, 1, 1), segs=12):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=segs // 2 + 2, radius=radius)
    for v in bm.verts:
        v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2])) + Vector(center)
    o = mesh_from_bmesh(name, bm, material)
    skin_to_bone(o, bone)
    return o

def make_cylinder(name, radius, depth, center, material, bone, axis='Z', segs=10):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=radius, radius2=radius, depth=depth)
    for v in bm.verts:
        c = v.co.copy()
        if axis == 'Y':
            c = Vector((c.x, c.z, c.y))
        elif axis == 'X':
            c = Vector((c.z, c.y, c.x))
        v.co = c + Vector(center)
    o = mesh_from_bmesh(name, bm, material)
    skin_to_bone(o, bone)
    return o

def make_torus(name, major, minor, center, material, bone):
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=False, segments=16, radius=major)
    geom = bm.verts[:] + bm.edges[:]
    # revolve circle cross-section manually: simpler — use primitive via ops
    bm.free()
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=18, minor_segments=8, location=center)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(material)
    skin_to_bone(o, bone)
    return o

def bone_pos(bone):
    b = rig.data.bones[bone]
    return rig.matrix_world @ b.head_local, rig.matrix_world @ b.tail_local

HAND_R = "DEF-hand.R"
HAND_L = "DEF-hand.L"
HEAD = "DEF-head"

def hand_frame(side):
    h, t = bone_pos(f"DEF-hand.{side}")
    d = (t - h).normalized()
    return h, d

def make_sword(prefix, side, mats, length=0.95, width=0.06):
    """Sword gripped in hand, blade pointing along hand direction (down the fingers)."""
    h, d = hand_frame(side)
    grip = h + d * 0.04
    # blade along d
    parts = []
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * width, v.co.y * 0.012, (v.co.z + 0.5) * length))
    o = mesh_from_bmesh(f"{prefix}_blade", bm, mats["metal"])
    # orient: local Z -> d
    quat = Vector((0, 0, 1)).rotation_difference(d)
    for v in o.data.vertices:
        v.co = quat @ v.co + grip + d * 0.08
    skin_to_bone(o, f"DEF-hand.{side}")
    parts.append(o)
    parts.append(make_box(f"{prefix}_guard", (0.16, 0.03, 0.03), grip + d * 0.08, mats["dark"], f"DEF-hand.{side}"))
    parts.append(make_cylinder(f"{prefix}_handle", 0.018, 0.18, grip - d * 0.02, mats["wood"], f"DEF-hand.{side}", axis='Z'))
    return parts

def make_hair(style, mats):
    hh, ht = bone_pos(HEAD)
    top = Vector((0, 0, 1.66))
    parts = []
    if style == "spiky":
        parts.append(make_sphere("hair_base", 0.115, top + Vector((0, 0.01, 0.03)), mats["hair"], HEAD, scale=(1.0, 1.05, 0.9)))
        for i, (x, y, z, s) in enumerate([(-0.05, 0.02, 0.1, 0.05), (0.03, -0.01, 0.12, 0.05), (0.0, 0.07, 0.09, 0.05), (-0.08, 0.06, 0.06, 0.045), (0.08, 0.05, 0.06, 0.045), (0.06, -0.06, 0.08, 0.04), (-0.06, -0.06, 0.08, 0.04)]):
            parts.append(make_sphere(f"hair_spike{i}", s, top + Vector((x, y, z)), mats["hair"], HEAD, scale=(1, 1, 1.8)))
    elif style == "long":
        parts.append(make_sphere("hair_base", 0.118, top + Vector((0, 0.015, 0.02)), mats["hair"], HEAD, scale=(1.0, 1.1, 0.9)))
        parts.append(make_sphere("hair_back", 0.1, top + Vector((0, 0.07, -0.15)), mats["hair"], HEAD, scale=(1.0, 0.7, 1.9)))
    elif style == "bob":
        parts.append(make_sphere("hair_base", 0.12, top + Vector((0, 0.015, 0.0)), mats["hair"], HEAD, scale=(1.0, 1.08, 1.1)))
    elif style == "short":
        parts.append(make_sphere("hair_base", 0.112, top + Vector((0, 0.015, 0.03)), mats["hair"], HEAD, scale=(1.0, 1.05, 0.85)))
    elif style == "ponytail":
        parts.append(make_sphere("hair_base", 0.112, top + Vector((0, 0.015, 0.03)), mats["hair"], HEAD, scale=(1.0, 1.05, 0.85)))
        parts.append(make_sphere("hair_tail", 0.06, top + Vector((0, 0.13, 0.02)), mats["hair"], HEAD, scale=(1, 1, 2.2)))
    elif style == "twintails":
        parts.append(make_sphere("hair_base", 0.112, top + Vector((0, 0.015, 0.03)), mats["hair"], HEAD, scale=(1.0, 1.05, 0.85)))
        for sx in (-1, 1):
            parts.append(make_sphere(f"hair_tail{sx}", 0.05, top + Vector((sx * 0.13, 0.04, -0.05)), mats["hair"], HEAD, scale=(1, 1, 2.6)))
    elif style == "bald":
        pass
    return parts


def make_cone(name, r1, r2, depth, center, material, bone, segs=14):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r1, radius2=r2, depth=depth)
    for v in bm.verts:
        v.co = v.co + Vector(center)
    o = mesh_from_bmesh(name, bm, material)
    skin_to_bone(o, bone)
    return o

def make_half_cone(name, r1, r2, depth, center, material, bone, segs=18, keep_back=True):
    """Open coat/cape: a cone with the front half removed (mannequin front is -Y)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=segs, radius1=r1, radius2=r2, depth=depth)
    kill = [v for v in bm.verts if (v.co.y < -0.02 if keep_back else v.co.y > 0.02)]
    bmesh.ops.delete(bm, geom=kill, context='VERTS')
    for v in bm.verts:
        v.co = v.co + Vector(center)
    o = mesh_from_bmesh(name, bm, material)
    skin_to_bone(o, bone)
    return o

def make_box_along(name, size, start, d, material, bone):
    """Box of `size` (x, y, length) whose local +Z runs along direction d starting at `start`."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], (v.co.z + 0.5) * size[2]))
    o = mesh_from_bmesh(name, bm, material)
    quat = Vector((0, 0, 1)).rotation_difference(d)
    for v in o.data.vertices:
        v.co = quat @ v.co + start
    skin_to_bone(o, bone)
    return o

def make_eyes(mats, eye_color):
    """Anime eyes: white, colored iris, dark pupil, thin brow. Mannequin forward is -Y."""
    parts = []
    iris = new_material("iris", hex_to_rgb(eye_color))
    white = new_material("eye_white", (0.97, 0.97, 0.97))
    for sx in (-1, 1):
        parts.append(make_sphere(f"eyew{sx}", 0.026, Vector((sx * 0.038, -0.092, 1.612)), white, HEAD, scale=(1.0, 0.45, 1.5), segs=10))
        parts.append(make_sphere(f"iris{sx}", 0.015, Vector((sx * 0.038, -0.104, 1.610)), iris, HEAD, scale=(1.0, 0.5, 1.5), segs=8))
        parts.append(make_sphere(f"pupil{sx}", 0.007, Vector((sx * 0.038, -0.111, 1.611)), mats["dark"], HEAD, scale=(1.0, 0.5, 1.5), segs=6))
        parts.append(make_box(f"brow{sx}", (0.045, 0.008, 0.008), Vector((sx * 0.04, -0.1, 1.655)), mats["hair"], HEAD))
    parts.append(make_box("mouth", (0.03, 0.006, 0.005), Vector((0, -0.105, 1.548)), mats["dark"], HEAD))
    return parts

def make_hair(style, mats):
    top = Vector((0, 0, 1.66))
    parts = []
    def base(r=0.115, off=(0, 0.015, 0.03), scale=(1.0, 1.05, 0.9)):
        parts.append(make_sphere("hair_base", r, top + Vector(off), mats["hair"], HEAD, scale=scale))
    def spikes(spec, scale=(1, 1, 1.8)):
        for i, (x, y, z, s) in enumerate(spec):
            parts.append(make_sphere(f"hair_spike{i}", s, top + Vector((x, y, z)), mats["hair"], HEAD, scale=scale))
    if style == "spiky":          # Lloyd: big spikes up and out
        base(0.118)
        spikes([(-0.05, 0.02, 0.1, 0.055), (0.03, -0.01, 0.12, 0.055), (0.0, 0.07, 0.09, 0.05), (-0.09, 0.06, 0.06, 0.045),
                (0.09, 0.05, 0.06, 0.045), (0.07, -0.06, 0.08, 0.045), (-0.07, -0.06, 0.08, 0.045), (0.0, -0.09, 0.05, 0.04)])
    elif style == "spiky_back":   # Kratos / Forcystus: swept back
        base(0.118, (0, 0.03, 0.03))
        spikes([(-0.05, 0.1, 0.05, 0.05), (0.05, 0.1, 0.05, 0.05), (0.0, 0.12, 0.0, 0.05), (-0.09, 0.07, 0.0, 0.045), (0.09, 0.07, 0.0, 0.045),
                (0.0, -0.06, 0.07, 0.04)], scale=(1, 1.9, 1.1))
    elif style == "long":         # Colette / Zelos / Regal / Remiel
        base(0.118, (0, 0.015, 0.02), (1.0, 1.1, 0.9))
        parts.append(make_sphere("hair_back", 0.1, top + Vector((0, 0.07, -0.16)), mats["hair"], HEAD, scale=(1.05, 0.7, 2.0)))
        for sx in (-1, 1):
            parts.append(make_sphere(f"hair_side{sx}", 0.045, top + Vector((sx * 0.1, 0.0, -0.1)), mats["hair"], HEAD, scale=(1, 1, 2.4)))
    elif style == "bob":          # Raine / Phaidra
        base(0.122, (0, 0.015, 0.0), (1.0, 1.08, 1.1))
        for sx in (-1, 1):
            parts.append(make_sphere(f"hair_side{sx}", 0.05, top + Vector((sx * 0.1, 0.0, -0.06)), mats["hair"], HEAD, scale=(1, 1, 1.6)))
    elif style == "short":        # Genis / Frank / Botta
        base(0.114, (0, 0.012, 0.03), (1.0, 1.05, 0.85))
        spikes([(0.0, -0.02, 0.1, 0.04), (-0.06, 0.0, 0.08, 0.035), (0.06, 0.0, 0.08, 0.035)], scale=(1, 1, 1.4))
    elif style == "ponytail":     # Sheena
        base()
        parts.append(make_sphere("hair_tail", 0.06, top + Vector((0, 0.13, 0.0)), mats["hair"], HEAD, scale=(1, 1, 2.4)))
        parts.append(make_box("hair_tie", (0.05, 0.05, 0.03), top + Vector((0, 0.11, 0.05)), mats["accent"], HEAD))
    elif style == "twintails":    # Presea
        base()
        for sx in (-1, 1):
            parts.append(make_sphere(f"hair_tail{sx}", 0.05, top + Vector((sx * 0.13, 0.04, -0.06)), mats["hair"], HEAD, scale=(1, 1, 2.8)))
            parts.append(make_box(f"hair_tie{sx}", (0.04, 0.04, 0.03), top + Vector((sx * 0.13, 0.04, 0.04)), mats["accent"], HEAD))
    elif style == "bun":          # Marble
        base(0.114, (0, 0.015, 0.03), (1.0, 1.05, 0.85))
        parts.append(make_sphere("hair_bun", 0.05, top + Vector((0, 0.09, 0.06)), mats["hair"], HEAD))
    elif style == "bald":
        pass
    return parts

def chest_z():
    h, t = bone_pos("DEF-spine.003")
    return (h.z + t.z) / 2

def make_feature(kind, mats, colors):
    parts = []
    hips_h, hips_t = bone_pos("DEF-hips")
    cz = chest_z()
    if kind == "collar":
        nh, nt = bone_pos("DEF-neck")
        parts.append(make_cone("collar", 0.095, 0.075, 0.06, (0, 0.0, nh.z + 0.02), mats["accent"], "DEF-spine.003"))
    elif kind == "belt":
        parts.append(make_sphere("belt", 0.178, (0, 0.0, hips_h.z + 0.02), mats["dark"], "DEF-hips", scale=(1.0, 0.78, 0.22)))
        parts.append(make_box("buckle", (0.05, 0.02, 0.04), (0, -0.135, hips_h.z + 0.02), mats["metal"], "DEF-hips"))
    elif kind == "straps":
        for sx in (-1, 1):
            parts.append(make_box(f"strap{sx}", (0.035, 0.012, 0.34), (sx * 0.07, -0.115, cz - 0.08), mats["accent"], "DEF-spine.003"))
    elif kind == "fringe":
        parts.append(make_sphere("fringe", 0.09, (0, -0.075, 1.675), mats["hair"], HEAD, scale=(1.25, 0.6, 0.7)))
    elif kind == "skirt":
        parts.append(make_cone("skirt", 0.2, 0.155, 0.34, (0, 0.0, hips_h.z - 0.16), mats["bottom"], "DEF-hips", segs=20))
    elif kind == "long_coat":
        parts.append(make_half_cone("coat_back", 0.26, 0.18, 0.6, (0, 0.0, hips_h.z - 0.28), mats["top"], "DEF-hips"))
    elif kind == "cape":
        parts.append(make_half_cone("cape", 0.3, 0.2, 1.0, (0, 0.02, cz - 0.45), mats["accent"], "DEF-spine.003"))
    elif kind == "bow_back":
        parts.append(make_box("bow", (0.34, 0.1, 0.2), (0, 0.16, hips_h.z + 0.05), mats["accent"], "DEF-hips"))
        parts.append(make_box("bow_knot", (0.1, 0.12, 0.1), (0, 0.17, hips_h.z + 0.05), mats["accent"], "DEF-hips"))
    elif kind == "wings":
        for sx in (-1, 1):
            parts.append(make_sphere(f"wing{sx}", 0.1, (sx * 0.34, 0.14, cz + 0.12), mats["accent"], "DEF-spine.003", scale=(3.6, 0.2, 1.1)))
            parts.append(make_sphere(f"wingtip{sx}", 0.07, (sx * 0.62, 0.14, cz + 0.22), mats["accent"], "DEF-spine.003", scale=(2.0, 0.2, 0.9)))
    elif kind == "shackles":
        for side in ("L", "R"):
            h, d = hand_frame(side)
            parts.append(make_torus(f"shackle_{side}", 0.05, 0.012, h - d * 0.03, mats["metal"], f"DEF-hand.{side}"))
    elif kind == "beard":
        parts.append(make_sphere("beard", 0.06, (0, -0.07, 1.5), mats["hair"], HEAD, scale=(1.4, 0.8, 1.3)))
    elif kind == "cannon_arm":
        fh, ft = bone_pos("DEF-forearm.L")
        d = (ft - fh).normalized()
        parts.append(make_box_along("cannon", (0.16, 0.16, 0.42), fh - d * 0.05, d, mats["metal"], "DEF-forearm.L"))
        parts.append(make_box_along("cannon_core", (0.07, 0.07, 0.5), fh, d, mats["dark"], "DEF-forearm.L"))
    elif kind == "headband":
        parts.append(make_torus("headband", 0.12, 0.012, (0, 0.0, 1.675), mats["accent"], HEAD))
    elif kind == "pauldrons":
        for sx in (-1, 1):
            parts.append(make_sphere(f"pauldron{sx}", 0.085, (sx * 0.2, 0.0, cz + 0.08), mats["metal"], f"DEF-shoulder.{'L' if sx < 0 else 'R'}", scale=(1.0, 1.0, 0.7)))
    elif kind == "greaves":
        for side in ("L", "R"):
            sh, st = bone_pos(f"DEF-shin.{side}")
            d = (st - sh).normalized()
            parts.append(make_box_along(f"greave_{side}", (0.13, 0.13, 0.36), sh, d, mats["metal"], f"DEF-shin.{side}"))
    return parts

def make_weapon(weapon, mats):
    parts = []
    if weapon == "twin_swords":
        parts += make_sword("sword_r", "R", mats, 0.85)
        parts += make_sword("sword_l", "L", mats, 0.85)
    elif weapon == "sword":
        parts += make_sword("sword_r", "R", mats, 1.0)
    elif weapon == "chakram":
        for side in ("R", "L"):
            h, d = hand_frame(side)
            parts.append(make_torus(f"chakram_{side}", 0.14, 0.012, h + d * 0.06, mats["metal"], f"DEF-hand.{side}"))
    elif weapon == "kendama":
        h, d = hand_frame("R")
        parts.append(make_cylinder("kendama_handle", 0.015, 0.22, h + d * 0.08, mats["wood"], HAND_R))
        parts.append(make_sphere("kendama_ball", 0.045, h + d * 0.22, mats["accent"], HAND_R))
    elif weapon == "staff":
        h, d = hand_frame("R")
        parts.append(make_cylinder("staff", 0.016, 1.5, h + d * 0.2, mats["wood"], HAND_R))
        parts.append(make_sphere("staff_orb", 0.05, h + d * 0.97, mats["accent"], HAND_R))
    elif weapon == "cards":
        h, d = hand_frame("R")
        for i in range(3):
            parts.append(make_box(f"card{i}", (0.06, 0.004, 0.09), h + d * (0.08 + i * 0.012) + Vector((i * 0.015, 0, 0)), mats["accent"], HAND_R))
    elif weapon == "axe":
        h, d = hand_frame("R")
        parts.append(make_cylinder("axe_handle", 0.02, 1.1, h + d * 0.35, mats["wood"], HAND_R))
        parts.append(make_box("axe_head", (0.34, 0.04, 0.3), h + d * 0.8 + Vector((0.14, 0, 0)), mats["metal"], HAND_R))
    elif weapon == "hammer":
        h, d = hand_frame("R")
        parts.append(make_cylinder("hammer_handle", 0.03, 1.1, h + d * 0.4, mats["wood"], HAND_R))
        parts.append(make_box("hammer_head", (0.4, 0.22, 0.22), h + d * 0.95, mats["metal"], HAND_R))
    elif weapon == "whip":
        h, d = hand_frame("R")
        parts.append(make_cylinder("whip_handle", 0.015, 0.25, h + d * 0.08, mats["dark"], HAND_R))
        parts.append(make_cylinder("whip_cord", 0.008, 0.9, h + d * 0.6, mats["wood"], HAND_R))
    return parts

CHARACTERS = json.load(open(os.path.join(ROOT, "src/data/characters.json")))
# Symphonia cast: hair style, eye color, weapon, outfit features. Colors come from characters.json.
EXTRA = {
    "lloyd":   {"hair": "spiky",      "eyes": "#6a4030", "weapon": "twin_swords", "features": ["collar", "straps", "belt"]},
    "colette": {"hair": "long",       "eyes": "#3a7ad8", "weapon": "chakram",     "features": ["fringe", "headband", "skirt", "collar"]},
    "genis":   {"hair": "short",      "eyes": "#3a7ad8", "weapon": "kendama",     "features": ["collar", "belt"]},
    "raine":   {"hair": "bob",        "eyes": "#3a7ad8", "weapon": "staff",       "features": ["long_coat", "collar", "belt"]},
    "kratos":  {"hair": "spiky_back", "eyes": "#7a3a2a", "weapon": "sword",       "features": ["long_coat", "collar", "belt", "pauldrons"]},
    "sheena":  {"hair": "ponytail",   "eyes": "#4a3020", "weapon": "cards",       "features": ["fringe", "bow_back", "belt", "skirt"]},
    "zelos":   {"hair": "long",       "eyes": "#3a7ad8", "weapon": "sword",       "features": ["fringe", "long_coat", "collar", "belt"]},
    "presea":  {"hair": "twintails",  "eyes": "#3a7ad8", "weapon": "axe",         "features": ["fringe", "skirt", "collar"]},
    "regal":   {"hair": "long",       "eyes": "#3a4a8a", "weapon": "none",        "features": ["shackles", "collar", "belt", "greaves"]},
}
NPCS = {
    "dirk":      {"colors": {"hair": "#6a3a1a", "skin": "#e8b890", "top": "#3a6a3a", "bottom": "#4a3a2a", "boots": "#2a1a10", "accent": "#c8a060"}, "hair": "bald", "eyes": "#3a2a1a", "weapon": "none", "features": ["beard", "belt"]},
    "phaidra":   {"colors": {"hair": "#c8c8d0", "skin": "#efd0b8", "top": "#3a7a8a", "bottom": "#2a5a6a", "boots": "#3a2a2a", "accent": "#f0e8d0"}, "hair": "bob", "eyes": "#4a4a6a", "weapon": "staff", "features": ["long_coat", "collar"]},
    "frank":     {"colors": {"hair": "#5a3a1a", "skin": "#efc8a6", "top": "#4a7a4a", "bottom": "#5a4a3a", "boots": "#2a1a10", "accent": "#e8e0c8"}, "hair": "short", "eyes": "#3a6ad0", "weapon": "none", "features": ["collar", "belt"]},
    "marble":    {"colors": {"hair": "#b8b8c0", "skin": "#e8c8b0", "top": "#7a5a4a", "bottom": "#6a4a3a", "boots": "#2a1a10", "accent": "#d8c8a8"}, "hair": "bun", "eyes": "#4a4a6a", "weapon": "none", "features": ["skirt", "collar"]},
    "mayor":     {"colors": {"hair": "#8a8a90", "skin": "#efc8a6", "top": "#3a3a4a", "bottom": "#2a2a3a", "boots": "#1a1a1a", "accent": "#c0b090"}, "hair": "bald", "eyes": "#2a2a2a", "weapon": "none", "features": ["long_coat", "collar", "belt", "beard"]},
    "remiel":    {"colors": {"hair": "#f0d890", "skin": "#f4dcc8", "top": "#f4f0e8", "bottom": "#e8e4dc", "boots": "#d0c8b8", "accent": "#f8f4e0"}, "hair": "long", "eyes": "#3a7ad8", "weapon": "none", "features": ["wings", "long_coat", "collar"]},
    "forcystus": {"colors": {"hair": "#3aa0a0", "skin": "#efc8a6", "top": "#2a4a9a", "bottom": "#1a2a5a", "boots": "#111122", "accent": "#d0d0e0"}, "hair": "spiky_back", "eyes": "#3a3a3a", "weapon": "none", "features": ["cannon_arm", "pauldrons", "collar", "belt"]},
    "botta":     {"colors": {"hair": "#2a2a2a", "skin": "#d8a880", "top": "#3a4a8a", "bottom": "#2a2a4a", "boots": "#1a1a1a", "accent": "#a0a8c0"}, "hair": "short", "eyes": "#2a2a2a", "weapon": "sword", "features": ["collar", "belt", "pauldrons"]},
    "yuan":      {"colors": {"hair": "#5ab0e0", "skin": "#f0d0b8", "top": "#4a4a8a", "bottom": "#2a2a5a", "boots": "#1a1a2a", "accent": "#e0e8f8"}, "hair": "long", "eyes": "#3a7ad8", "weapon": "none", "features": ["cape", "collar", "pauldrons"]},
    "mithos":    {"colors": {"hair": "#f0e090", "skin": "#f4dcc8", "top": "#3a8a6a", "bottom": "#2a6a4a", "boots": "#2a2a2a", "accent": "#f0f0e0"}, "hair": "long", "eyes": "#3a7ad8", "weapon": "none", "features": ["fringe", "collar"]},
    "desian_whip": {"colors": {"hair": "#1a1a2a", "skin": "#1a1a2a", "top": "#5a2a7a", "bottom": "#3a1a5a", "boots": "#111122", "accent": "#c0c0d0"}, "hair": "helmet", "eyes": "#ff3030", "weapon": "whip", "features": ["pauldrons"]},
}
ENEMY_HUMANOIDS = {
    "golem": {"colors": {"hair": "#6a6a70", "skin": "#7a7a80", "top": "#6a6a72", "bottom": "#5a5a62", "boots": "#4a4a50", "accent": "#8a8a90"}, "hair": "bald", "eyes": "#f0c040", "weapon": "none", "features": ["pauldrons", "greaves", "belt"]},
    "zombie": {"colors": {"hair": "#3a4a3a", "skin": "#7fa37a", "top": "#4a4a3a", "bottom": "#3a3a2a", "boots": "#222222", "accent": "#555555"}, "hair": "bald", "eyes": "#d0d040", "weapon": "none", "features": []},
    "desian": {"colors": {"hair": "#1a1a2a", "skin": "#1a1a2a", "top": "#2a3a7a", "bottom": "#1a2a5a", "boots": "#111122", "accent": "#c0c0d0"}, "hair": "helmet", "eyes": "#ff3030", "weapon": "sword", "features": ["pauldrons"]},
    "vidarr": {"colors": {"hair": "#5a3a1a", "skin": "#d9a877", "top": "#6a4a2a", "bottom": "#3a2a1a", "boots": "#222222", "accent": "#999999"}, "hair": "bald", "eyes": "#3a2a1a", "weapon": "hammer", "features": ["belt", "pauldrons", "beard"]},
}
COMMON = {"metal": "#d8dde6", "wood": "#5a3a1e", "dark": "#1a1216"}

def build_character(cid, colors, spec):
    new_body = body.copy()
    new_body.data = body.data.copy()
    new_body.name = f"Body_{cid}"
    bpy.context.collection.objects.link(new_body)
    allc = dict(COMMON); allc.update(colors)
    colorize_body(new_body, allc)
    mats = {r: new_body.data.materials[REGIONS.index(r)] for r in REGIONS}
    parts = [new_body]
    hair = spec.get("hair", "short")
    if hair == "helmet":
        parts.append(make_sphere("helmet", 0.128, Vector((0, 0.01, 1.655)), mats["accent"], HEAD, scale=(1.0, 1.1, 1.0)))
        parts.append(make_box("visor", (0.16, 0.02, 0.03), Vector((0, -0.1, 1.615)), new_material("visor", hex_to_rgb(spec.get("eyes", "#ff3030"))), HEAD))
    else:
        parts += make_eyes(mats, spec.get("eyes", "#3a3a3a"))
        parts += make_hair(hair, mats)
    for f in spec.get("features", []):
        parts += make_feature(f, mats, allc)
    parts += make_weapon(spec.get("weapon", "none"), mats)
    return parts

def export_selection(path, objs, animations):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    kwargs = dict(filepath=path, export_format='GLB', use_selection=True, export_apply=True,
                  export_animations=animations, export_yup=True, export_skins=True, export_materials='EXPORT')
    if animations:
        kwargs.update(export_animation_mode='NLA_TRACKS', export_nla_strips=True, export_force_sampling=True,
                      export_frame_range=False, export_optimize_animation_size=True)
    bpy.ops.export_scene.gltf(**kwargs)
    print("EXPORTED", path)

ONLY = [a for a in sys.argv[sys.argv.index("--") + 2:]]   # optional: character ids to (re)build
SKIP_ANIM = "--no-anim" in ONLY
ONLY = [a for a in ONLY if not a.startswith("--")]

# ---------- 3. export animation library ----------
if not SKIP_ANIM and not ONLY:
    export_selection(OUT_ANIM, [body], True)

# ---------- 4. export characters (no animations) ----------
for t in list(rig.animation_data.nla_tracks):
    rig.animation_data.nla_tracks.remove(t)
body.hide_set(True)
ALL = {}
for cid, cdata in CHARACTERS.items():
    ALL[cid] = (cdata["colors"], EXTRA[cid])
for nid, n in NPCS.items():
    ALL[nid] = (n["colors"], n)
for eid, e in ENEMY_HUMANOIDS.items():
    ALL[eid] = (e["colors"], e)
for cid, (colors, spec) in ALL.items():
    if ONLY and cid not in ONLY:
        continue
    parts = build_character(cid, colors, spec)
    export_selection(os.path.join(OUT_DIR, f"{cid}.glb"), parts, False)
    for p in parts:
        delete_obj(p)
print("ALL DONE", len(ALL))
