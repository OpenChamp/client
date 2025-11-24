shader_type spatial;

// --- Colors ---
uniform vec3 dirt_color_light : source_color = vec3(0.55, 0.42, 0.32);
uniform vec3 dirt_color_dark : source_color = vec3(0.4, 0.3, 0.2);
uniform vec3 rock_color_light : source_color = vec3(0.5, 0.5, 0.5);
uniform vec3 rock_color_dark : source_color = vec3(0.3, 0.3, 0.3);

// --- Tiling & Density ---
uniform float dirt_patch_scale = 5.0;
uniform float rock_scale = 15.0;
uniform float rock_threshold = 0.8;

// --- Rock Shape Controls ---
uniform float rock_height = 0.8; // How much rocks pop out
uniform float rock_sharpness = 0.4; // Edge sharpness (lower = sharper)

// 2D hash for better randomness
// Higher quality 2D hash
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}
// Smooth noise for dirt
float smooth_noise(vec2 coord, float scale) {
	vec2 scaled = coord * scale;
	vec2 grid = floor(scaled);
	vec2 frac_pos = fract(scaled);

	frac_pos = frac_pos * frac_pos * (3.0 - 2.0 * frac_pos);

	float a = hash(grid);
	float b = hash(grid + vec2(1.0, 0.0));
	float c = hash(grid + vec2(0.0, 1.0));
	float d = hash(grid + vec2(1.0, 1.0));

	return mix(mix(a, b, frac_pos.x), mix(c, d, frac_pos.x), frac_pos.y);
}

// Voronoi function - creates angular cells like low-poly crystals
vec3 voronoi(vec2 coord, float scale) {
	vec2 scaled = coord * scale;
	vec2 grid = floor(scaled);
	vec2 frac_pos = fract(scaled);

	float min_dist = 1.0;
	vec2 closest_point = vec2(0.0);
	vec2 closest_cell = vec2(0.0);

	// Check 3x3 grid of cells around current position
	for(int y = -1; y <= 1; y++) {
		for(int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 cell = grid + neighbor;

			// Random point within this cell
			vec2 point = hash2(cell);

			// Distance to this point
			vec2 diff = neighbor + point - frac_pos;
			float dist = length(diff);

			if(dist < min_dist) {
				min_dist = dist;
				closest_point = point;
				closest_cell = cell;
			}
		}
	}

	// Return: distance, cell ID (for random values)
	return vec3(min_dist, closest_cell);
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 coord = world_pos.xz;

	// --- 1. Base Dirt Layer ---
	float dirt_noise = smooth_noise(coord, dirt_patch_scale);
	float dirt_detail = smooth_noise(coord, dirt_patch_scale * 2.5) * 0.3;
	dirt_noise = dirt_noise * 0.7 + dirt_detail;

	vec3 color = mix(dirt_color_light, dirt_color_dark, dirt_noise);

	// --- 2. Rock Layer (Voronoi-based) ---
	vec2 rock_grid = floor(coord * rock_scale);
	float rock_value = hash(rock_grid);

	vec3 normal_offset = vec3(0.0, 0.0, 0.0);

	if (rock_value > rock_threshold) {
		// Get Voronoi cell info
		vec3 voronoi_data = voronoi(coord, rock_scale);
		float dist = voronoi_data.x;
		vec2 cell_id = voronoi_data.yz;

		// Create sharp-edged rock shape
		float rock_shape = 1.0 - smoothstep(0.0, rock_sharpness, dist);

		// Add some randomness to rock height per cell
		float height_variation = hash(cell_id + vec2(7.3, 2.1)) * 0.5 + 0.5;
		rock_shape *= height_variation;

		// Color the rock with per-cell variation
		float rock_mix = hash(cell_id + vec2(5.2, 1.8));
		vec3 rock_color = mix(rock_color_light, rock_color_dark, rock_mix);
		color = mix(color, rock_color, rock_shape);

		// --- Create Faceted Normal Map ---
		// Calculate position within the voronoi cell
		vec2 local_pos = fract(coord * rock_scale);

		// Find the center of this voronoi cell
		vec2 cell_center = hash2(cell_id);

		// Direction from cell center
		vec2 dir = local_pos - cell_center;

		// Create angular, faceted normals
		float angle = atan(dir.y, dir.x);
		int facets = 6; // Number of facets (hexagon-like)
		float facet_angle = floor(angle / (6.28318 / float(facets))) * (6.28318 / float(facets));

		vec2 facet_dir = vec2(cos(facet_angle), sin(facet_angle));

		// Apply normal offset based on facet direction
		normal_offset = vec3(
			facet_dir.x * rock_shape * rock_height,
			rock_shape * rock_height * 1.5, // Up direction
			facet_dir.y * rock_shape * rock_height
		);
	}

	// --- 3. Final Output ---
	ALBEDO = color;
	NORMAL = normalize(NORMAL + normal_offset);
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}