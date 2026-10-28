class_name Battler
extends CharacterBody3D
## Base class for everything that fights. Linear Motion Battle System: battlers move mostly along X
## toward their target; the camera looks from +Z, so screen-right is +X.

enum State { IDLE, MOVE, ATTACK, ARTE, CAST, HURT, GUARD, DEAD, WIN }

signal died(battler: Battler)
signal damaged(battler: Battler, amount: int, crit: bool, heal: bool)

var manager: Node                 # BattleManager
var model: CharacterModel
var id := ""
var display_name := ""
var player_side := true
var stats := {"hp": 100, "max_hp": 100, "tp": 10, "max_tp": 10, "atk": 10, "def": 10, "int": 10, "spr": 10, "acc": 10, "eva": 10, "luck": 10}
var element := "none"
var weak: Array = []
var resist: Array = []
var state: State = State.IDLE
var target: Battler
var facing := 1                   # +1 = +X
var move_speed := 5.0
var radius := 0.45
var hitstun := 0.0
var action_timer := 0.0
var knockback := Vector3.ZERO
var guarding := false
var combo_received := 0
var combo_timer := 0.0
var buffs: Dictionary = {}        # stat -> {mult, time}
var pending_hits: Array = []      # [{time, callable}]
var is_boss := false
var flying := false
var model_scale := 1.0
var _anim_prefix_sword := true
var _death_done := false
var ol_gauge := 0.0            # 0..100, fills when taking damage (player side)
var over_limit_t := 0.0        # seconds remaining of Over Limit
var ex: Dictionary = {}        # EX skill effects (player side)
var poise_t := 0.0             # enemies: seconds of stagger immunity after a long combo
var status := ""               # "" | "poison" | "stun"
var status_t := 0.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 16  # arena walls only; battlers pass through each other
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = radius
	cap.height = 1.6
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)

func init_model(model_id: String, scale_f := 1.0) -> void:
	model = CharacterModel.new()
	add_child(model)
	model.load_model(model_id)
	model_scale = scale_f
	model.scale = Vector3.ONE * scale_f
	set_facing(facing)
	play_idle()

func set_facing(f: int) -> void:
	facing = f
	if model:
		model.rotation.y = -PI / 2 if f > 0 else PI / 2

func is_alive() -> bool:
	return state != State.DEAD

func can_act() -> bool:
	return state == State.IDLE or state == State.MOVE

# ---------- animation helpers ----------
func anim_name(kind: String) -> String:
	if model == null:
		return ""
	if not model.humanoid:
		return {"idle": "Idle", "run": "Run", "attack1": "Attack", "attack2": "Attack", "attack3": "Attack", "hurt": "Hurt", "death": "Death", "guard": "Idle", "cast": "Idle", "shoot": "Attack", "win": "Idle"}.get(kind, "Idle")
	if id == "zombie":
		return {"idle": "Zombie_Idle", "run": "Zombie_Walk_Fwd", "attack1": "Zombie_Scratch", "attack2": "Zombie_Scratch", "attack3": "Zombie_Scratch", "hurt": "Hit_Chest", "death": "Death01", "guard": "Zombie_Idle", "cast": "Zombie_Idle", "shoot": "Zombie_Scratch", "win": "Zombie_Idle"}.get(kind, "Zombie_Idle")
	return {"idle": "Sword_Idle" if _anim_prefix_sword else "Idle", "run": "Jog_Fwd", "attack1": "Sword_Regular_A", "attack2": "Sword_Regular_B", "attack3": "Sword_Regular_C",
			"hurt": "Hit_Chest", "death": "Death01", "guard": "Sword_Block", "cast": "Spell_Simple_Idle", "cast_enter": "Spell_Simple_Enter", "shoot": "Spell_Simple_Shoot", "win": "Yes", "knockback": "Hit_Knockback", "revive": "LayToIdle"}.get(kind, "Idle")

func play_idle() -> void:
	model.play(anim_name("idle"))

func play(kind: String, speed := 1.0, force := false) -> float:
	var n := anim_name(kind)
	model.play(n, 0.08, speed, force)
	return model.anim_length(n) / speed

# ---------- stats ----------
func stat(name: String) -> float:
	var v := float(stats.get(name, 10))
	if buffs.has(name):
		v *= float(buffs[name]["mult"])
	if over_limit_t > 0 and (name == "atk" or name == "int"):
		v *= 1.3
	return v

func in_over_limit() -> bool:
	return over_limit_t > 0

func add_ol(amount: float) -> void:
	if over_limit_t > 0 or not player_side:
		return
	ol_gauge = min(100.0, ol_gauge + amount * float(ex.get("ol_rate", 1.0)))
	if ol_gauge >= 100.0:
		ol_gauge = 0.0
		over_limit_t = 8.0
		Audio.sfx("over_limit")
		manager.spawn_popup(global_position + Vector3(0, 2.1, 0), "OVER LIMIT", Color(1, 0.6, 0.2), 0.8)
		Effects.ring(manager._fx_root, global_position, Color(1, 0.5, 0.1), 2.5, 0.6)

