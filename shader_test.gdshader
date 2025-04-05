shader_type spatial;
render_mode specular_toon;

uniform float height_scale;
uniform float mesh_size;
uniform sampler2D noise;
uniform sampler2D normalmap;

varying vec2 texture_position;

float height(vec2 position) {
  return texture(noise, position / mesh_size).r; // Scaling factor is based on mesh size
}

void vertex() {
  vec2 pos = VERTEX.xz;
  float k = height(pos, TIME);
  VERTEX.y = k;
}

void fragment() {
	vec3 normals = texture(normalmap, texture_position).xyz;
	NORMAL_MAP = normals;
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	RIM = 0.2;
	METALLIC = 0.0;
	ROUGHNESS = 0.01 * (1.0 - fresnel);
	ALBEDO = vec3(0.1, 0.3, 0.5) + (0.1 * fresnel);
}