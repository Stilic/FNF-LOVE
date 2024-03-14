local CreditsState = State:extend()

function CreditsState:enter()
	CreditsState.super.enter(self)
	self.curSelected = 1
	self.curTab = 1

	self.bg = Sprite():loadTexture(paths.getImage('menus/menuDesat'))
	self.bg:setGraphicSize(math.floor(self.bg.width * (game.width / self.bg.width)))
	self.bg:updateHitbox()
	self.bg:screenCenter()
    self.bg:setScrollFactor()

	self:add(self.bg)
	self.bd = BackDrop(0, 0, game.width, game.height, 72, {1,0,0,1}, {0,0,0,0}, 26)
    self.bd:setScrollFactor()
	self:add(self.bd)
	self.bd.alpha = 0.5

	self.ui = {}
	local u = self.ui
	u.people = Group()

	u.peopleCards = Group()

	u.peopleAll = SpriteGroup()

	u.leftBox = Graphic(10, 10, 426, game.height - 20, Color.fromRGB(10, 12, 26))
	u.leftBox.alpha = 0.4
	u.leftBox.config.round = {16, 16}
	u.people:add(u.leftBox)

	u.peopleList = SpriteGroup(u.leftBox.x + 10, u.leftBox.y + 10)

	u.headers = Group()

	u.selectBar = Graphic(u.leftBox.x + 10, u.leftBox.y + 10,
		u.leftBox.width - 20, 54, Color.WHITE)
	u.selectBar.alpha = 0.16
	u.selectBar.blend = "add"

	u.card = Group()
	u.icon = Sprite(u.leftBox.x + u.leftBox.width + 10, 10)
    u.icon:setScrollFactor()
	u.icon:setGraphicSize(100)
	u.icon:updateHitbox()
	u.card:add(u.icon)

	u.name = Text(u.icon.x + u.icon.width + 10, 0, "Name",
		paths.getFont("phantommuff.ttf", 75))
	u.name:setOutline("normal", 4)
	u.name.y = 10 + (u.icon.height - u.name:getHeight()) / 2
    u.name:setScrollFactor()
	u.card:add(u.name)

	u.rightBox = Graphic(
		u.leftBox.x + u.leftBox.width + 10, 20 + u.icon.width,
		game.width - u.leftBox.width - 30, game.height - 100 - 30, Color.fromRGB(10, 12, 26))
	u.rightBox.alpha = 0.4
	u.rightBox.config.round = {16, 16}
    u.rightBox:setScrollFactor()
	u.card:add(u.rightBox)

	u.desc = Text(
		u.rightBox.x + 10, u.rightBox.y + 10, "Description",
			paths.getFont("vcr.ttf", 32), nil, nil, u.rightBox.width - 10)
    u.desc.antialiasing = false
    u.desc:setScrollFactor()
	u.card:add(u.desc)

	u.mediaList = Group()

	self:add(u.people)
	u.peopleAll:add(u.peopleCards)
	u.peopleAll:add(u.peopleList)
	self:add(u.peopleAll)
	self:add(u.headers)
	self:add(u.card)
	self:add(u.mediaList)
	self:add(u.selectBar)

	self.data = paths.getJSON("data/credits")
	self:createPeopleList()
	self:change(0)

    self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	local device = love.system.getDevice()
	if device == "Desktop" then
		Discord.changePresence({details = "In the Menus", state = "Credits"})
	elseif device == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134

		local down = VirtualPad("down", 0, game.height - w)
		local up = VirtualPad("up", 0, down.y - w)
		local back = VirtualPad("escape", game.width - w, down.y, nil, nil, Color.RED)

		self.buttons:add(down)
		self.buttons:add(up)
		self.buttons:add(back)

		self:add(self.buttons)
	end
end

function CreditsState:update(dt)
	CreditsState.super.update(self, dt)

    if self.throttles then
        if controls:pressed("back") then game.switchState(MainMenuState()) end
	    if self.throttles.up:check() then self:change(-1) end
	    if self.throttles.down:check() then self:change(1) end
    end

	local colorBG = Color.fromString(self.data[self.curTab].credits[self.curSelected].color or "#DF7B29")
	self.bg.color[1], self.bg.color[2], self.bg.color[3] =
		util.coolLerp(self.bg.color[1], colorBG[1], 3, dt),
		util.coolLerp(self.bg.color[2], colorBG[2], 3, dt),
		util.coolLerp(self.bg.color[3], colorBG[3], 3, dt)

	local color = {Color.RGBtoHSL(colorBG[1], colorBG[2], colorBG[3])}
	color[2] = 0.7
	colorBG = {Color.HSLtoRGB(color[1], color[2], color[3])}

	self.bd.color[1], self.bd.color[2], self.bd.color[3] =
		util.coolLerp(self.bd.color[1], colorBG[1], 3, dt),
		util.coolLerp(self.bd.color[2], colorBG[2], 3, dt),
		util.coolLerp(self.bd.color[3], colorBG[3], 3, dt)
