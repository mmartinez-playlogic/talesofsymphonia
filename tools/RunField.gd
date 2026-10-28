extends Node
## Boots straight into a field map for testing: godot --path . res://tools/RunField.tscn -- --map iselia_forest --shot x.png
func _ready() -> void:
	Game.new_game()
	var args := OS.get_cmdline_user_args()
	var map := "iselia_forest"
	for i in args.size():
		if args[i] == "--map" and i + 1 < args.size():
			map = args[i + 1]
	Router.goto_map(map, "default")
