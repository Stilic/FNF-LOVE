local Character = Sprite:extend("Character")

Character.directions = {"left", "down", "up", "right"}
Character.editorMode = false

function Character:new(x, y, char, isPlayer)
	Character.super.new(self, x, y)

	if not Character.editorMode then
		self.script = Script("data/characters/" .. char, false)
		self.script:linkObject(self)
		self.script:set("self", self)
		self.script:call("create")
	end

	self.char = char or "bf"
	self.isPlayer = isPlayer == true
	self.__reverseDraw = false

	local data = Parser.getCharacter(self.char)
	self.data = data

	self:setFrames(paths.getAtlas(data.sprite))
	if data.scale and data.scale ~= 1 then
		self:setGraphicSize(math.floor(self.width * data.scale))
		self:updateHitbox()
	end

	self.icon = data.icon or char
	self.iconColor = data.color

	self.flipX = data.flip_x == true
	self.antialiasing = ClientPrefs.data.antialiasing and data.antialiasing ~= false

	local atlasAdded = {}
	if data.animations and #data.animations > 0 then
		for _, an in ipairs(data.animations) do
			local anim, name, indices, fps, loop, offset, atlas =
				unpack(an)

			if atlas and atlas ~= "" and not atlasAdded[atlas] then
				self.frames:addCollection(paths.getAtlas(atlas))
				atlasAdded[atlas] = true
			end

			if indices ~= nil and #indices > 0 then
				self.animation:addByIndices(anim, name, indices, nil,
					fps, loop)
			else
				self.animation:addByPrefix(anim, name, fps, loop)
			end
			if offset ~= nil then
				local anim = self.animation:get(anim)
				if anim then anim.offset:set(unpack(offset)) end
			end
		end
	end

	if self.isPlayer ~= self.flipX then
		self.__reverseDraw = true
		self.animation:rename("singLEFT", "singRIGHT")
		self.animation:rename("singLEFTmiss", "singRIGHTmiss")
		self.animation:rename("singLEFT-loop", "singRIGHT-loop")
		self.animation:rename("singLEFT-end", "singRIGHT-end")
	end

	local position, x, y = Point()
	if data.position then
		x, y = data.position[1], data.position[2]
		if self.__reverseDraw then
			x = x + self.width / (self.isPlayer and -4 or 4)
		end
		position:set(x, y)
	end

	self.cameraPosition = Point()
	if data.camera_points then
		x, y = data.camera_points[1], data.camera_points[2]
		self.cameraPosition:set(x, y)
	end

	self.dirAnim, self.danced, self.isDanced, self.waitingFinish = nil, false, false, false
	self.lastHit = math.negative_infinity

	self.danceSpeed = data.dance_beats or 1
	self.holdTime = data.sing_duration or 8

	self.animation.onFinish:add(bind(self, self.__animFinished))

	if self.isPlayer then self.flipX = not self.flipX end

	self.isDanced = self.animation:has('danceLeft') and self.animation:has('danceRight')
	self:setPosition(self.x + position.x, self.y + position.y)

	self:dance()
	if self.animation.curAnim and not self.animation.curAnim.looped then
		self.animation:finish()
	end
end

function Character:__animFinished(name)
	if self.animation:has(name .. '-loop') then
		self.animation:play(name .. '-loop')
	end
	self.waitingFinish = false
end

function Character:update(dt)
	local animName = self.animation.curAnim and self.animation.curAnim.name or nil

	local cond, last, hold = PlayState.conductor, self.lastHit, self.holdTime
	local canDance = self.waitingFinish or (last > 0 and last + cond.stepCrotchet * hold < cond.time)

	if canDance and (self.dirAnim ~= nil and self.waitReleaseAfterSing) then
		canDance = controls:down(PlayState.keysControls[self.dirAnim]) ~= true
	end
	if canDance and self.animation:has(animName .. "-end") and not animName:endsWith("-end") then
		self:playAnim(animName .. '-end', true, nil, true)
	end

	if canDance and not self.waitingFinish then
		self:dance()
		self.lastHit = math.negative_infinity
	end

	Character.super.update(self, dt)
end

function Character:beat(b)
	if not self.waitingFinish and self.lastHit <= 0 and b % self.danceSpeed == 0 then
		self:dance(self.isDanced)
	end
end

function Character:playAnim(anim, force, frame, waitFinish)
	self.animation:play(anim, force, frame)
	self.dirAnim = nil
	self.waitingFinish = waitFinish == true
end

function Character:sing(dir, type, force)
	local anim = "sing" .. Character.directions[dir + 1]:upper()
	if type then
		local altAnim = anim .. (type == "miss" and type or "-" .. type)
		if self.animation:has(altAnim) then anim = altAnim end
	end
	self:playAnim(anim, force ~= false)

	self.dirAnim = type == "miss" and nil or dir
	self.lastHit = PlayState.conductor.time
	if self.isDanced then
		self.danced = anim:startsWith("singLEFT")
		if anim == "singUP" or anim == "singDOWN" then
			self.danced = not self.danced
		end
	end
end

function Character:dance(force)
	local result = self.script and self.script:call("dance") or true
	if result == nil then result = true end
	if result then
		if self.isDanced then
			self.danced = not self.danced
			self:playAnim(self.danced and "danceLeft" or "danceRight", force)
		elseif self.animation:has("idle") then
			self:playAnim("idle", force)
		end
	end
end

return Character
