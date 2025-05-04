shader_type spatial;

const int ITER_COUNT = 50;

uniform float ASPECT_RATIO;

#include "sdf_generator.gdshaderinc"

varying vec3 WORLD_POS;

void vertex() {
	WORLD_POS = VERTEX;
}
void fragment() {
	vec2 v = voronoi(WORLD_POS);
	ALBEDO = vec3(v.x, v.y, 0.0); //vec3(v.x, 0.0, 0.0); //
}