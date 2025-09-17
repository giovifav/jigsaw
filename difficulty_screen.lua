local difficulty = require "difficulty"
local lang = require "lang"
local ui = require "ui"

local DifficultyScreen = {}

local hovered = nil

function DifficultyScreen.draw()
    difficulty.draw()
    -- Tooltip
    if hovered then
        local i = nil
        for idx, n2 in ipairs(difficulty.levels) do if n2 == hovered then i = idx end end
        if i then
            local y = 300 + (i-1)*90
            local wbtn = 320
            local hbtn = 70
            local x = love.graphics.getWidth()/2 - wbtn/2
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
            local tx = math.max(10, math.min(x + wbtn/2 - tw/2, love.graphics.getWidth()-tw-10))
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
        end
    end
end

function DifficultyScreen.mousepressed(x, y, button, changeStateWithFade)
    -- Menu Button
    local btnMenuW, btnMenuH = 120, 48
    local btnMenuX, btnMenuY = 20, 20
    if x >= btnMenuX and x <= btnMenuX+btnMenuW and y >= btnMenuY and y <= btnMenuY+btnMenuH then
        if changeStateWithFade then changeStateWithFade("menu") end
        return "back"
    end
    -- Pause Button
    local btnW, btnH = 120, 48
    local btnX = love.graphics.getWidth() - btnW - 30
    local btnY = 20
    if x >= btnX and x <= btnX+btnW and y >= btnY and y <= btnY+btnH then
        if changeStateWithFade then changeStateWithFade("pausa") end
        return false
    end
    return difficulty.mousepressed(x, y, button)
end

function DifficultyScreen.wheelmoved(x, y) end
function DifficultyScreen.mousemoved(x, y, dx, dy) end
function DifficultyScreen.mousereleased(x, y, button) end
function DifficultyScreen.touchpressed(id, x, y, dx, dy, pressure) end
function DifficultyScreen.touchmoved(id, x, y, dx, dy, pressure) end
function DifficultyScreen.touchreleased(id, x, y, dx, dy, pressure) end

function DifficultyScreen.update(dt, changeStateWithFade)
    -- Update hovered
    hovered = nil
    local mx, my = love.mouse.getPosition()
    for i, n in ipairs(difficulty.levels) do
        local y = 300 + (i-1)*90
        local wbtn = 320
        local hbtn = 70
        local x = love.graphics.getWidth()/2 - wbtn/2
        local isHover = mx >= x and mx <= x+wbtn and my >= y and my <= y+hbtn
        if isHover then hovered = n end
    end
end

function DifficultyScreen.keypressed(key)
    -- Funzione vuota per compatibilità
end

return DifficultyScreen 