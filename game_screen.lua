local puzzle = require "puzzle"
local ui = require "ui"
local lang = require "lang"

local GameScreen = {}

function GameScreen.draw()
    puzzle.draw()
    -- Menu Button
    local btnMenuW, btnMenuH = 120, 48
    local btnMenuX, btnMenuY = 20, 20
    ui.drawButton(btnMenuX, btnMenuY, btnMenuW, btnMenuH, lang.t("menu"), nil, {fontSize=16, radius=9})
    -- Pause Button
    local btnW, btnH = 120, 48
    local btnX = love.graphics.getWidth() - btnW - 30
    local btnY = 20
    ui.drawButton(btnX, btnY, btnW, btnH, lang.t("pausa"), nil, {fontSize=16, radius=9})
    love.graphics.setColor(1,1,1,1)
end

function GameScreen.initCallbacks(changeStateWithFade, setLastResult)
    puzzle.on("onWin", function()
        print("[DEBUG] onWin CALLBACK TRIGGERED!")
        print("VITTORIA! Cambio stato a leaderboard")
        -- Aggiorna la leaderboard e passa allo stato leaderboard
        local timer, moves, _, hardcore = puzzle.getStats()
        local insert_id = os.time()
        print("[DEBUG] Timer: " .. timer .. ", Moves: " .. moves .. ", Hardcore: " .. tostring(hardcore))
        if setLastResult then
            setLastResult({time = timer, moves = moves, hardcore = hardcore, insert_id = insert_id})
            print("[DEBUG] setLastResult called")
        end
        puzzle.addToLeaderboard(timer, moves, insert_id)
        if changeStateWithFade then
            print("[DEBUG] changeStateWithFade called with 'leaderboard'")
            changeStateWithFade("leaderboard")
        else
            print("[WARNING] changeStateWithFade non disponibile, uso fallback")
            -- Fallback nel caso in cui la funzione non sia disponibile
            _G.state = "leaderboard"
            state = "leaderboard"
        end
    end)
    puzzle.on("onLoad", function()
        -- Qui puoi resettare popup, messaggi, ecc. se serve
        -- (esempio: nascondi popup di vittoria)
    end)
    puzzle.on("onMove", function()
        -- Qui puoi aggiornare la UI, suoni, ecc. dopo ogni mossa
        -- (esempio: aggiornare un contatore mosse personalizzato)
    end)
end

function GameScreen.update(dt, changeStateWithFade, setLastResult)
    -- Inizializza i callback solo la prima volta
    if not GameScreen._callbacksSet then
        GameScreen.initCallbacks(changeStateWithFade, setLastResult)
        GameScreen._callbacksSet = true
    end
    puzzle.update(dt)
    -- La logica di vittoria e cambio stato ora è gestita dal callback onWin
end

function GameScreen.mousepressed(x, y, button, changeStateWithFade)
    -- Menu Button
    local btnMenuW, btnMenuH = 120, 48
    local btnMenuX, btnMenuY = 20, 20
    if x >= btnMenuX and x <= btnMenuX+btnMenuW and y >= btnMenuY and y <= btnMenuY+btnMenuH then
        if changeStateWithFade then changeStateWithFade("menu") end
        return true
    end
    -- Pause Button
    local btnW, btnH = 120, 48
    local btnX = love.graphics.getWidth() - btnW - 30
    local btnY = 20
    if x >= btnX and x <= btnX+btnW and y >= btnY and y <= btnY+btnH then
        if changeStateWithFade then changeStateWithFade("pausa") end
        return true
    end
    puzzle.mousepressed(x, y, button)
    return false
end

function GameScreen.wheelmoved(x, y) end
function GameScreen.mousemoved(x, y, dx, dy) end
function GameScreen.mousereleased(x, y, button) end
function GameScreen.touchpressed(id, x, y, dx, dy, pressure) end
function GameScreen.touchmoved(id, x, y, dx, dy, pressure) end
function GameScreen.touchreleased(id, x, y, dx, dy, pressure) end

function GameScreen.keypressed(key)
    -- Gestione dei tasti (vuota per ora)
end

return GameScreen
