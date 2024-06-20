local CreditsState = State:extend()

-- would it be funny if the x renamed to twitter instead to mock elon musk
CreditsState.defaultData = {
	{
		header = "Engine Team",
		credits = {
			{
				name = "Stilic",
				icon = "stilic",
				color = "#FFCA45",
				description = "something",
				social = {
					{name = "X",      text = "@stilic_dev"},
					{name = "Github", text = "/Stilic"}
				}
			},
			{
				name = "Raltyro",
				icon = "ralty",
				color = "#FF4545",
				description = "something",
				social = {
					{name = "X",       text = "@raltyro"},
					{name = "Youtube", text = "@Raltyro"},
					{name = "Github",  text = "/Raltyro"}
				}
			},
			{
				name = "Fellyn",
				icon = "fellyn",
				color = "#E49CFA",
				description = "something",
				social = {
					{name = "X",       text = "@FellynnLol_"},
					{name = "Youtube", text = "@FellynnMusic_"},
					{name = "Github",  text = "/FellynYukira"}
				}
			},
			{
				name = "Victor Kaoy",
				icon = "vickaoy",
				color = "#D1794D",
				description = "something",
				social = {
					{name = "X", text = "@vk15_"}
				}
			},
			{
				name = "Blue Colorsin",
				icon = "bluecolorsin",
				color = "#2B56FF",
				description = "something",
				social = {
					{name = "X",       text = "@BlueColorsin"},
					{name = "Youtube", text = "@BlueColorsin"},
					{name = "Github",  text = "/BlueColorsin"}
				}
			},
			{
				name = "Ralsin",
				icon = "ralsin",
				color = "#383838",
				description = "something",
				social = {
					{name = "X",       text = "@ralsi_"},
					{name = "Youtube", text = "@ralsin"},
					{name = "Github",  text = "/Ralsin"}
				}
			}
		}
	},
	{
		header = "Funkin' Team",
		credits = {
			{
				name = "Ninjamuffin99",
				icon = "ninjamuffin",
				color = "#FF392B",
				description = "Programmer of Friday Night Funkin'",
				social = {
					{name = "X",       text = "@ninja_muffin99"},
					{name = "Youtube", text = "@camerontaylor5970"},
					{name = "Github",  text = "/ninjamuffin99"}
				}
			},
			{
				name = "Phantom Arcade",
				icon = "phantomarcade",
				color = "#EBC73B",
				description = "Animator of Friday Night Funkin'",
				social = {
					{name = "X",       text = "@PhantomArcade3K"},
					{name = "Youtube", text = "@PhantomArcade"}
				}
			},
			{
				name = "EvilSk8r",
				icon = "evilsk8r",
				color = "#5EED3E",
				description = "Artist of Friday Night Funkin'",
				social = {
					{name = "X", text = "@evilsk8r"}
				}
			},
			{
				name = "Kawai Sprite",
				icon = "kawaisprite",
				color = "#4185FA",
				description = "Musician of Friday Night Funkin'",
				social = {
					{name = "X",       text = "@kawaisprite"},
					{name = "Youtube", text = "@KawaiSprite"}
				}
			}
		}
	}
}

function CreditsState:enter()
	CreditsState.super.enter(self)
	self.data = {}

	self.lastHeight = 0
	self.curSelected = 1
	self.curTab = 1

	self.camFollow = {x = game.width / 2, y = game.height / 2}
	game.camera:follow(self.camFollow, nil, 8)
	game.camera:snapToTarget()

	self.bg = Sprite(0, 0, paths.getImage('menus/menuDesat'))
	self.bg:setGraphicSize(math.floor(self.bg.width * (game.width / self.bg.width)))
	self.bg:updateHitbox()
	self.bg:screenCenter()
	self.bg:setScrollFactor()
	self:add(self.bg)

	self.bd = BackDrop(0, 0, game.width, game.height, 72, nil, {0, 0, 0, 0}, 26)
	self.bd:setScrollFactor()
	self.bd.alpha = 0.5
	self:add(self.bd)

	self.ui = {}
	local u = self.ui

	u.usersMenu = SpriteGroup()

	u.userBox = Graphic(10, 10, 426, 0, Color.fromRGB(10, 12, 26))
	u.userBox.alpha = 0.4
	u.userBox:setScrollFactor(0, 1)
	u.usersMenu:add(u.userBox)

	local creditsMod = paths.getJSON('data/credits')
	if creditsMod then
		for i = 1, #creditsMod do table.insert(self.data, creditsMod[i]) end
	end

	for i = 1, #self.defaultData do
		table.insert(self.data, self.defaultData[i])
	end

	for i = 1, #self.data do
		local header = self.data[i]
		self:addUsers(header.header, header.credits, i - 1)
	end

	u.selectBar = Graphic(u.userBox.x + 20, u.userBox.y + 10,
		u.userBox.width - 40, 54, Color.WHITE)
	u.selectBar.alpha = 0.2
	u.selectBar:setScrollFactor(0, 1)
	u.usersMenu:add(u.selectBar)

	u.infoMenu = Group()

	u.infoBox = Graphic(
		u.userBox.x + u.userBox.width + 10, 120,
		game.width - u.userBox.width - 30, game.height - 130, Color.fromRGB(10, 12, 26))
	u.infoBox.alpha = 0.4
	u.infoBox.config.round = {16, 16}
	u.infoBox:setScrollFactor()
	u.infoMenu:add(u.infoBox)

	u.userIcon = Sprite(u.userBox.x + u.userBox.width + 10, 10)
	u.userIcon:setGraphicSize(100)
	u.userIcon:updateHitbox()
	u.userIcon:setScrollFactor()
	u.infoMenu:add(u.userIcon)

	u.userName = Text(u.userIcon.x + u.userIcon.width + 10, 0, "Name",
		paths.getFont("phantommuff.ttf", 75))
	u.userName:setOutline("normal", 4)
	u.userName.y = 10 + (u.userIcon.height - u.userName:getHeight()) / 2
	u.userName.antialiasing = false
	u.userName:setScrollFactor()
	u.infoMenu:add(u.userName)

	u.userDesc = Text(
		u.infoBox.x + 10, u.infoBox.y + 10, "Description",
		paths.getFont("vcr.ttf", 32), nil, nil, u.infoBox.width - 20)
	u.userDesc.antialiasing = false
	u.userDesc:setScrollFactor()
	u.infoMenu:add(u.userDesc)

	u.socials = Group()
	u.infoMenu:add(u.socials)

	local stencilObject = Graphic(10, 10, 426, game.height - 20, Color.fromRGB(10, 12, 26))
	stencilObject.config.round = {16, 16}
	stencilObject:setScrollFactor()
	local stencil = Stencil(u.usersMenu)
	stencil.stencilObject = stencilObject

	self:add(stencil)
	self:add(u.infoMenu)

	self:changeSelection()

	local colorBG = Color.fromString(self.data[self.curTab].credits[self.curSelected].color or "#DF7B29")
	self.bg.color = colorBG
	self.bd.color = Color.saturate(self.bg.color, 0.4)

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
		if self.throttles.up:check() then self:changeSelection(-1) end
		if self.throttles.down:check() then self:changeSelection(1) end
	end
	if controls:pressed("back") then
		util.playSfx(paths.getSound('cancelMenu'))
		game.switchState(MainMenuState())
	end

	local u = self.ui
	if u.selectBar.y > game.camera.scroll.y + game.height - u.selectBar.height then
		self.camFollow.y = u.selectBar.y - game.height / 2 + 74
	elseif u.selectBar.y < self.camFollow.y - game.height / 2 + 74 then
		self.camFollow.y = u.selectBar.y + game.height / 2 - 94
	end

	local colorBG = Color.fromString(self.data[self.curTab].credits[self.curSelected].color or "#DF7B29")
	self.bg.color = Color.lerpDelta(self.bg.color, colorBG, 3, dt)
	self.bd.color = Color.saturate(self.bg.color, 0.4)
