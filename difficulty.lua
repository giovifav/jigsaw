local difficulty = {}
local lang = require "lang"
local sound = require "sound"
local ui = require "ui"

difficulty.levels = {3, 4, 5, 6, 7, 8}
difficulty.selectedN = 3
difficulty.hardcore = false
local hovered = nil

function difficulty.draw()
    -- Sfondo sfumato chiaro
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(1,1,1,1)
    local grad = love.graphics.newMesh({
        {0,0, 0,0, 0.96,0.97,0.98,1},
        {w,0, 1,0, 0.92,0.93,0.95,1},
        {w,h, 1,1, 0.89,0.89,0.91,1},
        {0,h, 0,1, 0.98,0.98,0.99,1}
    }, "fan")
    love.graphics.draw(grad,0,0)
    love.graphics.setColor(1,1,1,1)

    -- Titolo
    ui.setFont(32)
    love.graphics.setColor(0,0,0,1)
    love.graphics.printf(lang.t("scegli_difficolta"), 0, 180, w, "center")
    love.graphics.setColor(1,1,1,1)
    ui.setFont(24)
    hovered = nil
    local mx, my = love.mouse.getPosition()
    for i, n in ipairs(difficulty.levels) do
        local y = 300 + (i-1)*90
        local wbtn = 320
        local hbtn = 70
        local x = w/2 - wbtn/2
        local isHover = mx >= x and mx <= x+wbtn and my >= y and my <= y+hbtn
        local stato = nil
        if n == difficulty.selectedN then stato = "selected" elseif isHover then stato = "hover" end
        ui.drawButton(x, y, wbtn, hbtn, (n==3 and lang.t("facile") or n==4 and lang.t("normale") or n==5 and lang.t("difficile") or n==6 and lang.t("esperto") or n==7 and lang.t("maestro") or n==8 and lang.t("genio") or (n.."x"..n)), stato, {fontSize=24, radius=9, lineWidth=(stato and 5 or 2)})
        if isHover then hovered = n end
    end
    -- Checkbox Modalità Hardcore
    local cbSize = 38
    local cbX = w/2 - 160
    local cbY = 300 + #difficulty.levels*90 + 24
    local label = "Modalità Hardcore"
    ui.drawCheckbox(cbX, cbY, cbSize, difficulty.hardcore, label, {fontSize=22})
    -- Hover su checkbox o testo
    local labelFontSize = 22
    local labelWidth = love.graphics.getFont():getWidth(label)
    local isHoverCheckbox = mx >= cbX and mx <= cbX+cbSize and my >= cbY and my <= cbY+cbSize
    local isHoverLabel = mx >= cbX+cbSize+16 and mx <= cbX+cbSize+16+labelWidth and my >= cbY and my <= cbY+cbSize
    -- Pulsante Indietro
    local btnW, btnH = 180, 54
    local btnX, btnY = 40, love.graphics.getHeight() - btnH - 40
    ui.drawButton(btnX, btnY, btnW, btnH, lang.t("indietro"), nil, {fontSize=24, radius=9})
    -- Pulsante Inizia
    local btnStartW, btnStartH = 180, 54
    local btnStartX = love.graphics.getWidth() - btnStartW - 40
    local btnStartY = love.graphics.getHeight() - btnH - 40
    ui.drawButton(btnStartX, btnStartY, btnStartW, btnStartH, lang.t("inizia"), nil, {fontSize=24, radius=9})
    love.graphics.setFont(_G.caviarFont[18])
    -- Tooltip
    if hovered then
        local i = nil
        for idx, n2 in ipairs(difficulty.levels) do if n2 == hovered then i = idx end end
        if i then
            local y = 300 + (i-1)*90
            local wbtn = 320
            local hbtn = 70
            local x = w/2 - wbtn/2
            local text = nil
            if hovered == 3 then text = lang.t("facile")
            elseif hovered == 4 then text = lang.t("normale")
            elseif hovered == 5 then text = lang.t("difficile")
            elseif hovered == 6 then text = lang.t("esperto")
            elseif hovered == 7 then text = lang.t("maestro")
            elseif hovered == 8 then text = lang.t("genio")
            else text = hovered.."x"..hovered end
            local tw = love.graphics.getFont():getWidth(text) + 24
            local th = 38
            local tx = math.max(10, math.min(x + wbtn/2 - tw/2, w-tw-10))
            local ty = y + hbtn + 12
            local grad = love.graphics.newMesh({
                {0,0, 0,0, 0.96,0.97,0.98,0.92},
                {tw,0, 1,0, 0.92,0.93,0.95,0.92},
                {tw,th, 1,1, 0.89,0.89,0.91,0.92},
                {0,th, 0,1, 0.98,0.98,0.99,0.92}
            }, "fan")
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(grad, tx, ty)
            love.graphics.setColor(0,0,0,1)
            love.graphics.printf(text, tx, ty+8, tw, "center")
            love.graphics.setColor(1,1,1,1)
        end
    end
    if isHoverCheckbox or isHoverLabel then
        local text = lang.t("hardcore_tooltip")
        local tw = love.graphics.getFont():getWidth(text) + 24
        local th = 44
        local tx = math.max(10, math.min(cbX + cbSize/2 - tw/2, w-tw-10))
        local ty = cbY + cbSize + 12
        local grad = love.graphics.newMesh({
            {0,0, 0,0, 0.96,0.97,0.98,0.92},
            {tw,0, 1,0, 0.92,0.93,0.95,0.92},
            {tw,th, 1,1, 0.89,0.89,0.91,0.92},
            {0,th, 0,1, 0.98,0.98,0.99,0.92}
        }, "fan")
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(grad, tx, ty)
        love.graphics.setColor(0,0,0,1)
        love.graphics.printf(text, tx, ty+8, tw, "center")
        love.graphics.setColor(1,1,1,1)
    end
end

function difficulty.mousepressed(x, y, button)
    local w = love.graphics.getWidth()
    -- Pulsante Indietro
    local btnW, btnH = 180, 54
    local btnX, btnY = 40, love.graphics.getHeight() - btnH - 40
    if x >= btnX and x <= btnX+btnW and y >= btnY and y <= btnY+btnH then
        sound.play('button')
        return "back"
    end
    -- Pulsante Inizia
    local btnStartW, btnStartH = 180, 54
    local btnStartX = love.graphics.getWidth() - btnStartW - 40
    local btnStartY = love.graphics.getHeight() - btnH - 40
    if x >= btnStartX and x <= btnStartX+btnStartW and y >= btnStartY and y <= btnStartY+btnStartH then
        sound.play('button')
        return "start"
    end
    -- Gestione click checkbox Modalità Hardcore
    local cbSize = 38
    local cbX = w/2 - 160
    local cbY = 300 + #difficulty.levels*90 + 24
    if x >= cbX and x <= cbX+cbSize and y >= cbY and y <= cbY+cbSize then
        sound.play('button')
        difficulty.hardcore = not difficulty.hardcore
        return false
    end
    for i, n in ipairs(difficulty.levels) do
        local ybtn = 300 + (i-1)*90
        local wbtn = 320
        local hbtn = 70
        local xbtn = w/2 - wbtn/2
        if x >= xbtn and x <= xbtn+wbtn and y >= ybtn and y <= ybtn+hbtn then
            sound.play('button')
            difficulty.selectedN = n
            return false
        end
    end
    return false
end

return difficulty 