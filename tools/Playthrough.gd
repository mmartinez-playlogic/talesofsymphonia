extends Node
## Headless end-to-end playthrough bot: walks the player with real physics, advances dialogue, interacts,
## auto-wins battles and asserts map/flag progression from the schoolhouse to the Triet desert.
##   godot --headless --path . res://tools/Playthrough.tscn
## Log lines: [STEP] ... / [OK] ... / [FAIL] ... / [FALLBACK] ...

const STEPS := [
	{"map": "iselia_school"},
	{"flag": "oracle_seen"},
	{"goto": [0, 7.2]}, {"map": "iselia_village"},
	{"flag": "frank_talked"},
	{"goto": [-8, 2]}, {"goto": [0, -10]}, {"goto": [0, -36.3]}, {"map": "iselia_forest"},
	{"goto": [-4, -4]}, {"goto": [2, -18]}, {"goto": [0, -34]}, {"goto": [0, -56.3]}, {"map": "martel_temple_ext"},
	{"flag": "vidarr_defeated"}, {"party_has": "kratos"},
	{"goto": [0, -26.6]}, {"map": "martel_temple"},
	{"flag": "temple_entered"},
	{"goto": [-13, 10]}, {"goto": [-9, 6]}, {"goto": [-14, 3]}, {"wait_defeated": 3},
	{"interact": "pedestal"}, {"flag": "got_ring"},
	{"interact": "seal"}, {"flag": "seal_open"},
	{"interact": "altar_trigger"}, {"flag": "temple_done"}, {"party_size": 2},
	{"goto": [0, 36.3]}, {"map": "martel_temple_ext"},
	{"goto": [0, 34.3]}, {"map": "iselia_forest"},
	{"goto": [0, -34]}, {"goto": [2, -18]}, {"goto": [-4, -4]}, {"goto": [0, 26.3]}, {"map": "iselia_village"},
	{"goto": [0, -10]}, {"goto": [14, -2]}, {"interact": "colette_door"}, {"flag": "colette_house_done"},
	{"goto": [0, 4]}, {"goto": [-16, 14]}, {"interact": "genis_door"}, {"flag": "genis_house_done"},
	{"goto": [-8, 2]}, {"goto": [0, -10]}, {"goto": [-4, -24]}, {"interact": "gate_villager"}, {"flag": "gate_done"},
	{"goto": [0, -36.3]}, {"map": "iselia_forest"}, {"flag": "noishe_ran_off"},
	{"goto": [-4, -4]}, {"goto": [2, -14]}, {"goto": [16, -12]}, {"goto": [36.3, -12]}, {"map": "iselia_ranch"},
	{"flag": "ranch_visited"}, {"map": "iselia_forest"},
	{"goto": [16, -12]}, {"goto": [2, -14]}, {"goto": [-4, -4]}, {"goto": [0, 26.3]}, {"map": "iselia_village"},
	{"goto": [0, -10]}, {"goto": [0, 10]}, {"goto": [0, 36.3]}, {"map": "world_sylvarant"},
	{"goto": [60, -60]}, {"goto": [30, -43.8]}, {"map": "dirks_house"},
	{"flag": "dirk_argument"},
	{"interact": "colette"}, {"flag": "night_dirk"}, {"flag": "dirk_morning"},
	{"goto": [0, 29.3]}, {"map": "world_sylvarant"},
	{"goto": [60, -60]}, {"goto": [70, -88]}, {"goto": [70, -93.5]}, {"map": "iselia_village"},
	{"flag": "raid_started"},
	{"goto": [0, 10]}, {"goto": [-4, 6]}, {"goto": [4, -20]}, {"wait_defeated": 2}, {"flag": "raid_fight_done"},
	{"goto": [0, 2]}, {"flag": "exiled"}, {"map": "world_sylvarant"},
	{"goto": [10, -10]}, {"goto": [-20, 22]}, {"interact": "salvation_woman"}, {"flag": "house_of_salvation"},
	{"goto": [-50, 50]}, {"goto": [-62, 60]}, {"flag": "renegades_cordon"},
	{"goto": [-80, 78]}, {"goto": [-92, 92]}, {"map": "triet_desert"}, {"flag": "triet_arrived"},
	{"goto": [-20, 4]}, {"goto": [-54, 0]}, {"interact": "poster"}, {"flag": "poster_seen"},
	{"goto": [-59.5, 0]}, {"interact": "triet_gate"},
]

