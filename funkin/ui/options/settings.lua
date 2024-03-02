local SpriteGroup = loxel.group.SpriteGroup
local Group = loxel.group.Group
local Graphic = loxel.Graphic
local Text = loxel.Text
local Color = loxel.util.Color

local Settings = {}
Settings.__index = Settings

function Settings:base(name, settings)
	local cls = {}
	cls.name = name
	cls.settings = settings
	cls.binds = 1
	cls.size = 30
	cls.margin = 15
	cls.titleWidth = 0.5

	return setmetatable(cls, self)
end

function Settings:getSize()
	return self.size + self.margin
end

function Settings:getY(i)
	local size = self:getSize()
	local v = (i - 1) * size
	for _, off in ipairs(self.offsets) do if i >= off then v = v + size end end
	return v
end

function Settings:makeLine(x, starti, endi)
	if starti > endi then return end
	local start = self:getY(starti)
	local line = Graphic(x - 1, start, 2, self:getSize() + self:getY(endi) - start, {1, 1, 1})
	line.alpha = 0.5
	self.tab.linesGroup:add(line)
end

function Settings:makeLines(width, offset, lines, starti, endi)
	if lines < 1 or starti > endi then return end

	local s = 1 / (lines + 1)
	for i = s, 1, s do
		if i == 1 then break end
		self:makeLine(width * i + offset, starti, endi)
	end
end

function Settings:getOption(id, bind)
	local option = self.settings[id]
	if type(option[3]) == "table" then return option[bind][3] and option[bind][3]() or nil end
	return ClientPrefs.data[option[1]]
end

function Settings:getOptionString(id, bind)
	local option, value = self.settings[id], self:getOption(id)
	if type(option[3]) == "table" then return option[bind][2](value) end
	if type(option[5]) == "function" then return option[5](value) end

	local optiontype = option[3]
	if optiontype == "boolean" then
		return value and "On" or "Off"
	elseif optiontype == "string" then
		return value:capitalize()
	end

	return value or "Unknown"
end

function Settings:changeOption(id, add, optionsUI, bind)
	local option, value = self.settings[id], self:getOption(id)
	local prev = value

	local optiontype, func = option[3], option[4]
	local functype, ret = type(func)
	if optiontype == "boolean" then
		if functype == "function" then
			ret = func(add)
			value = self:getOption(id)
		else
			value = not value
		end
	elseif optiontype == "string" then
		if functype == "function" then
			ret = func(add)
			value = self:getOption(id)
		elseif functype == "table" then
			value = func[math.wrap(math.find(func, value) + add, 1, #func)]
		else
			-- TODO: input
		end
	elseif optiontype == "number" then
		if functype == "function" then
			ret = func(add)
			value = self:getOption(id)
		elseif functype == "table" then
			value = func[math.wrap(value + add, 1, #func)]
		else
			value = value + add
		end
	elseif type(optiontype) == "table" or bind then
		if not bind then return false end
		ret = option[3][bind][1](add, value, optionsUI)
		value = self:getOption(id, bind)
	end

	if functype ~= "function" then ClientPrefs.data[option[1]] = value end
	if self.tab then self.tab.items[id].texts[bind or 1].content = self:getOptionString(id, bind) end
	if ret ~= nil then return ret end
	return value ~= prev
end

function Settings:acceptOption(id, optionsUI, bind)
	local option = self.settings[id]
	local optiontype = option[3]

	if optiontype == "boolean" then
		return self:changeOption(id, 1)
	elseif type(optiontype) == "table" or #self.tab.items[id].texts > 1 then
		if bind then
			local ret = option[3][bind][1](0, value, optionsUI, bind)
			if ret ~= nil then return ret end
			return true
		end

		optionsUI.blockInput = true
		self.curBind = 1
		self.onBinding = true
		self.dontOverrideUpdate = self.update ~= nil
		if not self.dontOverrideUpdate then
			self.update = self.updateInternal
		end
	end
	return false
end

function Settings:makeOption(group, i, font, tabWidth, titleWidth, binds)
	local margin, option = self.margin, self.settings[i]
	local optiontype = type(option[3])
	if optiontype == "table" then
		binds = #option[3]
	elseif optiontype == "number" then
		binds = options[3]
	elseif optiontype == "string" then
		binds = 1
	end

	group:add(Text(margin, margin / 2, option[2], font, Color.WHITE, "left", titleWidth - margin))
	group.texts = {}

	local width = tabWidth - titleWidth
	for i2 = 1, binds do
		local text = Text(width * (i2 - 1) / binds + margin + titleWidth, margin / 2,
			self:getOptionString(i, i2), font, Color.WHITE, "center", width / binds - margin * 2)

		table.insert(group.texts, text)
		group:add(text)
	end

	return binds
end

function Settings:changeBindSelection(add, dont)
	--self.optionsCursor

	if not dont then game.sound.play(paths.getSound("scrollMenu")) end
end

function Settings:updateInternal(dt, optionsUI)
	if not self.onBinding then return end
	if controls:pressed("back") then
		optionsUI.blockInput = false
		self.onBinding = false
		if not self.dontOverrideUpdate then
			self.update = nil
		end
		return
	end
end

function Settings:make(optionsUI)
	local size, margin, tabWidth = self.size, self.margin, optionsUI.tabBG.width
	local font = paths.getFont('phantommuff.ttf', size)

	local tab = SpriteGroup()
	self.tab = tab
	tab.name = self.name
	tab.items = {}

	tab.linesGroup = Group()

	self.offsets = {}
	local binds, lastbinds, lastcategoryi, lastlinesi, lastwidth, titlewidth = self.binds, 0, 0, 0, 0
	for i, option in ipairs(self.settings) do
		local group, length = SpriteGroup(), #option
		titlewidth = tabWidth * (option[6] or self.titleWidth)

		group.isTitle = length < 2 or type(option[2]) == "number"
		if group.isTitle then -- Category
			local bg = Graphic(0, 0, tabWidth, self:getSize(), Color.BLACK)
			bg.alpha = 1 / 3

			group:add(bg)
			group:add(Text(0, margin / 2, option[1], font, Color.WHITE, "center", tabWidth))

			if i ~= 1 then
				self:makeLine(lastwidth, lastcategoryi + 1, i - 1)
				self:makeLines(tabWidth - lastwidth, lastwidth, lastbinds - 1, lastlinesi + 1, i - 1)
				table.insert(self.offsets, i)
			end
			binds, lastcategoryi, lastlinesi = option[2] or self.binds, i, i
			lastbinds, lastwidth = binds, titlewidth
		else
			local v = self:makeOption(group, i, font, tabWidth, titlewidth, binds)
			local change = titlewidth ~= lastwidth
			if not v and lastbinds ~= binds then v = binds end
			if (v and v ~= lastbinds) or change then
				if change then
					self:makeLine(lastwidth, lastcategoryi + 1, i - 1)
					lastcategoryi = i - 1
				end
				self:makeLines(tabWidth - lastwidth, lastwidth, lastbinds - 1, lastlinesi + 1, i - 1)
				lastwidth, lastbinds, lastlinesi = titlewidth, v, i - 1
			end
		end

		group.y = self:getY(i)
		if next(group.members) then tab:add(group) end
		table.insert(tab.items, group)
	end

	local i = #self.settings
	titlewidth = tabWidth * (self.settings[i][6] or self.titleWidth)
	self:makeLine(titlewidth, lastcategoryi + 1, i)
	self:makeLines(tabWidth - titlewidth, titlewidth, lastbinds - 1, lastlinesi + 1, i)

	tab:add(tab.linesGroup)
	tab.data = self

	return tab
end

return Settings
