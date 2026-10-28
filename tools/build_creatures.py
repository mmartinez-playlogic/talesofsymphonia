"""Procedural low-poly creatures with simple rigs and keyframed animations (Idle, Run, Attack, Hurt, Death).
Usage: blender -b --python tools/build_creatures.py -- <project_root>
"""
import bpy, bmesh, os, sys, math
from mathutils import Vector, Euler

ROOT = sys.argv[sys.argv.index("--") + 1]
OUT_DIR = os.path.join(ROOT, "assets/characters")
FPS = 30

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS

def mat(name, rgb):
    m = bpy.data.materials.new(name); m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb, 1)
    return m

def sphere(name, r, center, material, scale=(1, 1, 1), segs=10):
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=max(4, segs // 2 + 1), radius=r)
    for v in bm.verts:
        v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2])) + Vector(center)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); me.materials.append(material)
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); return o

def cone(name, r1, r2, depth, center, material, rot=(0, 0, 0), segs=8):
    bm = bmesh.new(); bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=r1, radius2=r2, depth=depth)
    e = Euler(rot)
    for v in bm.verts:
        v.co = (e.to_matrix() @ v.co) + Vector(center)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free(); me.materials.append(material)
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); return o

def join(objs, name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object; o.name = name
    return o

def make_rig(name, bones):
    """bones: list of (name, parent, head, tail)."""
    arm = bpy.data.armatures.new(name + "_arm")
    rig = bpy.data.objects.new("Rig", arm)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='EDIT')
    eb = {}
    for bname, parent, head, tail in bones:
        b = arm.edit_bones.new(bname); b.head = Vector(head); b.tail = Vector(tail)
        if parent: b.parent = eb[parent]
        eb[bname] = b
    bpy.ops.object.mode_set(mode='OBJECT')
    return rig

def skin(obj, rig, weights):
    """weights: function(vertex_co) -> {bone: w}."""
    for b in rig.data.bones:
        obj.vertex_groups.new(name=b.name)
    for v in obj.data.vertices:
        for b, w in weights(v.co).items():
            obj.vertex_groups[b].add([v.index], w, 'REPLACE')
    mod = obj.modifiers.new("Armature", 'ARMATURE'); mod.object = rig
    obj.parent = rig

def key(rig, action_name, frames, length, loop):
    """frames: {frame: {bone: (loc(x,y,z) or None, rot_euler(x,y,z) or None)}}."""
    ad = rig.animation_data or rig.animation_data_create()
    act = bpy.data.actions.new(action_name)
    ad.action = act
    try:
        if hasattr(act, "slots"):
            slot = act.slots.new('OBJECT', rig.name)
            ad.action_slot = slot
    except Exception as e:
        print("slot", e)
    for f, bones in frames.items():
        for bname, (loc, rot) in bones.items():
            pb = rig.pose.bones[bname]
            pb.rotation_mode = 'XYZ'
            if loc is not None:
                pb.location = Vector(loc); pb.keyframe_insert("location", frame=f)
            if rot is not None:
                pb.rotation_euler = Euler([math.radians(a) for a in rot]); pb.keyframe_insert("rotation_euler", frame=f)
    for fc in (act.fcurves if hasattr(act, "fcurves") else []):
        for kp in fc.keyframe_points: kp.interpolation = 'BEZIER'
    track = ad.nla_tracks.new(); track.name = action_name
    strip = track.strips.new(action_name, 0, act)
    try:
        strip.action_slot = act.slots[0]
    except Exception: pass
    track.mute = True
    ad.action = None

def export(path, rig, parts):
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts: p.select_set(True)
    rig.select_set(True); bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_apply=True,
                              export_animations=True, export_animation_mode='NLA_TRACKS', export_nla_strips=True,
                              export_force_sampling=True, export_yup=True, export_skins=True)
    print("EXPORTED", path)

