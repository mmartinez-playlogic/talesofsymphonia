class_name RingShot
extends Area3D
## Sorcerer's Ring fireball on the field: flies forward, stuns the first FieldMonster it touches.

var velocity := Vector3.ZERO
var life := 1.1
var _mesh: MeshInstance3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # field monsters
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.45
	cs.shape = sph
	add_child(cs)
	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.28
	sm.height = 0.56
	sm.radial_segments = 10
	sm.rings = 6
	_mesh.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.55, 0.15)
	_mesh.material_override = m
	add_child(_mesh)
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.6, 0.2)
	l.light_energy = 2.0
	l.omni_range = 4.0
	add_child(l)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_mesh.scale = Vector3.ONE * (1.0 + 0.15 * sin(Time.get_ticks_msec() / 40.0))
	life -= delta
	if life <= 0:
		queue_free()

func _on_body(body: Node) -> void:
	if body is FieldMonster:
		(body as FieldMonster).stun(4.0)
		queue_free()
