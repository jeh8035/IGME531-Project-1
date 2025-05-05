shader_type spatial;

#include "sdf_generator.gdshaderinc"

varying vec3 WORLD_POS;

void vertex() {
	WORLD_POS = VERTEX;
}
void fragment() {
	vec3 v = voronoi(WORLD_POS);
	ALBEDO = vec3(v.x, v.y, v.z); //vec3(v.x, 0.0, 0.0); //
}