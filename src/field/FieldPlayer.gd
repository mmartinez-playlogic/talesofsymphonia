class_name FieldPlayer
extends CharacterBody3D
## Field exploration controller for the party leader.

signal interact_requested(target: Node)

const WALK_SPEED := 3.2
const RUN_SPEED := 6.4
const TURN_SPEED := 14.0

var model: CharacterModel
var can_move := true
var scripted := false      # true while a cutscene moves this body directly
var _interact_area: Area3D
var _camera_yaw := 0.0
var _enc_timer := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.6
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)
	model = CharacterModel.new()
	add_child(model)
	var leader: String = Game.party[0] if Game.party.size() > 0 else "lloyd"
	model.load_model(DB.characters.get(leader, {}).get("model", leader))
	model.rotation.y = PI  # glb faces -Z; we face +Z by convention after rotate_toward
	_interact_area = Area3D.new()
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 4  # interactables
	var s := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 1.5
	s.shape = sph
	s.position = Vector3(0, 0.9, 0.9)
	_interact_area.add_child(s)
	add_child(_interact_area)

func set_camera_yaw(yaw: float) -> void:
	_camera_yaw = yaw

func _physics_process(delta: float) -> void:
	if not can_move:
		if scripted:
			return
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= 19.6 * delta
		move_and_slide()
		if model.current() in ["Jog_Fwd", "Walk"]:
			model.play("Idle")
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, _camera_yaw)
	var speed := RUN_SPEED if not Input.is_action_pressed("free_run") else WALK_SPEED
	if dir.length() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-TURN_SPEED * delta))
		model.play("Jog_Fwd" if speed > 4 else "Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 6 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 6 * delta)
		model.play("Idle")
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not can_move:
		return
	if event.is_action_pressed("confirm"):
		var best: Node = null
		var best_d := INF
		for b in _interact_area.get_overlapping_bodies():
			if b.has_method("interact"):
				var d := global_position.distance_to(b.global_position)
				if d < best_d:
					best_d = d
					best = b
		for a in _interact_area.get_overlapping_areas():
			if a.has_method("interact"):
				var d := global_position.distance_to(a.global_position)
				if d < best_d:
					best_d = d
					best = a
		if best:
			get_viewport().set_input_as_handled()
			interact_requested.emit(best)

func face(target_pos: Vector3) -> void:
	var d := target_pos - global_position
	d.y = 0
	if d.length() > 0.01:
		rotation.y = atan2(d.x, d.z)
