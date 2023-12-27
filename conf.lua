local Project = require "project"

function love.conf(t)
	t.identity = Project.company
	t.console = Project.DEBUG_MODE
	t.gammacorrect = false
	t.highdpi = false
	t.renderers = {"metal", "opengl"}
	t.excluderenderers = {"vulkan"}

	t.window = nil -- we'll initialize it in run.lua

	t.modules.physics = false
	t.modules.touch = false
	t.modules.video = false
end
