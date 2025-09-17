local puzzle = require "puzzle"
local menu = require "menu"
local difficulty = require "difficulty"
local utils = require "utils"
local lang = require "lang"
local music = require "music"
local sound = require "sound"
local ui = require "ui"
local SplashScreen = require "splash"
local Transition = require "transition"
local LeaderboardScreen = require "leaderboard_screen"
local ResumePopupScreen = require "resume_popup_screen"
local PauseScreen = require "pause_screen"
local DifficultyScreen = require "difficulty_screen"
local GameScreen = require "game_screen"

local function setLastResult(val)
    lastResult = val
    LeaderboardScreen.lastResult = val
    -- Imposta i riferimenti per la leaderboard
    LeaderboardScreen.selectedImage = selectedImage
    LeaderboardScreen.pendingStartN = pendingStartN
    LeaderboardScreen.startPuzzle = startPuzzle
    LeaderboardScreen.changeStateWithFade = changeStateWithFade
end

local function changeStateWithFade(newState)
    print("[DEBUG] changeStateWithFade chiamata con:", newState, "stato attuale:", state, "Transition.active:", Transition.active)
    if state ~= newState and not Transition.active then
        print("[DEBUG] Avvio transizione verso:", newState)
        Transition.start(newState)
    else
        print("[DEBUG] Cambio stato diretto:", newState)
        state = newState
        _G.state = newState
    end
end

-- Forza la registrazione del callback di vittoria
GameScreen.initCallbacks(changeStateWithFade, setLastResult)

local state = "menu" -- "menu", "difficolta", "gioco", "resume_popup", "pausa", "leaderboard"
_G.state = state
local selectedImage = nil
local pendingStartN = nil
local hasSave = false
local lastResult = nil -- Per evidenziare il risultato appena ottenuto
local _showClearLeaderboardConfirm = false
local lastInsertId = 0

function love.load()
    love.window.setTitle("Jigsaw Puzzle")
    love.window.setMode(1024, 1024, {resizable=true})
    menu.loadImages()
    SplashScreen.logo = love.graphics.newImage("assets/logo.png")
    SplashScreen.active = true
    SplashScreen.timer = 0
    SplashScreen.onEnd = function()
        state = "menu"
        print("CAMBIO STATO: state = menu")
        _G.state = state
        print("CAMBIO STATO: _G.state = menu")
        if not music.isMuted() then
            music.playRandom()
        end
    end
    music.load()
    music.stop() -- ferma la musica durante lo splash
    sound.load()
    -- Carica i font tramite ui.loadFonts()
    ui.loadFonts()
    _G.caviarFont = ui.fonts
    ResumePopupScreen.changeStateWithFade = changeStateWithFade
    PauseScreen.changeStateWithFade = changeStateWithFade
end

function startPuzzle(imgName, n, reset, hardcore)
    if _G.state == "leaderboard" then
        print("startPuzzle bloccato: siamo in leaderboard")
        return
    end
    print("START PUZZLE", imgName, n, reset, hardcore)
    selectedImage = imgName
    pendingStartN = n
    if not reset then
        local safeName = imgName:gsub("/", "__")
        local fname = "save_"..safeName..".json"
        if love.filesystem.getInfo(fname) then
            hasSave = true
            ResumePopupScreen.selectedImage = imgName
            ResumePopupScreen.pendingStartN = n
            ResumePopupScreen.pendingHardcore = hardcore
            state = "resume_popup"
            print("CAMBIO STATO: state = resume_popup")
            _G.state = "resume_popup"
            print("CAMBIO STATO: _G.state = resume_popup")
            return
        end
    end
    if imgName:match("^user_images/") then
        puzzle.load(imgName, n, hardcore)
    else
        puzzle.load("img/"..imgName, n, hardcore)
    end
    state = "gioco"
    print("CAMBIO STATO: state = gioco")
    _G.state = "gioco"
    print("CAMBIO STATO: _G.state = gioco")
