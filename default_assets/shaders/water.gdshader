shader_type spatial;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 color3 : source_color;
uniform float x_amount = 32.0;
uniform float y_amount = 32.0;

float random (vec2 uv) { return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123) ; }

void fragment() {
	vec2 tiled_uvs = vec2(trunc(UV.x/(1.0/x_amount)), trunc(UV.y/(1.0/y_amount)));
	ALBEDO = mix(mix(color1.rgb, color2.rgb, sin(TIME + tiled_uvs.x - tiled_uvs.y * random(tiled_uvs))/2.5), color3.rgb, sin(TIME + tiled_uvs.x - tiled_uvs.y * random(tiled_uvs.yx))/2.0);

}