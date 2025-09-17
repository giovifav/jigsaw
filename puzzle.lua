local utils = require "utils"
local json = require("dkjson")
local sound = require "sound"
local ui = require "ui"

local puzzle = {}

-- Numero di pezzi per lato (es: 3x3)
local piecesPerSide = 3
local defaultImagePath = "img/puzzle.jpg"
local puzzleImage
local pieceWidth, pieceHeight
local pieces = {}
local selectedPiece = nil
local isGameWon = false
local scale = 1
local drawOffsetX, drawOffsetY = 0, 0
local areaW, areaH = 0, 0
local lockedIndices = {}
local saveFileName = nil
local currentImageName = nil
local timer = 0
local moves = 0
local winAnim = 0
local isAnimating = false
local animTime = 0
local animDuration = 0.38
local animPieces = nil
local animStart = nil
local animEnd = nil
local animGridStart = nil
local animGridEnd = nil
local showPreview = false
local leaderboardFileName = "leaderboard.json"
local leaderboard = {}

-- Callback/eventi per separare logica di gioco da UI e transizioni
local event_callbacks = {
    onWin = nil,         -- chiamato quando si vince
    onMove = nil,        -- chiamato dopo ogni mossa
    onLoad = nil         -- chiamato dopo il caricamento partita
}

-- Permette di registrare callback per eventi di gioco
function puzzle.on(event, callback)
    event_callbacks[event] = callback
end

-- Restituisce statistiche di gioco attuali
function puzzle.getStats()
    return timer, moves, isGameWon, puzzle._hardcore
end

-- Salva lo stato attuale della partita su file
function puzzle.saveState()
    if not saveFileName or isGameWon then return end
    local state = {
        N = piecesPerSide,
        selected = selectedPiece,
        gameWon = isGameWon,
        pieces = {},
        image = currentImageName,
        timer = timer,
        moves = moves
    }
    for i, p in ipairs(pieces) do
        if p and p.pos then
            state.pieces[i] = {
                pos = {p.pos[1], p.pos[2]},
                locked = p.locked
            }
        end
    end
    utils.save_json(saveFileName, state)
    if event_callbacks.onMove then event_callbacks.onMove() end -- callback dopo ogni mossa
end

-- Carica lo stato partita da file
function puzzle.loadState(imgName)
    local safeName = imgName:gsub("/", "__")
    local fname = "save_"..safeName..".json"
    local state = utils.load_json(fname)
    if state and state.N and state.pieces then
        piecesPerSide = state.N
        selectedPiece = state.selected
        isGameWon = state.gameWon
        timer = state.timer or 0
        moves = state.moves or 0
        for i, p in ipairs(state.pieces) do
            if pieces[i] then
                pieces[i].pos = {p.pos[1], p.pos[2]}
                pieces[i].locked = p.locked
            end
        end
        if event_callbacks.onLoad then event_callbacks.onLoad() end -- callback dopo caricamento
    end
end

-- Imposta il blocco dei pezzi agli angoli se sono nella posizione corretta (solo se non hardcore)
local function lockCornerPieces()
    if puzzle._hardcore then return end
    for i, p in ipairs(pieces) do
        if (p.correct[1] == 0 and p.correct[2] == 0) or (p.correct[1] == piecesPerSide-1 and p.correct[2] == piecesPerSide-1) then
            if p.pos[1] == p.correct[1] and p.pos[2] == p.correct[2] then
                p.locked = true
            else
                p.locked = false
            end
        end
    end
end

