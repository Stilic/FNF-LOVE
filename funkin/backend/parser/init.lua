local chart = require "funkin.backend.parser.chart"
local character = require "funkin.backend.parser.character"
local stage = require "funkin.backend.parser.stage"

local Parser = {}

local weak = {__mode = "k"}
local weakValue = {__mode = "kv"}

function Parser.sortByTime(a, b)
	if a and b then
		return a.t < b.t
	end
	return false
end

function Parser.pset(tbl, key, v) if v ~= nil then tbl[key] = v end end

function Parser.getChart(name, diff)
	name = paths.formatToSongPath(name)
	local data, path = chart.get(name, diff and diff:lower() or "normal")

	if data then
		local parser = chart.getParser(data)
		local parsed =
			parser.parse(data, paths.getJSON(path .. "events"),
				paths.getJSON(path .. "meta"), diff)

		table.sort(parsed.notes.enemy, Parser.sortByTime)
		table.sort(parsed.notes.player, Parser.sortByTime)
		table.sort(parsed.events, Parser.sortByTime)

		if parsed.song == nil then parsed.song = name end

		print("[CHART PARSER] Parsed \"" .. (parsed.song or "unknown") ..
			"\" as " .. (parser.name or "unknown"))
		return parsed
	else
		Toast.error("[CHART PARSER] Chart not found.")
		return Parser.getDummyChart(name, true)
	end
end

function Parser.getDummyChart(name, dummyData)
	return {
		song = name and paths.formatToSongPath(name) or nil,
		bpm = 100,
		speed = 1,

		difficulties = {"Easy", "Normal", "Hard"},

		player1 = dummyData and "bf" or nil,
		player2 = dummyData and "dad" or nil,
		gfVersion = dummyData and "gf" or nil,

		stage = dummyData and "stage" or nil,
		skin = dummyData and "default" or nil,

		events = {},
		notes = {player = {}, enemy = {}}
	}
end

function Parser.newTimeChange(time, bpm, beats, n, d)
	return {
		t = time,
		b = beats,
		bpm = bpm,
		n = n or 4,
		d = d or 4
	}
end

function Parser.getMeta(name)
	local format = paths.formatToSongPath
	local meta = {
		song = format(name),
		displayName = name,
		charter = "unknown",
		composer = "unknown",

		icon = HealthIcon.defaultIcon,
		color = Color.WHITE,
		difficulties = {"Easy", "Normal", "Hard"}
	}

	local data = paths.getJSON("songs/" .. format(name) .. "/meta")
	if not data then return meta end
	setmetatable(data, weakValue)

	local function get(key, def)
		local playData, info = data.playData or {}
		if type(key) == "table" then
			for i = 1, #key do
				local k = key[i]
				info = playData[k] ~= nil and playData[k] or
					data[k] ~= nil and data[k]
				if info then
					break
				end
			end
		else
			info = playData[key] ~= nil and playData[key] or
				data[key] ~= nil and data[key]
		end
		return info or def
	end

	meta.song = paths.formatToSongPath(get({"songName", "song", "name"}, meta.song))
	meta.displayName = get({"displayName", "songName", "song", "name"}, meta.displayName)
	meta.icon = get("icon", meta.icon)
	meta.difficulties = get("difficulties", meta.difficulties)

	meta.charter = get("charter", meta.charter)
	meta.composer = get({"composer", "artist"}, meta.composer)

	local rawColor = get("color", nil)
	if rawColor then
		switch(type(rawColor), {
			["string"] = function()
				if not rawColor:startsWith("#") then
					rawColor = "0x" .. rawColor
				else
					rawColor = rawColor:gsub("#", "0x")
				end
				meta.color = Color.fromHEX(tonumber(rawColor))
			end,
			["number"] = function() meta.color = Color.fromHEX(rawColor) end,
			["table"]  = function() meta.color = Color.convert(rawColor) end
		})
	end

	return meta
end

function Parser.getCharacter(name)
	local data = character.get(name)
	if not data then data = character.get("bf") end

	return character.getParser(data).parse(data, name)
end

function Parser.getDummyChar()
	return {
		animations = {},

		position = {0, 0},
		camera_points = {0, 0},
		sing_duration = 4,
		dance_beats = nil,

		flip_x = false,
		icon = HealthIcon.defaultIcon,
		sprite = nil,
		antialiasing = true,
		scale = 1
	}
end

function Parser.getStage(name)
	local data = stage.get(name)
	if not data then return false end

	return stage.getParser(data).parse(data)
end

function Parser.getDummyStage()
	return {
		name = "Stage",
		cameraZoom = 1.0,
		props = {},
		characters = {}
	}
end

return Parser
