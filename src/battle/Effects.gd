class_name Effects
## Simple procedural VFX for artes and spells (toon spheres, rings, particles).

static func fire_burst(parent: Node3D, pos: Vector3, color := Color(1.0, 0.45, 0.1), count := 3, radius := 0.6) -> void:
	for i in count:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = radius * randf_range(0.5, 1.0)
		sm.height = sm.radius * 2
		sm.radial_segments = 8
		sm.rings = 4
		mi.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m
		mi.position = pos + Vector3(randf_range(-0.6, 0.6), randf_range(0.2, 1.4), randf_range(-0.3, 0.3))
		parent.add_child(mi)
		var t := parent.create_tween()
		t.set_parallel(true)
		t.tween_property(mi, "scale", Vector3.ONE * 2.2, 0.45).set_ease(Tween.EASE_OUT)
		t.tween_property(m, "albedo_color:a", 0.0, 0.45)
		t.tween_property(mi, "position:y", mi.position.y + 1.0, 0.45)
		t.chain().tween_callback(mi.queue_free)

static func ring(parent: Node3D, pos: Vector3, color := Color(0.4, 0.8, 1.0), size := 1.5, duration := 0.5) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 24
	tm.ring_segments = 6
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position = pos + Vector3(0, 0.05, 0)
	mi.scale = Vector3.ONE * 0.2
	parent.add_child(mi)
	var t := parent.create_tween()
	t.set_parallel(true)
	t.tween_property(mi, "scale", Vector3.ONE * size, duration).set_ease(Tween.EASE_OUT)
	t.tween_property(m, "albedo_color:a", 0.0, duration)
	t.chain().tween_callback(mi.queue_free)

static func flash(parent: Node3D, pos: Vector3, color := Color(1, 1, 1), size := 0.5) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = size
	sm.height = size * 2
	sm.radial_segments = 6
	sm.rings = 3
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	var t := parent.create_tween()
	t.set_parallel(true)
	t.tween_property(mi, "scale", Vector3.ONE * 2.5, 0.2)
	t.tween_property(m, "albedo_color:a", 0.0, 0.2)
	t.chain().tween_callback(mi.queue_free)

static func pillar(parent: Node3D, pos: Vector3, color := Color(1, 1, 0.6), height := 4.0, duration := 0.5) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.7
	cm.height = height
	cm.radial_segments = 10
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color.r, color.g, color.b, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position = pos + Vector3(0, height / 2, 0)
	parent.add_child(mi)
	var t := parent.create_tween()
	t.set_parallel(true)
	t.tween_property(mi, "scale:x", 0.1, duration)
	t.tween_property(mi, "scale:z", 0.1, duration)
	t.tween_property(m, "albedo_color:a", 0.0, duration)
	t.chain().tween_callback(mi.queue_free)

static func element_color(elem: String) -> Color:
	return {"fire": Color(1.0, 0.45, 0.1), "water": Color(0.3, 0.6, 1.0), "earth": Color(0.6, 0.45, 0.2), "wind": Color(0.6, 1.0, 0.6),
		"lightning": Color(1.0, 1.0, 0.4), "light": Color(1.0, 0.95, 0.7), "dark": Color(0.5, 0.2, 0.7), "none": Color(0.9, 0.9, 1.0)}.get(elem, Color.WHITE)
