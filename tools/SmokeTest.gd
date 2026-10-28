extends Node
## Headless smoke test: loads every map in every story state, auto-presses Confirm, logs runtime errors.
##   godot --headless --path . res://tools/SmokeTest.tscn
## Each scenario: {map, spawn, flags, party, resume, seconds}

const SCENARIOS := [
	{"map": "iselia_school", "flags": []},
	{"map": "iselia_village", "spawn": "from_school", "flags": ["oracle_seen"]},
	{"map": "iselia_village", "spawn": "from_forest", "flags": ["oracle_seen", "frank_talked", "temple_done"], "party": ["lloyd", "genis"]},
	{"map": "iselia_forest", "flags": ["oracle_seen", "frank_talked"]},
	{"map": "iselia_forest", "spawn": "from_village", "flags": ["temple_done", "colette_house_done"], "party": ["lloyd", "genis"]},
	{"map": "martel_temple_ext", "flags": ["frank_talked"], "seconds": 8},
	{"map": "martel_temple_ext", "flags": ["temple_arrived", "temple_ambush_started"], "resume": "after_temple_desians", "seconds": 8},
	{"map": "martel_temple_ext", "flags": ["temple_arrived", "temple_ambush_started"], "resume": "after_vidarr", "party": ["lloyd", "colette", "genis", "kratos"]},
	{"map": "martel_temple", "flags": ["vidarr_defeated"], "party": ["lloyd", "colette", "genis", "kratos"]},
	{"map": "martel_temple", "flags": ["vidarr_defeated", "temple_entered", "got_ring", "seal_open"], "party": ["lloyd", "colette", "genis", "kratos"]},
	{"map": "iselia_ranch", "flags": ["temple_done", "colette_house_done", "noishe_ran_off"], "party": ["lloyd", "genis"], "seconds": 10},
	{"map": "iselia_ranch", "flags": ["temple_done", "noishe_ran_off", "ranch_event_started"], "resume": "after_ranch_fight", "party": ["lloyd"], "seconds": 8},
	{"map": "dirks_house", "flags": ["temple_done", "ranch_visited"], "party": ["lloyd", "genis"], "seconds": 8},
	{"map": "dirks_house", "flags": ["temple_done", "ranch_visited", "night_dirk"], "party": ["lloyd", "genis"]},
	{"map": "world_sylvarant", "spawn": "iselia", "flags": ["temple_done", "ranch_visited", "night_dirk", "exiled"], "party": ["lloyd", "genis"]},
	{"map": "iselia_village", "spawn": "from_world", "flags": ["temple_done", "ranch_visited", "night_dirk"], "party": ["lloyd", "genis"], "seconds": 8},
	{"map": "iselia_village", "flags": ["temple_done", "ranch_visited", "night_dirk", "raid_started"], "party": ["lloyd", "genis"]},
	{"map": "iselia_village", "flags": ["temple_done", "night_dirk", "raid_started", "raid_fight_done", "plaza_trigger"], "resume": "after_exbelua", "party": ["lloyd", "genis"], "seconds": 10},
	{"map": "triet_desert", "flags": ["exiled", "left_for_journey"], "party": ["lloyd", "genis"]},
	{"battle": ["wolf", "wolf"], "seconds": 6},
	{"battle": ["vidarr"], "party": ["lloyd", "colette", "genis", "kratos"], "seconds": 6},
]

var _press_timer := 0.0
var _pressed := false

func _ready() -> void:
	# survive scene changes: move under the root
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	await get_tree().process_frame
	_run()

func _run() -> void:
	for i in SCENARIOS.size():
		var sc: Dictionary = SCENARIOS[i]
		print("\n=== SCENARIO %d: %s ===" % [i, JSON.stringify(sc)])
		Game.new_game()
		for f in sc.get("flags", []):
			Game.set_flag(f, true)
		if sc.has("party"):
			Game.set_party(sc["party"])
		if sc.has("battle"):
			Game.current_map = "iselia_forest"
			Router.start_battle({"enemies": sc["battle"], "advantage": "normal", "map": "iselia_forest"})
		elif sc.has("resume"):
			Game.flags["resume_event"] = sc["resume"]
			Game.flags["resume_map"] = sc["map"]
			Game.current_map = sc["map"]
			Game.last_field_position = Vector3(0, 0.1, 0)
			Router.return_from_battle()
		else:
			Router.goto_map(sc["map"], sc.get("spawn", "default"))
		var t := 0.0
		var secs: float = float(sc.get("seconds", 14))
		while t < secs:
			var dt := get_process_delta_time()
			t += dt
			_press_timer -= dt
			if _press_timer <= 0:
				_press_timer = 0.12
				_tap("confirm")
			await get_tree().process_frame
		var scene := get_tree().current_scene
		print("--- scene after %0.1fs: %s" % [secs, scene.name if scene else "none"])
	print("\nSMOKE TEST DONE")
	get_tree().quit()

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
