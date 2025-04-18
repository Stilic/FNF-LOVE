local Stage = Group:extend("Stage")

local function getVector(tbl)
	return {x = tbl[1] or 0, y = tbl[2] or 0}
end

function Stage:new(name)
	Stage.super.new(self)

	self.name = name

	local data = Parser.getStage(name)

	self.__props = data.props or {}

    self.characters = data.characters or {}

	self.camZoom, self.camSpeed, self.camZoomSpeed = data.cameraZoom or 1.0, 1, 1

	self.boyfriendPos = getVector(data.characters.bf.position) or {x = 770, y = 100}
	self.gfPos = getVector(data.characters.gf.position) or {x = 400, y = 130}
	self.dadPos = getVector(data.characters.dad.position) or {x = 100, y = 100}

	self.boyfriendCam = {x = 0, y = 0}
	self.gfCam = {x = 0, y = 0}
	self.dadCam = {x = 0, y = 0}

	self.foreground = Group()
    self.props = Group()

	if name ~= "" then
		local path = "stages/" .. name
		self.script = Script("data/" .. path)
		self.script:linkObject(self)
		self.script:set("SCRIPT_PATH", path .. "/")
		self.script:set("self", self)

		self.script:call("create")
	end
	
	self:create()
end

function Stage:create()
    local path = "stages/" .. self.name .. '/'

    local function hexToRGB(hex)
        hex = hex:gsub("#", "")
        local r, g, b = hex:match("^(.)(.)(.)$")
        if #hex == 6 then
            r, g, b = hex:sub(1, 2), hex:sub(3, 4), hex:sub(5, 6)
        elseif not r then
            error("Invalid hex color format")
        end
        return tonumber("0x" .. r) / 255, tonumber("0x" .. g) / 255, tonumber("0x" .. b) / 255
    end

    for _, prop in pairs(self.__props) do
        local instance
        local isAnimated = prop.animations and next(prop.animations)

        if isAnimated then
            instance = Sprite(prop.position[1], prop.position[2]):loadTexture(paths.getImage(path .. prop.assetPath))
            instance:setFrames(paths.getSparrowAtlas(path .. prop.assetPath))
            for _, anim in pairs(prop.animations) do
                local name = anim.name
                if anim.frameIndices then
                    instance:addAnimByIndices(name, anim.prefix or '', anim.frameIndices, anim.frameRate or 24, anim.looped or false)
                else
                    instance:addAnimByPrefix(name, anim.prefix or '', anim.frameRate or 24, anim.looped or false)
                end
                if anim.offsets then
                    instance:addOffset(name, anim.offsets[1], anim.offsets[2])
                end
            end
            instance:play(prop.startingAnimation or "danceLeft", true)
        elseif prop.assetPath:sub(1, 1) == '#' then
            instance = Graphic(prop.position[1], prop.position[2], prop.scale[1] or 1.0, prop.scale[2] or 1.0)
            instance.color = {hexToRGB(prop.assetPath)}
        else
            instance = Sprite(prop.position[1], prop.position[2]):loadTexture(paths.getImage(path .. prop.assetPath))
        end

        instance.scale.x, instance.scale.y = prop.scale[1] or 1.0, prop.scale[2] or 1.0
        instance.flipX, instance.flipY = prop.flipX or false, prop.flipY or false
        instance:setScrollFactor(prop.scroll[1] or 1.0, prop.scroll[2] or 1.0)
        instance.name, instance.zIndex = prop.name, prop.zIndex or 0

        self.props:add(instance)
        self.script:set(prop.name, instance)
    end

    self.props:sort(function(a, b) return (a.zIndex or 0) < (b.zIndex or 0) end)
end

function Stage:add(obj, foreground)
	if foreground then
		self.foreground:add(obj)
	else
		Stage.super.add(self, obj)
	end
end

return Stage
