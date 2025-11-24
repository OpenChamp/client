shader_type spatial;

uniform sampler2D grass_texture;
uniform sampler2D grass2_texture;
uniform sampler2D dirt_texture;
uniform float texture_scale = 1.0;

void fragment() {
    // Get vertex color
    vec3 vertex_color = COLOR.rgb;

    // Sample each texture
    vec2 uv_scaled = UV * texture_scale;
    vec4 grass_tex = texture(grass_texture, uv_scaled);
    vec4 grass2_tex = texture(grass2_texture, uv_scaled);
    vec4 dirt_tex = texture(dirt_texture, uv_scaled);

    // Mix textures based on vertex colors
    vec4 final_color = vec4(0.0);
    final_color += grass_tex * vertex_color.r; // Grass for red
    final_color += grass2_tex * vertex_color.g; // Grass2 for green
    final_color += dirt_tex * vertex_color.b; // Dirt for blue

    // Output the final color
    ALBEDO = final_color.rgb;
}
