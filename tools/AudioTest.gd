extends Node
## Audio checks (headless): every referenced asset exists, every scene plays the right music,
## and a real-input battle triggers combat sounds.
var _ok := 0
var _fails := 0
func check(c: bool, what: String) -> void:
	if c:
		_ok += 1
	else:
		_fails += 1
		print("  [FAIL] ", what)

func _ready() -> void:
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	_assets()
	await _scene_music()
	await _battle_sounds()
	print("AUDIO TEST DONE: %d passed, %d failed" % [_ok, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _scan(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if d.current_is_dir():
			if not f.begins_with("."):
				_scan(dir_path + "/" + f, out)
		elif f.ends_with(".gd"):
			out.append(dir_path + "/" + f)
		f = d.get_next()

func _assets() -> void:
	print("== assets referenced by code")
	var files: Array = []
	_scan("res://src", files)
	var re_sfx := RegEx.create_from_string(r'(?:Audio\.sfx|c\.sfx)\("([a-z0-9_]+)"')
	var re_mus := RegEx.create_from_string(r'(?:play_music|push_music|c\.music)\("([a-z0-9_]+)"|bgm = "([a-z0-9_]+)"|bgm = "[a-z0-9_]+" if .* else "([a-z0-9_]+)"')
	var sfx_ids := {}
	var mus_ids := {}
	for p in files:
		var src := FileAccess.get_file_as_string(p)
		for m in re_sfx.search_all(src):
			sfx_ids[m.get_string(1)] = p
		for m in re_mus.search_all(src):
			for g in [1, 2, 3]:
				if m.get_string(g) != "":
					mus_ids[m.get_string(g)] = p
	# dynamic ids built in code
	for i in [1, 2, 3]:
		sfx_ids["slash%d" % i] = "Battler.gd"
	for e in ["fire", "earth", "water", "wind", "lightning", "light"]:
		sfx_ids[e] = "BattleManager.gd"
	for id in ["boss", "battle", "key_item", "item", "cook", "ko", "enemy_die"]:
		if Audio.has_sfx(id) or Audio.has_music(id):
			pass
	for id in sfx_ids:
		check(Audio.has_sfx(id), "sfx '%s' exists (used in %s)" % [id, sfx_ids[id]])
	for id in mus_ids:
		if Audio.has_sfx(id) and not Audio.has_music(id):
			continue  # regex also matches sfx names after 'else "' in ternaries
		check(Audio.has_music(id), "music '%s' exists (used in %s)" % [id, mus_ids[id]])
	print("  %d sfx ids, %d music ids referenced" % [sfx_ids.size(), mus_ids.size()])
	for id in ["title", "iselia", "field", "temple", "battle", "boss", "victory", "sad", "tension", "world", "desert", "gameover", "ending"]:
		var st: AudioStream = load("res://assets/audio/music/%s.ogg" % id)
		check(st != null and st.get_length() > 4.0, "music %s loads (%.1fs)" % [id, st.get_length() if st else 0.0])

func _wait(pred: Callable, frames := 1500) -> bool:
	for i in frames:
		await get_tree().process_frame
		if pred.call():
			return true
	return false

func _tap(a: String) -> void:
	var ev := InputEventAction.new(); ev.action = a; ev.pressed = true; Input.parse_input_event(ev)
	await get_tree().physics_frame
	var up := InputEventAction.new(); up.action = a; up.pressed = false; Input.parse_input_event(up)
	await get_tree().physics_frame

func _scene_music() -> void:
	print("== music per scene")
	get_tree().change_scene_to_file("res://src/Main.tscn")
	await _wait(func(): return Audio.current == "title", 120)
	check(Audio.current == "title", "title screen plays 'title' (%s)" % Audio.current)
	var cases := [
		["iselia_school", [], "iselia"], ["iselia_village", ["oracle_seen", "frank_talked"], "iselia"],
		["iselia_village", ["temple_done", "ranch_visited", "night_dirk", "raid_started"], "tension"],
		["iselia_forest", ["oracle_seen", "frank_talked"], "field"], ["martel_temple_ext", ["frank_talked"], "tension"],
		["martel_temple_ext", ["vidarr_defeated"], "field"], ["martel_temple", ["vidarr_defeated", "temple_entered"], "temple"],
		["iselia_ranch", ["ranch_visited", "ranch_event_started"], "tension"], ["dirks_house", ["ranch_visited", "night_dirk", "dirk_morning"], "iselia"],
		["world_sylvarant", ["exiled", "world_first_time"], "world"], ["triet_desert", ["exiled", "triet_arrived"], "desert"],
	]
	for c in cases:
		while Router._busy:
			await get_tree().process_frame
		Game.new_game()
		for f in c[1]:
			Game.set_flag(f, true)
		Router.goto_map(c[0], "default")
		var ok := await _wait(func(): var s = get_tree().current_scene; return s is Field and (s as Field).map_id == c[0] and Audio.current == c[2], 900)
		check(ok, "%s %s plays '%s' (got '%s')" % [c[0], str(c[1]), c[2], Audio.current])
	# Marble's death switches to the sad theme
	while Router._busy:
		await get_tree().process_frame
	Game.new_game()
	for f in ["temple_done", "night_dirk", "raid_started", "raid_fight_done", "plaza_trigger"]:
		Game.set_flag(f, true)
	Game.flags["resume_event"] = "after_exbelua"
	Game.flags["resume_map"] = "iselia_village"
	Game.current_map = "iselia_village"
	Game.last_field_position = Vector3(0, 0.1, 0)
	Router.return_from_battle()
	var ok2 := await _wait(func(): return Audio.current == "sad", 900)
	check(ok2, "Marble's death plays 'sad' (got '%s')" % Audio.current)
	# battle / boss / victory / game over
	for pair in [[["wolf"], "battle"], [["vidarr"], "boss"]]:
		while Router._busy:
			await get_tree().process_frame
		Game.new_game()
		Router.start_battle({"enemies": pair[0], "advantage": "normal", "map": "iselia_forest"})
		var okb := await _wait(func(): return get_tree().current_scene is BattleManager and Audio.current == pair[1], 600)
		check(okb, "%s battle plays '%s' (got '%s')" % [str(pair[0]), pair[1], Audio.current])
		var bm: BattleManager = get_tree().current_scene
		await _wait(func(): return bm.phase == BattleManager.Phase.FIGHT, 300)
		if pair[1] == "battle":
			for e in bm.enemies:
				e.take_hit(null, 9999999, 0.0, false, true, false)
			check(await _wait(func(): return Audio.current == "victory", 300), "winning plays 'victory'")
		else:
			for p in bm.party:
				p.take_hit(null, 9999999, 0.0, false, true, false)
			check(await _wait(func(): return Audio.current == "gameover", 300), "losing plays 'gameover'")
	get_tree().change_scene_to_file("res://src/ui/DemoEnd.tscn")
	check(await _wait(func(): return Audio.current == "ending", 200), "demo end plays 'ending'")

func _battle_sounds() -> void:
	print("== sounds in a real-input battle")
	while Router._busy:
		await get_tree().process_frame
	Game.new_game()
	Audio.played.clear()
	Router.start_battle({"enemies": ["wolf", "wolf"], "advantage": "normal", "map": "iselia_forest"})
	await _wait(func(): return get_tree().current_scene is BattleManager and (get_tree().current_scene as BattleManager).phase == BattleManager.Phase.FIGHT, 600)
	var bm: BattleManager = get_tree().current_scene
	check(int(Audio.played.get("encounter", 0)) > 0, "encounter swirl sound")
	for i in 900:
		if bm.phase != BattleManager.Phase.FIGHT:
			break
		var me: PlayerBattler = bm.controlled
		var tgt: Battler = me.target
		for a in ["move_left", "move_right"]:
			Input.action_release(a)
		if tgt and is_instance_valid(tgt) and tgt.is_alive() and abs(tgt.global_position.x - me.global_position.x) > 1.8:
			Input.action_press("move_right" if tgt.global_position.x > me.global_position.x else "move_left")
			await get_tree().physics_frame
		elif i % 40 == 0 and int(me.stats["tp"]) >= 6:
			await _tap("arte")
		else:
			await _tap("attack")
	for a in ["move_left", "move_right"]:
		Input.action_release(a)
	for id in ["slash1", "slash2", "hit", "arte", "enemy_attack", "enemy_die"]:
		check(int(Audio.played.get(id, 0)) > 0, "battle played '%s' (%d)" % [id, int(Audio.played.get(id, 0))])
	print("  battle sfx counts: ", Audio.played)