# ---------------- WOLF ----------------
def build_wolf():
    reset()
    fur = mat("fur", (0.42, 0.40, 0.44)); dark = mat("dark", (0.12, 0.10, 0.12)); eye = mat("eye", (0.9, 0.75, 0.2))
    # forward = -Y
    body = sphere("body", 0.32, (0, 0.05, 0.55), fur, scale=(0.7, 1.5, 0.8))
    chest = sphere("chest", 0.26, (0, -0.35, 0.58), fur, scale=(0.9, 1.0, 1.0))
    head = sphere("head", 0.19, (0, -0.72, 0.72), fur, scale=(0.9, 1.1, 0.85))
    snout = sphere("snout", 0.1, (0, -0.92, 0.66), fur, scale=(0.8, 1.3, 0.7))
    nose = sphere("nose", 0.035, (0, -1.04, 0.68), dark)
    ears = [cone(f"ear{i}", 0.06, 0.0, 0.16, (sx * 0.1, -0.7, 0.92), fur, rot=(math.radians(-15), 0, 0)) for i, sx in enumerate((-1, 1))]
    eyes = [sphere(f"eye{i}", 0.03, (sx * 0.09, -0.86, 0.76), eye, segs=6) for i, sx in enumerate((-1, 1))]
    tail = cone("tail", 0.07, 0.02, 0.45, (0, 0.62, 0.62), fur, rot=(math.radians(-60), 0, 0))
    legs = []
    for i, (x, y) in enumerate([(-0.15, -0.3), (0.15, -0.3), (-0.15, 0.35), (0.15, 0.35)]):
        legs.append(cone(f"leg{i}", 0.08, 0.05, 0.5, (x, y, 0.27), fur))
        legs.append(sphere(f"paw{i}", 0.07, (x, y - 0.03, 0.05), dark, scale=(1, 1.3, 0.6), segs=6))
    mesh = join([body, chest, head, snout, nose, *ears, *eyes, tail, *legs], "Mesh")
    rig = make_rig("wolf", [
        ("root", None, (0, 0, 0), (0, 0, 0.3)),
        ("spine", "root", (0, 0.3, 0.55), (0, -0.3, 0.58)),
        ("head", "spine", (0, -0.5, 0.62), (0, -0.9, 0.7)),
        ("tail", "spine", (0, 0.4, 0.6), (0, 0.8, 0.85)),
        ("leg_fl", "spine", (-0.15, -0.3, 0.5), (-0.15, -0.3, 0.0)),
        ("leg_fr", "spine", (0.15, -0.3, 0.5), (0.15, -0.3, 0.0)),
        ("leg_bl", "spine", (-0.15, 0.35, 0.5), (-0.15, 0.35, 0.0)),
        ("leg_br", "spine", (0.15, 0.35, 0.5), (0.15, 0.35, 0.0)),
    ])
    def w(co):
        if co.y < -0.5 and co.z > 0.45: return {"head": 1.0}
        if co.y > 0.5 and co.z > 0.5: return {"tail": 1.0}
        if co.z < 0.45:
            side = "l" if co.x < 0 else "r"; fb = "f" if co.y < 0 else "b"
            return {f"leg_{fb}{side}": 1.0}
        return {"spine": 1.0}
    skin(mesh, rig, w)
    key(rig, "Idle", {0: {"spine": (None, (0, 0, 0)), "head": (None, (0, 0, 0)), "tail": (None, (0, 0, 0))},
                      15: {"spine": ((0, 0, 0.02), (1, 0, 0)), "head": (None, (3, 0, 0)), "tail": (None, (0, 0, 15))},
                      30: {"spine": ((0, 0, 0), (0, 0, 0)), "head": (None, (0, 0, 0)), "tail": (None, (0, 0, -15))},
                      45: {"spine": ((0, 0, 0.02), (1, 0, 0)), "head": (None, (3, 0, 0)), "tail": (None, (0, 0, 15))},
                      60: {"spine": ((0, 0, 0), (0, 0, 0)), "head": (None, (0, 0, 0)), "tail": (None, (0, 0, 0))}}, 60, True)
    gal = {}
    for f in range(0, 25, 4):
        t = f / 24.0 * math.tau
        gal[f] = {"leg_fl": (None, (35 * math.sin(t), 0, 0)), "leg_br": (None, (35 * math.sin(t), 0, 0)),
                  "leg_fr": (None, (35 * math.sin(t + math.pi), 0, 0)), "leg_bl": (None, (35 * math.sin(t + math.pi), 0, 0)),
                  "spine": ((0, 0, 0.06 * abs(math.sin(t))), (6 * math.sin(t), 0, 0)), "head": (None, (-5 * math.sin(t), 0, 0))}
    key(rig, "Run", gal, 24, True)
    key(rig, "Attack", {0: {"spine": ((0, 0, 0), (0, 0, 0)), "head": (None, (0, 0, 0))},
                        6: {"spine": ((0, 0.15, 0.05), (-15, 0, 0)), "head": (None, (-20, 0, 0))},
                        12: {"spine": ((0, -0.35, 0.1), (20, 0, 0)), "head": (None, (25, 0, 0))},
                        22: {"spine": ((0, 0, 0), (0, 0, 0)), "head": (None, (0, 0, 0))}}, 22, False)
    key(rig, "Hurt", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 5: {"spine": ((0, 0.2, 0.05), (-12, 0, 8))}, 14: {"spine": ((0, 0, 0), (0, 0, 0))}}, 14, False)
    key(rig, "Death", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 12: {"spine": ((0, 0.1, -0.1), (0, 0, 60))}, 24: {"spine": ((0, 0.1, -0.45), (0, 0, 90))}}, 24, False)
    export(os.path.join(OUT_DIR, "wolf.glb"), rig, [mesh])