-- Mescola i pezzi del puzzle
local function shufflePieces()
    if puzzle._hardcore then
        -- Mescola tutti i pezzi, nessun bloccato
        local toShuffle = {}
        for i, p in ipairs(pieces) do
            table.insert(toShuffle, i)
        end
        local posList = {}
        for i, idx in ipairs(toShuffle) do
            local p = pieces[idx]
            table.insert(posList, {p.correct[1], p.correct[2]})
        end
        repeat
            utils.shuffle(posList)
            for i, idx in ipairs(toShuffle) do
                pieces[idx].pos = {posList[i][1], posList[i][2]}
                pieces[idx].locked = false
            end
            -- Controlla che nessun pezzo sia nella posizione corretta
            local anyInPlace = false
            for i, idx in ipairs(toShuffle) do
                local p = pieces[idx]
                if p.pos[1] == p.correct[1] and p.pos[2] == p.correct[2] then
                    anyInPlace = true
                    break
                end
            end
        until not anyInPlace
    else
        -- Mischia solo i pezzi che non sono in (0,0) o (N-1,N-1)
        local toShuffle = {}
        for i, p in ipairs(pieces) do
            if not ((p.correct[1] == 0 and p.correct[2] == 0) or (p.correct[1] == piecesPerSide-1 and p.correct[2] == piecesPerSide-1)) then
                table.insert(toShuffle, i)
            end
        end
        local posList = {}
        for i, idx in ipairs(toShuffle) do
            local p = pieces[idx]
            table.insert(posList, {p.correct[1], p.correct[2]})
        end
        local valid = false
        repeat
            utils.shuffle(posList)
            for i, idx in ipairs(toShuffle) do
                pieces[idx].pos = {posList[i][1], posList[i][2]}
                pieces[idx].locked = false
            end
            -- Blocca i pezzi agli angoli se sono nella posizione corretta
            lockCornerPieces()
            -- Controlla che nessun pezzo (tranne quelli bloccati) sia nella posizione corretta
            valid = true
            for i, idx in ipairs(toShuffle) do
                local p = pieces[idx]
                if p.pos[1] == p.correct[1] and p.pos[2] == p.correct[2] then
                    valid = false
                    break
                end
            end
        until valid
    end
end

-- Carica una nuova immagine e inizializza il puzzle
function puzzle.load(imagePathParam, nOverride, hardcore, skipLoadState)
    local path = imagePathParam or defaultImagePath
    -- Se è un'immagine utente, usa il percorso completo della directory di salvataggio
    if path:match("^user_images/") then
        path = love.filesystem.getSaveDirectory() .. "/" .. path
    else
        currentImageName = path:match("img/(.+)$") or path
        path = "img/" .. (path:match("img/(.+)$") or path)
    end
    currentImageName = imagePathParam -- salva il percorso originale per leaderboard, etc.
    saveFileName = "save_"..currentImageName:gsub("/", "__")..".json"
    piecesPerSide = nOverride or piecesPerSide
    puzzleImage = love.graphics.newImage(path)
    puzzle.recalc()
    pieces = {}
    lockedIndices = {}
    puzzle._hardcore = hardcore -- salvo lo stato
    for y = 0, piecesPerSide-1 do
        for x = 0, piecesPerSide-1 do
            local quad = love.graphics.newQuad(x*puzzleImage:getWidth()/piecesPerSide, y*puzzleImage:getHeight()/piecesPerSide, puzzleImage:getWidth()/piecesPerSide, puzzleImage:getHeight()/piecesPerSide, puzzleImage:getWidth(), puzzleImage:getHeight())
            table.insert(pieces, {
                quad = quad,
                pos = {x, y},
                correct = {x, y},
                locked = false
            })
        end
    end
    local loaded = false
    if not skipLoadState then
        local fname = "save_"..currentImageName:gsub("/", "__")..".json"
        if love.filesystem.getInfo(fname) then
            puzzle.loadState(currentImageName)
            loaded = true
        end
    end
    if skipLoadState or not loaded then
        shufflePieces()
    end
    selectedPiece = nil
    isGameWon = false
    timer = 0
    moves = 0
    winAnim = 0
end

