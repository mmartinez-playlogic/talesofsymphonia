extends SceneTree
func _init() -> void:
	var scene: PackedScene = load("res://assets/anim/humanoid_anims.glb")
	var inst := scene.instantiate()
	print("ROOT children: ", inst.get_children().map(func(c): return c.name + ":" + c.get_class()))
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	if ap == null:
		print("NO AnimationPlayer")
	else:
		print("libs: ", ap.get_animation_library_list())
		var names := ap.get_animation_list()
		print("count: ", names.size())
		print(names)
		if names.size() > 0:
			var a := ap.get_animation(names[0])
			print("track0 path: ", a.track_get_path(0), " tracks ", a.get_track_count())
	var sk := inst.find_child("Skeleton3D", true, false)
	print("skeleton: ", sk, " bones ", sk.get_bone_count() if sk else -1, " parent ", sk.get_parent().name if sk else "")
	var c: PackedScene = load("res://assets/characters/lloyd.glb")
	var ci := c.instantiate()
	print("LLOYD children: ", ci.get_children().map(func(c): return c.name + ":" + c.get_class()))
	var sk2 := ci.find_child("Skeleton3D", true, false)
	print("lloyd skeleton parent ", sk2.get_parent().name if sk2 else "none", " meshes ", ci.find_children("*", "MeshInstance3D", true, false).size())
	quit()
