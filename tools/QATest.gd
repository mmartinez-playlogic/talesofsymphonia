extends Node
## QA sweep (headless):
##  1) talk to / use EVERY interactable in every map and story state, assert it finishes and unlocks the player
##  2) fuzz the pause menu, shop and battle with thousands of random key presses
##  3) save mid-story and Continue from the title screen
##   godot --headless --path . --max-fps 0 --fixed-fps 60 res://tools/QATest.tscn

const STATES := [
	{"map": "iselia_school", "flags": ["oracle_seen"]},
	{"map": "iselia_village", "flags": ["oracle_seen", "frank_talked"]},
	{"map": "iselia_village", "flags": ["oracle_seen", "frank_talked", "temple_done"], "party": ["lloyd", "genis"]},
	{"map": "iselia_village", "flags": ["oracle_seen", "frank_talked", "temple_done", "colette_house_done", "genis_house_done", "gate_done", "ranch_visited"], "party": ["lloyd", "genis"]},
	{"map": "iselia_village", "flags": ["temple_done", "ranch_visited", "night_dirk", "exiled", "frank_talked"], "party": ["lloyd", "genis"]},
	{"map": "iselia_forest", "flags": ["oracle_seen", "frank_talked", "temple_arrived"]},
	{"map": "martel_temple_ext", "flags": ["vidarr_defeated", "temple_arrived", "temple_ambush_started"], "party": ["lloyd", "colette", "genis", "kratos"]},
	{"map": "martel_temple_ext", "flags": ["vidarr_defeated", "temple_done", "temple_arrived", "temple_ambush_started"], "party": ["lloyd", "genis"]},
	{"map": "martel_temple", "flags": ["vidarr_defeated", "temple_entered"], "party": ["lloyd", "colette", "genis", "kratos"]},
	{"map": "martel_temple", "flags": ["vidarr_defeated", "temple_entered", "got_ring", "seal_open", "temple_done"], "party": ["lloyd", "genis"]},
	{"map": "iselia_ranch", "flags": ["temple_done", "ranch_visited", "ranch_event_started"], "party": ["lloyd", "genis"]},
	{"map": "dirks_house", "flags": ["temple_done", "ranch_visited", "night_dirk", "dirk_morning"], "party": ["lloyd", "genis"]},
	{"map": "dirks_house", "flags": ["temple_done", "ranch_visited", "night_dirk", "dirk_morning", "exiled"], "party": ["lloyd", "genis"]},
	{"map": "world_sylvarant", "spawn": "iselia", "flags": ["temple_done", "ranch_visited", "world_first_time", "exiled", "salvation_arrive", "renegades_cordon"], "party": ["lloyd", "genis"]},
	{"map": "triet_desert", "flags": ["exiled", "triet_arrived"], "party": ["lloyd", "genis"]},
]

var _fails := 0
var _ok := 0

