local RGBShader = {}
RGBShader.cache = {}
RGBShader.code = [[
	uniform vec3 r; uniform vec3 g; uniform vec3 b;

	vec4 effect(vec4 color, Image texture,
			vec2 texture_coords, vec2 screen_coords) {
		vec4 pixel = Texel(texture, texture_coords);

		if (pixel.a == 0.0) {return pixel;}
		vec4 newColor = pixel;
		newColor.rgb = min(pixel.r * r +
			pixel.g * g + pixel.b * b, vec3(1.0));

		pixel.rgb = mix(pixel.rgb, newColor.rgb, 1.0);
		return pixel * color;
	}
]]

function RGBShader.create(r, g, b)
	r, g, b = r or Color.RED, g or Color.GREEN, b or Color.BLUE
	local key =
		table.concat(r) .. "_" ..
		table.concat(g) .. "_" ..
		table.concat(b)

	if RGBShader.cache[key] == nil then
		RGBShader.cache[key] = love.graphics.newShader(RGBShader.code)
		RGBShader.cache[key]:send("r", r)
		RGBShader.cache[key]:send("g", g)
		RGBShader.cache[key]:send("b", b)RGBShader.cache
	end

	return RGBShader.cache[key]
end

function RGBShader.reset()
	for key, shader in pairs(RGBShader.cache) do
		shader:release()
		RGBShader.cache[key] = nil
	end
end

return RGBShader
