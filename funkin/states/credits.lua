local CreditsState = State:extend("CreditsState")

local UserList = require "funkin.ui.credits.userlist"
local UserCard = require "funkin.ui.credits.usercard"

local function category(header, people)
	return { header = header, credits = people }
end

local function user(name, icon, color, description, ...)
	local socials = {}
	for i = 1, select("#", ...), 2 do
		local platform = select(i, ...)
		local handle   = select(i + 1, ...)
		socials[#socials + 1] = {name = platform, text = handle}
	end
	return {name = name, icon = icon, color = color, description = description, social = socials}
end

CreditsState.defaultData = {
	category("Contributors", {

		user("Stilic", "https://github.com/stilic.png", "#FFCA45", "Main director and programmer",
			"X", "@stilic_dev",
			"Github", "/Stilic"
		),

		user("Raltyro", "https://github.com/raltyro.png", "#FF4545", "Artist and programmer",
			"X", "@raltyro",
			"Youtube", "@Raltyro",
			"Github", "/Raltyro"
		),

		user("Fellyn", "https://github.com/yuk1r4luvyu.png", "#E49CFA", "Composer of \"Railways\", programmer and logo creator",
			"X", "@FellynnLol_",
			"Youtube", "@FellynnMusic_",
			"Github", "/FellynYukira"
		),

		user("MrMeep64", "https://github.com/Arm4GeDon.png", "#D1794D", "V-Slice content porting and programmer"),

		user("TehPuertoRicanSpartan", "https://github.com/TehPuertoRicanSpartan.png", "#D1794D", "V-Slice content porting and programmer"),

		user("Victor Kaoy", "https://github.com/vikaoy.png", "#D1794D", "Artist and programmer",
			"X", "@vk15_"
		),

		user("Blue Colorsin",           "https://github.com/bluecolorsin.png",           "#2B56FF", "Programmer",
			"X", "@BlueColorsin",
			"Youtube", "@BlueColorsin",
			"Github", "/BlueColorsin"
		),

		user("FowluhhDev", "https://github.com/fowluhhdevbcfunny.png", "#383838", "Programmer"),
	}),

	category("Funkin' Crew", {
		user("Ninjamuffin99", "https://github.com/ninjamuffin99.png", "#FF392B", "Programmer of Friday Night Funkin'",
			"X", "@ninja_muffin99",
			"Youtube", "@camerontaylor5970",
			"Github", "/ninjamuffin99"
		),
		user("Phantom Arcade", "https://github.com/phantomarcade.png", "#EBC73B", "Animator of Friday Night Funkin'",
			"X", "@PhantomArcade3K",
			"Youtube", "@PhantomArcade"
		),
		user("EvilSk8r", "https://github.com/evilsk8r.png", "#5EED3E", "Artist of Friday Night Funkin'",
			"X", "@evilsk8r"
		),
		user("Kawai Sprite", "https://github.com/kawaisprite.png", "#4185FA", "Musician of Friday Night Funkin'",
			"X", "@kawaisprite",
			"Youtube", "@KawaiSprite"
		),
	}),
}

function CreditsState:enter()
	CreditsState.super.enter(self)

	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Credits"})
	end

	self.data = {}

	self.lastHeight = 0
	self.curSelected = 1
	self.curTab = 1

	self.camFollow = {x = game.width / 2, y = game.height / 2}
	game.camera:follow(self.camFollow, nil, 8)
	game.camera:snapToTarget()

	self.bg = Sprite(0, 0, paths.getImage("menus/menuDesat"))
	self:add(util.responsiveBG(self.bg))

	self.bd = BackDrop(128)
	self.bd.moves = true
	self.bd.velocity:set(26, 26)
	self.bd.scrollFactor:set()
	self.bd.alpha = 0.5
	self:add(self.bd)

	local creditsMod = paths.getJSON('data/credits')
	if creditsMod then
		for i = 1, #creditsMod do table.insert(self.data, creditsMod[i]) end
	end
	for i = 1, #self.defaultData do
		table.insert(self.data, self.defaultData[i])
	end

	self.userList = UserList(self.data, game.width * 0.3)
	self.userList.parent = self
	self:add(self.userList)

	self.userCard = UserCard(10 + self.userList:getWidth() + 10, 10,
		game.width - self.userList:getWidth() - 30, game.height - 130)
	self.userCard.scrollFactor:set()
	self:add(self.userCard)

	self:changeSelection()

	local colorBG = Color.fromString(self.userList:getSelected().color or "#DF7B29")
	self.bg.color = colorBG
	self.bd.color = Color.saturate(self.bg.color, 0.4)

	self.throttles = {}
	self.throttles.up = Throttle:make({controls.down, controls, "ui_up"})
	self.throttles.down = Throttle:make({controls.down, controls, "ui_down"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = VirtualPadGroup()
		local w = 134

		local down = VirtualPad("down", 0, game.height - w)
		local up = VirtualPad("up", 0, down.y - w)

		self.buttons:add(down)
		self.buttons:add(up)

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

	local u = self.userList
	if u.bar.y > game.camera.scroll.y + game.height - u.bar.height then
		self.camFollow.y = u.bar.y - game.height / 2 + 84
	elseif u.bar.y < self.camFollow.y - game.height / 2 + 74 then
		self.camFollow.y = u.bar.y + game.height / 2 - 84
	end

	local colorBG = Color.fromString(self.userList:getSelected().color or "#DF7B29")
	self.bg.color = Color.lerpDelta(self.bg.color, colorBG, 3, dt)
	self.bd.color = Color.saturate(self.bg.color, 0.4)
end

function CreditsState:changeSelection(n)
	if n == nil then n = 0 end
	util.playSfx(paths.getSound('scrollMenu'))

	self.userList:changeSelection(n)
	self.userCard:reload(self.userList:getSelected())
end

return CreditsState
