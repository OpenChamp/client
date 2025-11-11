shader_type spatial;
instance uniform vec4 team_color = vec4(10,0,0,1);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = VERTEX;
	world_normal = NORMAL;
}

void fragment() {
	vec3 team_color_v3 = vec3(team_color.r, team_color.g,team_color.b);
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
	float fresnel = 1.0 - dot(normalize(world_normal), view_dir);
	fresnel = pow(fresnel, 2.0);

	// Base crystal color with team tint
	vec3 base_color = mix(vec3(0.9, 0.95, 1.0), team_color_v3, team_color.a);

	ALBEDO = base_color;
	EMISSION = team_color_v3 * fresnel * 0.5;
	METALLIC = 0.1;
	ROUGHNESS = 0.02;
	SPECULAR = 0.1;
	ALPHA = 0.5;
}