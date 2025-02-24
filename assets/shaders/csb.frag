#pragma language glsl3
extern vec3 modifier; extern bool isGraphic;
// modifier: x = contrast, y = saturation, z = brightness
// yeah im lazy lol don't judge me i hate shaders - kaoy

vec3 csb(vec3 color, vec3 adj) {
	const vec3 coeffi = vec3(0.2125, 0.7154, 0.0721);
	const vec3 lumins = vec3(0.5, 0.5, 0.5);

	vec3 brtcol = color * adj.z;
	vec3 intens = vec3(dot(brtcol, coeffi));
	vec3 satcol = mix(intens, brtcol, adj.y);
	vec3 concol = mix(lumins, satcol, adj.x);

	return concol;
}

vec4 effect(vec4 color, Image tex, vec2 coords, vec2 _) {
	vec4 pixel = Texel(tex, coords);
	vec3 modif; vec4 final;

	if (isGraphic) {
		modif = csb(color.rgb, modifier);
		final = vec4(modif, color.a);
	} else {
		modif = csb(pixel.rgb, modifier);
		final = vec4(modif, pixel.a) * color;
	}
	return final;
}
