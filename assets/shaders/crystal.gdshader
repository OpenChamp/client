shader_type spatial;

// Team tint: rgb color in xyz, alpha controls mix strength
instance uniform vec4 team_color = vec4(10,0,0,1);

// Inspector controls for rim and glass look
instance uniform bool rim_enabled = true;
instance uniform float rim_strength = 1.0; // 0..2
instance uniform float rim_exponent = 0.7; // controls rim sharpness
instance uniform vec3 glass_tint = vec3(0.9, 0.98, 1.0);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	// Convert to world-space so camera-based rim/fresnel is correct
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 team_color_v3 = vec3(team_color.r, team_color.g, team_color.b);

	// View direction in world-space
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);

	// Fresnel / rim term - highlights silhouettes and edges like a gemstone
	float ndotv = max(dot(normalize(world_normal), view_dir), 0.0);
	// Stronger falloff so edges are bright and faces stay darker
	float fresnel = pow(1.0 - ndotv, 3.0);

	// Rim - use an adjustable exponent and strength from the inspector
	float rim_base = pow(fresnel, rim_exponent);
	float rim_factor = rim_enabled ? rim_strength * rim_base : 0.0;

	// Base crystal color with team tint
	vec3 base_color = mix(vec3(0.9, 0.95, 1.0), team_color_v3, team_color.a);

	// Make the material look like looking INTO glass:
	// - stronger specular, near-zero metallic
	// - extremely low roughness for crisp reflections
	// - subtle internal tint based on viewing angle to suggest depth
	vec3 depth_tint = glass_tint;
	// When looking more head-on (ndotv close to 1) we see deeper into the glass.
	float view_depth = pow(ndotv, 1.2);
	// Blend base color slightly toward the glass tint based on angle
	vec3 final_albedo = mix(base_color, depth_tint, (1.0 - ndotv) * 0.25);

	// Rim color slightly tinted by team color but mostly bright/white
	vec3 rim_color = mix(vec3(1.0), team_color_v3, 0.25);
	vec3 rim_emission = rim_color * rim_factor * 1.6;

	// Small internal glow that is stronger toward edges (helps the 'glass' feel)
	vec3 internal_glow = team_color_v3 * 0.02 * (1.0 - ndotv);

	ALBEDO = final_albedo;
	EMISSION = rim_emission + internal_glow;

	// Glass-like surface parameters
	METALLIC = 0.0;
	ROUGHNESS = 0.005;
	SPECULAR = 0.6;

	// Make the object semi-transparent to allow seeing into the crystal.
	// Slightly more transparent when viewed head-on to simulate depth.
	ALPHA = clamp(0.15 + (1.0 - view_depth) * 0.35, 0.05, 0.8);

	// Slightly tint diffuse with the rim so edges blend smoothly
	ALBEDO = mix(ALBEDO, rim_color, rim_factor * 0.18);
}