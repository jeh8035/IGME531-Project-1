shader_type spatial;

const int ITER_COUNT = 500;

uniform float ASPECT_RATIO;

#include "sdf_generator.gdshaderinc"
#include "building_shader.gdshaderinc"


varying vec3 CAM_POS;
varying vec3 CAM_DIR;

varying vec3 WORLD_POS;

varying flat vec3 obj_cam;

// World colors
uniform vec3 road_color = vec3(1.0, 0.0, 0.0);
uniform vec3 fog_color = vec3(0.7, 0.2, 0.7);


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

void fragment() {

	//ALBEDO = voronoi(WORLD_POS.xz).xyz;

	//Scale position to UV
	vec2 uv_center = UV * vec2(2.0f, 2.0f) - 1.0;
	uv_center.x *= ASPECT_RATIO;

	vec3 rayOrigin = CAM_POS;
	vec3 rayDir = getRayDir(uv_center);

	bool hit = false;
	float final_dist = 0.0;

	// x = dist, y = type
	vec3 sdf_result;

	// Raymarching
	for(int i = 0; i < ITER_COUNT; i++){
		sdf_result = voronoi(rayOrigin);
		sdf_result.x *= (0.05/scale);

        rayOrigin += rayDir * sdf_result.x;
        if(sdf_result.x < 0.01) {
			hit = true;
            break;
        }
		final_dist += sdf_result.x;
    }

	// Get final color
	vec3 building_color = building_shader(rayOrigin, CAM_POS, sdf_result.z);
	
	vec3 hit_color =  mix(building_color, road_color, step(sdf_result.y, 0.0));
	ALBEDO = hit ? hit_color : fog_color;

	// Add fog based on distance
	float fog_factor = 1.0 - exp(-0.01 * final_dist);
	ALBEDO = mix(ALBEDO, fog_color, fog_factor);

}