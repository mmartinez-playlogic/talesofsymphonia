class_name BattleCamera
extends Camera3D
## Side-on battle camera from +Z, framing the controlled character and their target.

var manager: Node
var _shake := 0.0

func _ready() -> void:
	fov = 45

func _physics_process(delta: float) -> void:
	var p: Battler = manager.controlled
	if p == null:
		return
	var a := p.global_position
	var b := a
	if p.target and is_instance_valid(p.target):
		b = p.target.global_position
	var mid := (a + b) * 0.5
	var sep := abs(a.x - b.x)
	var dist := clamp(7.0 + sep * 0.75, 8.0, 18.0)
	var desired := Vector3(mid.x, 2.2 + dist * 0.18, mid.z + dist)
	global_position = global_position.lerp(desired, 1.0 - exp(-6.0 * delta))
	var look := Vector3(mid.x, 1.0, mid.z)
	if _shake > 0:
		_shake -= delta
		look += Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0) * _shake * 10
	look_at(look, Vector3.UP)

func shake(amount := 0.15) -> void:
	_shake = amount