var _tap_timer := 0.0
var _fails := 0
var _battle_t := 0.0
var _last_field: Field = null

func _ready() -> void:
	var root := get_tree().root
	get_parent().call_deferred("remove_child", self)
	root.call_deferred("add_child", self)
	await get_tree().process_frame
	await get_tree().process_frame
	Game.new_game()
	var start := 0
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--from" and i + 1 < args.size() and PRESETS.has(args[i + 1]):
			var pr: Dictionary = PRESETS[args[i + 1]]
			for f in pr["flags"]:
				Game.set_flag(f, true)
			Game.set_party(pr["party"])
			start = int(pr["step"])
			Router.goto_map(pr["map"], pr["spawn"])
	if start == 0:
		Router.goto_map("iselia_school", "default")
	await _run(start)

const PRESETS := {
	"raid": {"step": 80, "map": "world_sylvarant", "spawn": "dirk", "party": ["lloyd", "genis"],
		"flags": ["oracle_seen", "frank_talked", "temple_done", "colette_house_done", "genis_house_done", "gate_done", "noishe_ran_off", "ranch_visited", "world_first_time", "dirk_argument", "terrace_done", "night_dirk", "dirk_morning"]},
	"exile": {"step": 92, "map": "world_sylvarant", "spawn": "iselia", "party": ["lloyd", "genis"],
		"flags": ["oracle_seen", "frank_talked", "temple_done", "colette_house_done", "ranch_visited", "night_dirk", "raid_started", "raid_fight_done", "exiled"]},
}

func _run(start: int = 0) -> void:
	for i in range(start, STEPS.size()):
		var st: Dictionary = STEPS[i]
		print("[STEP %d] %s" % [i, JSON.stringify(st)])
		var ok := false
		if st.has("map"):
			ok = await _until(func(): return _field() != null and _field().map_id == st["map"], 40.0)
		elif st.has("flag"):
			ok = await _until(func(): return Game.get_flag(st["flag"], false), 90.0)
		elif st.has("party_has"):
			ok = await _until(func(): return Game.party.has(st["party_has"]), 30.0)
		elif st.has("party_size"):
			ok = await _until(func(): return Game.party.size() == int(st["party_size"]), 30.0)
		elif st.has("wait_defeated"):
			ok = await _until(func(): return _field() != null and _field().defeated_count() >= int(st["wait_defeated"]), 120.0)
		elif st.has("goto"):
			ok = await _walk_to(Vector3(st["goto"][0], 0, st["goto"][1]), 60.0)
		elif st.has("interact"):
			ok = await _interact(st["interact"])
		if ok:
			print("[OK] step %d" % i)
		else:
			_fails += 1
			var f := _field()
			print("[FAIL] step %d  map=%s pos=%s flags=%s" % [i, f.map_id if f else "none", str(_player_pos()), str(Game.flags.keys())])
			if _fails >= 3:
				break
	print("PLAYTHROUGH DONE: %d failures, play_time %.0fs, party %s, flags %d" % [_fails, Game.play_time, str(Game.party), Game.flags.size()])
	get_tree().quit(1 if _fails > 0 else 0)

# ---------- helpers ----------
func _field() -> Field:
	var s := get_tree().current_scene
	return s as Field if s is Field else null

func _player_pos() -> Vector3:
	var f := _field()
	return f.player.global_position if f and f.player else Vector3.ZERO

