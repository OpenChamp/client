shader_type canvas_item;

uniform float duration : hint_range(0.0, 10.0) = 1.0;
uniform vec4 text_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_vertex_color = true;

void fragment() {
	// Get the original texture (this contains the text with proper anti-aliasing)
	vec4 original_color = texture(TEXTURE, UV);
	
	// Apply the custom text color while preserving the original alpha for anti-aliasing
	COLOR = vec4(text_color.rgb, original_color.a * text_color.a);
	
	// Apply vertex color if enabled (for additional color modulation)
	if (use_vertex_color) {
		COLOR *= COLOR;
	}

	// Calculate fade progress based on time
	float fade_progress = clamp(TIME / duration, 0.0, 1.0);
	// Apply fade effect by multiplying the final alpha
	COLOR.a *= fade_progress;
}