local App = require "project"

function love.conf(t)
    t.identity = App.package
    t.console = App.DEBUG_MODE

    t.window.title = App.title
    t.window.icon = App.icon
    t.window.width = App.width
    t.window.height = App.height
    t.window.resizable = true
    t.window.vsync = false

    t.modules.physics = false
    t.modules.touch = false
    t.modules.video = false
end
