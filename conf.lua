local Application = require "project"

function love.conf(t)
    t.identity = Application.package
    t.console = Application.DEBUG_MODE

    t.window.title = Application.title
    t.window.icon = Application.icon
    t.window.width = Application.width
    t.window.height = Application.height
    t.window.resizable = true
    t.window.vsync = false

    t.modules.physics = false
    t.modules.touch = false
    t.modules.video = false
end
