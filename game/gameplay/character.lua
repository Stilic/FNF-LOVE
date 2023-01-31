local Character = Sprite:extend()

function Character:new(x, y, char, isPlayer)
	Character.super.new(self, x, y)

	self.char = char
	self.isPlayer = isPlayer
	self.animOffsets = {}

	self.__reverseDraw = false

	self.singDuration = 4
	self.lastHit = 0
	self.holding = false

	self.danceSpeed = 2
	self.danced = false

	self.cameraPosition = { x = 0, y = 0 }

	self.script = Script("characters/" .. char)
	if (self.script.closed) then self.script = Script("characters/bf") end
	self.script.variables["self"] = self

	self.script:call("create")

	if self.isPlayer ~= self.flipX then
		self.__reverseDraw = true
		self:switchAnim("singLEFT", "singRIGHT")
		self:switchAnim("singLEFTmiss", "singRIGHTmiss")
	end
	if self.isPlayer then self.flipX = not self.flipX end

	self:dance()
	self:finish()

	self.script:call("postCreate")
end

function Character:switchAnim(oldAnim, newAnim)
	local leftAnim = self.__animations[oldAnim]
	self.__animations[oldAnim] = self.__animations[newAnim]
	self.__animations[newAnim] = leftAnim

	local leftOffsets = self.animOffsets[oldAnim]
	self.animOffsets[oldAnim] = self.animOffsets[newAnim]
	self.animOffsets[newAnim] = leftOffsets
end

function Character:update(dt)
	self.script:call("update", dt)
	Character.super.update(self, dt)
	if self.holding and #self.curAnim.frames > 2 and self.curFrame > 2 then
		self.curFrame = 1
	end
	self.script:call("postUpdate", dt)
end

function Character:draw()
	self.script:call("draw")
	if self.__reverseDraw then self.offset.x = self.offset.x * -1 end
	Character.super.draw(self)
	if self.__reverseDraw then self.offset.x = self.offset.x * -1 end
	self.script:call("postDraw")
end

function Character:beat(b)
	self.script:call("beat", b)

	if self.lastHit > 0 then
		if b % math.max(self.danceSpeed, 2) == 0 and self.lastHit + music.stepCrochet *
			self.singDuration <= PlayState.songPosition then
			self:dance()
			self.lastHit = 0
		end
	elseif b % self.danceSpeed == 0 then
		self:dance()
	end

	self.script:call("postBeat", b)
end

function Character:playAnim(anim, force)
	Character.super.play(self, anim, force)

	local offset = self.animOffsets[anim]
	if offset then
		self.offset.x, self.offset.y = offset.x, offset.y
	else
		self.offset.x, self.offset.y = 0, 0
	end
end

function Character:dance(force)
	if self.__animations and self.script:callReturn("dance") then
		self.holding = false
		if self.__animations["danceLeft"] and self.__animations["danceRight"] then
			self.danced = not self.danced

			if self.danced then
				self:playAnim("danceRight", force)
			else
				self:playAnim("danceLeft", force)
			end
		else
			self:playAnim("idle", force)
		end
	end
end

function Character:addOffset(anim, x, y)
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	self.animOffsets[anim] = { x = x, y = y }
end

return Character
