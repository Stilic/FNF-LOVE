local Cutscene = Classic:extend("Cutscene")

function Cutscene:new(isEnd, onComplete)
	self.onComplete = onComplete

	self.state = game.getState()

	self.timer = TimerManager()
	self.tween = Tween()

	local name = paths.formatToSongPath(PlayState.SONG.song)
	if isEnd then name = name .. "-end" end

	self.isEnd = isEnd

	local fileExist, cutsceneType, cutsceneScript
	for _, path in ipairs({
		paths.getMods("data/cutscenes/" .. name .. ".lua"),
		paths.getMods("data/cutscenes/" .. name .. ".json"),
		paths.getPath("data/cutscenes/" .. name .. ".lua"),
		paths.getPath("data/cutscenes/" .. name .. ".json")
	}) do
		if paths.exists(path, "file") then
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
				cutsceneScript = Script("data/cutscenes/" .. name)
				cutsceneScript.errorCallback:add(function()
					print("Cutscene returned a error. Skipping")
					cutsceneScript:close()
				end)
				cutsceneScript.closeCallback:add(function()
					if self.onComplete then self.onComplete() end
				end)

				cutsceneScript:call("create")
				if isEnd then cutsceneScript:call("postCreate") end

				self.state.scripts:add(cutsceneScript)
				cutsceneScript:set("timer", self.timer)
				cutsceneScript:set("tween", self.tween)
			end,
			["data"] = function()
				local s, data = pcall(paths.getJSON, "data/cutscenes/" .. name)
				if not s then
					print("JSON cutscene returned a error. Skipping")
					if self.onComplete then self.onComplete() end
					return
				end

				for i, event in ipairs(data.cutscene) do
					Timer(self.timer):start(event.time / 1000, function()
						self:execute(event.event)
					end)
				end
			end
		})
	else
		self.onComplete()
		self:destroy()
	end
end

function Cutscene:update(dt)
	self.timer:update(dt)
	self.tween:update(dt)
end

function Cutscene:destroy()
	self.timer:clear()
	self.tween:clear()
end

function Cutscene:execute(event, isEnd)
	switch(event.name, {
		['Camera Position'] = function()
			local xCam, yCam = event.params[1], event.params[2]
			local isTweening = event.params[3]
			local time = event.params[4]
			local ease = event.params[5]
			if isTweening then
				game.camera:follow(self.camFollow, nil)
				Tween.tween(self.camFollow, {x = xCam, y = yCam}, time, {ease = Ease[ease]})
			else
				self.state.camFollow:set(xCam, yCam)
				game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
			end
		end,
		['Camera Zoom'] = function()
			local zoomCam = event.params[1]
			local isTweening = event.params[2]
			local time = event.params[3]
			local ease = event.params[4]
			if isTweening then
				Tween.tween(game.camera, {zoom = zoomCam}, time, {ease = Ease[ease]})
			else
				game.camera.zoom = zoomCam
			end
		end,
		["Play Sound"] = function()
			local soundPath = event.params[1]
			local volume = event.params[2]
			local isFading = event.params[3]
			local time = event.params[4]
			local volStart, volEnd = event.params[5], event.params[6]

			local sound = game.sound.play(paths.getSound(soundPath), volume)
			if isFading then sound:fade(time, volStart, volEnd) end
		end,
		["Play Animation"] = function()
			local character, nf, anim = nil, self.state.notefields, event.params[2]
			switch(event.params[1], {
				[{"bf", "boyfriend", "player"}] = function() character = nf[1].character end,
				[{"gf", "girlfriend", "bystander"}] = function() character = nf[3].character end,
				[{"dad", "enemy", "opponent"}] = function() character = nf[2].character end
			})
			if character then character:playAnim(anim, true) end
		end,
		["End Cutscene"] = function()
			game.camera:follow(self.state.camFollow, nil, 2.4 * self.state.camSpeed)
			if self.onComplete then self.onComplete() end
		end
	})
end

return Cutscene
