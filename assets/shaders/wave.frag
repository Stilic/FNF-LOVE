#pragma language glsl3
// code ass
extern float time;
extern float speed;
extern float intensity;

/* calculation for these is simple:
- for radius, the calculation structure would be
(area in pixels + (img width + img height) ÷ 2) ÷ 2

- for position, the calculation structure would be
point x ÷ img width
point y ÷ img height
*/

extern float radius;
extern vec2 position;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	float mask = smoothstep(radius * 0.8, radius, length(texture_coords - position));
	float wave = sin(texture_coords.y * 150.0 + time * speed) * 0.005 * intensity * (1.0 - mask);

	vec2 distortion = vec2(texture_coords.x + wave, texture_coords.y);
	return Texel(tex, distortion) * color;
}
