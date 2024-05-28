shader_type sky;

uniform vec4 skyColor : source_color;

void sky() {
	COLOR = skyColor.rgb;
}

