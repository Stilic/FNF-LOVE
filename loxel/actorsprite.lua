local ActorSprite = Actor:extend("ActorSprite")
ActorSprite:implement(Sprite)

function ActorSprite:new(x, y, z, texture)
	ActorSprite.super.new(self, x, y, z)

	self.texture = Sprite.defaultTexture

	self.clipRect = nil

	self.curAnim = nil
	self.curFrame = nil
	self.animFinished = nil
	self.animPaused = false

	self.__frames = nil
	self.__animations = nil

	self.__width, self.__height = self.width, self.height
	self.__rectangleMode = false

	if texture then self:loadTexture(texture) end
end

function ActorSprite:destroy()
	ActorSprite.super.destroy(self)

	self.texture = nil

	self.__frames = nil
	self.__animations = nil

	self.curAnim = nil
	self.curFrame = nil
	self.animFinished = nil
	self.animPaused = false
end

function ActorSprite:update(dt)
	if self.__width ~= self.width or self.__height ~= self.height then
		self:setGraphicSize(self.width, self.height)
		self.__width, self.__height = self.width, self.height
	end

	if self.curAnim and not self.animFinished and not self.animPaused then
		self.curFrame = self.curFrame + dt * self.curAnim.framerate
		if self.curFrame >= #self.curAnim.frames + 1 then
			if self.curAnim.looped then
				self.curFrame = 1
			else
				self.curFrame = #self.curAnim.frames
				self.animFinished = true
			end
		end
	end

	if self.moves then
		self.velocity.x = self.velocity.x + self.acceleration.x * dt
		self.velocity.y = self.velocity.y + self.acceleration.y * dt
		self.velocity.z = self.velocity.z + self.acceleration.z * dt

		self.x = self.x + self.velocity.x * dt
		self.y = self.y + self.velocity.y * dt
		self.z = self.z + self.velocity.z * dt
	end
end

function ActorSprite:_canDraw()
	return self.texture ~= nil and (self.width ~= 0 or self.height ~= 0) and
		ActorSprite.super._canDraw(self)
end

function ActorSprite:__render(camera)
	
end

return ActorSprite
