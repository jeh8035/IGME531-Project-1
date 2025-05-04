uniform sampler2D uv_texture : source_color, filter_nearest, repeat_enable;

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

vec3 building_shader(vec3 rayOrigin, vec3 cameraPos) {
	const float FLOOR_HEIGHT = 1.0;
	
	vec3 final_color = vec3(0.0);
	
	// Interior mapping
	
	vec3 obj_vertex = rayOrigin.xyz * 0.5;//(MODEL_MATRIX * vec4(rayOrigin.xyz, 1.0)).xyz * 0.5;
	obj_vertex *= vec3(1.0, -1.0, 1.0);
	vec3 obj_cam = (cameraPos * 0.5 * vec3(1.0, -1.0, 1.0));
	vec3 cam2pix = obj_vertex - obj_cam;
	float ceiling_y;
	float blue;
	if (cam2pix.y > 0.0) {
		ceiling_y = ceil(obj_vertex.y / FLOOR_HEIGHT) * FLOOR_HEIGHT;
		blue = 0.0;
	} else {
		ceiling_y = (ceil(obj_vertex.y / FLOOR_HEIGHT) - 1.0) * FLOOR_HEIGHT;
		blue = 1.0;
	}
	float t = (ceiling_y - obj_cam.y) / cam2pix.y;
	vec2 interior_texcoord = obj_cam.xz + t * cam2pix.xz;
	
	final_color += vec3(fract(interior_texcoord), blue);
	
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