shader_type spatial;

const int ITER_COUNT = 100;

uniform float ASPECT_RATIO;

uniform vec4 color = vec4(0.0,0.0,0.0,1.0); // Base color of the shader
uniform float scale : hint_range(0.1, 5.0, 0.1) = 1; // Scaling factor for the pattern
uniform vec2 disp = vec2(0.0, 0.0); // Displacement of the texture
uniform float speed : hint_range(0.0, 5.0, 0.1) = 1; // Controls animation speed
uniform float nucleus = 1.0; // Strength of cell nucleus highlights
uniform float contrast : hint_range(0.0, 5.0, 0.1) = 0.5; // Adjusts contrast
uniform float line : hint_range(0.0, 5.0, 0.1) = 1.0; // Strength of lines in cells
uniform float layer1 : hint_range(0.0, 5.0, 0.1) = 1.0; // Influence of first layer of shading
uniform float layer2 : hint_range(0.0, 2.0, 0.1) = 1.0; // Influence of secondary shading


varying vec3 CAM_POS;
varying vec3 CAM_DIR;

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
vec2 split_tile(vec2 uv, vec2 cell_id) {
    // Use cell_id as a seed for consistent randomness
    float rand_split = hash12(cell_id);

    // Randomly decide to split the tile
    if (rand_split > 0.1 && rand_split < 0.9) {
        // Randomly choose split direction
        if (rand_split > 0.5) {
            // Vertical split
            uv.x = fract(uv.x * rand_split * 2.0);
        } else {
            // Horizontal split
            uv.y = fract(uv.y * rand_split * 5.0);
        }
    }

    return uv;
}

// Function to filter small areas
// Calculate the number of connected components of the same color in O
// Filter out (fill with white) any small areas
vec4 filter_small_components(vec4 O, vec2 uv) {
    return O;
}


vec4 voronoi(vec2 uv){
	vec4 O = color; // Base color output

    // Use UVs instead of SCREEN_UV to work in 3D
    vec2 U = (uv - disp) * scale; // Adjusted UV coordinates, scaled and displaced.
    float ratio = 1.0; // Assuming square UV mapping

    vec2 R = vec2(1.0); // Normalized resolution
    vec2 u = 3.0 * (U + U - R) / R.y + vec2(0, iTime); // Adjusted coordinate space

	// Draws grid lines with exponental falloff
    vec2 g = (u - 0.5) - round(u - 0.5);
    g = abs(g);
    if (g.x < g.y) g = g.yx;
    O += 0.4 * exp(-1e2 * g.y) * layer1;
    O += exp(-1e2 * length(u)) * layer1;

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

	// Colors each cell based on position and animation
    O += mix(vec4(0.5, 0, (ia.y - iTime) / 2.0, 1.0) + 0.3,
             vec4(0, 0.3, (ia.x - 0.0) * 0.3, 0) + 0.2,
             hash12(ia)) * layer2;

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

	// Adds strong borders between cells.
	// Note: exp(-2e2 * md) changes size of cell boundry
    // d = 10.0 * clamp(exp(-2e1 * md), 0.0, 1.0) * layer2;
	// Sharp boundary instead of glow (.1 for size)
	d = (md < 0.05 ? 2.0 : 0.0) * layer2;
	// Adds striping effects within cells.
    //d += 0.1 * clamp(exp(-2e2 * cos(80.0 * md)), 0.0, 1.0) * line;

	// ---------- Building Grid Stuff ----------
	float angle = hash12(ia) * 6.2831 + iTime * 0.001;

	// Create a grid inside each cell
	vec2 local_uv = vec2(u.x * 5.0, u.y * 5.0); // Controls grid density
	local_uv = rotate2D(angle) * local_uv; // Rotate based on nucleus direction

	// Draw grid
	vec2 tile_uv = fract(local_uv);
    vec2 tile_id = floor(local_uv);

    // Apply random tile splitting
    tile_uv = split_tile(tile_uv, tile_id);

	float grid_lines = min(abs(tile_uv.x), abs(tile_uv.y)); // Distance to the nearest grid line
	float grid_mask = step(grid_lines, 0.1); // Solid grid lines with thickness 0.03
	// Set grid lines to solid white
	vec3 grid_color = vec3(2.0) * grid_mask;

	//d = mix(d, 2.0, grid_mask); // Apply the grid effect only where grid_mask is 1
	O.rgb = mix(O.rgb, grid_color, grid_mask); // Blend grid lines into output

	// Calculate the minumum BBox of any area that is NOT white
	// Filter out (fill with white) any small areas
	O = filter_small_components(O, uv);

	// Applies contrast adjustments.
    O = max(O - contrast * d, 0.0) + d;

	return O;
}


void vertex() {
	CAM_POS = CAMERA_POSITION_WORLD;
	CAM_DIR = -CAMERA_DIRECTION_WORLD;
}
 
float distToNearestSurface(vec3 point){
	vec4 shape = voronoi(point.xz);
	
	return (shape.x + shape.y + shape.z > 0.1) ? 0.0 : 0.01;
	
	
    //vec3 center = vec3(0.5, 0.5, -20.0);
    //float radius = 2.0f;

    //return length(center - point) - radius;
}

vec3 getRayDir(vec2 uv_center) {
	vec2 angle = vec2(
		asin(CAM_DIR.y),
		atan(-CAM_DIR.x, CAM_DIR.z)
	);
	mat3 yaw = mat3(
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, cos(angle.x), -sin(angle.x)),
		vec3(0.0, sin(angle.x), cos(angle.x))
	);
	mat3 pitch = mat3(
		vec3(cos(angle.y), 0.0, sin(angle.y)),
		vec3(0.0, 1.0, 0.0),
		vec3(-sin(angle.y), 0.0, cos(angle.y))
	);

	return pitch * yaw * normalize(vec3(-uv_center, 1.0));
}

void fragment() {
	vec2 uv_center = UV * vec2(2.0f, 2.0f) - 1.0;
	uv_center.x *= ASPECT_RATIO;

	vec3 rayOrigin = CAM_POS;
	vec3 rayDir = getRayDir(uv_center);

	vec3 final_color = vec3(0.0, 0.0, 0.0);

	//Scale position to UV
	bool hit = false;
	// Raymarching
	for(int i = 0; i < ITER_COUNT; i++){
        float dist = distToNearestSurface(rayOrigin);

        rayOrigin += rayDir * dist;
        if(dist < 0.01f) {
			hit = true;
            break;
        }
    }
	
	if (hit) final_color = voronoi(rayOrigin.xz).xyz;// vec3(0.0, 1.0, 0.0);
	ALBEDO = final_color;
	//ALBEDO = voronoi(UV).xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
