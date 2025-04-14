local AtlasText = SpriteGroup:extend("AtlasText")
AtlasText:exclude(
	"new", "__drawNestGroup", "_prepareCameraDraw",
	"getWidth", "getHeight"
)

local Glyph = require "funkin.ui.atlastext.glyph"

function AtlasText.getFont(name, size)
	local font = paths.getJSON("data/fonts/" .. name)
	if font == nil and AtlasText.defaultFont ~= nil then
		return AtlasText.defaultFont
	elseif not font then
		return
	end

	font.scale = font.scale or 1
	if size ~= nil then font.scale = font.scale * size end
	font.lineSize = font.lineSize or 70
	font.spaceWidth = font.spaceWidth or 40

	return font
end

function AtlasText:new(x, y, text, font, limit, align)
	Object.new(self, x or 0, y or 0)

	self.props = {
		text = text or "",
		limit = limit or 0,
		align = align or "left"
	}
	self.italic = false

	self.batchPool = {} -- see glyph.lua

	self.group = Group()
	self.members = self.group.members

	self:setTyping(nil, 0)
	self:setFont(font)

	self.batch = love.graphics.newSpriteBatch(
		self.frames.texture, 1, "stream")
end

function AtlasText:__index(k)
	if k == "text" or k == "limit" or k == "align" then
		return self.props[k]
	end
	return rawget(self, k) or AtlasText[k]
end

function AtlasText:__newindex(k, v)
	if k == "text" or k == "limit" or k == "align" then
		self.props[k] = v
		self:setFont()
		return
	else
		return rawset(self, k, v)
	end
end

function AtlasText:add(o)
	if not o.is or not o:is(Glyph) then
		local format = 'Expected Glyph object, got %s. Ignoring'
		print(string.format(format, tostring(o)))
		return
	end
	AtlasText.super.add(self, o)
end

function AtlasText:setTyping(text, speed, sound)
	self.typed = speed > 0
	if self.typed then
		self.text = ""
		self.finished = false
	end
	self.__target, self.timer, self.index = text or self.props.text, 0, 0
	self.sound, self.speed, self.completeCallback = sound, speed, nil
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

	if text ~= nil then self.props.text = text end
	local font = self.font
	if font == nil then return end

	local cache = {}
	local idx = 1
	for _, char in utf8.codes(self.props.text) do
		local c = Glyph(0, 0, char, self)
		cache[idx] = c
		idx = idx + 1
	end

	local words = {}
	local word = {text = "", width = 0, start = 1, stop = 0}
	local idx = 1

	for _, char in utf8.codes(self.props.text) do
		local c = utf8.char(char)
		local g = cache[idx]
		if c == " " or c == "\n" then
			if #word.text > 0 then
				word.stop = idx - 1
				table.insert(words, word)
				word = {text = "", width = 0, start = idx + 1, stop = 0}
			else word.start = idx + 1 end

			local sp = {start = idx, stop = idx}
			if c == " " then
				sp.text = " "
				sp.width = font.spaceWidth
				sp.space = true
			else
				sp.text = "\n"
				sp.width = 0
				sp.nl = true
			end
			table.insert(words, sp)
		else
			word.text = word.text .. c
			word.width = word.width + g.width
		end
		idx = idx + 1
	end

	if #word.text > 0 then
		word.stop = idx - 1
		table.insert(words, word)
	end

	local lines = {}
	local line, last = {text = "", width = 0, words = {}}, 0

	local limit = self.props.limit
	if self.props.limit > 0 and font.scale ~= 1 then
		limit = self.props.limit / font.scale
	end

	for i, w in ipairs(words) do
		if w.nl then
			if last > 0 and words[last].space then
				line.text = line.text:sub(1, -2)
				line.width = line.width - words[last].width
				table.remove(line.words)
				last = last - 1
			end

			table.insert(lines, line)
			line = {text = "", width = 0, words = {}}
			last = 0
		elseif limit > 0 and not w.space and
			   line.width + w.width > limit and
			   line.width > 0 then
			if last > 0 and words[last].space then
				line.text = line.text:sub(1, -2)
				line.width = line.width - words[last].width
				table.remove(line.words)
			end

			table.insert(lines, line)
			line = {text = w.text, width = w.width, words = {w}}
			last = i
		else
			line.text = line.text .. w.text
			line.width = line.width + w.width
			table.insert(line.words, w)
			last = i
		end
	end

	if #line.text > 0 then table.insert(lines, line) end

	for i, ln in ipairs(lines) do
		local y = (i - 1) * font.lineSize
		local xOff = 0
		if self.props.align ~= "left" then
			if self.props.limit > 0 then
				xOff = (self.props.limit - ln.width * font.scale) / (self.props.align == "center" and 2 or 1)
			else
				xOff = (ln.width * font.scale) / (self.props.align == "center" and 2 or 1)
			end
		end

		local x = 0
		for _, w in ipairs(ln.words) do
			if w.space then
				x = x + w.width
			else
				local wx = x
				for i = w.start, w.stop do
					local c = cache[i]
					if c and c.is then
						c:setPosition(wx + xOff, y)
						self:add(c)
						wx = wx + c.width
					end
				end
				x = wx
			end
		end
	end
	self:updateHitbox()
end

function AtlasText:update(dt)
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

	local x, y, rad, sx, sy, ox, oy = self:setupDrawLogic(camera)

	if self.font and self.font.scale then
		sx, sy = sx * self.font.scale, sy * self.font.scale
	end

	for i = 1, #self.members do self.members[i]:__render(camera) end

	love.graphics.push("all")

	local texture = self.batch:getTexture()
	local min, mag, anisotropy = texture:getFilter()
	local mode = self.antialiasing and "linear" or "nearest"
	texture:setFilter(mode, mode, anisotropy)

	love.graphics.setColor(Color.vec4(self.color, self.alpha))
	love.graphics.setBlendMode(self.blend)
	love.graphics.setShader(self.shader)

	love.graphics.rectangle("line", x, y, self.limit > 0 and self.limit or self.width, self.height)
	love.graphics.draw(self.batch, x, y, rad, sx, sy, ox, oy)

	texture:setFilter(min, mag, anisotropy)
	love.graphics.pop()
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

function AtlasText:__tostring() return self.props.text end

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