end

-- Patch robusta: aggiorna lo stato quando la transizione termina
local function transitionUpdate(dt)
    SplashScreen.update(dt)
    if SplashScreen.active then return end
    music.update(dt)
    if Transition.active then
        Transition.update(dt, function(newState)
            print("[DEBUG] Transizione completata: Cambio stato da '" .. state .. "' a '" .. newState .. "'")
            state = newState
            print("CAMBIO STATO: state =", newState)
            _G.state = newState
            print("CAMBIO STATO: _G.state =", newState)
        end)
    end
end

function love.update(dt)
    transitionUpdate(dt)
    state = _G.state
    if ResumePopupScreen.locked and state ~= "resume_popup" then
        ResumePopupScreen.locked = false
    end
    if Transition.active then return end
    if state == "gioco" then
        GameScreen.update(dt, changeStateWithFade, function(result)
            lastInsertId = lastInsertId + 1
            result.insert_id = lastInsertId
            setLastResult(result)
        end)
    elseif state == "difficolta" then
        DifficultyScreen.update(dt, changeStateWithFade)
    end
    -- _G.state = state  (rimossa)
    -- print("CAMBIO STATO: _G.state =", state) (rimossa)
end

function love.draw()
    if SplashScreen.active then
        SplashScreen.draw()
        return
    end
    if _G.state == "difficolta" then
        DifficultyScreen.draw()
    elseif _G.state == "menu" then
        menu.draw()
    elseif _G.state == "gioco" then
        GameScreen.draw()
    elseif _G.state == "leaderboard" then
        LeaderboardScreen.draw()
    elseif _G.state == "resume_popup" then
        menu.draw() -- Mostra il menu sotto il popup
        ResumePopupScreen.draw()
    elseif _G.state == "pausa" then
        PauseScreen.draw()
    end
    -- Disegna il gradiente di fade sopra la schermata se la transizione è attiva
    Transition.drawOverlay()
end

