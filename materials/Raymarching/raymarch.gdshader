shader_type spatial;

const int ITER_COUNT = 100;

uniform float ASPECT_RATIO;

#include "sdf_generator.gdshaderinc"


varying vec3 CAM_POS;
varying vec3 CAM_DIR;

varying vec3 WORLD_POS;

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

	vec3 final_color = vec3(0.0, 0.0, 0.0);

	bool hit = false;
	float final_dist = 0.0;

	// x = dist, y = type
	vec2 sdf_result;

	// Raymarching
	for(int i = 0; i < ITER_COUNT; i++){
		vec2 sdf = voronoi(rayOrigin);
		sdf_result = vec2(sdf.x * (0.25/scale), sdf.y);

        rayOrigin += rayDir * sdf_result.x;
        if(sdf_result.x < 0.01) {
			hit = true;
            break;
        }
		final_dist += sdf_result.x;
    }

	if (hit) final_color = vec3(0.01 * final_dist * sdf_result.y, 0.01 * final_dist * (1.0 - sdf_result.y), 0.0);//voronoi(rayOrigin.xz).xyz;//
	ALBEDO = final_color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