# ---------------- RABBIT ----------------
def build_rabbit():
    reset()
    fur = mat("fur", (0.85, 0.78, 0.68)); pink = mat("pink", (0.95, 0.6, 0.7)); dark = mat("dark", (0.1, 0.1, 0.1))
    body = sphere("body", 0.22, (0, 0.0, 0.3), fur, scale=(0.9, 1.2, 1.0))
    head = sphere("head", 0.16, (0, -0.2, 0.5), fur)
    ears = [cone(f"ear{i}", 0.045, 0.02, 0.35, (sx * 0.07, -0.18, 0.78), fur) for i, sx in enumerate((-1, 1))]
    inner = [cone(f"inner{i}", 0.02, 0.01, 0.25, (sx * 0.07, -0.21, 0.78), pink) for i, sx in enumerate((-1, 1))]
    eyes = [sphere(f"eye{i}", 0.03, (sx * 0.08, -0.33, 0.54), dark, segs=6) for i, sx in enumerate((-1, 1))]
    tail = sphere("tail", 0.07, (0, 0.26, 0.32), fur, segs=6)
    feet = [sphere(f"foot{i}", 0.07, (sx * 0.12, 0.05, 0.06), fur, scale=(1, 1.8, 0.7), segs=6) for i, sx in enumerate((-1, 1))]
    mesh = join([body, head, *ears, *inner, *eyes, tail, *feet], "Mesh")
    rig = make_rig("rabbit", [("root", None, (0, 0, 0), (0, 0, 0.2)), ("spine", "root", (0, 0.1, 0.25), (0, -0.1, 0.35)),
                              ("head", "spine", (0, -0.15, 0.45), (0, -0.3, 0.6)), ("ears", "head", (0, -0.18, 0.62), (0, -0.18, 0.95))])
    def w(co):
        if co.z > 0.62: return {"ears": 1.0}
        if co.y < -0.12 and co.z > 0.38: return {"head": 1.0}
        return {"spine": 1.0}
    skin(mesh, rig, w)
    key(rig, "Idle", {0: {"spine": ((0, 0, 0), (0, 0, 0)), "ears": (None, (0, 0, 0))}, 20: {"spine": ((0, 0, 0.015), (0, 0, 0)), "ears": (None, (-10, 0, 0))},
                      40: {"spine": ((0, 0, 0), (0, 0, 0)), "ears": (None, (0, 0, 0))}}, 40, True)
    hop = {}
    for f in range(0, 21, 4):
        t = f / 20.0
        h = 0.25 * math.sin(t * math.pi)
        hop[f] = {"spine": ((0, 0, h), (-20 * math.sin(t * math.pi), 0, 0)), "ears": (None, (25 * math.sin(t * math.pi), 0, 0))}
    key(rig, "Run", hop, 20, True)
    key(rig, "Attack", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 5: {"spine": ((0, 0.1, 0.1), (-20, 0, 0))}, 10: {"spine": ((0, -0.3, 0.05), (25, 0, 0))}, 18: {"spine": ((0, 0, 0), (0, 0, 0))}}, 18, False)
    key(rig, "Hurt", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 5: {"spine": ((0, 0.15, 0.05), (-15, 0, 0))}, 12: {"spine": ((0, 0, 0), (0, 0, 0))}}, 12, False)
    key(rig, "Death", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 15: {"spine": ((0, 0.1, -0.2), (0, 0, 90))}}, 15, False)
    export(os.path.join(OUT_DIR, "rabbit.glb"), rig, [mesh])

