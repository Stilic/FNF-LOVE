local bgMusic
local cutsceneTimer
local isVideo = ClientPrefs.data.lowQuality
local cutscene

function create()
	if isVideo then return end
	state.dad.alpha = 0
	state.camHUD.visible, state.camNotes.visible = false, false

	tankman = Sprite(state.dad.x + 100, state.dad.y)
	tankman:setFrames(paths.getSparrowAtlas('stages/tank/cutscenes/'
		.. paths.formatToSongPath(PlayState.SONG.song)))
	tankman:addAnimByPrefix('wellWell', 'TANK TALK 1 P1', 24, false)
	tankman:addAnimByPrefix('killYou', 'TANK TALK 1 P2', 24, false)
	tankman:play('wellWell', true)
	table.insert(state.members, table.find(state.members, state.dad) + 1, tankman)

	state.camFollow:set(state.dad.x + 380, state.dad.y + 170)
end

function postCreate()
	if isVideo then
		cutscene = Video(0, 0, "ughCutscene", true, true)
		cutscene:setScrollFactor()
		cutscene.cameras = {state.camOther}
		cutscene:play()
		state:add(cutscene)
		cutscene.onComplete = function()
			close()
		end
		return
	end
	bgMusic = Sound():load(paths.getMusic('gameplay/DISTORTO'), 0.5, true, true)
	bgMusic:play()
	game.camera.zoom = game.camera.zoom * 1.2

	Timer(timer):start(0.1, function()
		game.sound.play(paths.getSound('gameplay/wellWellWell'), ClientPrefs.data.vocalVolume / 100)
	end)

	Timer(timer):start(3, function()
		state.camFollow.x = state.camFollow.x + 650
		state.camFollow.y = state.camFollow.y + 100
	end)

	Timer(timer):start(4.5, function()
		state.boyfriend:playAnim('singUP', true)
		game.sound.play(paths.getSound('gameplay/bfBeep'), ClientPrefs.data.vocalVolume / 100)
	end)

	Timer(timer):start(5.2, function()
		state.boyfriend:playAnim('idle', true)
	end)

	Timer(timer):start(6, function()
		state.camFollow.x = state.camFollow.x - 650
		state.camFollow.y = state.camFollow.y - 100

		tankman:play('killYou', true)
		tankman.x = tankman.x - 36
		tankman.y = tankman.y - 10
		game.sound.play(paths.getSound('gameplay/killYou'), ClientPrefs.data.vocalVolume / 100)
	end)

	Timer(timer):start(12, function()
		tankman:destroy()
		state.dad.alpha = 1
		state.camHUD.visible, state.camNotes.visible = true, true

		local times = PlayState.conductor.crotchet / 1000 * 4.5
		state.tween:tween(game.camera, {zoom = state.stage.camZoom}, times, {ease = 'quadInOut'})
		close()
	end)
end

function songStart()
	if not isVideo then bgMusic:stop(); close() end
end

function pause() if isVideo then cutscene:pause() end end

function substateClosed() if isVideo then cutscene:play() end end
