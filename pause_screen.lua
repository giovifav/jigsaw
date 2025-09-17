local ui = require "ui"
local lang = require "lang"
local puzzle = require "puzzle"
local GameScreen = require "game_screen"

local PauseScreen = {}
PauseScreen.changeStateWithFade = nil -- to be set from main

function PauseScreen.draw()
    -- Prima disegna il gioco sottostante
    GameScreen.draw()
    -- Poi disegna lo sfondo trasparente e il popup
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0,0,0,0.45)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1,1,1,1)
    local pw, ph = 420, 220
    local px, py = (w-pw)/2, (h-ph)/2
    ui.drawWindow(px, py, pw, ph, lang.t("pausa"), {titleFontSize=36, radius=9})
    ui.setFont(26)
    local timer, moves = puzzle.getStats()
    local tmin = math.floor(timer/60)
    local tsec = math.floor(timer%60)
    local tstr = string.format("%02d:%02d", tmin, tsec)
    love.graphics.setColor(0,0,0,1)
    love.graphics.printf(lang.t("tempo")..": "..tstr, px, py+80, pw, "center")
    love.graphics.printf(lang.t("mosse")..": "..moves, px, py+120, pw, "center")
    ui.setFont(18)
    local btnW, btnH = 180, 54
    local btnX = w/2 - btnW/2
    local btnY = py+ph-70
    ui.drawButton(btnX, btnY, btnW, btnH, lang.t("riprendi"), nil, {fontSize=18, radius=9})
    love.graphics.setColor(1,1,1,1)
end

function PauseScreen.mousepressed(x, y, button)
    print("DEBUG: click su pausa", x, y, button)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local pw, ph = 420, 220
    local px, py = (w-pw)/2, (h-ph)/2
    local btnW, btnH = 180, 54
    local btnX = w/2 - btnW/2
    local btnY = py+ph-70
    print("DEBUG: bottone riprendi da", btnX, btnY, "a", btnX+btnW, btnY+btnH)
    if button ~= 1 then return end
    if x >= btnX and x <= btnX+btnW and y >= btnY and y <= btnY+btnH then
        print("DEBUG: click sul bottone riprendi")
        puzzle.saveState() -- Salva la partita quando si mette in pausa
        if PauseScreen.changeStateWithFade then
            PauseScreen.changeStateWithFade("gioco")
        end
        _G.state = "gioco"
        if state then state = "gioco" end
        return
    end
end

function PauseScreen.wheelmoved(x, y) end
function PauseScreen.mousemoved(x, y, dx, dy) end
function PauseScreen.mousereleased(x, y, button) end
function PauseScreen.touchpressed(id, x, y, dx, dy, pressure) end
function PauseScreen.touchmoved(id, x, y, dx, dy, pressure) end
function PauseScreen.touchreleased(id, x, y, dx, dy, pressure) end

function PauseScreen.keypressed(key)
    -- Funzione vuota per compatibilità
end

return PauseScreen 