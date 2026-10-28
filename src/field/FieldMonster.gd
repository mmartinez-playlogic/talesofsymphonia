class_name FieldMonster
extends CharacterBody3D
## Visible encounter on the field: wanders, chases the player, triggers a battle on contact.

var group: Array = []        # enemy ids
var model_id := "wolf"
var wander_center := Vector3.ZERO
var wander_radius := 6.0
var sight := 7.0
var speed := 4.0
var monster_index := -1
var model: CharacterModel
var _target: Vector3
var _wait := 0.0
var _field: Node
var _triggered := false
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var stun_t := 0.0
var _stun_mat: StandardMaterial3D

func setup(field: Node, enemies: Array, index: int) -> void:
	_field = field
	group = enemies
	monster_index = index
	model_id = DB.enemies.get(enemies[0], {}).get("model", "wolf")
	speed = float(DB.enemies.get(enemies[0], {}).get("speed", 4.0)) * 0.7

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.2
	shape.shape = cap
	shape.position.y = 0.6
	add_child(shape)
	model = CharacterModel.new()
	add_child(model)
	model.load_model(model_id)
	wander_center = global_position
	_pick_target()
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var s := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.9
	s.shape = sph
	s.position.y = 0.6
	area.add_child(s)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func _pick_target() -> void:
	var a := randf() * TAU
	_target = wander_center + Vector3(cos(a), 0, sin(a)) * randf_range(1.0, wander_radius)
	_wait = randf_range(0.8, 2.5)

## Sorcerer's Ring hit: freeze in place and glow blue; touching a stunned monster gives player advantage.
func stun(seconds: float) -> void:
	stun_t = seconds
	if _stun_mat == null:
		_stun_mat = StandardMaterial3D.new()
		_stun_mat.albedo_color = Color(0.4, 0.6, 1.0)
		_stun_mat.emission_enabled = true
		_stun_mat.emission = Color(0.3, 0.5, 1.0)
		_stun_mat.emission_energy_multiplier = 1.5
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _stun_mat

func _unstun() -> void:
	stun_t = 0.0
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = null

func _physics_process(delta: float) -> void:
	if stun_t > 0:
		stun_t -= delta
		velocity = Vector3.ZERO
		_anim_idle()
		if stun_t <= 0:
			_unstun()
		return
	if _triggered or _field == null or _field.player == null or not _field.player.can_move:
		velocity = Vector3.ZERO
		_anim_idle()
		return
	var player: Node3D = _field.player
	var to_player := player.global_position - global_position
	to_player.y = 0
	var chasing := to_player.length() < sight
	var dest := player.global_position if chasing else _target
	var d := dest - global_position
	d.y = 0
	var spd := speed * (1.6 if chasing else 1.0)
	if not chasing and _wait > 0.0 and d.length() < 0.5:
		_wait -= delta
		velocity.x = 0
		velocity.z = 0
		_anim_idle()
		if _wait <= 0.0:
			_pick_target()
	elif d.length() > 0.3:
		d = d.normalized()
		velocity.x = d.x * spd
		velocity.z = d.z * spd
		rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), 1.0 - exp(-10 * delta))
		_anim_run()
	else:
		velocity.x = 0
		velocity.z = 0
		if not chasing:
			_pick_target()
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0
	move_and_slide()
	# unstick: if pushing against something without moving, pick another wander target
	if velocity.length() > 0.5 and global_position.distance_to(_last_pos) < 0.02:
		_stuck_t += delta
		if _stuck_t > 0.8:
			_stuck_t = 0.0
			_pick_target()
			_wait = 0.0
	else:
		_stuck_t = 0.0
	_last_pos = global_position

func _anim_idle() -> void:
	model.play("Idle" if not model.humanoid else "Zombie_Idle" if model_id == "zombie" else "Idle")

func _anim_run() -> void:
	model.play("Run" if not model.humanoid else "Zombie_Walk_Fwd" if model_id == "zombie" else "Jog_Fwd")

func _on_body_entered(body: Node) -> void:
	if _triggered or body != _field.player or not _field.player.can_move:
		return
	_triggered = true
	# Advantage: player hits from behind -> player advantage; monster hits player from behind -> enemy advantage.
	var player: Node3D = _field.player
	var p_fwd := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
	var m_fwd := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var to_m := (global_position - player.global_position).normalized()
	var advantage := "normal"
	if stun_t > 0 or (p_fwd.dot(to_m) > 0.5 and m_fwd.dot(to_m) > 0.5):
		advantage = "player"
	elif p_fwd.dot(-to_m) < -0.5 and m_fwd.dot(-to_m) > 0.5:
		advantage = "enemy"
	_field.begin_battle(self, advantage)
