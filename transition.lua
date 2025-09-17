local Transition = {
    active = false,
    alpha = 0,
    direction = 1, -- 1 = fade out, -1 = fade in
    nextState = nil,
    speed = 2 -- velocità del fade (secondi per completare)
}

function Transition.update(dt, onStateChange)
    if not Transition.active then return end
    Transition.alpha = Transition.alpha + dt * Transition.speed * Transition.direction
    if Transition.direction == 1 and Transition.alpha >= 1 then
        print("[DEBUG] Transition.update: chiamata onStateChange con", Transition.nextState)
        Transition.alpha = 1
        if onStateChange and Transition.nextState then
            onStateChange(Transition.nextState)
        end
        Transition.direction = -1
    elseif Transition.direction == -1 and Transition.alpha <= 0 then
        print("[DEBUG] Transition.update: fine transizione")
        Transition.alpha = 0
        Transition.active = false
    end
end

function Transition.drawOverlay()
    if not Transition.active or Transition.alpha <= 0 then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local grad = love.graphics.newMesh({
        {0,0, 0,0, 0.96,0.97,0.98,1},
        {w,0, 1,0, 0.92,0.93,0.95,1},
        {w,h, 1,1, 0.89,0.89,0.91,1},
        {0,h, 0,1, 0.98,0.98,0.99,1}
    }, "fan")
    love.graphics.setColor(1,1,1,Transition.alpha)
    love.graphics.draw(grad,0,0)
    love.graphics.setColor(1,1,1,1)
end

function Transition.start(newState)
    print("[DEBUG] Transition.start verso:", newState)
    if not Transition.active then
        Transition.active = true
        Transition.alpha = 0
        Transition.direction = 1
        Transition.nextState = newState
    end
end

return Transition 