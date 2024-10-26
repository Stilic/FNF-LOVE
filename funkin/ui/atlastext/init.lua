local AtlasText = SpriteGroup:extend("AtlasText")
AtlasText:exclude(
	"new", "__drawNestGroup", "_prepareCameraDraw",
	"getWidth", "getHeight"
)

local Glyph = require "funkin.ui.atlastext.glyph"
local Boundary = loxreq "util.boundary"

function AtlasText.getFont(font, size)
	font = paths.getJSON("data/fonts/" .. font)
	if font == nil and AtlasText.defaultFont ~= nil then
		return AtlasText.defaultFont
	end

	font.scale = font.scale or 1
	if size ~= nil then font.scale = font.scale * size end
	font.lineSize = font.lineSize or 70
	font.spaceWidth = font.spaceWidth or 40

	return font
end

AtlasText.defaultFont = AtlasText.getFont("default")

function AtlasText:new(x, y, text, font, limit, align)
	Object.new(self, x or 0, y or 0)

	self.text = text or ""
	self.limit = limit or 0
	self.align = align or "left"
	self.italic = false

	self.batchPool = {} -- see glyph.lua

	self.group = Group()
	self.members = self.group.members

	self:setTyping(0)
	self:setFont(font)

	self.batch = love.graphics.newSpriteBatch(
		self.frames.texture, 1, "stream")

	self.oldProps = {
		text = self.text,
		align = self.align,
		limit = self.limit,
		font = self.font
	}
end

function AtlasText:add(o)
	if not o.is or not o:is(Glyph) then
		local format = 'Expected Glyph object, got %s. Ignoring'
		print(string.format(format, tostring(o)))
		return
	end
	AtlasText.super.add(self, o)
end

function AtlasText:setTyping(speed, sound)
	self.typed = speed > 0
	self.__target, self.timer, self.index = self.text, 0, 0
	self.sound, self.speed, self.completeCallback = sound, speed, nil
	self.finished = not self.typed
	if self.typed then self.text = "" end
end

function AtlasText:setFont(font, size)
	if (font and self.font == font) and (size and self.size == size) then
		return
	end
	font = font or self.font or AtlasText.defaultFont
	self.font = type(font) == "string" and AtlasText.getFont(font, size) or font

	self.frames = paths.getSparrowAtlas('fonts/' .. self.font.name)
	if self.batch then self.batch:setTexture(self.frames.texture) end

	self:setText()
end

function AtlasText:setText(text)
	self:cleanup()

	if text ~= nil then self.text = text end
	local font = self.font
	if font == nil then return end

	local line, lines, width, cache, idx = "", {}, 0, {}, 1

	for _, char in utf8.codes(self.text) do
		local c = Glyph(0, 0, char, self)
		cache[idx] = c
		idx = idx + 1

		local realChar = utf8.char(char)
		if realChar == "\n" or (self.limit > 0 and width + c.width >= self.limit) then
			table.insert(lines, {t = line, w = width})
			line = realChar
			width = c.width
		else
			line = line .. realChar
			width = width + c.width
		end
	end

	if #line > 0 then table.insert(lines, {t = line, w = width}) end

	idx = 1
	for i, curLine in ipairs(lines) do
		local x, xOff, y = 0, 0, (i - 1) * (font.lineSize * font.scale)
		if self.align ~= "left" then
			xOff = (self.limit - curLine.w) / (self.align == "center" and 2 or 1)
		end

		for _ = 1, utf8.len(curLine.t) do
			local char = cache[idx]
			idx = idx + 1
			if char and char.is then
				char:setPosition(x + xOff, y)
				self:add(char)
			end
			x = x + (char and char.width or 0)
		end
	end

	self:updateHitbox()
end

function AtlasText:hasChanged(props)
	for _, k in pairs(props) do
		if self.oldProps[k] ~= self[k] then
			self.oldProps[k] = self[k]
			return true
		end
	end
	return false
end

function AtlasText:update(dt)
	if self:hasChanged({"text", "align", "limit", "font"}) then
		self:setFont()
	end
	if not self.typed then
		return AtlasText.super.update(self, dt)
	end

	if self.typed and not self.finished then
		self.timer = self.timer + dt
		if self.timer >= self.speed then
			self:addLetter()
		end

		if self.index == #self.__target then
			self.finished = true
			if self.completeCallback then self.completeCallback() end
		end
	end

	AtlasText.super.update(self, dt)
end

