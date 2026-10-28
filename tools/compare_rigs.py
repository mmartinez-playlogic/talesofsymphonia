import bpy, sys
from mathutils import Matrix
args = sys.argv[sys.argv.index("--")+1:]
MAP = {
 "pelvis":"DEF-hips","spine_01":"DEF-spine.001","spine_02":"DEF-spine.002","spine_03":"DEF-spine.003",
 "neck_01":"DEF-neck","Head":"DEF-head","root":"root",
}
for s,S in (("l","L"),("r","R")):
    MAP.update({f"clavicle_{s}":f"DEF-shoulder.{S}",f"upperarm_{s}":f"DEF-upper_arm.{S}",f"lowerarm_{s}":f"DEF-forearm.{S}",
      f"hand_{s}":f"DEF-hand.{S}",f"thigh_{s}":f"DEF-thigh.{S}",f"calf_{s}":f"DEF-shin.{S}",f"foot_{s}":f"DEF-foot.{S}",f"ball_{s}":f"DEF-toe.{S}"})
    for f in ("index","middle","ring","pinky","thumb"):
        for i in (1,2,3):
            MAP[f"{f}_0{i}_{s}"] = f"DEF-f_{f}.0{i}.{S}" if f!="thumb" else f"DEF-thumb.0{i}.{S}"
def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    arm = [o for o in bpy.data.objects if o.type=='ARMATURE'][0]
    return {b.name: (b.matrix_local.copy(), b.head_local.copy(), b.tail_local.copy()) for b in arm.data.bones}
r1 = load(args[0]); r2 = load(args[1])
bad = 0
for u, d in MAP.items():
    if u not in r2 or d not in r1:
        print("MISSING", u, d); continue
    m2, h2, t2 = r2[u]; m1, h1, t1 = r1[d]
    dh = (h1-h2).length; dt=(t1-t2).length
    diff = max(abs(a-b) for ra, rb in zip(m1, m2) for a, b in zip(ra, rb))
    if diff > 1e-3 or dh > 1e-3:
        bad += 1
        print("DIFF", u, "->", d, "head", round(dh,4), "tail", round(dt,4), "mat", round(diff,4))
print("TOTAL mapped", len(MAP), "mismatched", bad)