-- Controlla se il puzzle è stato completato
local function checkWin()
    print("[DEBUG] checkWin() chiamato, controllo " .. #pieces .. " pezzi")
    for i, p in ipairs(pieces) do
        print("[DEBUG] Pezzo " .. i .. ": pos(" .. p.pos[1] .. "," .. p.pos[2] .. ") vs correct(" .. p.correct[1] .. "," .. p.correct[2] .. ")")
        if p.pos[1] ~= p.correct[1] or p.pos[2] ~= p.correct[2] then
            print("[DEBUG] Pezzo " .. i .. " NON in posizione corretta")
            return false
        end
    end
    print("[DEBUG] TUTTI i pezzi sono in posizione corretta! VITTORIA!")
    return true
end

puzzle.checkWin = checkWin

-- Ricalcola dimensioni e posizione del puzzle in base alla finestra
function puzzle.recalc()
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = math.max(40, math.min(winW, winH) * 0.05)
    areaW = math.min(winW, winH) - 2*margin
    areaH = areaW
    if puzzleImage then
        local imgW, imgH = puzzleImage:getWidth(), puzzleImage:getHeight()
        scale = math.min(areaW/imgW, areaH/imgH, 1)
        local scaledW = imgW * scale
        local scaledH = imgH * scale
        pieceWidth = scaledW / piecesPerSide
        pieceHeight = scaledH / piecesPerSide
        drawOffsetX = (winW - scaledW) / 2
        drawOffsetY = (winH - scaledH) / 2
        -- Salvo anche scaledW e scaledH per il bordo
        puzzle.scaledW = scaledW
        puzzle.scaledH = scaledH
    end
end

-- Aggiorna lo stato del puzzle (timer, animazioni, controllo vittoria)
function puzzle.update(dt)
    if not isGameWon and not isAnimating then
        timer = timer + dt
    elseif isAnimating then
        animTime = animTime + dt
        if animTime >= animDuration then
            -- Fine animazione: aggiorna le posizioni logiche (griglia)
            pieces[animPieces[1]].pos = animGridEnd[animPieces[1]]
            pieces[animPieces[2]].pos = animGridEnd[animPieces[2]]
            -- Gestione blocco pezzi
            if not puzzle._hardcore then
                for i, p in ipairs(pieces) do
                    if p.pos[1] == p.correct[1] and p.pos[2] == p.correct[2] then
                        p.locked = true
                    else
                        p.locked = false
                    end
                end
                -- Blocca i pezzi agli angoli se sono nella posizione corretta
                lockCornerPieces()
            else
                for i, p in ipairs(pieces) do
                    p.locked = false
                end
            end
            isAnimating = false
            animPieces = nil
            animStart = nil
            animEnd = nil
            animGridStart = nil
            animGridEnd = nil
            -- NUOVA GESTIONE VITTORIA: controlla subito dopo l'animazione
            print("[DEBUG] Controllo vittoria dopo animazione")
            if checkWin() then
                print("[DEBUG] VITTORIA! Imposto isGameWon = true, suono, cancello save, chiamo callback")
                isGameWon = true
                local success, err = pcall(function() sound.play('win') end)
                if not success then
                    print("[WARNING] Errore suono win:", err)
                end
                if saveFileName then
                    local info = love.filesystem.getInfo(saveFileName)
                    if info then
                        local success, err = pcall(function() love.filesystem.remove(saveFileName) end)
                        if not success then
                            print("[WARNING] Errore cancellazione save file:", err)
                        else
                            print("[DEBUG] Save file cancellato")
                        end
                    else
                        print("[DEBUG] Save file non trovato")
                    end
                end
                if event_callbacks.onWin then
                    print("[DEBUG] Chiamo callback onWin")
                    event_callbacks.onWin()
                else
                    print("[WARNING] Callback onWin non registrato!")
                end
            else
                -- Salva solo se non hai vinto
                print("[DEBUG] Nessuna vittoria, salvo stato partita")
                puzzle.saveState()
            end
        end
    elseif isGameWon and winAnim < 1 then
        winAnim = math.min(1, winAnim + dt*0.7)
        -- Fix: cancella il file di salvataggio appena si vince, anche in hardcore
        if saveFileName and love.filesystem.getInfo(saveFileName) then
            love.filesystem.remove(saveFileName)
            saveFileName = nil
        end
    end
end

-- Disegna il puzzle e la UI di gioco
function puzzle.draw()
    puzzle.recalc()
    -- Sfondo sfumato chiaro
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    local grad = love.graphics.newMesh({
        {0,0, 0,0, 0.96,0.97,0.98,1},
        {winW,0, 1,0, 0.92,0.93,0.95,1},
        {winW,winH, 1,1, 0.89,0.89,0.91,1},
        {0,winH, 0,1, 0.98,0.98,0.99,1}
    }, "fan")
    love.graphics.draw(grad,0,0)
    -- Ombra area puzzle
    love.graphics.setColor(0,0,0,0.10)
    love.graphics.rectangle("fill", drawOffsetX+8, drawOffsetY+8, puzzle.scaledW-16, puzzle.scaledH-16, 4, 4)
    -- Cornice area puzzle
    love.graphics.setColor(1,1,1,0.92)
    love.graphics.setLineWidth(6)
    love.graphics.rectangle("line", drawOffsetX, drawOffsetY, puzzle.scaledW, puzzle.scaledH, 4, 4)
    love.graphics.setLineWidth(1)
    -- Pezzi
    for i, p in ipairs(pieces) do
        if p and p.pos then
            local gridPos = p.pos
            -- Reset colore prima di disegnare il pezzo
            love.graphics.setColor(1,1,1,1)
            -- Se in animazione, calcola posizione interpolata tra le coordinate logiche
            if isAnimating and (animPieces and (i == animPieces[1] or i == animPieces[2])) then
                -- Easing: ease-in-out (cubic)
                local t = math.min(animTime/animDuration, 1)
                local function easeInOutCubic(x)
                    return x < 0.5 and 4*x*x*x or 1 - math.pow(-2*x+2,3)/2
                end
                local et = easeInOutCubic(t)
                local sx, sy = animGridStart[i][1], animGridStart[i][2]
                local ex, ey = animGridEnd[i][1], animGridEnd[i][2]
                local px = (sx + (ex-sx)*et) * pieceWidth + drawOffsetX
                local py = (sy + (ey-sy)*et) * pieceHeight + drawOffsetY
                -- Glow/ombra sotto il pezzo in movimento
                love.graphics.setColor(0.2, 0.6, 1, 0.25 + 0.25*math.sin(t*math.pi))
                love.graphics.ellipse("fill", px+pieceWidth/2, py+pieceHeight/2+4, pieceWidth*0.48, pieceHeight*0.18)
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(puzzleImage, p.quad, px, py, 0, scale, scale)
                -- Glow esterno
                love.graphics.setColor(0.9, 0.85, 0.2, 0.18 + 0.18*math.sin(t*math.pi))
                love.graphics.setLineWidth(8)
                love.graphics.rectangle("line", px-2, py-2, pieceWidth+4, pieceHeight+4, 6, 6)
                love.graphics.setLineWidth(1)
                -- Cerchio bloccato o selezionato
                if p.locked then
                    local cx = px + pieceWidth/2
                    local cy = py + pieceHeight/2
                    local r = math.min(pieceWidth, pieceHeight)/16
                    love.graphics.setColor(0.2, 0.6, 1, 1)
                    love.graphics.circle("fill", cx, cy, r)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", cx, cy, r)
                    love.graphics.setLineWidth(1)
                elseif selectedPiece == i and not isAnimating then
                    local cx = px + pieceWidth/2
                    local cy = py + pieceHeight/2
                    local r = math.min(pieceWidth, pieceHeight)/16
                    love.graphics.setColor(1, 0.85, 0.2, 1)
                    love.graphics.circle("fill", cx, cy, r)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", cx, cy, r)
                    love.graphics.setLineWidth(1)
                end
            else
                local px, py = gridPos[1] * pieceWidth + drawOffsetX, gridPos[2] * pieceHeight + drawOffsetY
                love.graphics.draw(puzzleImage, p.quad, px, py, 0, scale, scale)
                if p.locked then
                    -- Cerchio più piccolo, colore azzurro e bordo bianco
                    local cx = px + pieceWidth/2
                    local cy = py + pieceHeight/2
                    local r = math.min(pieceWidth, pieceHeight)/16
                    love.graphics.setColor(0.2, 0.6, 1, 1) -- azzurro
                    love.graphics.circle("fill", cx, cy, r)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", cx, cy, r)
                    love.graphics.setLineWidth(1)
                elseif selectedPiece == i and not isAnimating then
                    -- Puntino giallo con bordo bianco (come prima)
                    local cx = px + pieceWidth/2
                    local cy = py + pieceHeight/2
                    local r = math.min(pieceWidth, pieceHeight)/16
                    love.graphics.setColor(1, 0.85, 0.2, 1) -- giallo
                    love.graphics.circle("fill", cx, cy, r)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", cx, cy, r)
                    love.graphics.setLineWidth(1)
                end
            end
        end
    end
    -- Glow animato sopra il pezzo selezionato
    if selectedPiece and pieces[selectedPiece] and pieces[selectedPiece].pos and not isAnimating then
        local gridPos = pieces[selectedPiece].pos
        local px = gridPos[1] * pieceWidth + drawOffsetX
        local py = gridPos[2] * pieceHeight + drawOffsetY
        local t = love.timer.getTime()
        local glowAlpha = 0.35 + 0.25 * math.sin(t * 2)
        love.graphics.setColor(1, 0.85, 0.2, glowAlpha)
        love.graphics.setLineWidth(12)
        love.graphics.rectangle("line", px-6, py-6, pieceWidth+12, pieceHeight+12, 8, 8)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1,1,1,1)
    end
    -- Timer e mosse SOLO se in pausa
    if _G._showStatsInPause then
        love.graphics.setFont(love.graphics.newFont(26))
        love.graphics.setColor(1,1,1,0.95)
        local tmin = math.floor(timer/60)
        local tsec = math.floor(timer%60)
        local tstr = string.format("%02d:%02d", tmin, tsec)
        local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
        local btnW, btnH = 120, 48
        local btnX = winW - btnW - 30
        local btnY = 20
        love.graphics.print("Tempo: "..tstr, btnX, btnY + btnH + 18)
        love.graphics.print("Mosse: "..moves, btnX, btnY + btnH + 58)
        love.graphics.setFont(love.graphics.newFont(18))
    end
    -- Animazione di vittoria
    -- Pulsante anteprima SOLO se non hardcore
    if not puzzle._hardcore and not showPreview then
        local btnW, btnH = 60, 60
        local btnX = winW - btnW - 30
        local btnY = 90
        ui.drawButton(btnX, btnY, btnW, btnH, "?", nil, {fontSize=38, radius=9})
    end
    -- Se showPreview, disegna l'immagine intera sopra il puzzle SOLO se non hardcore
    if not puzzle._hardcore and showPreview and puzzleImage then
        love.graphics.setColor(1,1,1,1)
        local imgW, imgH = puzzleImage:getWidth(), puzzleImage:getHeight()
        local scale = math.min((winW-80)/imgW, (winH-80)/imgH, 1)
        local px = (winW - imgW*scale)/2
        local py = (winH - imgH*scale)/2
        love.graphics.draw(puzzleImage, px, py, 0, scale, scale)
        -- Pulsante X per chiudere (ora nella stessa posizione del tasto '?')
        local btnW, btnH = 60, 60
        local btnX = winW - btnW - 30
        local btnY = 90
        ui.drawButton(btnX, btnY, btnW, btnH, "X", nil, {fontSize=38, radius=9})
    end