## Per-frame housekeeping: advance dialogue, auto-win battles.
func _tick(delta: float) -> void:
	_tap_timer -= delta
	var s := get_tree().current_scene
	if s is BattleManager:
		var bm := s as BattleManager
		_battle_t += delta
		if bm.phase == BattleManager.Phase.FIGHT and _battle_t > 1.0:
			for e in bm.enemies:
				if e.is_alive():
					e.take_hit(null, 999999, 0.0, false, true, false)
		if _tap_timer <= 0:
			_tap_timer = 0.3
			_tap("confirm")
		return
	_battle_t = 0.0
	var f := _field()
	if f and f.dialogue and f.dialogue.is_active() and _tap_timer <= 0:
		_tap_timer = 0.1
		_tap("confirm")

func _until(cond: Callable, timeout: float) -> bool:
	var t := 0.0
	while t < timeout:
		var dt := get_process_delta_time()
		t += dt
		_tick(dt)
		if cond.call():
			return true
		await get_tree().process_frame
	return false

func _release_moves() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)

func _walk_to(target: Vector3, timeout: float) -> bool:
	var start_map := _field().map_id if _field() else ""
	var t := 0.0
	var last_progress := 0.0
	var best := INF
	var unstick := 0.0
	var side := 1.0
	while t < timeout:
		var dt := get_process_delta_time()
		t += dt
		_tick(dt)
		var f := _field()
		if f == null or f.player == null:
			_release_moves()
			await get_tree().process_frame
			continue
		if f.map_id != start_map:
			_release_moves()
			print("    (walk ended: map changed to %s)" % f.map_id)
			return true
		if not f.player.can_move or f != _last_field:
			_last_field = f
			_release_moves()
			last_progress = t
			best = INF
			await get_tree().process_frame
			continue
		var p := f.player.global_position
		var d := target - p
		d.y = 0
		var dist := d.length()
		if dist < 0.9:
			_release_moves()
			return true
		if dist < best - 0.05:
			best = dist
			last_progress = t
		if t - last_progress > 1.5 and unstick <= 0:
			unstick = 0.9
			side = -side
			last_progress = t
		var dir := d.normalized()
		if unstick > 0:
			unstick -= dt
			dir = Vector3(-dir.z * side, 0, dir.x * side) * 0.8 - dir * 0.3
			dir = dir.normalized()
		_release_moves()
		if dir.x > 0.05: Input.action_press("move_right", min(1.0, dir.x))
		if dir.x < -0.05: Input.action_press("move_left", min(1.0, -dir.x))
		if dir.z > 0.05: Input.action_press("move_down", min(1.0, dir.z))
		if dir.z < -0.05: Input.action_press("move_up", min(1.0, -dir.z))
		await get_tree().process_frame
	_release_moves()
	return false

func _interact(node_name: String) -> bool:
	for attempt in 3:
		# wait for any running event to finish and for the node to exist (events spawn actors late)
		await _until(func(): return _field() != null and not _field().event_running and _field().get_node_or_null(node_name) != null, 120.0)
		var f := _field()
		var n: Node3D = f.get_node_or_null(node_name) if f else null
		if n == null:
			print("[FAIL] no node named ", node_name)
			return false
		var target: Vector3 = n.global_position + Vector3(0, 0, 1.3)
		var start_map := f.map_id
		var ok := await _walk_to(target, 40.0)
		f = _field()
		if f == null or f.map_id != start_map or not is_instance_valid(n) or not n.is_inside_tree():
			print("    (interaction interrupted by a scene change; retrying %s)" % node_name)
			continue
		if not ok:
			print("[FALLBACK] could not reach %s, calling interact directly" % node_name)
		else:
			f.player.face(n.global_position)
		await _until(func(): return _field() != null and _field().player.can_move, 10.0)
		for i in 3:
			await get_tree().physics_frame
		f = _field()
		if f == null or f.map_id != start_map or not is_instance_valid(n):
			continue
		var before := f.event_running
		_tap("confirm")
		await get_tree().process_frame
		await get_tree().process_frame
		if not is_instance_valid(f) or not is_instance_valid(n):
			continue
		if not f.event_running and not before:
			print("[FALLBACK] confirm did not start interaction with %s; calling _on_interact (can_move=%s pos=%s)" % [node_name, f.player.can_move, f.player.global_position])
			f._on_interact(n)
		await _until(func(): return _field() == null or not _field().event_running, 120.0)
		return true
	return false

func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
