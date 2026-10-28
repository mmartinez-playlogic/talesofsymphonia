extends Node
## Full game-flow test with real key presses (headless). Backs up and restores the player's save slots.
##   godot --headless --path . --max-fps 0 --fixed-fps 60 res://tools/FlowTest.tscn
var _ok := 0
var _fails := 0
var _backup := {}

func check(c: bool, what: String) -> void:
	if c:
		_ok += 1
		print("  [PASS] ", what)
	else:
		_fails += 1
		print("  [FAIL] ", what)

func _ready() -> void:
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	for i in Game.SLOT_COUNT:
		var p := Game.SAVE_PATH % i
		if FileAccess.file_exists(p):
			_backup[i] = FileAccess.get_file_as_string(p)
		Game.delete_save(i)
	await _title_without_saves()
	await _save_at_circle()
	await _continue_from_title()
	await _game_over()
	await _demo_end()
	for i in Game.SLOT_COUNT:
		Game.delete_save(i)
		if _backup.has(i):
			var w := FileAccess.open(Game.SAVE_PATH % i, FileAccess.WRITE)
			w.store_string(_backup[i])
	print("FLOW TEST DONE: %d passed, %d failed" % [_ok, _fails])
	get_tree().quit(1 if _fails > 0 else 0)

func _tap(a: String) -> void:
	var ev := InputEventAction.new(); ev.action = a; ev.pressed = true; Input.parse_input_event(ev)
	await get_tree().process_frame
	var up := InputEventAction.new(); up.action = a; up.pressed = false; Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame

func _wait_scene(pred: Callable, frames := 900) -> bool:
	for i in frames:
		await get_tree().process_frame
		if pred.call():
			return true
	return false

func _field() -> Field:
	var s := get_tree().current_scene
	return s as Field if s is Field else null

func _ready_field(map_id: String) -> Field:
	var ok := await _wait_scene(func(): return _field() != null and _field().map_id == map_id and _field().player and _field().player.can_move and not _field().event_running and not Router._busy, 2400)
	return _field() if ok else null

func _load_state(map_id: String, flags: Array, party: Array) -> Field:
	while Router._busy:
		await get_tree().process_frame
	Game.new_game()
	for f in flags:
		Game.set_flag(f, true)
	Game.set_party(party)
	Router.goto_map(map_id, "default")
	# drive any entry event
	for i in 2400:
		await get_tree().process_frame
		var f := _field()
		if f and f.map_id == map_id and f.player and f.player.can_move and not f.event_running and not Router._busy:
			return f
		if f and f.dialogue and f.dialogue.is_active() and i % 6 == 0:
			await _tap("confirm")
	return null

func _title_without_saves() -> void:
	print("== title without saves")
	get_tree().change_scene_to_file("res://src/Main.tscn")
	for i in 20:
		await get_tree().process_frame
	var main = get_tree().current_scene
	check(main.name == "Main", "title screen shown")
	check(not Game.any_save(), "no saves present")
	check(main._cursor == 0, "cursor starts on Nueva partida when there are no saves")
	await _tap("move_down")
	await _tap("confirm")
	for i in 30:
		await get_tree().process_frame
	check(get_tree().current_scene.name == "Main" and not main._save_menu.is_open(), "Continuar does nothing without saves")
	await _tap("move_up")
	await _tap("confirm")
	var ok := await _wait_scene(func(): return _field() != null and _field().map_id == "iselia_school")
	check(ok, "Nueva partida starts in the Iselia schoolhouse")

func _save_at_circle() -> void:
	print("== save at a Memory Circle")
	var f := await _load_state("iselia_village", ["oracle_seen", "frank_talked", "temple_done"], ["lloyd", "genis"])
	check(f != null, "village ready")
	if f == null:
		return
	# away from the circle: menu refuses
	f.player.global_position = Vector3(0, 0.1, 20)
	await get_tree().physics_frame
	check(not f.can_save_here(), "cannot save away from a circle")
	var done := [false]
	(func(): await f._pause.open(); done[0] = true).call()
	await get_tree().process_frame
	for i in 8:
		await _tap("move_down")
	await _tap("confirm")
	check(not Game.save_exists(0), "pause-menu Guardar refused off-circle")
	await _tap("cancel")
	await _wait_scene(func(): return done[0], 60)
	# on the circle: pause menu -> Guardar -> slot 1
	f.player.global_position = Vector3(-4, 0.1, -12)
	await get_tree().physics_frame
	check(f.can_save_here(), "can save standing on the circle")
	Game.gald = 777
	done[0] = false
	(func(): await f._pause.open(); done[0] = true).call()
	await get_tree().process_frame
	for i in 8:
		await _tap("move_down")
	await _tap("confirm")     # Guardar -> save menu
	await _tap("confirm")     # slot 1
	check(Game.save_exists(0), "saved to slot 1 from the pause menu")
	check(Game.slot_info(0).get("map", "") == "iselia_village", "slot 1 records the map")
	check(int(Game.slot_info(0).get("gald", 0)) == 777, "slot 1 records gald")
	await _tap("cancel")
	await _wait_scene(func(): return done[0], 60)
	check(done[0], "pause menu closes after saving")
	# circle interaction directly -> slot 2
	var circle: Node = f.get_node_or_null("memory_circle_1")
	check(circle != null, "memory circle node exists")
	if circle:
		(func(): f._on_interact(circle)).call()
		await get_tree().process_frame
		await _tap("confirm")     # "Guardar"
		await _tap("move_down")   # slot 2
		await _tap("confirm")
		check(Game.save_exists(1), "saved to slot 2 from the circle")
		await _wait_scene(func(): return not f.event_running, 120)
		check(f.player.can_move, "player regains control after saving")
	# overwrite slot 1 needs a second confirm
	Game.gald = 888
	var r := [-2]
	(func(): r[0] = await f.save_game()).call()
	await get_tree().process_frame
	await _tap("confirm")
	check(int(Game.slot_info(0).get("gald", 0)) == 777, "first confirm on a used slot does not overwrite")
	await _tap("confirm")
	check(int(Game.slot_info(0).get("gald", 0)) == 888, "second confirm overwrites")
	await _wait_scene(func(): return r[0] != -2, 30)

