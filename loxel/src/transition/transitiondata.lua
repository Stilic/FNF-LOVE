local source = (...) and (...):gsub('%.transition.transitiondata$', '.') or ""
local Classic = require(source .. "lib.classic")

---@class TransitionData:Classic
local TransitionData = Classic:extend("TransitionData")

function TransitionData:new(duration)
	self.duration = duration
end

function TransitionData:start()
	self.timer = 0
end

function TransitionData:cancel()
	self.timer = self.duration
end

function TransitionData:update(dt)
	self.timer = self.timer + dt
	if self.timer >= self.duration then
		self:finish()
	end
end

function TransitionData:draw()
	local a = self.timer / self.duration
	if self.status == "in" then a = -a + 1 end
	love.graphics.setColor(0, 0, 0, a)
	love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return TransitionData
