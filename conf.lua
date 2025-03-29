local Project = require "project"

function love.conf(t)
	t.identity = Project.package
	t.console = Project.DEBUG_MODE
	t.gammacorrect = false
	t.highdpi = false

	-- we'll initialize the window in loxel/init.lua
	-- we need it for mobile to not be bugging
	t.modules.window = false
	t.modules.physics = false
end
