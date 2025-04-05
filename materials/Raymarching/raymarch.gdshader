shader_type spatial;

uniform float ASPECT_RATIO;

varying vec3 CAM_POS;
varying vec3 CAM_DIR;
varying mat4 MAIN_MAT;

void vertex() {
	CAM_POS = CAMERA_POSITION_WORLD;
	CAM_DIR = CAMERA_DIRECTION_WORLD;
	
	MAIN_MAT = MAIN_CAM_INV_VIEW_MATRIX;
}


float distToNearestSurface(vec3 point){
    vec3 center = vec3(0.5, 0.5, 1.0);
    float radius = 0.3f;
	
    return length(center - point) - radius;
}

void fragment() {
	vec2 uv_center = UV * vec2(2.0f, 2.0f) - 1.0;
	uv_center.x *= ASPECT_RATIO;
	
	vec3 rayOrigin = CAM_POS;
    vec3 rayDir = normalize(vec3(uv_center, 1.0));
	
	vec3 color = vec3(0.0, 0.0, 0.0);
	
	for(int i = 0; i < 100; i++){
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
