class_name ToonMaterial
## Factory for toon + outline materials.

static var _toon_shader: Shader = preload("res://assets/shaders/toon.gdshader")
static var _outline_shader: Shader = preload("res://assets/shaders/outline.gdshader")

static func make(color: Color, outline := true, thickness := 0.012, vertex_color := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _toon_shader
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("use_vertex_color", vertex_color)
	if outline:
		var o := ShaderMaterial.new()
		o.shader = _outline_shader
		o.set_shader_parameter("thickness", thickness)
		m.next_pass = o
	return m

static func apply_to_mesh(mesh_instance: MeshInstance3D, color: Color, outline := true) -> void:
	for i in mesh_instance.get_surface_override_material_count():
		mesh_instance.set_surface_override_material(i, make(color, outline))
