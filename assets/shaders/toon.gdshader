shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// Vesperia-style cel shading: hard two-band diffuse, soft rim, tinted shadow, specular blob.
uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_vertex_color = false;
uniform vec4 shadow_tint : source_color = vec4(0.55, 0.5, 0.7, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_softness : hint_range(0.0, 0.2) = 0.02;
uniform float specular_size : hint_range(0.0, 1.0) = 0.12;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.35;
uniform float rim_size : hint_range(0.0, 1.0) = 0.3;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	vec4 base = albedo * texture(albedo_tex, UV);
	if (use_vertex_color) {
		base *= vcol;
	}
	ALBEDO = base.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, ndl * ATTENUATION);
	vec3 shade = mix(ALBEDO * shadow_tint.rgb, ALBEDO, lit);
	// Specular blob (Blinn-Phong stepped)
	vec3 h = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, h), 0.0);
	float spec = step(1.0 - specular_size, ndh) * specular_strength * lit;
	// Rim
	float ndv = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	float rim = step(1.0 - rim_size, ndv) * rim_strength * lit;
	DIFFUSE_LIGHT += shade * LIGHT_COLOR / 3.14159;
	SPECULAR_LIGHT += (spec + rim * rim_color.rgb) * LIGHT_COLOR / 3.14159;
}
