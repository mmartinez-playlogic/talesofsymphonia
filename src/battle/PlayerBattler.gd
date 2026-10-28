class_name PlayerBattler
extends Battler
## Party member: controlled by the player when `controlled`, otherwise by simple strategy AI.

var controlled := false
var combo_step := 0
var combo_window := 0.0
var free_run := false
var arte_shortcuts: Array = []     # up to 3 arte ids
var known_artes: Array = []
var ai_cooldown := 0.0
var strategy := "normal"
var char_data: Dictionary = {}
var member: Dictionary = {}

func setup_from_member(char_id: String) -> void:
	id = char_id
	player_side = true
	char_data = DB.characters[char_id]
	member = Game.members[char_id]
	display_name = char_data["name"]
	stats = {
		"hp": int(member["hp"]), "max_hp": Game.max_hp(char_id),
		"tp": int(member["tp"]), "max_tp": Game.max_tp(char_id),
		"atk": Game.stat(char_id, "atk"), "def": Game.stat(char_id, "def"),
		"int": Game.stat(char_id, "int"), "spr": Game.stat(char_id, "spr"),
		"acc": Game.stat(char_id, "acc"), "eva": Game.stat(char_id, "eva"), "luck": Game.stat(char_id, "luck"),
	}
	known_artes = member["artes"].duplicate()
	arte_shortcuts = known_artes.slice(0, 3)
	var saved_sc: Array = member.get("shortcuts", [])
	if saved_sc.size() > 0:
		arte_shortcuts = saved_sc.filter(func(x): return x != "" and known_artes.has(x))
		if arte_shortcuts.is_empty():
			arte_shortcuts = known_artes.slice(0, 3)
	strategy = member.get("strategy", "normal")
	ex = Game.ex_effects(char_id)
	_anim_prefix_sword = char_data["weapon"] in ["twin_swords", "sword", "axe"]
	move_speed = 6.0
	var sc: float = {"genis": 0.82, "presea": 0.85, "colette": 0.95, "raine": 0.98, "sheena": 0.97, "regal": 1.06, "kratos": 1.04, "zelos": 1.02}.get(char_id, 1.0)
	init_model(char_data.get("model", char_id), sc)
	if stats["hp"] <= 0:
		state = State.DEAD
		play("death", 4.0, true)

func sync_back() -> void:
	member["hp"] = int(stats["hp"])
	member["tp"] = int(stats["tp"])

func is_caster() -> bool:
	return char_data["weapon"] in ["kendama", "staff"]

func _input_dir() -> float:
	return Input.get_axis("move_left", "move_right")

func think(delta: float) -> void:
	if combo_window > 0:
		combo_window -= delta
		if combo_window <= 0:
			combo_step = 0
	if controlled:
		_think_player(delta)
	else:
		_think_ai(delta)

