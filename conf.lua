local Project = require "project"

function love.conf(t)
    t.identity = Project.package
    t.console = Project.DEBUG_MODE

    t.window.title = Project.title
    t.window.icon = Project.icon
    t.window.width = Project.width
    t.window.height = Project.height
    t.window.resizable = true
    t.window.vsync = false

    t.modules.physics = false
    t.modules.touch = false
    t.modules.video = false
end
