function create()
	self.camZoom = 0.725

	self.boyfriendPos = {x = 880, y = 100}
	self.gfPos = {x = 400, y = 130}
	self.dadPos = {x = -10, y = 100}

	local bg = Sprite(-600, -300):load(paths.getImage(SCRIPT_PATH .. "tomback"))
	bg.antialiasing = true
	bg:setScrollFactor(1)
	self:add(bg)

	local gb =
					Sprite(-500, -140):load(paths.getImage(SCRIPT_PATH .. "gamebananaL"))
	gb.antialiasing = true
	gb:setScrollFactor(.9)
	gb.scale.x, gb.scale.y = 0.8, 0.8
	self:add(gb)

	local light = Sprite(-900, -300):load(paths.getImage(SCRIPT_PATH .. "light"))
	light.antialiasing = true
	light:setScrollFactor(1.3)
	light.scale.x, light.scale.y = 1.25, 1.25
	self.front:add(light)
end

local anims, add = {l = {-1, 0}, r = {1, 0}, u = {0, -1}, d = {0, 1}}, 25

function postUpdate()
	local mustHit = state:getCurrentMustHit()
	if mustHit ~= nil then
		local char
		if not mustHit then
			char = state.dad
		else
			char = state.boyfriend
		end
		local idx
		if char.curAnim and #char.curAnim.name > 4 then
			idx = string.sub(char.curAnim.name, 5, 5)
		end
		if idx ~= nil then
			idx = string.lower(idx)
			local anim = anims[idx]
			state.camFollow.x, state.camFollow.y = state.camFollow.x + add * anim[1],
			                                       state.camFollow.y + add * anim[2]
		end
	end
end
