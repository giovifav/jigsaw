local SplashScreen = {
    active = true,
    timer = 0,
    duration = 2.5, -- durata totale splash
    fade = 1.2,     -- durata fade in/out aumentata
    logo = nil,
    onEnd = nil,    -- funzione callback da chiamare alla fine
}

function SplashScreen.update(dt)
    if not SplashScreen.active then return end
    SplashScreen.timer = SplashScreen.timer + dt
    if SplashScreen.timer >= SplashScreen.duration then
        SplashScreen.active = false
        if SplashScreen.onEnd then SplashScreen.onEnd() end
    end
end

function SplashScreen.draw()
    if not SplashScreen.active then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local alpha = 1
    local fadeIn = SplashScreen.timer < SplashScreen.fade
    local fadeOut = SplashScreen.timer > SplashScreen.duration - SplashScreen.fade
    if fadeIn then
        alpha = SplashScreen.timer / SplashScreen.fade
    elseif fadeOut then
        alpha = 1 - (SplashScreen.timer - (SplashScreen.duration - SplashScreen.fade)) / SplashScreen.fade
    end
    -- Splashscreen con gradiente chiaro
    local grad = love.graphics.newMesh({
        {0,0, 0,0, 0.96,0.97,0.98,1},
        {w,0, 1,0, 0.92,0.93,0.95,1},
        {w,h, 1,1, 0.89,0.89,0.91,1},
        {0,h, 0,1, 0.98,0.98,0.99,1}
    }, "fan")
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad,0,0)
    -- Logo
    if SplashScreen.logo then
        local lw, lh = SplashScreen.logo:getWidth(), SplashScreen.logo:getHeight()
        local scale = math.min(w*0.5/lw, h*0.5/lh, 1)
        love.graphics.setColor(1,1,1,alpha)
        love.graphics.draw(SplashScreen.logo, (w-lw*scale)/2, (h-lh*scale)/2, 0, scale, scale)
    end
    love.graphics.setColor(1,1,1,1)
end

function SplashScreen.skip()
    SplashScreen.active = false
    if SplashScreen.onEnd then SplashScreen.onEnd() end
end

function SplashScreen.mousepressed(x, y, button)
    SplashScreen.skip()
end

return SplashScreen 