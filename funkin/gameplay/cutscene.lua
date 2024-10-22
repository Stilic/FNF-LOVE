local Cutscene = Classic:extend("Cutscene")

function Cutscene:new(isEnd, onComplete)
	self.onComplete = onComplete or __NULL__

	self.state = game.getState()
	self.timer = self.state.timer or Timer()

	local songName = paths.formatToSongPath(PlayState.SONG.song)
	local suffix = ""
	if isEnd then suffix = "-end" end

	local fileExist, cutsceneType, cutsceneScript
	for i, path in ipairs({
		paths.getMods('data/cutscenes/' .. songName .. suffix .. '.lua'),
		paths.getMods('data/cutscenes/' .. songName .. suffix .. '.json'),
		paths.getPath('data/cutscenes/' .. songName .. suffix .. '.lua'),
		paths.getPath('data/cutscenes/' .. songName .. suffix .. '.json')
	}) do
		if paths.exists(path, 'file') then
			fileExist = true
			switch(path:ext(), {
				["lua"] = function() cutsceneType = "script" end,
				["json"] = function() cutsceneType = "data" end,
			})
		end
	end
	if fileExist then
		switch(cutsceneType, {
			["script"] = function()
				cutsceneScript = Script('data/cutscenes/' .. songName .. suffix)
				cutsceneScript.errorCallback:addOnce(function()
					print("Cutscene returned a error. Skipping")
					cutsceneScript:close()
				end)
				cutsceneScript.closeCallback:addOnce(function()
					self.onComplete()
				end)

				cutsceneScript:call("create")
				self.state.scripts:add(cutsceneScript)
				if isEnd then cutsceneScript:call("postCreate") end
			end,
			["data"] = function()
				local s, cutsceneData = pcall(paths.getJSON, 'data/cutscenes/' .. songName .. suffix)
				if not s then
					print("Cutscene returned a error. Skipping")
					self.onComplete()
					return
				end

				for i, event in ipairs(cutsceneData.cutscene) do
					self.timer:after(event.time / 1000, function()
						self:execute(event.event, isEnd)
					end)
				end
			end
		})
	else
		self.onComplete()
	end
end

function Cutscene:update(dt)
	if self.state.timer == nil then self.timer:update(dt) end
	Cutscene.super.update(self, dt)
end

function Cutscene:execute(event, isEnd)
	switch(event.name, {
		['Camera Position'] = function()
			local xCam, yCam = event.params[1], event.params[2]
			local isTweening = event.params[3]
			local time = event.params[4]
			local ease = event.params[6] .. '-' .. event.params[5]
			if isTweening then
				game.camera:follow(self.state.camFollow, nil)
				self.timer:tween(time, self.state.camFollow, {x = xCam, y = yCam}, ease)
			else
				self.state.camFollow:set(xCam, yCam)
				game.camera:follow(self.state.camFollow, nil, 2.4 * self.state.camSpeed)
			end
		end,
		['Camera Zoom'] = function()
			local zoomCam = event.params[1]
			local isTweening = event.params[2]
			local time = event.params[3]
			local ease = event.params[5] .. '-' .. event.params[4]
			if isTweening then
				self.timer:tween(time, game.camera, {zoom = zoomCam}, ease)
			else
				game.camera.zoom = zoomCam
			end
		end,
		['Play Sound'] = function()
			local soundPath = event.params[1]
			local volume = event.params[2]
			local isFading = event.params[3]
			local time = event.params[4]
			local volStart, volEnd = event.params[5], event.params[6]

			local sound = game.sound.play(paths.getSound(soundPath), volume)
			if isFading then sound:fade(time, volStart, volEnd) end
		end,
		['Play Animation'] = function()
			local character = nil
			switch(event.params[1], {
				['bf'] = function() character = self.state.boyfriend end,
				['gf'] = function() character = self.state.gf end,
				['dad'] = function() character = self.state.dad end
			})
			local animation = event.params[2]

			if character then character:playAnim(animation, true) end
		end,
		['End Cutscene'] = function()
			game.camera:follow(self.state.camFollow, nil, 2.4 * self.state.camSpeed)
			self.onComplete(event)
		end
	})
end

return Cutscene
