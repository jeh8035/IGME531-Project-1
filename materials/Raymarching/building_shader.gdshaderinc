uniform sampler2D uv_texture : source_color, filter_nearest, repeat_enable;

// ceiling, floor, wall albedo
uniform sampler2DArray room_albedo;
//uniform sampler2D room_exterior_albedo;

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

float random3(vec3 uv) {
    return fract(sin(dot(uv.xyz,
        vec3(12.9898,78.233,41.2512))) * 43758.5453123);
}

float random2(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898,78.233))) * 43758.5453123);
}

float random1(float seed) {
	return random2(vec2(seed, seed));
}

float random1_alt(float seed) {
	return random2(vec2(seed, -seed));
}

const float room_scale = 2.0;

vec3 building_shader(vec3 rayOrigin, vec3 cameraPos) {
	const float FLOOR_HEIGHT = 1.0;
	const float ROOM_SIZE = 1.0;
	
	vec3 final_color = vec3(0.0);
	
	// Interior mapping
	vec3 obj_vertex = rayOrigin.xyz * room_scale;//(MODEL_MATRIX * vec4(rayOrigin.xyz, 1.0)).xyz * 0.5;
	obj_vertex *= vec3(1.0, -1.0, 1.0);
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
			// Ceiling
			tex_coord = vec3(obj_cam.xz + ceiling_t * cam2pix.xz, is_floor);
		}
		else {
			// Front/back wall
			tex_coord = vec3(obj_cam.xy + front_wall_t * cam2pix.xy, 2.0);
		}
	} else {
		if (front_wall_t < side_wall_t) {
			// Front/back wall
			tex_coord = vec3(obj_cam.xy + front_wall_t * cam2pix.xy, 2.0);
		} else {
			// Side wall
			tex_coord = vec3(obj_cam.zy + side_wall_t * cam2pix.zy, 2.0);
		}
	}
	//vec2 exterior_uv = vec2(obj_vertex.x + obj_vertex.z, obj_vertex.y);
	//vec4 exterior = texture(room_exterior_albedo, exterior_uv);
	final_color = texture(room_albedo, tex_coord).rgb;//mix(interior_texture, exterior.rgb, exterior.a);
	
	// Window lights
	vec3 uv1_power_normal = pow( normalize(vec3(1.0, 1.0, 1.0)), vec3(1.0));
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	
	vec4 uv_tex = triplanar_texture(uv_texture, uv1_power_normal, obj_vertex);

	// Random value per window
	vec3 random_seed = vec3(round(obj_vertex.x - 0.5), round(obj_vertex.y - 0.5), round(obj_vertex.z - 0.5));
	float random_window_val = random3(random_seed);

	const vec2 WINDOW_SIZE = vec2(1.0, 1.0);

	// Make emissive windows
	bool is_window =
		// Turn off some windows
		random_window_val > 0.8 &&
		// No windows on top/bottom faces
		//(INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).y < 0.2 &&
		// Window size
		(uv_tex.x > (0.50 - WINDOW_SIZE.x/2.0) &&
			uv_tex.x < (0.5 + WINDOW_SIZE.x/2.0) &&
			uv_tex.y > (0.5 - WINDOW_SIZE.y/2.0) &&
			uv_tex.y < (0.5 + WINDOW_SIZE.y/2.0));
	float window_intensity = random1(random_window_val);
	window_intensity *= (0.5 + sin(TIME * random1_alt(random_window_val))/2.0);
	final_color += vec3(float(is_window) * window_intensity);
	
	return final_color;
}