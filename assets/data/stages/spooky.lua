local base, back, window, reflect
local shader = [[
extern vec3 modf;
// modf.x = contrast, modf.y = saturation, modf.z = brightness
// yeah im lazy lol don't judge me i hate shaders - kaoy

vec3 scb(vec3 color, vec3 adj) {
	const float alumR = 0.5;
	const float alumG = 0.5;
	const float alumB = 0.5;

	const vec3 coeff = vec3(0.2125, 0.7154, 0.0721);

	vec3 lumin = vec3(alumR, alumG, alumB);
	vec3 brtcol = color * adj.z;
	vec3 intensity = vec3(dot(brtcol, coeff));
	vec3 satcol = mix(intensity, brtcol, adj.y);
	vec3 concol = mix(lumin, satcol, adj.x);

	return concol;
}

vec4 effect(vec4 vcolor, Image tex, vec2 textureCoords, vec2 screenCoords) {
	vec4 pixel = Texel(tex, textureCoords);
	vec3 color = scb(pixel.rgb, modf);
	return vec4(color, pixel.a) * vcolor;
}
]]

function create()
	self.dadCam.y = 34

	base = Sprite(-350, -260, paths.getImage(SCRIPT_PATH .. "base"))
	base:setGraphicSize(2280)
	base:setScrollFactor()
	base.shader = love.graphics.newShader(shader)
	self:add(base)

	window = Sprite(243, 68, paths.getImage(SCRIPT_PATH .. "window"))
	window.shader = love.graphics.newShader(shader)
	self:add(window)

	back = Sprite(-200, -100, paths.getImage(SCRIPT_PATH .. "bg_shadows"))
	back.shader = love.graphics.newShader(shader)
	self:add(back)

	reflect = Sprite(262, 609, paths.getImage(SCRIPT_PATH .. "windowReflect"))
	reflect.alpha = 0.5
	reflect.blend = "add"
	reflect.shader = window.shader
	self:add(reflect)

	modify(base, 1, 1, 1)
	modify(back, 1, 1, 1)
	modify(window, 1, 1, 1)
end

local lightningStrikeBeat = 0
local lightningOffset = love.math.random(8, 24)
function beat()
	if love.math.randomBool(10) and curBeat > lightningStrikeBeat +
		lightningOffset then
		lightingAnimation()

		lightningStrikeBeat = curBeat
		lightningOffset = love.math.random(8, 24)
	end
end

function lightingAnimation()
	local flashAllowed = ClientPrefs.data.flashingLights
	if flashAllowed then
		modify(base, 1, 0.8, 1.6)
		modify(back, 1.25, 1.5, 0.8)
		modify(window, 1, 1, 10)

		reflect.alpha = 1
	end

	state.timer:after(1 / 12, function()
		local eh = {c = 3, s = 2, b = 0.9}
		local eh2 = {b = 10}

		if flashAllowed then
			modify(base, 1.5, 1, 0.5)
			modify(back, 1.5, 1, 0.5)
			modify(window, 1.3, 1, 0.5)

			reflect.alpha = 0
		else
			-- lower the intensity for next animation
			eh2.b = 1.5
			eh.c, eh.s = 1.5, 1
		end

		state.timer:after(1 / 24, function()
			game.camera:shake(0.001, 1.4)
			state.camHUD:shake(0.001, 1.4)

			util.playSfx(paths.getSound('gameplay/thunder_' ..
			love.math.random(1, 2)))

			reflect.alpha = 0.9

			state.timer:tween(0.6, eh, {c = 1, s = 1, b = 1}, "out-expo")
			state.timer:tween(0.8, eh2, {b = 1}, "out-expo")

			state.timer:tween(0.8, reflect, {alpha = 0.6}, "out-expo")

			state.timer:during(0.8, function()
				modify(base, eh.c, eh.s, eh.b)
				modify(back, eh.c, eh.s, eh.b)
				modify(window, 1, 1, eh2.b)
			end)

			state.boyfriend:playAnim('scared', true)
			state.gf:playAnim('scared', true)

			state.boyfriend.lastHit = PlayState.conductor.time + 300
			state.gf.lastHit = PlayState.conductor.time + 300
		end)
	end)
end

function modify(obj, c, s, b)
	obj.shader:send("modf", {c, s, b})
end

function close()
	base.shader:release()
	back.shader:release()
	window.shader:release()
end
