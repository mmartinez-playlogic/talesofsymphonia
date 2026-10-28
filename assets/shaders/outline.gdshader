shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;

// Inverted-hull outline. Use as next_pass of the toon material.
uniform vec4 outline_color : source_color = vec4(0.05, 0.03, 0.08, 1.0);
uniform float thickness : hint_range(0.0, 0.1) = 0.012;
uniform bool scale_with_distance = true;

void vertex() {
	float d = 1.0;
	if (scale_with_distance) {
		vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		d = clamp(-view_pos.z * 0.08, 0.6, 2.5);
	}
	VERTEX += normalize(NORMAL) * thickness * d;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