end

-- Restituisce l'indice del pezzo sotto le coordinate x,y
local function getPieceAt(x, y)
    puzzle.recalc()
    for i, p in ipairs(pieces) do
        if p and p.pos then
            local px = p.pos[1] * pieceWidth + drawOffsetX
            local py = p.pos[2] * pieceHeight + drawOffsetY
            if x >= px and x < px + pieceWidth and y >= py and y < py + pieceHeight then
                return i
            end
        end
    end
    return nil
end

-- Gestisce il click del mouse sui pezzi del puzzle
function puzzle.mousepressed(x, y, button)
    if isGameWon or isAnimating then return end
    if button == 1 then
        local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
        local btnW, btnH = 60, 60
        local btnX = winW - btnW - 30
        local btnY = 90
        -- Gestione click pulsante anteprima
        if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
            if showPreview then
                showPreview = false
                sound.play('cancel')
            elseif not puzzle._hardcore then
                showPreview = true
                sound.play('select1')
            end
            return
        end
        local idx = getPieceAt(x, y)
        if idx and not pieces[idx].locked then
            if not selectedPiece then
                sound.play('select_piece')
                selectedPiece = idx
            elseif selectedPiece ~= idx and not pieces[selectedPiece].locked then
                -- Prepara animazione
                local i1, i2 = selectedPiece, idx
                isAnimating = true
                animTime = 0
                animPieces = {i1, i2}
                animGridStart = {
                    [i1] = {pieces[i1].pos[1], pieces[i1].pos[2]},
                    [i2] = {pieces[i2].pos[1], pieces[i2].pos[2]}
                }
                animGridEnd = {
                    [i1] = {pieces[i2].pos[1], pieces[i2].pos[2]},
                    [i2] = {pieces[i1].pos[1], pieces[i1].pos[2]}
                }
                -- Scambia le posizioni logiche solo a fine animazione
                sound.play('swap_piece')
                selectedPiece = nil
                moves = moves + 1
                -- NON salvare qui, lo stato viene salvato a fine animazione
                return
            else
                selectedPiece = nil
            end
        else
            sound.play('error')
            selectedPiece = nil
        end
    end
    -- Controllo vittoria anche se non parte nessuna animazione
    print("[DEBUG] Controllo vittoria dopo mousepressed")
    if not isAnimating and puzzle.checkWin() and not isGameWon then
        print("[DEBUG] VITTORIA da mousepressed! Imposto isGameWon = true, suono, cancello save, chiamo callback")
        isGameWon = true
        local success, err = pcall(function() sound.play('win') end)
        if not success then
            print("[WARNING] Errore suono win:", err)
        end
        if saveFileName then
            local info = love.filesystem.getInfo(saveFileName)
            if info then
                local success, err = pcall(function() love.filesystem.remove(saveFileName) end)
                if not success then
                    print("[WARNING] Errore cancellazione save file:", err)
                else
                    print("[DEBUG] Save file cancellato")
                end
            else
                print("[DEBUG] Save file non trovato")
            end
        end
        if event_callbacks.onWin then
            print("[DEBUG] Chiamo callback onWin")
            event_callbacks.onWin()
        else
            print("[WARNING] Callback onWin non registrato!")
        end
    end
