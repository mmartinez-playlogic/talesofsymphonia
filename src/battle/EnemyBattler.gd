class_name EnemyBattler
extends Battler
## Enemy with data-driven stats and simple AI.

var data: Dictionary = {}
var attacks: Array = []
var ai_cooldown := 1.0
var ai_mode := "melee"
var strafe_timer := 0.0

func setup_from_data(enemy_id: String, level_bonus := 0) -> void:
	id = enemy_id
	player_side = false
	data = DB.enemies[enemy_id]
	display_name = data["name"]
	var m := 1.0 + level_bonus * 0.05
	stats = {"hp": int(data["hp"] * m), "max_hp": int(data["hp"] * m), "tp": 0, "max_tp": 0,
		"atk": int(data["atk"] * m), "def": int(data["def"] * m), "int": int(data["int"] * m), "spr": int(data["spr"] * m),
		"acc": int(data["acc"]), "eva": int(data["eva"]), "luck": 5}
	element = data.get("element", "none")
	weak = data.get("weak", [])
	resist = data.get("resist", [])
	attacks = data.get("attacks", [])
	ai_mode = data.get("ai", "melee")
	is_boss = bool(data.get("boss", false))
	flying = bool(data.get("flying", false))
	move_speed = float(data.get("speed", 4.0))
	radius = 0.45 * float(data.get("size", 1.0))
	_anim_prefix_sword = true
	init_model(data.get("model", enemy_id), float(data.get("size", 1.0)))
	if flying:
		model.position.y = 0.0
	ai_cooldown = randf_range(0.6, 1.5)

func think(delta: float) -> void:
	ai_cooldown -= delta
	if state == State.ATTACK or state == State.ARTE or state == State.CAST:
		velocity.x = 0
		velocity.z = 0
		return
	if target == null or not is_instance_valid(target) or not target.is_alive() or randf() < 0.002:
		target = manager.random_opponent(self)
	if target == null:
		velocity = Vector3.ZERO
		return
	var atk: Dictionary = attacks[randi() % attacks.size()] if attacks.size() > 0 else {"power": 1.0, "range": 1.5}
	var reach: float = float(atk.get("range", 1.5)) + radius
	if move_toward_target(delta, reach):
		if ai_cooldown <= 0:
			ai_cooldown = randf_range(0.9, 2.0) if not is_boss else randf_range(0.6, 1.3)
			_attack(atk)
		else:
			strafe_timer -= delta
			if strafe_timer <= 0 and randf() < 0.3:
				strafe_timer = 0.4
				velocity.x = -facing * move_speed * 0.5

func _attack(atk: Dictionary) -> void:
	state = State.ATTACK
	face_target()
	var anim: String = atk.get("anim", "Attack") if model.humanoid else "Attack"
	if not model.anim or not model.anim.has_animation(anim):
		anim = anim_name("attack1")
	model.play(anim, 0.06, 1.0, true)
	var length := model.anim_length(anim)
	action_timer = min(length, 1.4)
	var power := float(atk.get("power", 1.0))
	var range_x := float(atk.get("range", 1.5))
	var knock := float(atk.get("knockback", 1.2))
	schedule_hit(length * 0.45, func():
		for v in targets_in_front(range_x):
			deal_physical(v, power, knock)
	)
