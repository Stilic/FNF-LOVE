// this one is for thorns bg effect lul
extern float time;

vec2 wiggle(vec2 uv, float t, float amp, float freq) {
	uv.x += sin(uv.y * freq + t) * amp;
	uv.y += cos(uv.x * freq + t) * amp;
	uv = mix(uv, vec2(uv.x, uv.y + sin(t * 0.5) * 0.002), 0.5);
	return uv;
}

vec4 effect(vec4 color, Image texture, vec2 coords, vec2 _) {
	float dynamic = 0.01 + sin(time * 0.5) * 0.005;
	vec2 uv = wiggle(coords, time, dynamic, 6.0);
	return Texel(texture, uv) * color;
}

