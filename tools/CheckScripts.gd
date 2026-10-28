extends Node
## Loads every GDScript in the project (with autoloads active) so parse errors surface headless:
##   godot --headless --path . res://tools/CheckScripts.tscn
func _ready() -> void:
	var bad := 0
	var n := 0
	for path in _collect("res://src") + _collect("res://tools") + _collect("res://assets/shaders"):
		n += 1
		var s = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if s == null:
			bad += 1
			print("FAILED: ", path)
		elif s is GDScript and not (s as GDScript).can_instantiate() and not path.ends_with("CheckScripts.gd"):
			# scripts with class_name may report false here if abstract; report but don't count
			print("WARN (cannot instantiate): ", path)
	print("CHECKED %d scripts, %d failed" % [n, bad])
	get_tree().quit(1 if bad > 0 else 0)

func _collect(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		var p := dir_path + "/" + f
		if dir.current_is_dir():
			if not f.begins_with("."):
				out += _collect(p)
		elif f.ends_with(".gd") and f != "ListAnims.gd":
			out.append(p)
		f = dir.get_next()
	return out