function AtlasText:forceEnd()
	if not self.typed then return end

	self.text = self.__target
	self.finished = true
	if self.completeCallback then self.completeCallback() end
end

function AtlasText:addLetter()
	if not self.typed then return end

	self.timer = 0
	self.index = self.index + 1
	self.text = self.__target:sub(1, self.index)
	if self.sound then game.sound.play(self.sound) end
end

function AtlasText:__render(camera)
	if not self.batch then return end

	local x, y, rad, sx, sy, ox, oy = self.x, self.y, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	if self.font and self.font.scale then
		sx, sy = sx * self.font.scale, sy * self.font.scale
	end

	x, y = (x + ox - self.offset.x),
		(y + oy - self.offset.y)
	x, y = x - (camera.scroll.x * self.scrollFactor.x), y - (camera.scroll.y * self.scrollFactor.y)

	for i, member in ipairs(self.members) do
		member:__render(camera)

		love.graphics.push()
		love.graphics.translate(x, y)
		love.graphics.scale(sx, sy)
		Boundary.render(camera, member, i, #self.members, function(c)
			return {1, c, 0}
		end)
		love.graphics.pop()
	end

	local texture = self.batch:getTexture()

	local oldState = Object.saveDrawState(texture)
	local mode = self.antialiasing and "linear" or "nearest"
	texture:setFilter(mode, mode, oldState.filter[3])

	love.graphics.setColor(Color.vec4(self.color, self.alpha))
	love.graphics.setBlendMode(self.blend)
	love.graphics.setShader(self.shader)

	love.graphics.draw(self.batch, x, y, rad, sx, sy, ox, oy)

	Object.loadDrawState(oldState)
end

function AtlasText:__getNestDimension(members)
	local xmin, xmax, ymin, ymax, x, y, w, h = 0, 0, 0, 0
	for _, member in ipairs(members) do
		x, y = member.x * self.font.scale, member.y * self.font.scale
		w = x + member.width * self.font.scale
		h = y + member.height * self.font.scale

		if w > xmax then xmax = w end
		if x < xmin then xmin = x end
		if h > ymax then ymax = h end
		if y < ymin then ymin = y end
	end

	return xmin, xmax, ymin, ymax
end

function AtlasText:cleanup()
	for i = #self.members, 1, -1 do
		local char = self.members[i]
		char:destroy()
		self:remove(char)
	end
end

function AtlasText:destroy()
	self:cleanup()
	if self.batch then self.batch:release() end
	self.batch = nil
	AtlasText.super.destroy(self)
end

function AtlasText:isOnScreen(...) return Object.isOnScreen(self, ...) end

function AtlasText:_isOnScreen(...) return Object._isOnScreen(self, ...) end

function AtlasText:_canDraw() return #self.members > 0 and Object._canDraw(self) end

function AtlasText:__tostring() return self.text end

-- moved getWidth/Height stuff to updateHitbox, because it's called
-- less times, what should have a minimal performance hit for huge texts
function AtlasText:updateHitbox()
	if not next(self.members) then return 0 end

	local xmin, xmax, ymin, ymax = self:__getNestDimension(self.members)
	self.width, self.height = xmax - xmin, ymax - ymin

	-- self:centerOffsets()
	-- self:centerOrigin()
end

function AtlasText:_getBoundary()
	local tx, ty = self.x or 0, self.y or 0
	if self.offset ~= nil then tx, ty = tx - self.offset.x, ty - self.offset.y end

	local xmin, ymin, xmax, ymax = math.huge, math.huge, -math.huge, -math.huge

	for _, member in pairs(self.members) do
		local x, y, w, h, sx, sy = member:_getBoundary()

		x, y = x or 0, y or 0
		w, h = w or 0, h or 0
		sx, sy = sx or 1, sy or 1

		x, y = x * self.font.scale, y * self.font.scale
		w = x + w * self.font.scale
		h = y + h * self.font.scale

		if x < xmin then xmin = x end
		if w > xmax then xmax = w end
		if y < ymin then ymin = y end
		if h > ymax then ymax = h end
	end

	tx, ty = tx + xmin, ty + ymin
	return tx, ty, xmax - xmin, ymax - ymin,
		math.abs(self.scale.x * self.zoom.x), math.abs(self.scale.y * self.zoom.y),
		self.origin.x, self.origin.y
end

function AtlasText:getWidth() return self.width end

function AtlasText:getHeight() return self.height end

return AtlasText