func _ready() -> void:
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	await get_tree().process_frame
	await _sweep()
	await _fuzz_menus()
	await _fuzz_battle()
	await _continue_from_title()
	print("QA TEST DONE: %d ok, %d failures" % [_ok, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _check(cond: bool, what: String) -> void:
	if cond:
		_ok += 1
	else:
		_fails += 1
		print("  [FAIL] ", what)

func _field() -> Field:
	var s := get_tree().current_scene
	return s as Field if s is Field else null

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame

func _load_state(st: Dictionary) -> Field:
	Game.new_game()
	for f in st.get("flags", []):
		Game.set_flag(f, true)
	if st.has("party"):
		Game.set_party(st["party"])
	Game.add_item("apple_gel", 5)
	Router.goto_map(st["map"], st.get("spawn", "default"))
	var t := 0
	while t < 2400:
		t += 1
		await get_tree().process_frame
		var f := _field()
		if f and f.map_id == st["map"] and f.player and f.player.can_move and not f.event_running and not Router._busy:
			return f
		if f and (f.event_running or f.dialogue.is_active()) and t % 6 == 0:
			await _tap("confirm")
	return null

## Wait for an interaction/event to end, pressing confirm for dialogues/choices.
func _drive_until_free(timeout_frames := 3600) -> bool:
	var t := 0
	while t < timeout_frames:
		t += 1
		var f := _field()
		if f == null:
			# a scene change (battle or map) happened: wait for it and keep driving
			await get_tree().process_frame
			var s := get_tree().current_scene
			if s is BattleManager:
				var bm := s as BattleManager
				if bm.phase == BattleManager.Phase.FIGHT:
					for e in bm.enemies:
						if e.is_alive():
							e.take_hit(null, 9999999, 0.0, false, true, false)
				if t % 10 == 0:
					await _tap("confirm")
			continue
		if not f.event_running and f.player and f.player.can_move and not Router._busy:
			return true
		if (f._shop and f._shop._open) or (f._pause and f._pause._open):
			await _tap("cancel")
		elif t % 6 == 0:
			await _tap("confirm")
		else:
			await get_tree().process_frame
	return false

func _sweep() -> void:
	print("== interaction sweep")
	for st in STATES:
		var f := await _load_state(st)
		_check(f != null, "state loads: %s %s" % [st["map"], str(st.get("flags", []))])
		if f == null:
			continue
		var names: Array = []
		for n in f.get_children():
			if n.has_method("interact") and n is Node3D:
				names.append(n.name)
		print("  %s: %d interactables" % [st["map"], names.size()])
		for nm in names:
			f = _field()
			if f == null or f.map_id != st["map"]:
				f = await _load_state(st)
				if f == null:
					break
			var n: Node3D = f.get_node_or_null(NodePath(nm))
			if n == null:
				continue  # removed by an earlier interaction (e.g. chest, seal)
			f.player.global_position = n.global_position + Vector3(0, 0.1, 1.3)
			await get_tree().physics_frame
			f._on_interact(n)
			var ok := await _drive_until_free()
			_check(ok, "interaction finishes: %s/%s" % [st["map"], nm])
			if ok:
				print("    [OK] ", nm)

func _fuzz_menus() -> void:
	print("== menu fuzz")
	var f := await _load_state({"map": "iselia_village", "flags": ["oracle_seen", "frank_talked", "temple_done"], "party": ["lloyd", "genis"]})
	_check(f != null, "fuzz field ready")
	if f == null:
		return
	Game.add_member("kratos")
	Game.set_party(["lloyd", "genis", "kratos"])
	for r in DB.recipes:
		Game.learn_recipe(r)
		for ing in DB.recipes[r]["ingredients"]:
			Game.add_item(ing, 5)
	for it in ["iron_sword", "leather_armor", "talisman", "ribbon", "ex_gem_1", "ex_gem_2", "life_bottle", "orange_gel", "steel_sword"]:
		Game.add_item(it, 3)
	Game.gald = 99999
	Game.members["genis"]["hp"] = 0
	var keys := ["move_up", "move_down", "move_left", "move_right", "confirm", "confirm", "cancel"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for round_i in 6:
		var done := [false]
		(func(): await f._pause.open(); done[0] = true).call()
		for i in 400:
			await _tap(keys[rng.randi() % keys.size()])
			if done[0]:
				break
		for i in 12:
			if done[0]:
				break
			await _tap("cancel")
		_check(done[0], "pause menu fuzz round %d closes" % round_i)
		var done2 := [false]
		(func(): await f.open_shop(["iselia", "triet", "salvation"][round_i % 3]); done2[0] = true).call()
		for i in 300:
			await _tap(keys[rng.randi() % keys.size()])
			if done2[0]:
				break
		for i in 6:
			if done2[0]:
				break
			await _tap("cancel")
		_check(done2[0], "shop fuzz round %d closes" % round_i)
	_check(Game.gald >= 0, "gald never negative (%d)" % Game.gald)
	for id in Game.inventory:
		_check(int(Game.inventory[id]) > 0, "no zero/negative stacks (%s)" % id)
	for id in Game.members:
		var m: Dictionary = Game.members[id]
		_check(int(m["hp"]) <= Game.max_hp(id) and int(m["hp"]) >= 0, "hp within bounds for %s" % id)

func _fuzz_battle() -> void:
	print("== battle fuzz")
	Game.new_game()
	Game.add_member("kratos")
	Game.set_party(["lloyd", "colette", "genis", "kratos"])
	Game.add_item("apple_gel", 5)
	Game.add_item("life_bottle", 2)
	Router.start_battle({"enemies": ["desian_soldier", "wolf", "bee"], "advantage": "normal", "map": "iselia_forest"})
	var keys := ["move_up", "move_down", "move_left", "move_right", "attack", "attack", "arte", "guard", "target_next", "menu", "confirm", "cancel", "unison", "free_run"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bm: BattleManager = null
	for i in 3000:
		var s := get_tree().current_scene
		if s is BattleManager:
			bm = s
			if bm.phase == BattleManager.Phase.WIN or bm.phase == BattleManager.Phase.LOSE:
				break
			if i % 200 == 0:
				bm.unison_gauge = 100.0
		await _tap(keys[rng.randi() % keys.size()])
	_check(bm != null, "battle fuzz ran")
	if bm:
		print("  battle fuzz ended in phase ", BattleManager.Phase.keys()[bm.phase])
	get_tree().change_scene_to_file("res://tools/Blank.tscn")
	await get_tree().process_frame

func _continue_from_title() -> void:
	print("== save + Continue from title")
	var backup := ""
	if FileAccess.file_exists("user://save_0.json"):
		backup = FileAccess.get_file_as_string("user://save_0.json")
	var f := await _load_state({"map": "dirks_house", "flags": ["temple_done", "ranch_visited", "night_dirk", "dirk_morning"], "party": ["lloyd", "genis"]})
	_check(f != null, "save state ready")
	Game.current_map = "dirks_house"
	Game.spawn_point = "default"
	Game.gald = 4321
	Game.save(0)
	Game.new_game()
	get_tree().change_scene_to_file("res://src/Main.tscn")
	for i in 30:
		await get_tree().process_frame
	await _tap("move_down")
	await _tap("confirm")
	var reached := false
	for i in 1200:
		await get_tree().process_frame
		var ff := _field()
		if ff and ff.map_id == "dirks_house":
			reached = true
			break
	_check(reached, "Continue loads the saved map")
	_check(Game.gald == 4321, "Continue restores gald")
	_check(Game.get_flag("night_dirk", false), "Continue restores flags")
	if backup != "":
		var w := FileAccess.open("user://save_0.json", FileAccess.WRITE)
		w.store_string(backup)