end

local function loadLeaderboard()
    leaderboard = utils.load_json(leaderboardFileName) or {}
end

local function saveLeaderboard()
    utils.save_json(leaderboardFileName, leaderboard)
end

local function getLeaderboardKey(imageName, n)
    return (imageName or "") .. "_" .. tostring(n)
end

function puzzle.getLeaderboard()
    loadLeaderboard()
    local key = getLeaderboardKey(currentImageName, piecesPerSide)
    return leaderboard[key] or {}
end

function puzzle.addToLeaderboard(timer, moves, insert_id)
    loadLeaderboard()
    local key = getLeaderboardKey(currentImageName, piecesPerSide)
    leaderboard[key] = leaderboard[key] or {}
    local entry = {time = timer, moves = moves, hardcore = puzzle._hardcore}
    if insert_id then entry.insert_id = insert_id end
    table.insert(leaderboard[key], entry)
    -- Ordina per tempo, poi per mosse
    table.sort(leaderboard[key], function(a, b)
        if a.time == b.time then
            return a.moves < b.moves
        else
            return a.time < b.time
        end
    end)
    -- Tieni solo i migliori 10
    while #leaderboard[key] > 10 do table.remove(leaderboard[key]) end
    saveLeaderboard()
end

function puzzle.clearLeaderboard()
    loadLeaderboard()
    local key = getLeaderboardKey(currentImageName, piecesPerSide)
    leaderboard[key] = {}
    saveLeaderboard()
end

-- Restituisce la massima difficoltà completata per una certa immagine (senza considerare l'hardcore)
function puzzle.getMaxCompletedDifficulty(imageName)
    local maxN = nil
    local maxHardcore = false
    -- Carica la leaderboard
    if love.filesystem.getInfo(leaderboardFileName) then
        local data = love.filesystem.read(leaderboardFileName)
        leaderboard = json.decode(data) or {}
    else
        leaderboard = {}
    end
    -- Trova la massima difficoltà completata
    for key, entries in pairs(leaderboard) do
        local img, n = key:match("(.+)_([0-9]+)$")
        n = tonumber(n)
        if img == imageName and entries and #entries > 0 then
            if not maxN or n > maxN then
                maxN = n
            end
        end
    end
    -- Ora controlla se la massima difficoltà è stata vinta in hardcore
    if maxN then
        for key, entries in pairs(leaderboard) do
            local img, n = key:match("(.+)_([0-9]+)$")
            n = tonumber(n)
            if img == imageName and n == maxN and entries and #entries > 0 then
                for _, entry in ipairs(entries) do
                    if entry.hardcore then
                        maxHardcore = true
                        break
                    end
                end
            end
        end
    end
    return maxN, maxHardcore
end

return puzzle
