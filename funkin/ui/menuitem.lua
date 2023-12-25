---@class MenuItem:Sprite
local MenuItem = Sprite:extend("MenuItem")

function MenuItem:new(x, y, weekName)
	MenuItem.super.new(self, x, y)
	self:loadTexture(paths.getImage('menus/storymenu/weeks/' .. weekName))
	self.targetY = 0
	self.flashingInt = 0
	self.__isFlashing = false
end

function MenuItem:startFlashing() self.__isFlashing = true end

function MenuItem:update(dt)
	MenuItem.super.update(self, dt)

	self.y = math.lerp(self.y, (self.targetY * 120) + 480,
		math.clamp(dt * 10.2, 0, 1))

	if self.__isFlashing then self.flashingInt = self.flashingInt + 1 end

	local fakeFramerate = math.round((1 / dt) / 10)
	if self.flashingInt % fakeFramerate >= math.floor(fakeFramerate / 2) then
		self.color = Color.fromRGB(51, 255, 255)
	else
		self.color = Color.WHITE
	end
end

return MenuItem
