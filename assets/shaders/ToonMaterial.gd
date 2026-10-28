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
		o.set_shader_parameter("outline_color", Color(color.r * 0.25, color.g * 0.2, color.b * 0.3, 1.0))
		m.next_pass = o
	return m

## Character material: picks Vesperia-style parameters from the Blender material name.
static func make_character(color: Color, mat_name: String, thickness := 0.012) -> ShaderMaterial:
	var n := mat_name.to_lower()
	var face_part := n.contains("iris") or n.contains("eye_") or n.contains("shine") or n.contains("visor")
	var m := make(color, not face_part, thickness)
	if face_part:
		m.set_shader_parameter("unshaded_face_part", true)
	if n.ends_with("_hair") or n == "hair":
		m.set_shader_parameter("hair", true)
		m.set_shader_parameter("shadow_tint", Color(0.66, 0.58, 0.8))
	if n.ends_with("_skin") or n.ends_with("_hands") and color.r > 0.6:
		m.set_shader_parameter("shadow_tint", Color(0.9, 0.68, 0.66))
		m.set_shader_parameter("deep_shadow_tint", Color(0.72, 0.5, 0.52))
		m.set_shader_parameter("specular_strength", 0.0)
	if n.ends_with("_metal") or n.contains("gem"):
		m.set_shader_parameter("specular_size", 0.2)
		m.set_shader_parameter("specular_strength", 0.6)
	return m

static func apply_to_mesh(mesh_instance: MeshInstance3D, color: Color, outline := true) -> void:
	for i in mesh_instance.get_surface_override_material_count():
		mesh_instance.set_surface_override_material(i, make(color, outline))