func _continue_from_title() -> void:
	print("== Continue from title")
	while Router._busy:
		await get_tree().process_frame
	Game.new_game()
	get_tree().change_scene_to_file("res://src/Main.tscn")
	for i in 20:
		await get_tree().process_frame
	var main = get_tree().current_scene
	check(main._cursor == 1, "cursor starts on Continuar when saves exist")
	await _tap("confirm")
	check(main._save_menu.is_open(), "Continuar opens the load menu")
	await _tap("confirm")      # slot 1
	var f := await _ready_field("iselia_village")
	check(f != null, "loading slot 1 returns to Iselia")
	if f:
		check(f.player.global_position.distance_to(Vector3(-4, 0.1, -12)) < 1.0, "player appears where the game was saved (%s)" % str(f.player.global_position))
		check(Game.gald == 888, "gald restored")
		check(Game.get_flag("temple_done", false), "story flags restored")

func _game_over() -> void:
	print("== game over")
	while Router._busy:
		await get_tree().process_frame
	Game.new_game()
	Router.start_battle({"enemies": ["vidarr"], "advantage": "normal", "map": "iselia_forest"})
	var ok := await _wait_scene(func(): return get_tree().current_scene is BattleManager and (get_tree().current_scene as BattleManager).phase == BattleManager.Phase.FIGHT)
	check(ok, "battle started")
	if not ok:
		return
	var bm: BattleManager = get_tree().current_scene
	for p in bm.party:
		p.take_hit(null, 999999, 0.0, false, true, false)
	ok = await _wait_scene(func(): return bm.phase == BattleManager.Phase.LOSE, 120)
	check(ok, "party wipe -> defeat")
	await _wait_scene(func(): return bm._results_ready, 400)
	check(bm.hud._results.visible and bm.hud._results_text.text.contains("Game Over"), "Game Over screen shown")
	await _tap("confirm")
	ok = await _wait_scene(func(): return get_tree().current_scene != null and get_tree().current_scene.name == "Main", 400)
	check(ok, "Game Over returns to the title")

func _demo_end() -> void:
	print("== demo ending")
	var f := await _load_state("triet_desert", ["exiled", "left_for_journey", "triet_arrived"], ["lloyd", "genis"])
	check(f != null, "desert ready")
	if f == null:
		return
	var gate: Node = f.get_node_or_null("triet_gate")
	f.player.global_position = Vector3(-59.5, 0.1, 0)
	await get_tree().physics_frame
	(func(): f._on_interact(gate)).call()
	# lines, then the choice "Entrar en Triet"
	var ok := false
	for i in 1200:
		await get_tree().process_frame
		var s := get_tree().current_scene
		if s and s.name == "DemoEnd":
			ok = true
			break
		if i % 8 == 0 and _field() and _field().dialogue.is_active():
			await _tap("confirm")
	check(ok, "entering Triet ends the demo")
	if not ok:
		return
	for i in 90:
		await get_tree().process_frame
	check(Game.get_flag("demo_complete", false), "demo_complete flag set")
	var de = get_tree().current_scene
	await _tap("confirm")         # Guardar partida
	check(de._save_menu.is_open(), "end screen opens the save menu")
	await _tap("move_down")
	await _tap("move_down")       # slot 3
	await _tap("confirm")
	check(Game.save_exists(2) and bool(Game.slot_info(2).get("demo_complete", false)), "end-of-demo save marks ★ Demo completada")
	await _tap("move_down")       # Volver al título
	await _tap("confirm")
	ok = await _wait_scene(func(): return get_tree().current_scene != null and get_tree().current_scene.name == "Main", 400)
	check(ok, "end screen returns to the title")
	# the end-of-demo save continues at the Triet gate
	await _wait_scene(func(): return not Router._busy, 200)
	check(Game.load_save(2), "load the end-of-demo save")
	Router.goto_map(Game.current_map, Game.spawn_point)
	var ff := await _ready_field("triet_desert")
	check(ff != null and ff.player.global_position.distance_to(Vector3(-50, 0.1, 0)) < 1.5, "continues next to the Triet gate")
