shader_type canvas_item;

uniform float border_width : hint_range(0.0, 0.5) = 0.05;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White border
uniform float radius : hint_range(0.0, 0.5) = 0.5;

void fragment() {
    // 1. Calculate distance from the center (0.5, 0.5) in normalized UV space (0 to 1)
    vec2 center = vec2(0.5);
    float dist = distance(UV, center);

    // 2. Determine the inner radius (where the image ends)
    float inner_radius = radius - border_width;

    // 3. Get the color of the original texture
    vec4 image_color = texture(TEXTURE, UV);

    // 4. Determine pixel color based on distance
    if (dist <= inner_radius) {
        // Inside the image circle
        COLOR = image_color;
    } else if (dist <= radius) {
        // Inside the border ring
        COLOR = border_color;
    } else {
        // Outside the border - discard the pixel (make it transparent)
        discard;
    }
}