# ---------------- BEE ----------------
def build_bee():
    reset()
    yellow = mat("yellow", (0.95, 0.75, 0.15)); dark = mat("dark", (0.15, 0.12, 0.1)); wing = mat("wing", (0.85, 0.9, 1.0))
    body = sphere("body", 0.18, (0, 0.05, 0.9), yellow, scale=(0.9, 1.4, 0.9))
    stripes = [sphere(f"stripe{i}", 0.183, (0, 0.05 + y, 0.9), dark, scale=(0.9, 0.18, 0.9)) for i, y in enumerate((0.0, 0.12))]
    head = sphere("head", 0.12, (0, -0.22, 0.93), dark)
    eyes = [sphere(f"eye{i}", 0.045, (sx * 0.07, -0.3, 0.97), wing, segs=6) for i, sx in enumerate((-1, 1))]
    stinger = cone("stinger", 0.04, 0.0, 0.18, (0, 0.36, 0.88), dark, rot=(math.radians(90), 0, 0))
    wings = [sphere(f"wing{i}", 0.16, (sx * 0.2, 0.0, 1.05), wing, scale=(1.6, 0.8, 0.1), segs=8) for i, sx in enumerate((-1, 1))]
    mesh = join([body, *stripes, head, *eyes, stinger, *wings], "Mesh")
    rig = make_rig("bee", [("root", None, (0, 0, 0), (0, 0, 0.3)), ("spine", "root", (0, 0.2, 0.9), (0, -0.2, 0.9)),
                           ("wing_l", "spine", (-0.05, 0, 1.0), (-0.4, 0, 1.0)), ("wing_r", "spine", (0.05, 0, 1.0), (0.4, 0, 1.0))])
    def w(co):
        if co.z > 1.0 and abs(co.x) > 0.08: return {"wing_l" if co.x < 0 else "wing_r": 1.0}
        return {"spine": 1.0}
    skin(mesh, rig, w)
    flap = {}
    for f in range(0, 13, 2):
        a = 40 * math.sin(f / 12.0 * math.tau * 2)
        flap[f] = {"wing_l": (None, (0, -a, 0)), "wing_r": (None, (0, a, 0)), "spine": ((0, 0, 0.05 * math.sin(f / 12.0 * math.tau)), None)}
    key(rig, "Idle", flap, 12, True)
    key(rig, "Run", {k: {**v, "spine": ((0, 0, 0.05 * math.sin(k / 12.0 * math.tau)), (-15, 0, 0))} for k, v in flap.items()}, 12, True)
    key(rig, "Attack", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 6: {"spine": ((0, 0.15, 0.1), (-25, 0, 0))}, 10: {"spine": ((0, -0.4, -0.1), (30, 0, 0))}, 18: {"spine": ((0, 0, 0), (0, 0, 0))}}, 18, False)
    key(rig, "Hurt", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 5: {"spine": ((0, 0.2, 0.0), (-15, 0, 10))}, 12: {"spine": ((0, 0, 0), (0, 0, 0))}}, 12, False)
    key(rig, "Death", {0: {"spine": ((0, 0, 0), (0, 0, 0))}, 15: {"spine": ((0, 0, -0.85), (0, 0, 180))}}, 15, False)
    export(os.path.join(OUT_DIR, "bee.glb"), rig, [mesh])

build_wolf(); build_rabbit(); build_bee()
print("ALL DONE")
