// ceiling, floor, wall albedo
uniform sampler2DArray room_albedo;
uniform sampler2D room_exterior_albedo;

float random3(vec3 uv) {
    return fract(sin(dot(uv.xyz,
        vec3(12.9898,78.233,41.2512))) * 43758.5453123);
}

const float room_scale = 1.0;

vec3 building_shader(vec3 rayOrigin, vec3 cameraPos, float building_hash) {
	const float FLOOR_HEIGHT = 1.0;
	const float ROOM_SIZE = 1.0;

	vec3 obj_vertex = rayOrigin.xyz * room_scale;//(MODEL_MATRIX * vec4(rayOrigin.xyz, 1.0)).xyz * 0.5;
	obj_vertex *= vec3(1.0, -1.0, 1.0);

	// Random value per window
	vec3 random_seed = vec3(round(obj_vertex.x - 0.5), round(obj_vertex.y - 0.5), round(obj_vertex.z - 0.5));
	float random_window_val = random3(random_seed);


	// Interior mapping
	vec3 obj_cam = (cameraPos * room_scale * vec3(1.0, -1.0, 1.0));
	vec3 cam2pix = obj_vertex - obj_cam;

	float is_floor = step(cam2pix.y, 0.0);
	float ceiling_y = ceil(obj_vertex.y / FLOOR_HEIGHT - is_floor) * FLOOR_HEIGHT;
	float ceiling_t = (ceiling_y - obj_cam.y) / cam2pix.y;

	float is_north = step(cam2pix.z, 0.0);
	float front_wall_z = ceil(obj_vertex.z / ROOM_SIZE - is_north) * ROOM_SIZE;
	float front_wall_t = (front_wall_z - obj_cam.z) / cam2pix.z;

	float is_east = step(cam2pix.x, 0.0);
	float side_wall_x = ceil(obj_vertex.x / ROOM_SIZE - is_east) * ROOM_SIZE;
	float side_wall_t = (side_wall_x - obj_cam.x) / cam2pix.x;

	vec3 tex_coord;
	if (ceiling_t < side_wall_t) {
		if (ceiling_t < front_wall_t) {
			// Ceiling/floor
			tex_coord = vec3(obj_cam.xz + ceiling_t * cam2pix.xz, is_floor);
			tex_coord.x = mod(tex_coord.x / 4.0, 1.0/4.0);
			tex_coord.x += floor(random_window_val * 4.0) / 4.0;
		}
		else {
			// Front/back wall
			tex_coord = vec3(obj_cam.xy + front_wall_t * cam2pix.xy, 2.0);
			tex_coord.x = mod(tex_coord.x / 8.0, 1.0/8.0);
			tex_coord.x += floor(random_window_val * 8.0) / 8.0;
		}
	} else {
		if (front_wall_t < side_wall_t) {
			// Front/back wall
			tex_coord = vec3(obj_cam.xy + front_wall_t * cam2pix.xy, 2.0);
			tex_coord.x = mod(tex_coord.x / 8.0, 1.0/8.0);
			tex_coord.x += floor(random_window_val * 8.0) / 8.0;
		} else {
			// Side wall
			tex_coord = vec3(obj_cam.zy + side_wall_t * cam2pix.zy, 2.0);
			tex_coord.x = mod(tex_coord.x / 8.0, 1.0/8.0);
			tex_coord.x += floor(random_window_val * 8.0) / 8.0;
		}
	}
	vec2 exterior_uv = vec2(obj_vertex.x + obj_vertex.z, obj_vertex.y);

	// Exterior texture (randomly select)
	exterior_uv.x = mod(exterior_uv.x / 3.0, 1.0/3.0);
	exterior_uv.x += floor(building_hash * 3.0) / 3.0;
	vec4 exterior = texture(room_exterior_albedo, exterior_uv);
	
	// Random lighting
	vec3 interior = texture(room_albedo, tex_coord).rgb;
	interior = min(interior * random_window_val * 2.0, vec3(1.0));
	
	return mix(interior, exterior.rgb, exterior.a);
}