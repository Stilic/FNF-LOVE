local Stage = Group:extend("Stage")

local function getVector(tbl)
	return {x = tbl[1] or 0, y = tbl[2] or 0}
end

function Stage:new(name)
	Stage.super.new(self)

	self.name = name

	local data = Parser.getStage(name)

	self.__props = data.props or {}

	self.camZoom, self.camSpeed, self.camZoomSpeed = data.cameraZoom or 1.0, 1, 1

	self.boyfriendPos = getVector(data.characters.bf.position) or {x = 770, y = 100}
	self.gfPos = getVector(data.characters.gf.position) or {x = 400, y = 130}
	self.dadPos = getVector(data.characters.dad.position) or {x = 100, y = 100}

	self.boyfriendCam = getVector(data.characters.bf.cameraOffsets) or {x = 0, y = 0}
	self.gfCam = getVector(data.characters.gf.cameraOffsets) or {x = 0, y = 0}
	self.dadCam = getVector(data.characters.dad.cameraOffsets) or {x = 0, y = 0}

	self.foreground = Group()
	self.props = Group()

	if name ~= "" then
		local path = "selfs/" .. name
		self.script = Script("data/" .. path)
		self.script:linkObject(self)
		self.script:set("SCRIPT_PATH", path .. "/")
		self.script:set("self", self)

		self.script:call("create")
	end
	
	--self:create()
end

function Stage:create()
    local function hexToRGB(hex)
        hex = hex:gsub("#", "")
        if #hex == 6 then
            return tonumber("0x" .. hex:sub(1, 2)) / 255,
                   tonumber("0x" .. hex:sub(3, 4)) / 255,
                   tonumber("0x" .. hex:sub(5, 6)) / 255
        elseif #hex == 3 then
            return tonumber("0x" .. hex:sub(1, 1) .. hex:sub(1, 1)) / 255,
                   tonumber("0x" .. hex:sub(2, 2) .. hex:sub(2, 2)) / 255,
                   tonumber("0x" .. hex:sub(3, 3) .. hex:sub(3, 3)) / 255
        else
            error("Invalid hex color format")
        end
    end
    for i,prop in pairs(self.__props) do
        local animated, instace
        if prop.animations then
            if next(prop.animations) == nil then
                animated = false
            else
                animated = true
            end
        else
            animated = false
        end
        instance = Sprite(prop.position[1], prop.position[2], paths.getImage(self.name..'/'..prop.assetPath))
        instance.zIndex = prop.zIndex or 0
        instance.scale.x = prop.scale[1] or 1.0
        instance.scale.y = prop.scale[2] or 1.0
        instance:setScrollFactor(prop.scroll[1] or 1.0, prop.scroll[2] or 1.0)
        if animated then
            instance:setFrames(paths.getSparrowAtlas(self.name..'/'..prop.assetPath))
            for i,anim in pairs(prop.animations) do
                local name = anim.name
                if anim.frameIndices then
                    instance:addByIndices(name, anim.prefix or '', anim.frameIndices, anim.fps or 24, anim.looped or false)
                else
                    instance:addByPrefix(name, anim.prefix or '', anim.fps or 24, anim.looped or false)
                end
                if anim.offsets then
                    instance:addOffset(name, anim.offsets[1], anim.offsets[2])
                end
            end
            instance:play(prop.startingAnimation or "danceLeft", true)
        else
            if prop.assetPath:sub(1, 1) == '#' then
                local color = {hexToRGB(prop.assetPath)}
                instance = Graphic(prop.position[1], prop.position[2], prop.scale[1], prop.scale[2])
                instance.color = color
            else
                instance = Sprite(prop.position[1], prop.position[2], paths.getImage(prop.assetPath))
            end
        end
        self.props:insert(prop.zIndex, instance)
    end
    return self
end

function Stage:add(obj, foreground)
	if foreground then
		self.foreground:add(obj)
	else
		Stage.super.add(self, obj)
	end
end

return Stage
