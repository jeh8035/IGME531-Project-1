shader_type spatial;

const int ITER_COUNT = 700;

uniform float ASPECT_RATIO;

#include "sdf_generator.gdshaderinc"
#include "building_shader.gdshaderinc"


varying vec3 CAM_POS;
varying vec3 CAM_DIR;

varying vec3 WORLD_POS;

varying flat vec3 obj_cam;

void vertex() {
	CAM_POS = CAMERA_POSITION_WORLD;
	CAM_DIR = -CAMERA_DIRECTION_WORLD;

	WORLD_POS = VERTEX;
}

// Get ray direction going out of the screen
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

// SDF for a plane at y=0
float sdf_plane(vec3 p) {
    return p.y - 1.0;
}

void fragment() {
	//Scale position to UV
	vec2 uv_center = UV * vec2(2.0f, 2.0f) - 1.0;
	uv_center.x *= ASPECT_RATIO;

	vec3 rayOrigin = CAM_POS;
	vec3 rayDir = getRayDir(uv_center);

	bool hit = false;
	float final_dist = 0.0;

	// x = dist, y = type
	vec3 sdf_result;

	// Hitting the ground plane
	bool hit_ground = false;

	// Raymarching
	for(int i = 0; i < ITER_COUNT; i++){
		// Culling
		if (final_dist > 500.0) break;

		// Distance to the ground plane
		float dist_to_plane = sdf_plane(rayOrigin);

		// Distance to roads & buildings
		sdf_result = voronoi(rayOrigin);
		sdf_result.x *= (0.1/scale);

		// Choose the closest hit
		float min_dist = min(dist_to_plane, sdf_result.x);

		// If closest is the ground plane, mark it
        if (min_dist == dist_to_plane && dist_to_plane < 0.01) {
            hit = true;
            hit_ground = true;
            break;
        } else {
	        rayOrigin += rayDir * sdf_result.x;
	        if(sdf_result.x < 0.01) {
				hit = true;
	            break;
	        }
		}
		final_dist += sdf_result.x;
    }

	// World colors
	vec3 road_color = vec3(0.3, 0.3, 0.3); // Dark Gray
	vec3 fog_color = vec3(0.46, 0.63, 0.77) * 10.0; // Light blue //vec3(0.0, 0.0, 0.0); // Black
	vec3 sidewalk_color = vec3(0.83, 0.74, 0.56); // Cream
	vec3 roof_color = vec3(0.75, 0.74, 0.73); // Light gray

	vec3 hit_color = fog_color; // Default to sky/fog color

	if (hit) {
		if(sdf_result.y == 0.0){
			hit_color = road_color;
		} else if (hit_ground == true) {
			hit_color = sidewalk_color;
		} else if(sdf_result.y == 2.0) {
			// Offset slightly by id
			hit_color = roof_color * sdf_result.z * 2.0;
		} else if(sdf_result.y == 1.0){
			hit_color = building_shader(rayOrigin, CAM_POS, sdf_result.z) * 2.0;
		}

		// Add fog based on distance
		float fog_factor = clamp(pow(final_dist / 500.0, 2.0), 0.0, 1.0);
		ALBEDO = mix(hit_color, fog_color, fog_factor);
	} else {
		ALBEDO = fog_color;
	}

}