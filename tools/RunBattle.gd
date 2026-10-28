extends Node
## Boots straight into a battle: godot --path . res://tools/RunBattle.tscn -- --enemies wolf,wolf --shot x.png
func _ready() -> void:
	Game.new_game()
	var args := OS.get_cmdline_user_args()
	var enemies := ["wolf", "wolf"]
	var adv := "normal"
	for i in args.size():
		if args[i] == "--enemies" and i + 1 < args.size():
			enemies = Array(args[i + 1].split(","))
		if args[i] == "--adv" and i + 1 < args.size():
			adv = args[i + 1]
	Router.start_battle({"enemies": enemies, "advantage": adv, "map": "iselia_forest"})
