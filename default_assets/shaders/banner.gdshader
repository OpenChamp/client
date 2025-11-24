shader_type spatial;

uniform float wind_strength : hint_range(0.0, 2.0) = 0.5;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.5);
instance uniform vec4 team_color : source_color = vec4(1,0,0,1);
uniform float dampening = 0.9;
varying vec3 world_position;

void vertex() {
	world_position = VERTEX;

	// Calculate wind effect based on vertex position and time
	float wind_wave = sin(TIME * wind_speed + world_position.x * 0.5 + world_position.z * 0.3) * wind_strength;
	float wind_wave2 = cos(TIME * wind_speed * 0.7 + world_position.x * 0.3 + world_position.z * 0.5) * wind_strength * 0.5;

	// Apply wind displacement primarily to Y and slightly to X/Z
	VERTEX.y += wind_wave * 0.1;
	VERTEX.x += wind_direction.x * wind_wave2 * 0.05;
	VERTEX.z += wind_direction.y * wind_wave2 * 0.05;
}

void fragment() {
	// Use team_color as base with slight shading variation
	vec3 base_color = vec3(team_color.r,team_color.g,team_color.b);
	// Add subtle wind-based color variation
	float color_variation = sin(TIME * 0.5 + world_position.x * 0.2) * 0.1 + 0.9;

	ALPHA = team_color.a;
	ALBEDO = base_color * color_variation * dampening;
	ROUGHNESS = 0.8;
	METALLIC = 0.1;

}
