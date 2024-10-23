local utf8 = require "utf8"

-- messy implementation of uft8.upper/lower
local function newcasemap(ranges)
	local upper, lower = {}, {}

	for _, range in pairs(ranges) do
		local u1, u2, l1, l2 = unpack(range)
		local lower_cp = l1

		for codepoint = u1, u2 do
			local char1 = utf8.char(codepoint)
			local char2 = utf8.char(lower_cp)
			lower[char1] = char2
			upper[char2] = char1
			lower_cp = lower_cp + 1
		end
	end

	return upper, lower
end

local upcase, lowcase = newcasemap({
	-- latin
	{0x00C0, 0x00DF, 0x00E0, 0x00FF},
	-- cyrillic
	{0x0400, 0x040F, 0x0450, 0x045F},
	{0x0410, 0x042F, 0x0430, 0x044F},
	-- i may add more in the future??
})

local function lower(input)
	local result = {}
	for _, c in utf8.codes(input) do
		c = utf8.char(c)
		table.insert(result, lowcase[c] or c:lower())
	end
	return table.concat(result)
end

local function upper(input)
	local result = {}
	for _, c in utf8.codes(input) do
		c = utf8.char(c)
		table.insert(result, upcase[c] or c:upper())
	end
	return table.concat(result)
end

local Glyph = Sprite:extend("Glyph")
-- !! INTENDED TO BE USED ONLY WITH ATLASTEXT

function Glyph:new(x, y, glyph, parent)
	Glyph.super.new(self, x or 0, y or 0)

	self.glyph = glyph or "#"
	self.letterOffset = {x = 0, y = 0}
	self.parent = parent

	self.__forceUpdate = false
	self.__lastFrame = -1
	self.__lastAtlas = self.parent.frames

	self:setFont()
end

function Glyph:setFont()
	local font = self.parent.font or AtlasText.defaultFont
	self:setFrames(self.parent.frames)
	self:updateHitbox()
	self.antialiasing = font.antialiasing ~= nil and font.antialiasing or true

	Glyph.lastHeight = self.height

	self.__forceUpdate = true
	self:set()
end

function Glyph:set(glyph)
	self.glyph = utf8.char(glyph or self.glyph)
	if self.glyph == "\n" then
		self.visible = false
		self.width = 0
	else
		local font = self.parent.font or AtlasText.defaultFont
		self.glyph = font.noUpper and lower(self.glyph) or
			(font.noLower and upper(self.glyph) or self.glyph)

		local glyphData = font.glyphs and font.glyphs[self.glyph]
		if glyphData then
			if self.glyph == "\t" or self.glyph == " " then
				self.visible = false
				self.width, self.height = glyphData[1], glyphData[1]
			else
				self.glyph = glyphData[1]
				if glyphData[2] then
					self.letterOffset.x, self.letterOffset.y =
						glyphData[2][1], glyphData[2][2]
				end
			end
		end

		-- Animation handling
		if self.glyph ~= " " then
			local framerate = font.framerate or 24
			local looped = font.looped ~= nil and font.looped or true

			self:addAnimByPrefix(self.glyph, self.glyph, framerate, looped)
			if self.__animations and self.__animations[self.glyph] then
				self:play(self.glyph)
			end
			self:updateHitbox()
		end
	end
end

function Glyph:updateHitbox()
	Glyph.super.updateHitbox(self)
	self:__resetOffsets()
end

function Glyph:__resetOffsets()
	local font = self.parent.font or AtlasText.defaultFont

	local fx = font.offsets and font.offsets[1] or 0
	local fy = font.offsets and font.offsets[2] or 0

	local ox = self.letterOffset.x
	local oy = self.letterOffset.y - (110 - self.height)

	self.offset = {x = ox - fx, y = oy - fy}
end

function Glyph:__render(camera)
	local batch = self.parent and self.parent.batch
	if not batch or not self.visible then return end

	local r, g, b, a = batch:getColor()
	batch:setColor(Color.vec4(self.color, self.alpha))

	local f = self:getCurrentFrame()
	local x, y, rad, sx, sy, ox, oy = self.x, self.y, math.rad(self.angle),
		self.scale.x * self.zoom.x, self.scale.y * self.zoom.y,
		self.origin.x, self.origin.y
	local s = (self.parent and self.parent.italic) and -0.2 or 0

	if self.flipX then sx = -sx end
	if self.flipY then sy = -sy end

	x, y = (x + ox - self.offset.x), (y + oy - self.offset.y)
	x, y = x - (camera.scroll.x * self.scrollFactor.x), y - (camera.scroll.y * self.scrollFactor.y)

	ox, oy = ox + f.offset.x, oy + f.offset.y

	if self.__lastFrame ~= math.floor(self.curFrame or 0) or self.__forceUpdate then
		-- use old slots if any
		-- made this so the batch doesn't grows. indv sprites can't be removed from it at all
		if not self.batchIdx then
			if #self.parent.batchPool > 0 then
				self.batchIdx = table.remove(self.parent.batchPool)
				batch:set(self.batchIdx, f.quad, x, y, rad, sx, sy, ox, oy, s)
			else
				self.batchIdx = batch:add(f.quad, x, y, rad, sx, sy, ox, oy, s)
			end
		else
			batch:set(self.batchIdx, f.quad, x, y, rad, sx, sy, ox, oy, s)
		end

		self.__lastFrame = math.floor(self.curFrame or 0)
		if self.__forceUpdate then self.__forceUpdate = false end
	end

	batch:setColor(r or 1, g or 1, b or 1, a or 1)
end

function Glyph:destroy()
	Glyph.super.destroy(self)
	if self.parent and self.parent.batch and self.batchIdx then
		table.insert(self.parent.batchPool, self.batchIdx)
		self.parent.batch:set(self.batchIdx, 0, 0, 0, 0, 0, 0, 0)
	end
	self.parent = nil
end

return Glyph
