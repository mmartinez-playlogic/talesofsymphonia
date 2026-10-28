extends Node
func _ready() -> void:
	var lib := CharacterModel.get_anim_library()
	var names := lib.get_animation_list()
	var out := []
	for n in names:
		out.append("%s(%.2f%s)" % [n, lib.get_animation(n).length, ",L" if lib.get_animation(n).loop_mode != Animation.LOOP_NONE else ""])
	print("ANIMS ", " ".join(out))
	get_tree().quit()