end

function CreditsState:changeSelection(n)
	if n == nil then n = 0 end
	util.playSfx(paths.getSound('scrollMenu'))

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
	u.selectBar.y = 94 + 84 * (self.curTab - 1) + 64 * (currentList - 1)

	local d = self.data[self.curTab].credits[self.curSelected]
	u.userName.content = d.name
	u.userDesc.content = d.description

	u.userIcon:loadTexture(paths.getImage("menus/credits/icons/" .. d.icon))
	u.userIcon:setGraphicSize(100)
	u.userIcon:updateHitbox()

	self:reloadSocials()
end

function CreditsState:addUsers(name, people, i)
	local u = self.ui

	local card = SpriteGroup(u.userBox.x + 10, u.userBox.y + 10)
	u.usersMenu:add(card)

	local box = Graphic(0, 0, u.userBox.width - 20, 60)
	box.y = (self.lastHeight > 0 and self.lastHeight + 10 or 0)
	box.alpha = 0.2
	box.config.round = {18, 18}
	box:setScrollFactor(0, 1)
	card:add(box)

	local title = Text(10, box.y + 8, name or "Unknown", paths.getFont("vcr.ttf", 38))
	title.y = box.y + (box.height - title:getHeight()) / 2
	title.limit = box.width - 20
	title:setScrollFactor(0, 1)
	title.alignment = "center"
	title.antialiasing = false
	card:add(title)

	local function makeCard(name, icon, i)
		local img = Sprite(10, box.y +
			(64 * i + 10), paths.getImage("menus/credits/icons/" .. icon))
		img:setGraphicSize(54)
		img:updateHitbox()
		img:setScrollFactor(0, 1)
		card:add(img)

		local txt = Text(img.x + img.width + 10, 0,
			name, paths.getFont("vcr.ttf", 36))
		txt.y = img.y + (img.height - txt:getHeight()) / 2
		txt.limit = box.width - img.width - 30
		txt:setScrollFactor(0, 1)
		txt.antialiasing = false
		card:add(txt)

		return img, txt
	end

	for i = 1, #people do
		local img, txt = makeCard(people[i].name, people[i].icon, i)
		self.lastHeight = img.y + img.height + 10
	end
	u.userBox.height = math.max(game.height - 10, self.lastHeight + 10)
end

function CreditsState:reloadSocials()
	local u = self.ui
	for _, o in ipairs(u.socials.members) do
		o:destroy()
	end

	local function makeThing(name, icon, i)
		local img = Sprite(u.infoBox.x + 10, 0, paths.getImage("menus/credits/social/" .. icon))
		img.y = u.infoBox.y + u.infoBox.height - (img.height * i) - (10 * i)
		img:setGraphicSize(img.width, 42)
		img:updateHitbox()
		img:setScrollFactor()
		u.socials:add(img)

		local txt = Text(img.x + img.width + 10, img.y,
			name or "Missing", paths.getFont("vcr.ttf", 34))
		txt.y = img.y + (img.height - txt:getHeight()) / 2
		txt:setOutline("normal", 4)
		txt.antialiasing = false
		txt:setScrollFactor()
		u.socials:add(txt)
	end

	local person = self.data[self.curTab].credits[self.curSelected]
	if person.social then
		for i = #person.social, 1, -1 do
			local social = person.social[i]
			makeThing(social.text, social.name:lower(), #person.social - i + 1)
		end
	end
end

return CreditsState
