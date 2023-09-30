local State = Group:extend()

function State:new()
    State.super.new(self)

    self.persistentUpdate = false
    self.persistentDraw = true
end

function State:update(dt) State.super.update(self, dt) end

function State:openSubState(subState)
    self.subState = subState
    subState.__parentState = self
    Gamestate.push(subState)
end

function State:closeSubState()
    if self.subState then
        Gamestate.pop(table.find(Gamestate.stack, self.subState))
        self.subState = nil
    end
end

return State
