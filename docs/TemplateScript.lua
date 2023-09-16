--- gets called BEFORE registering all of the variables and creating objects, used for creating objects
function create() end

--- gets called AFTER registering all of the variables and creating objects, used for setting values
function postCreate() end

--- gets called every frame
---@param elapsed integer
function update(elapsed) end

--- gets called every frame AFTER update.super()
---@param elapsed integer
function postUpdate(elapsed) end

--- gets called BEFORE drawing all off the sprites onto the screen
function draw() end

--- gets called AFTER drawing all off the sprites onto the screen
function postDraw() end

--- gets called after the vocals and inst start playing
function songStart() end

--- gets called every stepHit
---@param curStep integer
function step(curStep) end

--- gets called every stepHit AFTER beat.super()
---@param curStep integer
function postStep(curStep) end

--- gets called every beatHit
---@param curBeat integer
function beat(curBeat) end

--- gets called every beatHit AFTER beat.super()
---@param curBeat integer
function postBeat(curBeat) end

--- gets called every noteHit
---@param note table
function goodNoteHit(note) end

--- gets called every noteHit AFTER the note is removed
---@param note table
function postGoodNoteHit(note) end

-- Called before destroying Inst/Vocals 
function leave() end

--- Called after leaving state completely
function postLeave() end
