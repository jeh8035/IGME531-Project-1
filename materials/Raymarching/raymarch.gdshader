shader_type spatial;

const int ITER_COUNT = 100;

uniform float ASPECT_RATIO;

varying vec3 CAM_POS;
varying vec3 CAM_DIR;

void vertex() {
	CAM_POS = CAMERA_POSITION_WORLD;
	CAM_DIR = -CAMERA_DIRECTION_WORLD;
}


float distToNearestSurface(vec3 point){
    vec3 center = vec3(0.5, 0.5, -20.0);
    float radius = 2.0f;

    return length(center - point) - radius;
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

	vec3 color = vec3(0.0, 0.0, 0.0);

	// Raymarching
	for(int i = 0; i < ITER_COUNT; i++){
        float dist = distToNearestSurface(rayOrigin);

        rayOrigin += rayDir * dist;
        if(dist < 0.01f) {
            color = vec3(0.0, 1.0, 0.0);
            break;
        }
    }

	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
