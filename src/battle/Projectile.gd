class_name Projectile
extends Node3D
## Straight-line projectile along X that damages the first opponent it reaches.

var owner_b: Battler
var arte: Dictionary
var speed := 11.0
var life := 1.2
var dir := 1
var mesh: MeshInstance3D
var _hit: Array = []

func setup(o: Battler, a: Dictionary) -> void:
	owner_b = o
	arte = a
	dir = o.facing
	var kind: String = a.get("projectile", "ground_wave")
	mesh = MeshInstance3D.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Effects.element_color(a.get("element", "none"))
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.85
	match kind:
		"ground_wave":
			var sm := SphereMesh.new()
			sm.radius = 0.5
			sm.height = 1.0
			mesh.mesh = sm
			mesh.scale = Vector3(1.2, 0.6, 1.0)
			position.y = 0.3
			life = float(a.get("range", 8.0)) / speed
		"chakram", "hammer":
			var tm := TorusMesh.new()
			tm.inner_radius = 0.18
			tm.outer_radius = 0.3
			mesh.mesh = tm
			mesh.rotation_degrees.x = 90
			position.y = 1.1
			speed = 14.0
			life = float(a.get("range", 9.0)) / speed
		_:
			var sm := SphereMesh.new()
			sm.radius = 0.25
			sm.height = 0.5
			mesh.mesh = sm
			position.y = 1.2
			speed = 16.0
			life = float(a.get("range", 10.0)) / speed
	mesh.material_override = m
	add_child(mesh)

func _physics_process(delta: float) -> void:
	position.x += dir * speed * delta
	life -= delta
	mesh.rotation.z += delta * 15
	for b in owner_b.manager.opponents_of(owner_b):
		if b in _hit or not b.is_alive():
			continue
		var d: Vector3 = b.global_position - global_position
		if abs(d.x) < 0.7 + b.radius and abs(d.z) < 1.2:
			_hit.append(b)
			if arte.get("type", "base") == "angel" or arte.get("type") == "spell":
				owner_b.deal_magic(b, float(arte.get("power", 1.0)), arte.get("element", "none"), 1.0)
			else:
				owner_b.deal_physical(b, float(arte.get("power", 1.0)), float(arte.get("knockback", 1.5)), arte.get("element", "none"))
			Effects.flash(get_parent(), b.global_position + Vector3(0, 1, 0), Effects.element_color(arte.get("element", "none")))
			if int(arte.get("hits", 1)) <= 1:
				queue_free()
				return
	if life <= 0:
		queue_free()
