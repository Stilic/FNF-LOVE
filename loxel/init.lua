local dimensions = require "dimensions"
game = {width = dimensions.width, height = dimensions.height}

Object = require "lib.classic"
Gamestate = require "lib.gamestate"

Basic = require "loxel.basic"
Camera = require "loxel.camera"
Sprite = require "loxel.sprite"
Sound = require "loxel.sound"
Text = require "loxel.text"
Bar = require "loxel.ui.bar"
Group = require "loxel.group.group"
SpriteGroup = require "loxel.group.spritegroup"
State = require "loxel.state"
SubState = require "loxel.substate"
Flicker = require "loxel.effects.flicker"

Keyboard = require "loxel.input.keyboard"
Mouse = require "loxel.input.mouse"
ui = {
    UIButton = require "loxel.ui.button",
    UICheckbox = require "loxel.ui.checkbox",
    UIDropDown = require "loxel.ui.dropdown",
    UIGrid = require "loxel.ui.grid",
    UIInputTextBox = require "loxel.ui.inputtextbox",
    UINumericStepper = require "loxel.ui.numericstepper",
    UITabMenu = require "loxel.ui.tabmenu",
    UISlider = require "loxel.ui.slider"
}

game.cameras = require "loxel.managers.cameramanager"
game.sound = require "loxel.managers.soundmanager"
game.cameras.reset()