func hp_ratio() -> float:
	return float(stats["hp"]) / float(max(1, stats["max_hp"]))

# ---------- combat ----------
func schedule_hit(delay: float, fn: Callable) -> void:
	pending_hits.append({"time": delay, "fn": fn})

func targets_in_front(range_x: float, range_z := 1.6) -> Array:
	var out: Array = []
	for b in manager.opponents_of(self):
		if not b.is_alive():
			continue
		var dx: float = b.global_position.x - global_position.x
		var dz: float = abs(b.global_position.z - global_position.z)
		if dz > range_z + b.radius:
			continue
		if abs(dx) <= range_x + b.radius and (sign(dx) == facing or abs(dx) < 0.6):
			out.append(b)
	return out

func face_target() -> void:
	if target and is_instance_valid(target):
		var dx := target.global_position.x - global_position.x
		if abs(dx) > 0.05:
			set_facing(1 if dx > 0 else -1)

## Physical hit. Returns damage dealt.
func deal_physical(victim: Battler, power: float, knock := 1.5, elem := "none", launch := false) -> int:
	var crit := randf() < 0.04 + stat("luck") * 0.002 + float(ex.get("crit", 0.0))
	var base := stat("atk") * power * (0.85 if player_side else 1.15) - victim.stat("def") * 0.45
	base = max(base, stat("atk") * power * 0.12)
	base *= randf_range(0.92, 1.08)
	base *= _element_mult(victim, elem)
	if crit:
		base *= 1.5
	var dmg := int(round(base))
	victim.take_hit(self, dmg, knock, crit, false, launch)
	return dmg

func deal_magic(victim: Battler, power: float, elem := "none", knock := 1.0) -> int:
	var base := stat("int") * power * (1.05 if player_side else 1.4) - victim.stat("spr") * 0.4
	base = max(base, stat("int") * power * 0.15)
	base *= randf_range(0.92, 1.08) * _element_mult(victim, elem)
	var dmg := int(round(base))
	victim.take_hit(self, dmg, knock, false, true, false)
	return dmg

func _element_mult(victim: Battler, elem: String) -> float:
	if elem == "none":
		return 1.0
	if elem in victim.weak:
		return 1.5
	if elem in victim.resist:
		return 0.5
	return 1.0

func take_hit(attacker: Battler, dmg: int, knock: float, crit: bool, magical: bool, launch: bool) -> void:
	if state == State.DEAD:
		return
	var blocked: bool = guarding and attacker != null and (int(sign(attacker.global_position.x - global_position.x)) == facing)
	if blocked:
		Audio.sfx("guard")
		dmg = int(dmg * 0.25)
		manager.spawn_popup(global_position + Vector3(0, 1.6, 0), "GUARD", Color(0.6, 0.8, 1.0))
	dmg = max(1, dmg)
	stats["hp"] = max(0, int(stats["hp"]) - dmg)
	combo_received += 1
	combo_timer = 1.2
	damaged.emit(self, dmg, crit, false)
	manager.on_damage(attacker, self, dmg, crit)
	if attacker and attacker.player_side and not player_side:
		attacker.stats["tp"] = min(int(attacker.stats["max_tp"]), int(attacker.stats["tp"]) + 1)
	if stats["hp"] <= 0:
		_die()
		return
	if player_side:
		add_ol(float(dmg) / max(1.0, float(stats["max_hp"])) * 100.0 * 0.9)
	if blocked:
		return
	if over_limit_t > 0 or poise_t > 0 or (bool(ex.get("super_armor", false)) and dmg < stats["max_hp"] * 0.08):
		return  # no stagger
	if not player_side and not is_boss and combo_received >= 5:
		combo_received = 0
		poise_t = 1.2
		manager.spawn_popup(global_position + Vector3(0, 2.0, 0), "¡Rompe!", Color(1, 0.4, 0.3), 0.6)
		return
	if is_boss and randf() < 0.6 and not magical:
		return  # bosses resist stagger
	# stagger
	hitstun = 0.42 if not magical else 0.5
	var dir: int = 1 if (attacker == null or attacker.global_position.x < global_position.x) else -1
	knockback = Vector3(dir * knock * 2.2, 0, 0)
	if launch:
		velocity.y = 7.0
	state = State.HURT
	pending_hits.clear()
	if launch or knock >= 3.0:
		play("knockback", 1.2, true)
	else:
		play("hurt", 1.0, true)

