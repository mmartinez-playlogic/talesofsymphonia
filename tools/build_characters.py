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

def make_eyes(mats):
    # mannequin forward is -Y. Eyes at face height.
    parts = []
    for sx in (-1, 1):
        parts.append(make_sphere(f"eye{sx}", 0.018, Vector((sx * 0.035, -0.095, 1.615)), mats["dark"], HEAD, scale=(1.0, 0.5, 1.4), segs=8))
    return parts

CHARACTERS = json.load(open(os.path.join(ROOT, "src/data/characters.json")))
EXTRA = {
    "lloyd":   {"hair": "spiky", "weapon": "twin_swords"},
    "colette": {"hair": "long", "weapon": "chakram"},
    "genis":   {"hair": "short", "weapon": "kendama"},
    "raine":   {"hair": "bob", "weapon": "staff"},
    "kratos":  {"hair": "spiky", "weapon": "sword"},
    "sheena":  {"hair": "ponytail", "weapon": "cards"},
    "zelos":   {"hair": "long", "weapon": "sword"},
    "presea":  {"hair": "twintails", "weapon": "axe"},
    "regal":   {"hair": "long", "weapon": "none"},
}
ENEMY_HUMANOIDS = {
    "zombie": {"colors": {"hair": "#3a4a3a", "skin": "#7fa37a", "top": "#4a4a3a", "bottom": "#3a3a2a", "boots": "#222222", "accent": "#555555"}, "hair": "bald", "weapon": "none"},
    "desian": {"colors": {"hair": "#1a1a2a", "skin": "#1a1a2a", "top": "#2a3a7a", "bottom": "#1a2a5a", "boots": "#111122", "accent": "#c0c0d0"}, "hair": "helmet", "weapon": "sword"},
    "vidarr": {"colors": {"hair": "#5a3a1a", "skin": "#d9a877", "top": "#6a4a2a", "bottom": "#3a2a1a", "boots": "#222222", "accent": "#999999"}, "hair": "bald", "weapon": "hammer"},
}
COMMON = {"metal": "#d8dde6", "wood": "#5a3a1e", "dark": "#1a1216"}

def build_character(cid, colors, hair, weapon):
    # duplicate body
    new_body = body.copy()
    new_body.data = body.data.copy()
    new_body.name = f"Body_{cid}"
    bpy.context.collection.objects.link(new_body)
    allc = dict(COMMON); allc.update(colors)
    colorize_body(new_body, allc)
    mats = {r: new_body.data.materials[REGIONS.index(r)] for r in REGIONS}
    parts = [new_body]
    parts += make_eyes(mats)
    if hair == "helmet":
        parts.append(make_sphere("helmet", 0.125, Vector((0, 0.01, 1.655)), mats["accent"], HEAD, scale=(1.0, 1.1, 1.0)))
    else:
        parts += make_hair(hair, mats)
    if weapon == "twin_swords":
        parts += make_sword("sword_r", "R", mats, 0.85)
        parts += make_sword("sword_l", "L", mats, 0.85)
    elif weapon == "sword":
        parts += make_sword("sword_r", "R", mats, 1.0)
    elif weapon == "chakram":
        h, d = hand_frame("R")
        parts.append(make_torus("chakram", 0.14, 0.012, h + d * 0.06, mats["metal"], HAND_R))
    elif weapon == "kendama":
        h, d = hand_frame("R")
        parts.append(make_cylinder("kendama_handle", 0.015, 0.22, h + d * 0.08, mats["wood"], HAND_R))
        parts.append(make_sphere("kendama_ball", 0.045, h + d * 0.22, mats["accent"], HAND_R))
    elif weapon == "staff":
        h, d = hand_frame("R")
        parts.append(make_cylinder("staff", 0.016, 1.5, h + d * 0.2, mats["wood"], HAND_R))
        parts.append(make_sphere("staff_orb", 0.05, h + d * 0.97, mats["accent"], HAND_R))
    elif weapon == "axe":
        h, d = hand_frame("R")
        parts.append(make_cylinder("axe_handle", 0.02, 0.9, h + d * 0.3, mats["wood"], HAND_R))
        parts.append(make_box("axe_head", (0.3, 0.04, 0.25), h + d * 0.7 + Vector((0.12, 0, 0)), mats["metal"], HAND_R))
    elif weapon == "hammer":
        h, d = hand_frame("R")
        parts.append(make_cylinder("hammer_handle", 0.03, 1.1, h + d * 0.4, mats["wood"], HAND_R))
        parts.append(make_box("hammer_head", (0.4, 0.22, 0.22), h + d * 0.95, mats["metal"], HAND_R))
    return parts

def export_selection(path, objs, animations):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    kwargs = dict(filepath=path, export_format='GLB', use_selection=True, export_apply=True,
                  export_animations=animations, export_yup=True, export_skins=True,
                  export_materials='EXPORT', export_colors=False if False else None)
    kwargs.pop("export_colors")
    if animations:
        kwargs.update(export_animation_mode='NLA_TRACKS', export_nla_strips=True, export_force_sampling=True,
                      export_frame_range=False, export_optimize_animation_size=True)
    bpy.ops.export_scene.gltf(**kwargs)
    print("EXPORTED", path)

# ---------- 3. export animation library ----------
export_selection(OUT_ANIM, [body], True)

# ---------- 4. export characters (no animations) ----------
# Temporarily strip NLA so character exports carry no animation data.
tracks_backup = []
for t in list(rig.animation_data.nla_tracks):
    tracks_backup.append((t.name, t.strips[0].action, int(t.strips[0].frame_start)))
    rig.animation_data.nla_tracks.remove(t)
body.hide_set(True)
for cid, cdata in CHARACTERS.items():
    ex = EXTRA[cid]
    parts = build_character(cid, cdata["colors"], ex["hair"], ex["weapon"])
    export_selection(os.path.join(OUT_DIR, f"{cid}.glb"), parts, False)
    for p in parts:
        delete_obj(p)
for eid, e in ENEMY_HUMANOIDS.items():
    parts = build_character(eid, e["colors"], e["hair"], e["weapon"])
    export_selection(os.path.join(OUT_DIR, f"{eid}.glb"), parts, False)
    for p in parts:
        delete_obj(p)
print("ALL DONE")
