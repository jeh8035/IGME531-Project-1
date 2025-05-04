
uniform vec4 color = vec4(0.0,0.0,0.0,1.0); // Base color of the shader
const float scale = .001; // Scaling factor for the pattern
uniform vec2 disp = vec2(0.0, 0.0); // Displacement of the texture
uniform float speed : hint_range(0.0, 5.0, 0.1) = 1; // Controls animation speed
uniform float nucleus = 1.0; // Strength of cell nucleus highlights
uniform float contrast : hint_range(0.0, 5.0, 0.1) = 0.5; // Adjusts contrast
uniform float line : hint_range(0.0, 5.0, 0.1) = 1.0; // Strength of lines in cells
uniform float layer1 : hint_range(0.0, 5.0, 0.1) = 1.0; // Influence of first layer of shading
uniform float layer2 : hint_range(0.0, 2.0, 0.1) = 1.0; // Influence of secondary shading


// Macros
#define iTime TIME * speed
#define iResolution 1.0 / SCREEN_PIXEL_SIZE

// Psudo random number
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.zyx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Cell radius calculation
float rcel(vec2 ip) {
    return mix(0.25, 0.45, hash12(ip + 0.2));
}

// Cell nucleaus calculation
vec2 cell(vec2 ip) {
    float ag = 6.28 * hash12(ip + 1.23) + 5.0 * iTime;
    return vec2(cos(ag), sin(ag)) * rcel(ip);
}

// Rotation function for inner grid
mat2 rotate2D(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(
		vec2(c, -s),
		vec2(s, c)
		);
}

// Function to split tiles randomly
// Returns a signed distance from the nearest road
vec2 split_tile(vec2 uv, vec2 cell_id) {
    // Use cell_id as a seed for consistent randomness
    float rand_split = hash12(cell_id);
	// Width of the roads
	float road_width = 0.05;
	
	// Default values
    float dist_to_road = 1.0;
    float road_type = 0.0;
	
	// Initial road distance calculation (distance to cell borders)
    float dist_to_border = min(
        min(uv.x, 1.0 - uv.x),
        min(uv.y, 1.0 - uv.y)
    );
	
	// Update distance to include cell borders
    dist_to_road = min(dist_to_road, dist_to_border);

    // Only apply subdivision if within the randomness threshold
    if (rand_split > 0.1 && rand_split < 0.9) {
        // Randomly choose split direction
        if (rand_split > 0.5) {
            // Vertical split
            float split_pos = 0.5; // Position of the split
            float dist_to_split = abs(uv.x - split_pos);
            
            // Update distance to nearest road
            if (dist_to_split < dist_to_road) {
                dist_to_road = dist_to_split;
                road_type = 1.0; // Internal road
            }
            
            // Apply the split for texture coordinates
            uv.x = fract(uv.x * rand_split * 2.0);
		} else {
            // Horizontal split
            float split_pos = 0.5; // Position of the split
            float dist_to_split = abs(uv.y - split_pos);
            
            // Update distance to nearest road
            if (dist_to_split < dist_to_road) {
                dist_to_road = dist_to_split;
                road_type = 1.0; // Internal road
            }
			// Apply the split for texture coordinates
	        uv.y = fract(uv.y * rand_split * 5.0);
		}
	}
	// Calculate signed distance (negative inside roads, positive outside)
    float signed_dist = dist_to_road - road_width;
    
    // Return both the signed distance and the road type
    return vec2(signed_dist, road_type);
}

// Calculates an SDF based on a height
float sdf_height(float top, float bottom, float height) {
	return scale * float(height > top) * abs(height - top) +
						float(height < bottom) * abs(height - bottom);
}

// Returns: x = dist, y = type
vec2 voronoi(vec3 point){
	vec4 O = color; // Base color output

    // Use UVs instead of SCREEN_UV to work in 3D
    vec2 U = (point.xz - disp) * scale; // Adjusted UV coordinates, scaled and displaced.
    float ratio = 1.0; // Assuming square UV mapping

    vec2 R = vec2(1.0); // Normalized resolution
    vec2 u = 3.0 * (U + U - R) / R.y + vec2(0, iTime); // Adjusted coordinate space

    vec2 p = u; // Position of the current fragment
	vec2 ip = round(p); // Rounded integer cell position
	vec2 fp = p - ip; // Fractional part (offset inside the cell)
	vec2 ct = cell(ip); // The computed cell nucleus position.

    O.x += exp(-30.0 * length(fp - ct)) * nucleus; // Highlights the cell nucleus.
    O += 0.2 * exp(-99.0 * abs(length(fp) - rcel(ip))) * layer1; // Adds a glowing effect around the cell.

	// Iterates over neighboring cells to find the nearest nucleus.
    vec2 a, ia;
    float md = 1e8, d;
    for (float j = -1.0; j < 2.0; j++) {
        for (float i = -1.0; i < 2.0; i++) {
            vec2 e = ip + vec2(i, j), c = cell(e) + e;
            d = length(c - p);
            if (d < md) {
                md = d; // (minimum distance) to track the closest cell
                ia = e; // Closest cell integer position
                a = c; // Closest cell nucleus position
            }
        }
    }

	// Searches for the nearest cell boundary
	// Uses dot products to measure distances to edges
    md = 1e8;
    for (float j = -2.0; j <= 2.0; j++) {
        for (float i = -2.0; i <= 2.0; i++) {
            if (abs(i) + abs(j) > 0.1) {
                vec2 e = ia + vec2(i, j), b = cell(e) + e;
                d = dot(p - (a + b) / 2.0, normalize(a - b)); // float distance to edge
                md = min(md, d);
            }
        }
    }

	// ---------- Building Grid Stuff ----------
	float angle = hash12(ia) * 6.2831 + iTime * 0.001;

	// Create a grid inside each cell
	vec2 local_uv = vec2(u.x * 5.0, u.y * 5.0); // Controls grid density
	local_uv = rotate2D(angle) * local_uv; // Rotate based on nucleus direction

	// Draw grid
	vec2 tile_uv = fract(local_uv);
    vec2 tile_id = floor(local_uv);

    // Apply random tile splitting
    // Get road SDF and type from split_tile
	vec2 road_data = split_tile(tile_uv, tile_id);
	float road_dist = road_data.x;
	float road_type = road_data.y;
	
	if (road_dist < 0.0) {
	    // Inside a road
	    if (road_type < 0.5) {
	        // Main road
	        O = vec4(1.0, 0.0, 0.0, 1.0);
	    } else {
	        // Internal road
	        O = vec4(0.0, 0.0, 1.0, 1.0);
		}
    }


	// Thickness
	road_dist = min(max(md - 0.01, 0.0), max(road_dist - 0.01, 0.0));

	// Buildings
	float rand_building_value = hash12(ia);
	float building_dist = max((0.01 - road_dist), 0.0);
	// Height
	building_dist = sqrt(pow(building_dist, 2.0) + pow(sdf_height(rand_building_value * 50.0, -5.0, point.y), 2.0));
	road_dist = sqrt(pow(road_dist, 2.0) + pow(sdf_height(-3.0, -5.0, point.y), 2.0));
	
	float min_dist = min(building_dist, road_dist);
	float type = building_dist < road_dist ? 1.0 : 0.0;

	return vec2(min_dist, type); 
}