func heal(amount: int) -> void:
	if state == State.DEAD:
		return
	stats["hp"] = min(int(stats["max_hp"]), int(stats["hp"]) + amount)
	damaged.emit(self, amount, false, true)
	manager.spawn_popup(global_position + Vector3(0, 1.8, 0), str(amount), Color(0.5, 1.0, 0.5))

func revive(ratio: float) -> void:
	if state != State.DEAD:
		return
	_death_done = false
	stats["hp"] = max(1, int(stats["max_hp"] * ratio))
	state = State.IDLE
	play("revive", 1.4, true)
	schedule_hit(0.9, func(): if state == State.IDLE: play_idle())

func _die() -> void:
	Audio.sfx("ko" if player_side else "enemy_die")
	state = State.DEAD
	pending_hits.clear()
	hitstun = 0.0
	play("death", 1.0, true)
	died.emit(self)

func apply_buff(stat_name: String, mult: float, duration: float) -> void:
	buffs[stat_name] = {"mult": mult, "time": duration}

# ---------- per-frame ----------
func _physics_process(delta: float) -> void:
	if has_method("_choreo_tick"):
		call("_choreo_tick", delta)
	if over_limit_t > 0:
		over_limit_t -= delta
	if poise_t > 0:
		poise_t -= delta
	if status != "":
		status_t -= delta
		if status == "poison" and int(Time.get_ticks_msec() / 1000) != int((Time.get_ticks_msec() - delta * 1000) / 1000) and is_alive():
			stats["hp"] = max(1, int(stats["hp"]) - max(1, int(stats["max_hp"] * 0.02)))
		if status_t <= 0:
			status = ""
	# buffs
	for k in buffs.keys():
		buffs[k]["time"] -= delta
		if buffs[k]["time"] <= 0:
			buffs.erase(k)
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_received = 0
	# scheduled hits
	var i := 0
	while i < pending_hits.size():
		pending_hits[i]["time"] -= delta
		if pending_hits[i]["time"] <= 0:
			var fn: Callable = pending_hits[i]["fn"]
			pending_hits.remove_at(i)
			fn.call()
		else:
			i += 1
	if state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0, 20 * delta)
		velocity.z = 0
		_gravity(delta)
		move_and_slide()
		return
	if state == State.HURT:
		hitstun -= delta
		velocity.x = knockback.x
		velocity.z = 0
		knockback.x = move_toward(knockback.x, 0, 14 * delta)
		_gravity(delta)
		move_and_slide()
		if hitstun <= 0 and is_on_floor():
			state = State.IDLE
			play_idle()
		return
	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0 and (state == State.ATTACK or state == State.ARTE or state == State.CAST):
			state = State.IDLE
			play_idle()
	if manager.phase != manager.Phase.FIGHT:
		velocity.x = 0
		velocity.z = 0
		_gravity(delta)
		move_and_slide()
		return
	think(delta)
	_gravity(delta)
	move_and_slide()
	_clamp_arena()

func _gravity(delta: float) -> void:
	if flying:
		velocity.y = 0
		return
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = max(velocity.y, 0)

func _clamp_arena() -> void:
	var r: float = float(manager.arena_radius) - 0.5
	var p := global_position
	var flat := Vector2(p.x, p.z)
	if flat.length() > r:
		flat = flat.normalized() * r
		global_position = Vector3(flat.x, p.y, flat.y)

## Override: decide movement/actions this frame.
func think(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0

## Move along X toward target (linear) and drift Z to align.
func move_toward_target(delta: float, stop_distance: float) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_alive():
		velocity.x = 0
		velocity.z = 0
		return false
	face_target()
	var dx := target.global_position.x - global_position.x
	var dz := target.global_position.z - global_position.z
	var dist := abs(dx)
	if dist > stop_distance:
		velocity.x = sign(dx) * move_speed
		velocity.z = clamp(dz * 3.0, -move_speed, move_speed)
		if state == State.IDLE:
			state = State.MOVE
			play("run")
		return false
	velocity.x = 0
	velocity.z = clamp(dz * 3.0, -move_speed, move_speed) if abs(dz) > 0.2 else 0.0
	if state == State.MOVE:
		state = State.IDLE
		play_idle()
	return true

func start_attack(step: int, power := 1.0, range_x := 1.8, knock := 1.2, elem := "none", speed := 1.0, launch := false) -> void:
	state = State.ATTACK
	face_target()
	var kind := "attack%d" % clamp(step, 1, 3)
	var length := play(kind, speed, true)
	if player_side:
		Audio.sfx("slash%d" % clamp(step, 1, 3), -3.0)
	action_timer = length
	var hit_at: float = length * (0.4 if step < 3 else 0.35)
	schedule_hit(hit_at, func():
		for v in targets_in_front(range_x):
			deal_physical(v, power, knock, elem, launch)
	)
