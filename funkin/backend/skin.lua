local function loadAsset(type, p)
	local obj
	switch(type, {
		["image"] = function() obj = paths.getImage(p) end,
		["atlas"] = function() obj = paths.getAtlas(p) end,
		["sound"] = function() obj = paths.getSound(p) end
	})
	return obj
end

local Skin = Classic:extend("Skin")

function Skin:new(name)
	local s, d = pcall(paths.getJSON, "data/skins/" .. name)

	if s and d then
		self.data = d
		self.data.skin = self.data.skin or name
		self.skin = self.data.skin
	else
		self.data = paths.getJSON("data/skins/default" ..
			name:endsWith("-pixel") and "-pixel" or "")
	end
	self.isPixel = self.skin:endsWith("-pixel")
end

function Skin:get(asset, type)
	type = type or "image"

	local function try(skin)
		return loadAsset(type, "skins/" .. skin .. "/" .. asset)
	end

	local obj = try(self.skin)
	if not obj and self.isPixel and self.skin ~= "default-pixel" then
		obj = try("default-pixel")
	end
	if not obj then obj = try("default") end
	return obj
end

function Skin:getPath(asset, type)
	type = type or "image"

	local function buildFullPath(skin)
		local path, full = "skins/" .. skin .. "/" .. asset
		switch(type, {
			[{"image", "atlas"}] = function() full = "images/" .. path .. ".png" end,
			["sound"] = function() full = "sounds/" .. path .. ".ogg" end
		})
		if full and paths.exists(paths.getPath(full), "file") then
			return path
		end
	end

	local path = buildFullPath(self.skin)
	if not path and self.isPixel and self.skin ~= "default-pixel" then
		path = buildFullPath("default-pixel")
	end
	if not path then path = buildFullPath("default") end
	return path or "skins/default/" .. asset
end

return Skin
