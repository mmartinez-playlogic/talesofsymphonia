class_name CharacterModel
extends Node3D
## Loads a character GLB (res://assets/characters/<id>.glb), applies toon materials,
## and attaches the shared humanoid animation library so every humanoid shares animations.

const ANIM_LIB_PATH := "res://assets/anim/humanoid_anims.glb"
static var _anim_lib: AnimationLibrary
const LOOPING := ["Idle", "Walk", "Jog_Fwd", "Sprint", "Sword_Idle", "Spell_Simple_Idle", "Zombie_Idle", "Zombie_Walk_Fwd", "Idle_Shield", "Idle_Talking", "Crouch_Idle", "Sitting_Idle", "Sitting_Talking", "Idle_FoldArms"]

var anim: AnimationPlayer
var skeleton: Skeleton3D
var model_root: Node3D
var _current := ""
var humanoid := true

static func get_anim_library() -> AnimationLibrary:
	if _anim_lib:
		return _anim_lib
	var scene: PackedScene = load(ANIM_LIB_PATH)
	var inst := scene.instantiate()
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var lib_names := ap.get_animation_library_list()
	var src: AnimationLibrary = ap.get_animation_library(lib_names[0])
	_anim_lib = AnimationLibrary.new()
	for n in src.get_animation_list():
		var a: Animation = src.get_animation(n).duplicate()
		if n in LOOPING:
			a.loop_mode = Animation.LOOP_LINEAR
		_anim_lib.add_animation(n, a)
	inst.queue_free()
	return _anim_lib

func load_model(model_id: String, outline_thickness := 0.012) -> void:
	for c in get_children():
		c.queue_free()
	var path := "res://assets/characters/%s.glb" % model_id
	if not ResourceLoader.exists(path):
		push_warning("Model not found: " + path)
		_make_placeholder()
		return
	var scene: PackedScene = load(path)
	model_root = scene.instantiate()
	model_root.name = "Model"
	add_child(model_root)
	skeleton = model_root.find_child("Skeleton3D", true, false)
	_apply_toon(model_root, outline_thickness)
	# Creatures carry their own animations; humanoids use the shared library.
	var own: AnimationPlayer = null
	for ap in model_root.find_children("*", "AnimationPlayer", true, false):
		if ap.get_animation_list().size() > 0:
			own = ap
		else:
			ap.queue_free()
	if own != null:
		anim = own
		humanoid = false
		for n in anim.get_animation_list():
			if n in ["Idle", "Run"]:
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	else:
		humanoid = true
		anim = AnimationPlayer.new()
		anim.name = "AnimationPlayer"
		model_root.add_child(anim)
		anim.root_node = anim.get_path_to(model_root)
		anim.add_animation_library("", get_anim_library())
	play("Idle")

func _apply_toon(root: Node, thickness: float) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i)
			var color := Color(0.8, 0.8, 0.8)
			if src is BaseMaterial3D:
				color = (src as BaseMaterial3D).albedo_color
			mi.set_surface_override_material(i, ToonMaterial.make(color, true, thickness))

func _make_placeholder() -> void:
	var mi := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	mi.mesh = capsule
	mi.position.y = 0.85
	mi.set_surface_override_material(0, ToonMaterial.make(Color(0.6, 0.6, 0.7)))
	add_child(mi)

func play(name: String, blend := 0.12, speed := 1.0, force := false) -> void:
	if anim == null:
		return
	if not anim.has_animation(name):
		push_warning("No animation " + name)
		return
	if _current == name and not force:
		return
	_current = name
	anim.play(name, blend, speed)

func is_playing(name: String) -> bool:
	return anim != null and anim.current_animation == name and anim.is_playing()

func anim_length(name: String) -> float:
	if anim and anim.has_animation(name):
		return anim.get_animation(name).length
	return 0.5

func current() -> String:
	return _current
