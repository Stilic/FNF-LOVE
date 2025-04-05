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
	self.isPlayer = isPlayer or false
	self.animOffsets = {}
	self.animAtlases = {}

	self.__reverseDraw = self.__reverseDraw or false

	self.dirAnim, self.holdTime, self.lastHit = nil, 8, math.negative_infinity
	self.danceSpeed, self.danced, self.forceIdleBeats = 1, false, false

	local data = Parser.getCharacter(self.char)

	self.ogFrames = paths.getAtlas(data.sprite)
	self:setFrames(self.ogFrames)

	self.imageFile = data.sprite
	self.jsonScale = 1
	if data.scale and data.scale ~= 1 then
		self.jsonScale = data.scale
		self:setGraphicSize(math.floor(self.width * self.jsonScale))
		self:updateHitbox()
	end

	self.icon = data.icon or char
	self.iconColor = data.color

	self.flipX = data.flip_x == true
	self.jsonFlipX = self.flipX

	self.jsonAntialiasing = data.antialiasing == nil and true or data.antialiasing
	self.antialiasing = ClientPrefs.data.antialiasing and self.jsonAntialiasing or false

	self.animationsTable = data.animations
	self:resetAnimations()
	if self.isPlayer then self.flipX = not self.flipX end

	local x, y
	if data.position then
		x, y = data.position[1], data.position[2]
		if self.__reverseDraw then
			x = x + self.width / (self.isPlayer and -4 or 4)
		end
		self.positionTable = {x = x, y = y}
		self.x, self.y = self.x + x, self.y + y
	else
		self.positionTable = {x = 0, y = 0}
	end
	if data.camera_points then
		x, y = data.camera_points[1], data.camera_points[2]
		self.cameraPosition = {x = x, y = y}
		self.cameraPosition.x, self.cameraPosition.y = x, y
	else
		self.cameraPosition = {x = 0, y = 0}
	end

	if data.dance_beats ~= nil then
		self.danceSpeed = data.dance_beats
	elseif self.__animations and self.__animations['danceLeft'] and self.__animations['danceRight'] then
		self.forceIdleBeats = true
	end
	if data.sing_duration ~= nil then
		self.holdTime = data.sing_duration
	end

	self:dance()
	if self.curAnim and not self.curAnim.looped then
		self:finish()
	end
end

function Character:resetAnimations(skipSwap)
	if self.animationsTable and #self.animationsTable > 0 then
		for _, anim in ipairs(self.animationsTable) do
			local animAnim = '' .. anim[1]
			local animName = '' .. anim[2]
			local animIndices = anim[3]
			local animFps = anim[4]
			local animLoop = anim[5]
			local animOffsets = anim[6]
			local animAtlas = anim[7]

			if animAtlas and animAtlas ~= "" then
				self:addAtlas(animAnim, animAtlas)
			end

			if animIndices ~= nil and #animIndices > 0 then
				self:addAnimByIndices(animAnim, animName, animIndices, nil,
					animFps, animLoop)
			else
				self:addAnimByPrefix(animAnim, animName, animFps, animLoop)
			end

			if animOffsets ~= nil and #animOffsets > 1 then
				self:addOffset(animAnim, animOffsets[1], animOffsets[2])
			end
		end
	end
	if self.isPlayer ~= self.flipX and not skipSwap then
		self.__reverseDraw = true
		self:switchAnim("singLEFT", "singRIGHT")
		self:switchAnim("singLEFTmiss", "singRIGHTmiss")
		self:switchAnim("singLEFT-loop", "singRIGHT-loop")
	end
end

function Character:switchAnim(oldAnim, newAnim)
	local leftAnim = self.__animations[oldAnim]
	if leftAnim and self.__animations[newAnim] then
		leftAnim.name = newAnim
		self.__animations[oldAnim] = self.__animations[newAnim]
		self.__animations[oldAnim].name = oldAnim
		self.__animations[newAnim] = leftAnim
	end

	local leftOffsets = self.animOffsets[oldAnim]
	if leftOffsets and self.animOffsets[newAnim] then
		self.animOffsets[oldAnim] = self.animOffsets[newAnim]
		self.animOffsets[newAnim] = leftOffsets
	end
