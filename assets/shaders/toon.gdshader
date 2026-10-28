shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// Vesperia-style cel shading: three tones (lit / shade / deep shade) with a tinted shadow,
// stepped specular, soft fresnel rim on the lit side, and an anisotropic "angel ring" highlight for hair.
uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_vertex_color = false;
uniform vec4 shadow_tint : source_color = vec4(0.62, 0.56, 0.78, 1.0);
uniform vec4 deep_shadow_tint : source_color = vec4(0.42, 0.38, 0.6, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.42;
uniform float deep_threshold : hint_range(-1.0, 1.0) = -0.25;
uniform float shadow_softness : hint_range(0.0, 0.2) = 0.03;
uniform float specular_size : hint_range(0.0, 1.0) = 0.08;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.25;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform bool hair = false;
uniform float hair_ring_strength : hint_range(0.0, 1.0) = 0.45;
uniform bool unshaded_face_part = false;   // eyes, mouth: flat colour, no shading

void vertex() {}

void fragment() {
	vec4 base = albedo * texture(albedo_tex, UV);
	if (use_vertex_color) {
		base *= COLOR;
	}
	ALBEDO = base.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	if (unshaded_face_part) {
		EMISSION = base.rgb * 0.85;
	}
}

void light() {
	if (unshaded_face_part) {
		DIFFUSE_LIGHT += ALBEDO * 0.05 * LIGHT_COLOR;
	} else {
		float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
		float lit = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, ndl);
		float deep = smoothstep(deep_threshold - shadow_softness, deep_threshold + shadow_softness, ndl);
		vec3 shade = mix(ALBEDO * deep_shadow_tint.rgb, ALBEDO * shadow_tint.rgb, deep);
		shade = mix(shade, ALBEDO, lit);
		vec3 h = normalize(VIEW + LIGHT);
		float ndh = max(dot(NORMAL, h), 0.0);
		float spec = step(1.0 - specular_size, ndh) * specular_strength * lit;
		if (hair) {
			// anisotropic ring: highlight band where the normal faces the halfway vector in the vertical plane
			vec3 t = normalize(cross(NORMAL, vec3(0.0, 1.0, 0.0)) + vec3(1e-4));
			float th = dot(t, h);
			float band = sqrt(max(0.0, 1.0 - th * th));
			spec = smoothstep(0.94, 0.97, band) * hair_ring_strength * (0.4 + 0.6 * lit);
		}
		float fres = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);
		float rim = smoothstep(0.35, 0.5, fres) * rim_strength * max(lit, 0.25);
		DIFFUSE_LIGHT += shade * LIGHT_COLOR / 3.14159;
		SPECULAR_LIGHT += (spec + rim * rim_color.rgb) * LIGHT_COLOR / 3.14159;
	}
}