function love.mousepressed(x, y, button)
    if Transition.active then
        return
    end
    if SplashScreen.active then
        SplashScreen.mousepressed(x, y, button)
        return
    end
    -- Blocca input al menu se il popup impostazioni è aperto
    if state == "menu" and menu.showSettings and button == 1 then
        menu.mousepressed(x, y, button)
        return
    end
    if state == "resume_popup" and button == 1 then
        ResumePopupScreen.mousepressed(x, y, button)
        return
    end
    if state == "menu" and button == 1 then
        local img = menu.mousepressed(x, y, button)
        if img then
            selectedImage = img
            changeStateWithFade("difficolta")
        end
    elseif state == "difficolta" and button == 1 then
        local result = DifficultyScreen.mousepressed(x, y, button, changeStateWithFade)
        if result == "back" then
            changeStateWithFade("menu")
            return
        elseif result == "start" then
            print("PREMO INIZIA", selectedImage, difficulty.selectedN, difficulty.hardcore)
            if selectedImage then
                startPuzzle(selectedImage, difficulty.selectedN, false, difficulty.hardcore)
            end
            return
        end
    elseif state == "gioco" and button == 1 then
        GameScreen.mousepressed(x, y, button, changeStateWithFade)
    elseif state == "leaderboard" and button == 1 then
        LeaderboardScreen.mousepressed(x, y, button)
    elseif state == "pausa" and button == 1 then
        PauseScreen.mousepressed(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if state == "menu" then
        menu.wheelmoved(x, y)
    elseif state == "difficolta" then
        DifficultyScreen.wheelmoved(x, y)
    elseif state == "gioco" then
        GameScreen.wheelmoved(x, y)
    elseif state == "leaderboard" then
        LeaderboardScreen.wheelmoved(x, y)
    elseif state == "pausa" then
        PauseScreen.wheelmoved(x, y)
    end
end

function love.mousemoved(x, y, dx, dy)
    if state == "menu" then
        menu.mousemoved(x, y, dx, dy)
    elseif state == "difficolta" then
        DifficultyScreen.mousemoved(x, y, dx, dy)
    elseif state == "gioco" then
        GameScreen.mousemoved(x, y, dx, dy)
    elseif state == "leaderboard" then
        LeaderboardScreen.mousemoved(x, y, dx, dy)
    elseif state == "pausa" then
        PauseScreen.mousemoved(x, y, dx, dy)
    end
end

function love.mousereleased(x, y, button)
    if state == "menu" then
        menu.mousereleased(x, y, button)
    elseif state == "difficolta" then
        DifficultyScreen.mousereleased(x, y, button)
    elseif state == "gioco" then
        GameScreen.mousereleased(x, y, button)
    elseif state == "leaderboard" then
        LeaderboardScreen.mousereleased(x, y, button)
    elseif state == "resume_popup" then
        ResumePopupScreen.mousereleased(x, y, button)
    elseif state == "pausa" then
        PauseScreen.mousereleased(x, y, button)
    end
end

function love.keypressed(key)
    if state == "menu" then
        menu.keypressed(key)
    elseif state == "difficolta" then
        DifficultyScreen.keypressed(key)
    elseif state == "gioco" then
        GameScreen.keypressed(key)
    elseif state == "leaderboard" then
        LeaderboardScreen.keypressed(key)
    elseif state == "pausa" then
        PauseScreen.keypressed(key)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if state == "menu" then
        menu.touchpressed(id, x, y, dx, dy, pressure)
    elseif state == "difficolta" then
        DifficultyScreen.touchpressed(id, x, y, dx, dy, pressure)
    elseif state == "gioco" then
        GameScreen.touchpressed(id, x, y, dx, dy, pressure)
    elseif state == "leaderboard" then
        LeaderboardScreen.touchpressed(id, x, y, dx, dy, pressure)
    elseif state == "pausa" then
        PauseScreen.touchpressed(id, x, y, dx, dy, pressure)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if state == "menu" then
        menu.touchmoved(id, x, y, dx, dy, pressure)
    elseif state == "difficolta" then
        DifficultyScreen.touchmoved(id, x, y, dx, dy, pressure)
    elseif state == "gioco" then
        GameScreen.touchmoved(id, x, y, dx, dy, pressure)
    elseif state == "leaderboard" then
        LeaderboardScreen.touchmoved(id, x, y, dx, dy, pressure)
    elseif state == "pausa" then
        PauseScreen.touchmoved(id, x, y, dx, dy, pressure)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if state == "menu" then
        menu.touchreleased(id, x, y, dx, dy, pressure)
    elseif state == "difficolta" then
        DifficultyScreen.touchreleased(id, x, y, dx, dy, pressure)
    elseif state == "gioco" then
        GameScreen.touchreleased(id, x, y, dx, dy, pressure)
    elseif state == "leaderboard" then
        LeaderboardScreen.touchreleased(id, x, y, dx, dy, pressure)
    elseif state == "pausa" then
        PauseScreen.touchreleased(id, x, y, dx, dy, pressure)
    end
end

function love.filedropped(file)
    if _G.state ~= "menu" then return end

    local filename = file:getFilename()
    local ext = filename:match("%.([^.]+)$"):lower()
    if ext ~= "jpg" and ext ~= "jpeg" and ext ~= "png" then
        return
    end

    love.filesystem.createDirectory("user_images")

    local name = filename:match("([^/\\]+)$")
    local newFilename = name
    local counter = 1
    local base, dotext = name:match("(.+)%.(.+)$")
    if base and dotext then
        while love.filesystem.getInfo("user_images/" .. newFilename) do
            newFilename = base .. "(" .. counter .. ")." .. dotext
            counter = counter + 1
        end
    end

    file:open("r")
    local data = file:read("data")
    file:close()
    love.filesystem.write("user_images/" .. newFilename, data)
    menu.loadImages()
end