end

function Character:update(dt)
	if self.curAnim then
		if self.animFinished and self.__animations[self.curAnim.name .. '-loop'] ~= nil then
			self:playAnim(self.curAnim.name .. '-loop')
		end

		local offset = self.animOffsets[self.curAnim.name]
		if offset then
			local rot = math.pi * self.angle / 180
			local offX, offY = self.__reverseDraw and -offset.x or offset.x, offset.y
			local rotOffX = offX * math.cos(rot) - offY * math.sin(rot)
			local rotOffY = offX * math.sin(rot) + offY * math.cos(rot)
			self.offset:set(rotOffX, rotOff)
		else
			self.offset:set(0, 0)
		end
	end

	if self.lastHit > 0 and
		self.lastHit + PlayState.conductor.stepCrotchet * self.holdTime < math.abs(PlayState.conductor.time) and
		(not self.isPlayer or not self.dirAnim or not controls:down(PlayState.keysControls[self.dirAnim])) then
		if self.__animations[self.curAnim.name .. "-end"] and
			not self.curAnim.name:endsWith("-end") then
			self:playAnim(self.curAnim.name .. '-end')
			self.isPlayingEnd = true
			canDance = false
		elseif not self.isPlayingEnd then
			self:dance()
			self.lastHit = math.negative_infinity
		end
	end

	if self.isPlayingEnd and self.animFinished then
		self:dance()
		self.isPlayingEnd = false
	end

	Character.super.update(self, dt)
end

function Character:beat(b)
	if self.lastHit <= 0 and b % self.danceSpeed == 0 then
		self:dance(self.forceIdleBeats)
	end
end

function Character:playAnim(anim, force, frame)
	if self.animAtlases[anim] and self.__frames ~= self.animAtlases[anim].frames then
		self:setFrames(self.animAtlases[anim])
		self:resetAnimations(true)
	elseif self.animAtlases[anim] == nil and self.__frames ~= self.ogFrames.frames then
		self:setFrames(self.ogFrames)
		self:resetAnimations(true)
	end

	Character.super.play(self, anim, force, frame)
	self.dirAnim = nil
	self.isPlayingEnd = false

	local offset = self.animOffsets[anim]
	if offset then
		local rot = math.pi * self.angle / 180
		local offX, offY = offset.x, offset.y
		if self.__reverseDraw then offX = -offX end
		local rotOffX = offX * math.cos(rot) - offY * math.sin(rot)
		local rotOffY = offX * math.sin(rot) + offY * math.cos(rot)
		self.offset:set(rotOffX, rotOffY)
	else
		self.offset:set(0, 0)
	end

	if self.__animations["danceLeft"] and self.__animations["danceRight"] then
		if anim == "singLEFT" then
			self.danced = true
		elseif anim == "singRIGHT" then
			self.danced = false
		end
		if anim == "singUP" or anim == "singDOWN" then
			self.danced = not self.danced
		end
	end
end

function Character:sing(dir, type, force)
	local anim = "sing" .. string.upper(Character.directions[dir + 1])
	if type then
		local altAnim = anim .. (type == "miss" and type or "-" .. type)
		if self.__animations[altAnim] then anim = altAnim end
	end
	self:playAnim(anim, force == nil and true or force)

	self.dirAnim = type == "miss" and nil or dir
	self.lastHit = PlayState.conductor.time
end

function Character:dance(force)
	if self.__animations then
		local result = self.script and self.script:call("dance") or true
		if result == nil then result = true end
		if result then
			if self.__animations["danceLeft"] and self.__animations["danceRight"] then
				self.danced = not self.danced

				if self.danced then
					self:playAnim("danceRight", force)
				else
					self:playAnim("danceLeft", force)
				end
			elseif self.__animations["idle"] then
				self:playAnim("idle", force)
			end
		end
	end
end

function Character:addOffset(anim, x, y)
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	self.animOffsets[anim] = {x = x, y = y}
end

function Character:addAtlas(anim, atlasName)
	self.animAtlases[anim] = paths.getAtlas(atlasName)
end

return Character