func _think_player(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.is_alive():
		target = manager.nearest_opponent(self)
	free_run = Input.is_action_pressed("free_run")
	guarding = false
	if state == State.ATTACK or state == State.ARTE or state == State.CAST:
		velocity.x = 0
		velocity.z = 0
		# combo cancel into next attack after the hit lands
		if state == State.ATTACK and combo_step < 3 and Input.is_action_just_pressed("attack") and pending_hits.is_empty():
			_do_combo()
		elif state == State.ATTACK and Input.is_action_just_pressed("arte") and pending_hits.is_empty():
			_use_shortcut()
		return
	if Input.is_action_pressed("guard"):
		state = State.GUARD
		guarding = true
		velocity.x = 0
		velocity.z = 0
		model.play(anim_name("guard"), 0.08)
		return
	if state == State.GUARD:
		state = State.IDLE
		play_idle()
	if Input.is_action_just_pressed("target_next"):
		target = manager.next_opponent(self, target)
	if Input.is_action_just_pressed("attack"):
		_do_combo()
		return
	if Input.is_action_just_pressed("arte"):
		_use_shortcut()
		return
	if Input.is_action_just_pressed("unison"):
		manager.try_unison()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if free_run:
		if input.length() > 0.1:
			velocity.x = input.x * move_speed
			velocity.z = input.y * move_speed
			if abs(input.x) > 0.1:
				set_facing(1 if input.x > 0 else -1)
			if state != State.MOVE:
				state = State.MOVE
				play("run")
		else:
			velocity.x = 0
			velocity.z = 0
			if state == State.MOVE:
				state = State.IDLE
				play_idle()
		return
	# linear movement along X toward/away from target
	var dz := 0.0
	if target:
		dz = clamp((target.global_position.z - global_position.z) * 3.0, -move_speed, move_speed)
	if abs(input.x) > 0.2:
		velocity.x = input.x * move_speed
		velocity.z = dz
		if target:
			var toward: float = sign(target.global_position.x - global_position.x)
			set_facing(int(toward) if toward != 0 else facing)
			# running backwards: play run but keep facing target
		else:
			set_facing(1 if input.x > 0 else -1)
		if state != State.MOVE:
			state = State.MOVE
			play("run")
	else:
		velocity.x = 0
		velocity.z = dz if abs(dz) > 0.3 else 0.0
		if state == State.MOVE:
			state = State.IDLE
			play_idle()
		face_target()

func _do_combo() -> void:
	combo_step += 1
	var max_combo: int = int(ex.get("combo", 3))
	if combo_step > max_combo:
		combo_step = 1
	combo_window = 0.9
	var last: bool = combo_step == max_combo
	var speed := 1.0 if not last else 1.6
	var power: float = [1.0, 1.05, 1.2, 1.35][min(combo_step, 4) - 1]
	var knock: float = [0.8, 1.0, 1.2, 2.4][min(combo_step, 4) - 1]
	start_attack(min(combo_step, 3), power, 1.9, knock, "none", speed, last)
	if last:
		action_timer = min(action_timer, 0.9)

func _use_shortcut() -> void:
	var idx := 0
	if Input.is_action_pressed("move_up"):
		idx = 1
	elif Input.is_action_pressed("move_down"):
		idx = 2
	if idx >= arte_shortcuts.size():
		idx = 0
	if arte_shortcuts.is_empty():
		return
	use_arte(arte_shortcuts[idx])

func use_arte(arte_id: String) -> bool:
	var a: Dictionary = DB.artes.get(arte_id, {})
	if a.is_empty():
		return false
	var cost: int = max(1, int(round(int(a["tp"]) * (1.0 + float(ex.get("tp_cost", 0.0))))))
	if int(stats["tp"]) < cost:
		manager.spawn_popup(global_position + Vector3(0, 1.9, 0), "TP insuficientes", Color(0.8, 0.8, 0.8))
		return false
	stats["tp"] = int(stats["tp"]) - cost
	face_target()
	combo_step = 0
	manager.announce_arte(self, a["name"])
	match a.get("type", "base"):
		"spell", "heal", "support", "angel":
			_cast(arte_id, a)
		_:
			_melee_arte(arte_id, a)
	return true

func _melee_arte(_arte_id: String, a: Dictionary) -> void:
	state = State.ARTE
	var anim: String = a.get("anim", "Sword_Regular_A")
	var speed := 1.0 if anim != "Sword_Regular_C" and anim != "Sword_Regular_Combo" else 1.5
	model.play(anim, 0.06, speed, true)
	var length := model.anim_length(anim) / speed
	action_timer = min(length, 1.3)
	var hits := int(a.get("hits", 1))
	var power := float(a.get("power", 1.0))
	var elem: String = a.get("element", "none")
	if a.has("projectile"):
		schedule_hit(length * 0.35, func(): manager.spawn_projectile(self, a))
		return
	for h in hits:
		var t: float = length * 0.3 + h * (length * 0.5 / max(1, hits))
		schedule_hit(t, func():
			for v in targets_in_front(float(a.get("range", 1.8))):
				deal_physical(v, power, float(a.get("knockback", 1.0)), elem, bool(a.get("launch", false)))
		)

func _cast(_arte_id: String, a: Dictionary) -> void:
	state = State.CAST
	velocity = Vector3.ZERO
	var cast_time := float(a.get("cast", 1.2)) * (1.0 + float(ex.get("cast", 0.0)))
	model.play(anim_name("cast_enter"), 0.08, 1.0, true)
	action_timer = cast_time + 0.6
	manager.show_cast_circle(self, cast_time)
	schedule_hit(cast_time, func():
		if state != State.CAST:
			return
		model.play(anim_name("shoot"), 0.05, 1.2, true)
		manager.resolve_spell(self, a)
	)

# ---------- AI ----------
func _think_ai(delta: float) -> void:
	ai_cooldown -= delta
	guarding = false
	if state == State.ATTACK or state == State.ARTE or state == State.CAST or state == State.GUARD:
		velocity.x = 0
		velocity.z = 0
		return
	if target == null or not is_instance_valid(target) or not target.is_alive():
		target = manager.nearest_opponent(self)
	if target == null:
		return
	# healer logic
	if id == "raine" or id == "kratos":
		var heal_id := "first_aid" if id == "raine" else "k_first_aid"
		if known_artes.has(heal_id) and ai_cooldown <= 0:
			var low: Battler = manager.lowest_hp_ally(self)
			if low and low.hp_ratio() < 0.5 and int(stats["tp"]) >= int(DB.artes[heal_id]["tp"]):
				target_ally = low
				ai_cooldown = 2.5
				use_arte(heal_id)
				return
	if is_caster():
		var dx := abs(target.global_position.x - global_position.x)
		face_target()
		if dx < 5.0:
			var away: float = -sign(target.global_position.x - global_position.x)
			velocity.x = away * move_speed * 0.8
			velocity.z = 0
			if state != State.MOVE:
				state = State.MOVE
				play("run")
			return
		velocity.x = 0
		velocity.z = 0
		if state == State.MOVE:
			state = State.IDLE
			play_idle()
		if ai_cooldown <= 0:
			var spells: Array = known_artes.filter(func(x): return DB.artes[x].get("type") == "spell" and int(stats["tp"]) >= int(DB.artes[x]["tp"]))
			if spells.size() > 0:
				ai_cooldown = randf_range(1.0, 2.2)
				use_arte(spells[randi() % spells.size()])
			else:
				ai_cooldown = 1.0
		return
	# melee ally
	if move_toward_target(delta, 1.7):
		if ai_cooldown <= 0:
			ai_cooldown = randf_range(0.5, 1.1)
			var melee: Array = known_artes.filter(func(x): return DB.artes[x].get("type") == "base" and int(stats["tp"]) >= int(DB.artes[x]["tp"]))
			if randf() < 0.3 and melee.size() > 0:
				use_arte(melee[randi() % melee.size()])
			else:
				_do_combo()

var target_ally: Battler
