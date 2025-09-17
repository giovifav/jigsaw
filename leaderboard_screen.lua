-- Modulo per la gestione della schermata classifica (leaderboard) dopo la vittoria nel puzzle
-- Visualizza i risultati migliori con statistiche, permette di rilanciare il gioco e evidenzia il punteggio attuale

-- Moduli richiesti per funzionamento: puzzle per dati, ui per disegno, lang per traduzioni, difficulty per impostazioni
local puzzle = require "puzzle"
local ui = require "ui"
local lang = require "lang"
local difficulty = require "difficulty"

-- Tabella principale del modulo leaderboard_screen
local LeaderboardScreen = {}

-- Risultato dell'ultima partita vinta, utilizzato per evidenziare nella tabella della classifica
LeaderboardScreen.lastResult = nil

-- Immagine del puzzle appena completato, per mostrare come sfondo con effetto
LeaderboardScreen.selectedImage = nil

-- Numero di pezzi per il nuovo gioco quando si seleziona rigioca
LeaderboardScreen.pendingStartN = nil

-- Funzione per cambiare stato del gioco, impostata dal modulo main
LeaderboardScreen.changeStateWithFade = nil -- to be set from main

-- Funzione per avviare un nuovo puzzle, impostata dal modulo main
LeaderboardScreen.startPuzzle = nil -- to be set from main

