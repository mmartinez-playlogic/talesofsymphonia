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

var _focus_pos = null       # Vector3 or null
var _shake_t := 0.0
var _shake_s := 0.0

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var want: Vector3
	if _focus_pos != null:
		var back := Vector3(sin(deg_to_rad(yaw_deg)), 0, cos(deg_to_rad(yaw_deg))) * distance
		want = (_focus_pos as Vector3) + back + Vector3(0, height, 0)
	else:
		want = _desired()
	global_position = global_position.lerp(want, 1.0 - exp(-smooth * delta))
	var off := Vector3.ZERO
	if _shake_t > 0:
		_shake_t -= delta
		off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake_s * clamp(_shake_t / 0.5, 0.0, 1.0)
	global_position += off
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0)

## Smoothly look at a world position; pass null to return to following the target.
func focus(pos, time := 0.6) -> void:
	_focus_pos = pos
	if not is_inside_tree():
		return
	await get_tree().create_timer(time).timeout

func shake(strength := 0.3, duration := 0.5) -> void:
	_shake_s = strength
	_shake_t = duration
	if not is_inside_tree():
		return
	await get_tree().create_timer(duration).timeout
