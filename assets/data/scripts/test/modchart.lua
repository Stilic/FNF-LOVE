local ogNotePos = {}

function postCreate()
	for i = 1, #state.receptors.members do
		ogNotePos[i] = {
			x = state.receptors.members[i].x,
			y = state.receptors.members[i].y
		}
	end
end

function onSettingChange(setting)
	if setting == 'gameplay' then
		for i = 1, #state.receptors.members do
			ogNotePos[i] = {
				x = state.receptors.members[i].x,
				y = state.receptors.members[i].y
			}
		end
	end
end

local introBeats = {0, 6, 12, 20, 22, 28, 32, 38, 44, 52, 54, 60, 61, 62, 63}
local noteModchart = {
	offset = {x = 0, y = 0},
	noteY = 0,
	beat = 0,
	sin = 0,
	sin_speed = 1,
	cos = 0,
	cos_speed = 1,
	bounce = 0,
	amount = 0,
	enabled = false
}

function songStart() randomMoveArrow() end

function step()
	if curStep >= 0 and curStep < 128 or curStep >= 512 and curStep < 639 then
		noteModchart.enabled = false
		noteModchart.cos = 0
		noteModchart.cos_speed = 1
		noteModchart.sin = 0
		noteModchart.sin_speed = 1
		if table.find(introBeats, curStep % 64) then
			randomMoveArrow()
		end
	end
	if curStep >= 128 and curStep < 512 or curStep >= 639 then
		if curStep == 128 or curStep == 639 then
			noteModchart.enabled = true
			noteModchart.cos = 6
			noteModchart.cos_speed = 3
			Timer.tween(1.2, noteModchart, {amount = 1}, 'out-circ')
		end
		if curStep == 192 then
			noteModchart.sin_speed = 3
			Timer.tween(stepCrotchet * 0.002, noteModchart, {sin = 6}, 'in-out-sine')
		end
		if curStep == 504 then
			Timer.tween(stepCrotchet * 0.002, noteModchart, {amount = 0}, 'in-out-sine')
		end
		if curStep == 896 then
			Timer.tween(stepCrotchet * 0.002, noteModchart, {sin = 6}, 'in-out-sine')
			Timer.tween(stepCrotchet * 0.002, noteModchart, {noteY = 15}, 'in-out-sine')
		end
		if curStep % 4 == 0 then
			if curStep >= 256 then
				Timer.tween(0.1, noteModchart, {beat = ((curBeat % 2 == 0) and 10 or -10)}, 'in-out-sine', function()
					Timer.tween(0.1, noteModchart, {beat = 0}, 'in-out-sine')
				end)
			end
			if curStep >= 384 and curStep < 512 or curStep >= 768 and curStep < 896 then
				Timer.tween(stepCrotchet * 0.002, noteModchart, {bounce = 10}, 'out-circ', function()
					Timer.tween(stepCrotchet * 0.002, noteModchart, {bounce = 0}, 'in-sine')
				end)
			end
		end
	end
end

local time = 0
function postUpdate(dt)
	time = time + dt
	if noteModchart.enabled then
		local cosAmt = noteModchart.cos
		local sinAmt = noteModchart.sin
		local cosSpeed = noteModchart.cos_speed
		local sinSpeed = noteModchart.sin_speed
		noteModchart.offset.x = math.cos(time * cosSpeed) * cosAmt
		noteModchart.offset.y = math.sin(time * sinSpeed) * sinAmt

		local beatAmt = noteModchart.beat
		noteModchart.offset.x = noteModchart.offset.x + beatAmt

		local bounceAmt = noteModchart.bounce
		noteModchart.offset.y = noteModchart.offset.y + bounceAmt

		local amount = noteModchart.amount
		for i, n in ipairs(state.receptors.members) do
			local noteX = noteModchart.offset.x
			local noteY = noteModchart.offset.y

			local yPos = noteModchart.noteY
			noteY = noteY + (math.sin(time + (i + 10)) * yPos)

			noteX = noteX * amount
			noteY = noteY * amount
			n:setPosition(ogNotePos[i].x - noteX, ogNotePos[i].y - noteY)
		end
	end
end

function randomMoveArrow()
	for i, n in ipairs(state.receptors.members) do
		local randomX = ogNotePos[i].x + love.math.random(-20, 20)
		local randomY = ogNotePos[i].y + love.math.random(-20, 20)
		local randomAngle = love.math.random(-20, 20)
		n:setPosition(randomX, randomY)
		n.angle = randomAngle
		Timer.cancelTweensOf(n)
		Timer.tween(0.4, n, {x = ogNotePos[i].x, y = ogNotePos[i].y, angle = 0}, 'out-circ')
	end
end