end

function CreditsState:createPeopleList()
	local u = self.ui

	for i = 1, #self.data do
		local header = self.data[i]
		self:createPeopleCard(header.header, header.credits, i - 1)
	end
end

function CreditsState:createSocialList()
	local u = self.ui
	for _, o in ipairs(u.mediaList.members) do
		o:destroy()
	end

	local function makeThing(name, icon, i)
		local img = Sprite(u.rightBox.x + 10, 0, paths.getImage("menus/credits/social/" .. icon))
		img.y = u.rightBox.y + u.rightBox.height - (img.height * i) - (10 * i)
		img:updateHitbox()
        img:setScrollFactor()
		u.mediaList:add(img)

		local txt = Text(img.x + img.width + 10, img.y,
			name, paths.getFont("vcr.ttf", 34))
		txt:setOutline("normal", 4)
        txt.antialiasing = false
        txt:setScrollFactor()
		u.mediaList:add(txt)
	end

	local person = self.data[self.curTab].credits[self.curSelected]
	if person.social then
		for i = 1, #person.social do
			local social = person.social[i]
			makeThing(social.text, social.name:lower(), i)
		end
	end
end

function CreditsState:change(n)
	game.sound.play(paths.getSound('scrollMenu'))
	local u = self.ui
	self.curSelected = self.curSelected + n
    if self.curSelected > #self.data[self.curTab].credits or self.curSelected < 1 then
        if self.curSelected > #self.data[self.curTab].credits then
            self.curSelected = 1
        end
        self.curTab = self.curTab + n
        self.curTab = (self.curTab - 1) % #self.data + 1
        if self.curSelected < 1 then
            self.curSelected = #self.data[self.curTab].credits
        end
    end
	self.curSelected = (self.curSelected - 1) % #self.data[self.curTab].credits + 1

    local currentList = self.curSelected
    if self.curTab > 1 then
        for dataID, data in ipairs(self.data) do
            if dataID == self.curTab then break end
            currentList = currentList + #data.credits
        end
    end
	u.selectBar.y = 104 + 84 * (self.curTab - 1) + 64 * (currentList - 1)
	self:reloadCard()
end

function CreditsState:reloadCard()
	local u = self.ui
	local d = self.data[self.curTab].credits[self.curSelected]
	u.name.content = d.name
	u.desc.content = d.description

	u.icon:loadTexture(d.icon and paths.getImage("menus/credits/icons/" .. d.icon) or Sprite.defaultTexture)
	u.icon:setGraphicSize(100)
	u.icon:updateHitbox()

	self:createSocialList(true)
end

local lastWidth = 0
function CreditsState:createPeopleCard(name, people, i)
	local u = self.ui

	local card = SpriteGroup(u.leftBox.x + 10, u.leftBox.y + 10)

	local box = Graphic(0, 0, u.leftBox.width - 20, 60)
	box.y = lastWidth + 10
	box.alpha = 0.2
	box.config.round = {18, 18}
	card:add(box)

	local title = Text(10, box.y + 10, name or "UNKNOWN", paths.getFont("vcr.ttf", 36))
    title.antialiasing = false
	title.limit = box.width - 10
	title.alignment = "center"
	card:add(title)

	local function makePersonCard(name, icon, i)
		local grp = Group()
		local img = Sprite(10, box.y +
			(64 * i + 10), paths.getImage("menus/credits/icons/" .. icon))
		img:setGraphicSize(54)
		img:updateHitbox()
		grp:add(img)

		local txt = Text(img.x + img.width + 10, 0,
			name, paths.getFont("vcr.ttf", 38))
		txt.y = img.y + (img.height - txt:getHeight()) / 2
        txt.antialiasing = false
		grp:add(txt)

		grp.id = i

		return grp, img.y, img.height
	end

	for i = 1, #people do
		local people = people[i]
		local grp, y, h = makePersonCard(people.name, people.icon, i)
		lastWidth = y + h + 10
		u.peopleList:add(grp)
	end

	u.peopleCards:add(card)
end

return CreditsState