function LeaderboardScreen.draw()
    print("Disegno leaderboard")
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- Se disponibile, disegna l'immagine del puzzle completato come sfondo trasparente e sfocato
    local img = nil
    if LeaderboardScreen.selectedImage then
        local ok, loaded = pcall(love.graphics.newImage, "img/"..LeaderboardScreen.selectedImage)
        if ok and loaded then img = loaded end
    end
    if img then
        local imgW, imgH = img:getWidth(), img:getHeight()
        local scale = math.min((w-80)/imgW, (h-80)/imgH, 1)
        local px = (w - imgW*scale)/2
        local py = (h - imgH*scale)/2
        love.graphics.setColor(1,1,1,0.18)
        for dx=-2,2 do for dy=-2,2 do
            love.graphics.draw(img, px+dx*2, py+dy*2, 0, scale, scale)
        end end
        love.graphics.setColor(1,1,1,0.32)
        love.graphics.draw(img, px, py, 0, scale, scale)
        love.graphics.setColor(1,1,1,1)
    end
    -- Sfondo sfumato chiaro (come menu e gioco)
    local grad = love.graphics.newMesh({
        {0,0, 0,0, 0.96,0.97,0.98,1},
        {w,0, 1,0, 0.92,0.93,0.95,1},
        {w,h, 1,1, 0.89,0.89,0.91,1},
        {0,h, 0,1, 0.98,0.98,0.99,1}
    }, "fan")
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad,0,0)
    -- Popup conferma cancellazione classifica
    if _G._showClearLeaderboardConfirm then
        -- Sfondo scuro trasparente
        love.graphics.setColor(0,0,0,0.55)
        love.graphics.rectangle("fill", 0, 0, w, h)
        local pw, ph = 420, 200
        local px, py = (w-pw)/2, (h-ph)/2
        local grad = love.graphics.newMesh({
            {0,0, 0,0, 0.96,0.97,0.98,0.75},
            {w,0, 1,0, 0.92,0.93,0.95,0.75},
            {w,h, 1,1, 0.89,0.89,0.91,0.75},
            {0,h, 0,1, 0.98,0.98,0.99,0.75}
        }, "fan")
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(grad,0,0)
        ui.drawWindow(px, py, pw, ph, lang.t("conferma_cancella_leaderboard"), {titleFontSize=24, radius=9})
        ui.setFont(20)
        local btnW, btnH = 140, 48
        local btnY = py+ph-70
        ui.drawButton(px+40, btnY, btnW, btnH, lang.t("conferma"), nil, {fontSize=18, radius=9})
        ui.drawButton(px+pw-btnW-40, btnY, btnW, btnH, lang.t("annulla"), nil, {fontSize=18, radius=9})
        love.graphics.setColor(1,1,1,1)
        return
    end
    local leaderboard = puzzle.getLeaderboard()
    local nRows = math.max(1, math.min(10, #leaderboard))
    local rowHeight = 48
    local ph = rowHeight * nRows + 170
    local minRows = 10
    local minPh = rowHeight * minRows + 170
    if ph < minPh then ph = minPh end
    local pw = 520
    local px, py = (w-pw)/2, (h-ph)/2
    ui.drawWindow(px, py, pw, ph, lang.t("classifica"), {titleFontSize=36, radius=9})
    ui.setFont(22)
    local evidenziato = false
    ui.setFont(18)
    local topMargin = 60
    for i, entry in ipairs(leaderboard) do
        if i > 10 then break end
        local tmin = math.floor(entry.time/60)
        local tsec = math.floor(entry.time%60)
        local tstr = string.format("%02d:%02d", tmin, tsec)
        local highlight = false
        if LeaderboardScreen.lastResult and LeaderboardScreen.lastResult.insert_id and entry.insert_id and entry.insert_id == LeaderboardScreen.lastResult.insert_id then
            highlight = true
        elseif not evidenziato and LeaderboardScreen.lastResult and not LeaderboardScreen.lastResult.insert_id and entry.time == LeaderboardScreen.lastResult.time and entry.moves == LeaderboardScreen.lastResult.moves and (entry.hardcore == LeaderboardScreen.lastResult.hardcore) then
            highlight = true
            evidenziato = true
        end
        if highlight then
            local grad = love.graphics.newMesh({
                {0,0, 0,0, 0.96,0.97,0.98,0.7},
                {pw-60,0, 1,0, 0.92,0.93,0.95,0.7},
                {pw-60,rowHeight-4, 1,1, 0.89,0.89,0.91,0.7},
                {0,rowHeight-4, 0,1, 0.98,0.98,0.99,0.7}
            }, "fan")
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(grad, px+30, py+topMargin+(i-1)*rowHeight)
            love.graphics.setColor(0.5,0.8,0.5,1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", px+30, py+topMargin+(i-1)*rowHeight, pw-60, rowHeight-4, 10, 10)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0,0,0,1)
        else
            love.graphics.setColor(0,0,0,1)
        end
        love.graphics.printf(i..".", px+40, py+topMargin+(i-1)*rowHeight+6, 40, "left")
        love.graphics.printf(tstr, px+90, py+topMargin+(i-1)*rowHeight+6, 100, "left")
        love.graphics.printf(entry.moves.." "..lang.t("mosse"), px+220, py+topMargin+(i-1)*rowHeight+6, 120, "left")
        if entry.hardcore then
            love.graphics.setColor(0.8, 0.2, 0.2, 1)
            love.graphics.printf(lang.t('hardcore'), px+340, py+topMargin+(i-1)*rowHeight+6, pw-400, "right")
            love.graphics.setColor(0,0,0,1)
        end
    end
    ui.setFont(18)
    local btnW, btnH = 180, 54
    local btnX = px+40
    local btnY = py+ph-70
    ui.drawButton(btnX, btnY, btnW, btnH, lang.t("rigioca"), nil, {fontSize=18, radius=9})
    local btnX2 = px+pw-btnW-40
    ui.drawButton(btnX2, btnY, btnW, btnH, lang.t("menu"), nil, {fontSize=18, radius=9})
end

function LeaderboardScreen.mousepressed(x, y, button)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- Gestione popup conferma cancellazione classifica
    if _G._showClearLeaderboardConfirm then
        local pw, ph = 420, 200
        local px, py = (w-pw)/2, (h-ph)/2
        local btnW, btnH = 140, 48
        local btnY = py+ph-70
        -- Conferma
        if x >= px+40 and x <= px+40+btnW and y >= btnY and y <= btnY+btnH then
            _G._showClearLeaderboardConfirm = false
            puzzle.clearLeaderboard()
            sound.play('popup_close')
            return
        end
        -- Annulla
        if x >= px+pw-btnW-40 and x <= px+pw-40 and y >= btnY and y <= btnY+btnH then
            _G._showClearLeaderboardConfirm = false
            sound.play('popup_close')
            return
        end
        return
    end
    local leaderboard = puzzle.getLeaderboard()
    local nRows = math.max(1, math.min(10, #leaderboard))
    local rowHeight = 48
    local ph = rowHeight * nRows + 170
    local minRows = 10
    local minPh = rowHeight * minRows + 170
    if ph < minPh then ph = minPh end
    local pw = 520
    local px, py = (w-pw)/2, (h-ph)/2
    local btnW, btnH = 180, 54
    local btnX = px+40
    local btnY = py+ph-70
    local btnX2 = px+pw-btnW-40
    if x >= btnX and x <= btnX+btnW and y >= btnY and y <= btnY+btnH then
        if LeaderboardScreen.selectedImage and LeaderboardScreen.startPuzzle then
            LeaderboardScreen.lastResult = nil
            local safeName = LeaderboardScreen.selectedImage:gsub("/", "__")
            local fname = "save_"..safeName..".json"
            if love.filesystem.getInfo(fname) then
                love.filesystem.remove(fname)
            end
            LeaderboardScreen.startPuzzle(LeaderboardScreen.selectedImage, LeaderboardScreen.pendingStartN, true, difficulty.hardcore)
        end
        return
    end
    if x >= btnX2 and x <= btnX2+btnW and y >= btnY and y <= btnY+btnH then
        print("CLICK MENU CLASSIFICA")
        if LeaderboardScreen.changeStateWithFade then
            LeaderboardScreen.changeStateWithFade("menu")
        else
            _G.state = "menu"
        end
        return
    end
end

function LeaderboardScreen.wheelmoved(x, y) end
function LeaderboardScreen.mousemoved(x, y, dx, dy) end
function LeaderboardScreen.mousereleased(x, y, button) end
function LeaderboardScreen.touchpressed(id, x, y, dx, dy, pressure) end
function LeaderboardScreen.touchmoved(id, x, y, dx, dy, pressure) end
function LeaderboardScreen.touchreleased(id, x, y, dx, dy, pressure) end

function LeaderboardScreen.keypressed(key)
    -- Funzione vuota per compatibilità
end

return LeaderboardScreen
