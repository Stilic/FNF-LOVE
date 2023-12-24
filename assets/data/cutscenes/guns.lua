local bgMusic
local cutsceneTimer

function create()
	cutsceneTimer = Timer.new()

	state.dad.alpha = 0.00001
	state.camHUD.visible = false

	local songName = paths.formatToSongPath(state.SONG.song)

	tankman = Sprite(state.dad.x + 100, state.dad.y)
	tankman:setFrames(paths.getSparrowAtlas('stages/tank/cutscenes/' .. songName))
	tankman:addAnimByPrefix('tightBars', 'TANK TALK 2', 24, false)
	tankman:play('tightBars', true)
	table.insert(state.members, table.find(state.members, state.dad) + 1, tankman)

	state.camFollow = {x = state.dad.x + 380, y = state.dad.y + 170}
end

function postCreate()
	bgMusic = game.sound.load(paths.getMusic('gameplay/DISTORTO'), 0.5, true, true)
	bgMusic:play()
	game.camera.zoom = game.camera.zoom * 1.2

	game.sound.play(paths.getSound('gameplay/tankSong2'))
	Timer.tween(4, game.camera, {zoom = state.stage.camZoom * 1.2}, 'in-out-quad')

	cutsceneTimer:after(4, function ()
		Timer.tween(0.5, game.camera, {zoom = state.stage.camZoom * 1.2 * 1.2}, 'in-out-quad')
		state.gf:playAnim('sad', true)
	end)

	cutsceneTimer:after(4.5, function ()
		Timer.tween(1, game.camera, {zoom = state.stage.camZoom * 1.2}, 'in-out-quad')
	end)

	cutsceneTimer:after(11.5, function ()
		tankman:destroy()
		state.dad.alpha = 1
		state.camHUD.visible = true

		local times = PlayState.conductor.crochet / 1000 * 4.5
		Timer.tween(times, game.camera, {zoom = state.stage.camZoom}, 'in-out-quad')
		state:startCountdown()
	end)
end

function songStart()
	bgMusic:stop()
	close()
end

function update(dt) cutsceneTimer:update(dt) end
