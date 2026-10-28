extends Node
## Real combat bot: plays every C1 battle with real inputs (no cheats) at the expected level.
##   godot --headless --path . res://tools/CombatTest.tscn [-- --runs 3]
## Output: [BATTLE] name run result time hp_left

const BATTLES := [
	{"name": "bosque lobos",      "enemies": ["wolf", "wolf"],                     "party": ["lloyd", "genis", "colette"], "lv": 1},
	{"name": "bosque fantasma",   "enemies": ["ghost", "zombie"],                  "party": ["lloyd", "genis", "colette"], "lv": 2},
	{"name": "templo soldados",   "enemies": ["desian_soldier", "desian_soldier"], "party": ["lloyd", "genis", "colette"], "lv": 3},
	{"name": "VIDARR",            "enemies": ["vidarr"],                           "party": ["lloyd", "colette", "genis", "kratos"], "lv": 4},
	{"name": "golem",             "enemies": ["golem"],                            "party": ["lloyd", "colette", "genis", "kratos"], "lv": 5},
	{"name": "templo zombis",     "enemies": ["ghost", "zombie"],                  "party": ["lloyd", "colette", "genis", "kratos"], "lv": 5},
	{"name": "rancho (Lloyd solo)", "enemies": ["desian_soldier", "desian_soldier"], "party": ["lloyd"], "lv": 6},
	{"name": "mundo lobos",       "enemies": ["wolf", "wolf", "bee"],              "party": ["lloyd", "genis"], "lv": 6},
	{"name": "ataque Iselia 1",   "enemies": ["desian_soldier", "desian_soldier"], "party": ["lloyd", "genis"], "lv": 7},
	{"name": "ataque Iselia 2",   "enemies": ["desian_soldier", "desian_whip"],    "party": ["lloyd", "genis"], "lv": 7},
	{"name": "EXBELUA",           "enemies": ["exbelua"],                          "party": ["lloyd", "genis"], "lv": 7},
	{"name": "desierto",          "enemies": ["sand_wolf", "desert_hornet"],       "party": ["lloyd", "genis"], "lv": 8},
	{"name": "desierto 3",        "enemies": ["desert_hornet", "desert_hornet", "hare"], "party": ["lloyd", "genis"], "lv": 9},
]

var _runs := 3
var _results: Array = []

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--runs" and i + 1 < args.size():
			_runs = int(args[i + 1])
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	await get_tree().process_frame
	var only := ""
	for i in args.size():
		if args[i] == "--only" and i + 1 < args.size():
			only = args[i + 1]
	for b in BATTLES:
		if only != "" and not str(b["name"]).contains(only):
			continue
		for r in _runs:
			await _fight(b, r)
	print("\n===== COMBAT SUMMARY =====")
	var losses := 0
	for b in BATTLES:
		var wins := 0
		var times: Array = []
		var hps: Array = []
		for res in _results:
			if res["name"] == b["name"]:
				if res["result"] == "WIN":
					wins += 1
				times.append(res["time"])
				hps.append(res["hp"])
		if times.is_empty():
			continue
		losses += _runs - wins
		print("%-22s lv%d  wins %d/%d   avg time %5.1fs   avg party HP left %3d%%" % [b["name"], b["lv"], wins, _runs, _avg(times), int(_avg(hps))])
	print("COMBAT TEST DONE: %d losses" % losses)
	get_tree().quit(0)

func _avg(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for x in a:
		s += float(x)
	return s / a.size()

func _set_level(id: String, lvl: int) -> void:
	var m: Dictionary = Game.members[id]
	var start: int = int(DB.characters[id].get("start_level", 1))
	lvl = max(lvl, start)
	m["level"] = lvl
	m["exp"] = DB.exp_for_level(lvl)
	m["artes"] = Game._artes_known(id, lvl)
	m["hp"] = Game.max_hp(id)
	m["tp"] = Game.max_tp(id)

func _fight(b: Dictionary, run: int) -> void:
	Game.new_game()
	Game.set_party(b["party"])
	for id in Game.members:
		_set_level(id, int(b["lv"]))
	Game.add_item("apple_gel", 2)  # ~5 gels, what a player has by then
	Router.start_battle({"enemies": b["enemies"], "advantage": "normal", "map": "iselia_forest"})
	var bm: BattleManager = null
	for i in 600:
		await get_tree().process_frame
		var sc := get_tree().current_scene
		if sc is BattleManager:
			bm = sc
			if bm.phase == BattleManager.Phase.FIGHT:
				break
	if bm == null:
		print("[BATTLE] %s run %d: NO BATTLE SCENE" % [b["name"], run])
		return
	bm.debug_log = OS.get_cmdline_user_args().has("--debug")
	var f0 := Engine.get_physics_frames()
	var t := 0.0
	var atk_cd := 0.0
	var arte_cd := 1.5
	var item_cd := 0.0
	var result := "TIMEOUT"
	var last_t := 0.0
	while t < 240.0:
		t = float(Engine.get_physics_frames() - f0) / 60.0
		var dt := t - last_t
		last_t = t
		atk_cd -= dt
		arte_cd -= dt
		item_cd -= dt
		if bm.phase == BattleManager.Phase.WIN:
			result = "WIN"
			break
		if bm.phase == BattleManager.Phase.LOSE:
			result = "LOSE"
			break
		_release()
		var me: PlayerBattler = bm.controlled
		if bm.phase == BattleManager.Phase.FIGHT and me and me.is_alive():
			# heal with a gel when low (real battle menu: I, confirm item, confirm target)
			if me.hp_ratio() < 0.35 and Game.has_item("apple_gel") and item_cd <= 0:
				item_cd = 6.0
				await _tap("menu")
				await _tap("confirm")
				await _tap("confirm")
				continue
			if bm.unison_gauge >= 100.0:
				await _tap("unison")
				continue
			var tgt: Battler = me.target
			if tgt == null or not is_instance_valid(tgt) or not tgt.is_alive():
				await _tap("target_next")
				await get_tree().physics_frame
				continue
			var dx := tgt.global_position.x - me.global_position.x
			if abs(dx) > 1.8:
				Input.action_press("move_right" if dx > 0 else "move_left")
			elif arte_cd <= 0 and int(me.stats["tp"]) >= 6:
				arte_cd = 2.5
				await _tap("arte")
			elif atk_cd <= 0:
				atk_cd = 0.22
				await _tap("attack")
		await get_tree().physics_frame
	_release()
	var hp := 0.0
	for p in bm.party:
		hp += p.hp_ratio()
	hp = hp / max(1, bm.party.size()) * 100.0
	_results.append({"name": b["name"], "result": result, "time": t, "hp": hp})
	var dmg_taken: int = bm._damage_taken
	print("[BATTLE] %-22s run %d: %-7s %5.1fs  party HP %3d%%  damage taken %d" % [b["name"], run, result, t, int(hp), dmg_taken])
	# leave the battle scene cleanly
	get_tree().change_scene_to_file("res://tools/Blank.tscn")
	await get_tree().process_frame
	await get_tree().process_frame

func _release() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().physics_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().physics_frame
