local UIState = State:extend("UIState")

-- for new loxel ui testing
-- Fellyn

function UIState:enter()
    self.uiButton = newUI.UIButton(10, 60)
    self:add(self.uiButton)
end

return UIState