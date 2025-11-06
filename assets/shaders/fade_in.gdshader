shader_type canvas_item;
uniform float fade_time : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	COLOR.a *= fade_time;
}