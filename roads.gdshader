shader_type spatial;

// Uniforms for the grid
uniform sampler2D voronoi_texture; // Voronoi noise texture
uniform vec3 color1 = vec3(1.0, 0.0, 0.0); // Inside cell color (Red)
uniform vec3 color2 = vec3(0.0, 0.0, 1.0); // Inside cell color (Blue)
uniform vec3 border_color = vec3(0.0, 0.0, 0.0); // Border color (Black)
uniform float scale = 1.0; // Scaling factor for texture mapping
uniform float border_width = 0.01; // Adjust for visible borders

// Uniforms for buildings
uniform sampler2D grid_texture: filter_nearest; // City building grid texture
uniform sampler2D normal_map: filter_nearest;
uniform float grid_scale = .01; // Scaling factor for texture mapping
uniform float grid_opacity = 0.5;

varying vec2 grid_uv;

// Vertex shader
void vertex() {
    // Sample the grid texture based on the UV
    grid_uv = UV * grid_scale;
    vec3 grid_sample = texture(grid_texture, grid_uv).rgb;

	// Add spacing between each tile of size "road_size"


    // Check if the grid texture is not black
    if (!(grid_sample.r == 0.0 && grid_sample.g == 0.0 && grid_sample.b == 0.0)) {
        // Increase the y-position by the color scaled if not black
        VERTEX.y += 20.0 * grid_sample.r;
    }
}

void fragment() {
    // Scale UVs for texture lookup
    vec2 uv_scaled = UV * scale;

    // Offsets for Sobel sampling
    float offset = 1.0 / float(textureSize(voronoi_texture, 0).x);

    // Sample the texture at the surrounding 3x3 grid
    float tl = texture(voronoi_texture, uv_scaled + vec2(-offset, offset)).r;
    float t  = texture(voronoi_texture, uv_scaled + vec2(0.0, offset)).r;
    float tr = texture(voronoi_texture, uv_scaled + vec2(offset, offset)).r;

    float l  = texture(voronoi_texture, uv_scaled + vec2(-offset, 0.0)).r;
    float c  = texture(voronoi_texture, uv_scaled).r; // Center pixel
    float r  = texture(voronoi_texture, uv_scaled + vec2(offset, 0.0)).r;

    float bl = texture(voronoi_texture, uv_scaled + vec2(-offset, -offset)).r;
    float b  = texture(voronoi_texture, uv_scaled + vec2(0.0, -offset)).r;
    float br = texture(voronoi_texture, uv_scaled + vec2(offset, -offset)).r;

    // Sobel filter matrices
    mat3 sobel_x = mat3(
        vec3(1.0,  2.0,  1.0),
        vec3(0.0,  0.0,  0.0),
        vec3(-1.0, -2.0, -1.0)
    );

    mat3 sobel_y = mat3(
        vec3(1.0,  0.0, -1.0),
        vec3(2.0,  0.0, -2.0),
        vec3(1.0,  0.0, -1.0)
    );

    // Compute gradient values
    float gx = sobel_x[0][0] * tl + sobel_x[0][1] * t + sobel_x[0][2] * tr +
               sobel_x[1][0] * l  + sobel_x[1][2] * r +
               sobel_x[2][0] * bl + sobel_x[2][1] * b + sobel_x[2][2] * br;

    float gy = sobel_y[0][0] * tl + sobel_y[0][1] * t + sobel_y[0][2] * tr +
               sobel_y[1][0] * l  + sobel_y[1][2] * r +
               sobel_y[2][0] * bl + sobel_y[2][1] * b + sobel_y[2][2] * br;

    // Compute edge magnitude
    float edge_strength = length(vec2(gx, gy));

    // Normalize edge strength
    float edge_mask = smoothstep(border_width * 0.5, border_width, edge_strength);

    // Interpolate Voronoi cell colors
    vec3 cell_color = mix(color1, color2, c);

	// For each uniquely colored cell in the texture, overlay the grid texture in that area
    // ---- OVERLAY GRID TEXTURE ----

    vec3 grid_overlay = texture(grid_texture, grid_uv).rgb;

    // Blend the grid texture with the cell color
    vec3 blended_color = mix(cell_color, grid_overlay, grid_opacity);

    // Apply border effect
    //ALBEDO = mix(blended_color, border_color, edge_mask);
	ALBEDO = grid_overlay;

	vec3 normals = texture(normal_map, grid_uv).xyz;
	NORMAL = normals;
	ALBEDO = normals;
}