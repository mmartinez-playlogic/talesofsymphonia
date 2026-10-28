class_name FieldCamera
extends Camera3D
## Tales-style follow camera: fixed pitch, behind and above, smooth follow, slight look-ahead.

@export var target: Node3D
@export var distance := 7.0
@export var height := 4.2
@export var pitch_deg := -28.0
@export var smooth := 8.0
@export var yaw_deg := 0.0

func _ready() -> void:
	fov = 55
	if target:
		_snap()

func _snap() -> void:
	global_position = _desired()
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0)

func _desired() -> Vector3:
	var back := Vector3(sin(deg_to_rad(yaw_deg)), 0, cos(deg_to_rad(yaw_deg))) * distance
	return target.global_position + back + Vector3(0, height, 0)

func _physics_process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(_desired(), 1.0 - exp(-smooth * delta))
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0)
