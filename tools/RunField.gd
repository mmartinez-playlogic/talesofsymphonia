extends Node
## Boots straight into a field map for testing: godot --path . res://tools/RunField.tscn -- --map iselia_forest --shot x.png
func _ready() -> void:
	Game.new_game()
	var args := OS.get_cmdline_user_args()
	var map := "iselia_forest"
	var spawn := "default"
	for i in args.size():
		if args[i] == "--map" and i + 1 < args.size():
			map = args[i + 1]
		if args[i] == "--spawn" and i + 1 < args.size():
			spawn = args[i + 1]
		if args[i] == "--flags" and i + 1 < args.size():
			for f in args[i + 1].split(","):
				Game.set_flag(f, true)
		if args[i] == "--party" and i + 1 < args.size():
			Game.set_party(Array(args[i + 1].split(",")))
	Router.goto_map(map, spawn)
