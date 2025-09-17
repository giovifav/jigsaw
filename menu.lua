local menu = {}

local images = {}
local thumbs = {}
local categories = {}
local scrollY = 0
local thumbSize = 180
local spacing = 30
local cols = 3
local menuAreaH = 1024 - 2*spacing
local visibleRows = math.floor(menuAreaH / (thumbSize + spacing))
local hovered = nil

local lang = require "lang"
local music = require "music"
local sound = require "sound"
local ui = require "ui"
local puzzle = require "puzzle"
local difficulty = require "difficulty"
local utils = require "utils"

local flag_imgs = {}
local logo = nil

local scrollbarDragging = false
local scrollbarDragOffset = 0
local lastTouchY = nil
local mouseDragging = false

menu.fullscreen = love.window.getFullscreen() -- stato iniziale fullscreen
menu.currentCategory = nil -- nil: mostra categorie, stringa: mostra immagini di quella categoria

local settingsFile = "settings.json"

-- Stato per mostrare il popup legenda
menu.showLegend = false

local creditsText = nil
local creditsScroll = 0
menu.showCredits = false

function menu.saveSettings()
    local data = {
        music = not music.isMuted(),
        sound = not sound.isMuted(),
        fullscreen = menu.fullscreen,
        language = lang.current_lang()
    }
    utils.save_json(settingsFile, data)
end

function menu.loadSettings()
    local obj = utils.load_json(settingsFile)
    if obj then
        if obj.music ~= nil then music.setMuted(not obj.music) end
        if obj.sound ~= nil then sound.setMuted(not obj.sound) end
        if obj.fullscreen ~= nil then
            menu.fullscreen = obj.fullscreen
            love.window.setFullscreen(menu.fullscreen)
        end
        if obj.language and (obj.language == "it" or obj.language == "en") then
            lang.set_language(obj.language)
        end
    end
end

function menu.loadImages()
    images = {}
    thumbs = {}
    categories = {}
    -- Carica bandiere
    flag_imgs.it = love.graphics.newImage("assets/flag_it.png")
    flag_imgs.en = love.graphics.newImage("assets/flag_en.png")
    logo = love.graphics.newImage("assets/logo.png")
    menu.loadSettings() -- carica le impostazioni all'avvio
    if not menu.currentCategory then
        -- Carica le sottocartelle di img/ come categorie
        local files = love.filesystem.getDirectoryItems("img")
        for _, file in ipairs(files) do
            local info = love.filesystem.getInfo("img/"..file)
            if info and info.type == "directory" then
                table.insert(categories, file)
            end
        end
    else
        -- Carica le immagini della categoria selezionata
        local path = "img/"..menu.currentCategory
        local files = love.filesystem.getDirectoryItems(path)
        for _, file in ipairs(files) do
            if file:match("%.jpg$") or file:match("%.png$") or file:match("%.jpeg$") then
                table.insert(images, file)
            end
        end
        for i, file in ipairs(images) do
            local img = love.graphics.newImage(path.."/"..file)
            -- Crop centrale quadrato
            local iw, ih = img:getWidth(), img:getHeight()
            local size = math.min(iw, ih)
            local ox = math.floor((iw - size)/2)
            local oy = math.floor((ih - size)/2)
            local quad = love.graphics.newQuad(ox, oy, size, size, iw, ih)
            thumbs[i] = {img=img, quad=quad}
        end
    end
end

function menu.draw()
    -- Sfondo sfumato chiaro
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local grad = love.graphics.newMesh({
        {0,0, 0,0, 0.96,0.97,0.98,1},
        {w,0, 1,0, 0.92,0.93,0.95,1},
        {w,h, 1,1, 0.89,0.89,0.91,1},
        {0,h, 0,1, 0.98,0.98,0.99,1}
    }, "fan")
    love.graphics.draw(grad,0,0)
    -- Logo centrato sopra la griglia
    local logoH = 0
    local logoY = 24
    if logo then
        local lw, lh = logo:getWidth(), logo:getHeight()
        local scale = math.min(w*0.25/lw, 120/lh, 1)
        logoH = lh*scale + 24
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(logo, (w-lw*scale)/2, logoY, 0, scale, scale)
    end
    -- Calcolo posizione e area della griglia immagini/categorie sotto il logo
    local gridW = cols*thumbSize + (cols-1)*spacing
    local startX = (w - gridW)/2
    local gridY = logoY + logoH + 12 -- 12px di margine sotto il logo
    local scissorY = logoY + logoH + 8 -- 8px di padding sotto il logo
    local availableH = h - gridY - 40 -- 40px margine inferiore
    local items = menu.currentCategory and thumbs or categories
    local nItems = menu.currentCategory and #thumbs or #categories
    local rows = math.ceil(nItems/cols)
    local visibleRows = math.floor(availableH / (thumbSize + spacing))
    -- Limita scrollY per non sovrapporre il logo
    local maxScroll = math.max(0, (rows-visibleRows)*(thumbSize+spacing))
    scrollY = math.max(0, math.min(scrollY, maxScroll))
    local startY = gridY - scrollY
    hovered = nil
    local mx, my = love.mouse.getPosition()
    -- Blocca hover se il popup riprendi è attivo
    if _G and _G.state == "resume_popup" then
        mx, my = -1000, -1000 -- posizione fuori schermo, nessun hover
    end
    -- Imposta la scissor per la griglia immagini/categorie
    love.graphics.setScissor(0, scissorY, w, h - scissorY - 40)
    for i = 1, nItems do
        local row = math.floor((i-1)/cols)
        local col = (i-1)%cols
        local x = startX + col*(thumbSize+spacing)
        local y = startY + row*(thumbSize+spacing)
        if y + thumbSize > gridY and y < h-40 then
            local isHover = false
            if not menu.showSettings then
                isHover = mx >= x and mx <= x+thumbSize and my >= y and my <= y+thumbSize
                if isHover then hovered = i end
            end
            -- Ombra
            love.graphics.setColor(0,0,0,0.18)
            love.graphics.rectangle("fill", x+6, y+6, thumbSize, thumbSize, 18, 18)
            -- Effetto hover
            local scale = 1
            local borderColor = {0,0,0,0.2}
            local borderRadius = 9
            if isHover then
                scale = 1.07
                borderColor = {0.8,0.82,0.88,1}
                borderRadius = 9
            end
            love.graphics.stencil(function()
                love.graphics.rectangle("fill", x, y, thumbSize*scale, thumbSize*scale, borderRadius, borderRadius)
            end, "replace", 1)
            love.graphics.setStencilTest("greater", 0)
            love.graphics.setColor(1,1,1,1)
            if menu.currentCategory then
                -- Disegna thumb immagine
                local thumb = thumbs[i]
                if thumb and thumb.quad then
                    local qx, qy, qw, qh = thumb.quad:getViewport()
                    love.graphics.draw(thumb.img, thumb.quad, x, y, 0, thumbSize/qw*scale, thumbSize/qh*scale)
                end
                -- Pallino leaderboard
                local imgName = menu.currentCategory.."/"..images[i]
                local maxN, isHardcore = puzzle.getMaxCompletedDifficulty(imgName)
                if maxN then
                    -- Scegli colore in base alla difficoltà
                    local color = {0.2, 0.8, 0.2, 1} -- verde (facile)
                    if maxN >= 8 then
                        color = {0.9, 0.1, 0.1, 1} -- rosso (genio)
                    elseif maxN >= 6 then
                        color = {0.95, 0.7, 0.1, 1} -- giallo/ambra (esperto/maestro)
                    elseif maxN >= 4 then
                        color = {0.9, 0.9, 0.2, 1} -- giallo (normale/difficile)
                    end
                    local r = 18 * scale
                    local px = x + thumbSize*scale - r - 10
                    local py = y + r + 10
                    love.graphics.setColor(color)
                    love.graphics.circle("fill", px, py, r)
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", px, py, r)
                    love.graphics.setLineWidth(1)
                    -- Disegna la 'h' se hardcore
                    if isHardcore then
                        ui.setFont(16)
                        love.graphics.setColor(1,1,1,1)
                        local text = "h"
                        local tw = love.graphics.getFont():getWidth(text)
                        local th = love.graphics.getFont():getHeight()
                        love.graphics.print(text, px-tw/2, py-th/2)
                        love.graphics.setColor(1,1,1,1)
                    end
                end
            else
                -- Disegna "icona" categoria (rettangolo e nome)
                love.graphics.setColor(0.92,0.93,0.95,1)
                love.graphics.rectangle("fill", x, y, thumbSize*scale, thumbSize*scale, borderRadius, borderRadius)
                love.graphics.setColor(0.2,0.2,0.3,1)
                ui.setFont(22)
                local catKey = 'categoria_'..categories[i]:gsub("%W", ""):lower()
                local localized = lang.t(catKey)
                local text = (localized ~= catKey) and localized or (categories[i] or "?")
                local tw = love.graphics.getFont():getWidth(text)
                love.graphics.print(text, x + (thumbSize*scale-tw)/2, y + thumbSize*scale/2 - 12)
            end
            love.graphics.setStencilTest()
            love.graphics.setColor(borderColor)
            love.graphics.setLineWidth(isHover and 5 or 2)
            love.graphics.rectangle("line", x, y, thumbSize*scale, thumbSize*scale, borderRadius, borderRadius)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(1,1,1,1)
        end
    end
    love.graphics.setScissor() -- Disabilita la scissor
    -- Scrollbar
    if rows > visibleRows then
        local barH = availableH * visibleRows / rows
        local barY = gridY + (availableH-barH) * (scrollY / math.max(1, (rows-visibleRows)*(thumbSize+spacing)))
        love.graphics.setColor(0.7,0.7,0.7,0.7)
        love.graphics.rectangle("fill", w-24, barY, 12, barH, 6, 6)
        love.graphics.setColor(1,1,1,1)
    end
    -- Pulsante Settings
    local btnW, btnH = 120, 48
    local btnX, btnY = w - btnW - 30, 30
    ui.drawButton(btnX, btnY, btnW, btnH, lang.t("settings"), nil, {radius=9})
    -- Pulsante Esci
    local btnExitW, btnExitH = 120, 48
    local btnExitX, btnExitY = w - btnExitW - 30, h - btnExitH - 30
    ui.drawButton(btnExitX, btnExitY, btnExitW, btnExitH, lang.t("menu_esci") or "Esci", nil, {fontSize=22, radius=9})
    -- Pulsante indietro se siamo in una categoria
    if menu.currentCategory then
        local backW, backH = 120, 44
        local backX, backY = 30, 30
        ui.drawButton(backX, backY, backW, backH, "< "..lang.t("indietro") or "Indietro", nil, {fontSize=18, radius=9})
    end
    -- Popup settings
    if menu.showSettings then
        local pw, ph = 420, 400
        local px, py = (w-pw)/2, (h-ph)/2
        local grad = love.graphics.newMesh({
            {0,0, 0,0, 0.96,0.97,0.98,0.75},
            {w,0, 1,0, 0.92,0.93,0.95,0.75},
            {w,h, 1,1, 0.89,0.89,0.91,0.75},
            {0,h, 0,1, 0.98,0.98,0.99,0.75}
        }, "fan")
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(grad,0,0)
        ui.drawWindow(px, py, pw, ph, lang.t("settings"), {titleFontSize=26, radius=9})
        ui.setFont(22)
        ui.drawButton(px+40, py+70, 140, 44, "Italiano", lang.current_lang()=="it" and "selected" or nil, {fontSize=18, radius=9})
        ui.drawButton(px+240, py+70, 140, 44, "English", lang.current_lang()=="en" and "selected" or nil, {fontSize=18, radius=9})
        ui.drawCheckbox(px+40, py+140, 32, not music.isMuted(), lang.t("settings_music"), {fontSize=20})
        ui.drawCheckbox(px+40, py+200, 32, not sound.isMuted(), lang.t("settings_sound"), {fontSize=20})
        ui.drawCheckbox(px+240, py+140, 32, menu.fullscreen, lang.t("settings_fullscreen"), {fontSize=20})
        -- Pulsante Crediti
        ui.drawButton(px+40, py+260, 340, 44, lang.t("settings_credits"), nil, {fontSize=18, radius=9})
        ui.drawButton(px+pw/2-60, py+ph-60, 120, 44, lang.t("settings_close"), nil, {fontSize=18, radius=9})
        love.graphics.setColor(1,1,1,1)
    end
    -- Popup credits
    if menu.showCredits then
        local pw, ph = 540, 420
        local px, py = (w-pw)/2, (h-ph)/2
        local grad = love.graphics.newMesh({
            {0,0, 0,0, 0.96,0.97,0.98,0.95},
            {pw,0, 1,0, 0.92,0.93,0.95,0.95},
            {pw,ph, 1,1, 0.89,0.89,0.91,0.95},
            {0,ph, 0,1, 0.98,0.98,0.99,0.95}
        }, "fan")
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(grad,px,py)
        ui.drawWindow(px, py, pw, ph, lang.t("credits"), {titleFontSize=26, radius=9})
        -- Area testo scorrevole
        local textAreaX, textAreaY = px+32, py+60
        local textAreaW, textAreaH = pw-64, ph-120
        love.graphics.setScissor(textAreaX, textAreaY, textAreaW, textAreaH)
        ui.setFont(16)
        if creditsText then
            love.graphics.setColor(0,0,0,1)
            love.graphics.printf(creditsText, textAreaX, textAreaY-creditsScroll, textAreaW, "left")
        end
        love.graphics.setScissor()
        -- Scrollbar
        if creditsText then
            local font = love.graphics.getFont()
            local _, wrapped = font:getWrap(creditsText, textAreaW)
            local textHeight = #wrapped * font:getHeight()
            if textHeight > textAreaH then
                local barH = textAreaH * textAreaH / textHeight
                local barY = textAreaY + (creditsScroll/(textHeight-textAreaH))*(textAreaH-barH)
                love.graphics.setColor(0.7,0.7,0.7,0.7)
                love.graphics.rectangle("fill", px+pw-20, barY, 8, barH, 4, 4)
                love.graphics.setColor(1,1,1,1)
            end
        end
        -- Pulsante chiudi
        ui.drawButton(px+pw/2-60, py+ph-50, 120, 38, lang.t("settings_close"), nil, {fontSize=18, radius=9})
        love.graphics.setColor(1,1,1,1)
    end
    -- Icona info per la legenda
    local showLegend = false
    if menu.currentCategory then
        local iconR = 16
        local iconX = 40
        local iconY = h - 40
        love.graphics.setColor(0.85,0.85,0.95,1)
        love.graphics.circle("fill", iconX, iconY, iconR)
        love.graphics.setColor(0.3,0.3,0.5,1)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", iconX, iconY, iconR)
        ui.setFont(18)
        love.graphics.setColor(0.3,0.3,0.5,1)
        local text = "i"
        local tw = love.graphics.getFont():getWidth(text)
        local th = love.graphics.getFont():getHeight()
        love.graphics.print(text, iconX-tw/2, iconY-th/2)
        love.graphics.setColor(1,1,1,1)
        -- Mostra il popup legenda solo se il mouse è sopra l'icona
        if mx >= iconX-iconR and mx <= iconX+iconR and my >= iconY-iconR and my <= iconY+iconR then
            showLegend = true
        end
    end
    -- Popup legenda solo in hover
    if showLegend then
        local pw, ph = 340, 220
        local px, py = 40 + 32, h - ph - 32
        ui.drawWindow(px, py, pw, ph, lang.t("Legenda"), {titleFontSize=22, radius=9})
        local legendSpacing = 34
        local legendRadius = 14
        local legendFont = 18
        local legend = {
            {color={0.2,0.8,0.2,1}, label=lang.t("facile")},
            {color={0.9,0.9,0.2,1}, label=lang.t("normale").."/"..lang.t("difficile")},
            {color={0.95,0.7,0.1,1}, label=lang.t("esperto").."/"..lang.t("maestro")},
            {color={0.9,0.1,0.1,1}, label=lang.t("genio")},
        }
        ui.setFont(legendFont)
        for i, item in ipairs(legend) do
            love.graphics.setColor(item.color)
            love.graphics.circle("fill", px+32, py+60 + (i-1)*legendSpacing, legendRadius)
            love.graphics.setColor(1,1,1,1)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", px+32, py+60 + (i-1)*legendSpacing, legendRadius)
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(item.label, px+32 + legendRadius + 12, py+60 + (i-1)*legendSpacing - legendRadius/1.2)
        end
        -- Legenda hardcore
        local hColor = {0.2,0.8,0.2,1}
        love.graphics.setColor(hColor)
        love.graphics.circle("fill", px+32, py+60 + #legend*legendSpacing, legendRadius)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", px+32, py+60 + #legend*legendSpacing, legendRadius)
        ui.setFont(legendFont)
        love.graphics.setColor(1,1,1,1)
        local text = "h"
        local tw = love.graphics.getFont():getWidth(text)
        local th = love.graphics.getFont():getHeight()
        love.graphics.print(text, px+32-tw/2, py+60 + #legend*legendSpacing - th/2)
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(lang.t("hardcore").." (h)", px+32 + legendRadius + 12, py+60 + #legend*legendSpacing - legendRadius/1.2)
        love.graphics.setColor(1,1,1,1)
    end
end

function menu.mousepressed(x, y, button)
    -- Blocca tutto se popup credits aperto
    if menu.showCredits then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local pw, ph = 540, 420
        local px, py = (w-pw)/2, (h-ph)/2
        -- Chiudi
        if x >= px+pw/2-60 and x <= px+pw/2+60 and y >= py+ph-50 and y <= py+ph-12 then
            menu.showCredits = false
            sound.play('popup_close')
        end
        return nil
    end
    if _G and _G.state == "resume_popup" then return end
    if button == 1 then
        mouseDragging = true
        lastTouchY = y
    end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local gridW = cols*thumbSize + (cols-1)*spacing
    local nItems = menu.currentCategory and #thumbs or #categories
    local rows = math.ceil(nItems/cols)
    local menuAreaH = h - 2*spacing
    local visibleRows = math.floor(menuAreaH / (thumbSize + spacing))
    -- Scrollbar
    if rows > visibleRows then
        local barH = menuAreaH * visibleRows / rows
        local barY = spacing + (menuAreaH-barH) * (scrollY / math.max(1, (rows-visibleRows)*(thumbSize+spacing)))
        if x >= w-24 and x <= w-12 and y >= barY and y <= barY+barH then
            scrollbarDragging = true
            scrollbarDragOffset = y - barY
            return nil
        end
    end
    local startX = (w - gridW)/2
    -- Calcolo la stessa startY usata nel draw (logoH + 24 - scrollY)
    local logoH = 0
    if logo then
        local lw, lh = logo:getWidth(), logo:getHeight()
        local scale = math.min(w*0.25/lw, 120/lh, 1)
        logoH = lh*scale + 24
    end
    local startY = logoH + 24 - scrollY
    -- Calcolo coordinate pulsante Settings
    local btnW, btnH = 120, 48
    local btnX, btnY = w - btnW - 30, 30
    -- Gestione prioritaria del popup settings
    if menu.showSettings then
        local pw, ph = 420, 400
        local px, py = (w-pw)/2, (h-ph)/2
        -- Lingua IT
        if x >= px+40 and x <= px+180 and y >= py+70 and y <= py+114 then
            lang.set_language("it")
            menu.saveSettings()
            sound.play('button')
            return nil
        end
        -- Lingua EN
        if x >= px+240 and x <= px+380 and y >= py+70 and y <= py+114 then
            lang.set_language("en")
            menu.saveSettings()
            sound.play('button')
            return nil
        end
        -- Musica
        if x >= px+40 and x <= px+72 and y >= py+140 and y <= py+172 then
            music.setMuted(not music.isMuted())
            menu.saveSettings()
            sound.play('button')
            return nil
        end
        -- Suoni
        if x >= px+40 and x <= px+72 and y >= py+200 and y <= py+232 then
            sound.setMuted(not sound.isMuted())
            menu.saveSettings()
            return nil
        end
        -- Fullscreen
        if x >= px+240 and x <= px+272 and y >= py+140 and y <= py+172 then
            menu.fullscreen = not menu.fullscreen
            love.window.setFullscreen(menu.fullscreen)
            menu.saveSettings()
            sound.play('button')
            return nil
        end
        -- Crediti
        if x >= px+40 and x <= px+380 and y >= py+260 and y <= py+304 then
            if not creditsText then
                if love.filesystem.getInfo("credits.txt") then
                    creditsText = love.filesystem.read("credits.txt")
                else
                    creditsText = "" -- fallback
                end
            end
            menu.showCredits = true
            sound.play('popup_open')
            return nil
        end
        -- Chiudi
        if x >= px+pw/2-60 and x <= px+pw/2+60 and y >= py+ph-60 and y <= py+ph-16 then
            menu.showSettings = false
            sound.play('popup_close')
            return nil
        end
        return nil
    end
    -- Popup credits
    if menu.showCredits then
        local pw, ph = 540, 420
        local px, py = (w-pw)/2, (h-ph)/2
        -- Chiudi
        if x >= px+pw/2-60 and x <= px+pw/2+60 and y >= py+ph-50 and y <= py+ph-12 then
            menu.showCredits = false
            sound.play('popup_close')
            return nil
        end
        return nil
    end
    -- Se siamo nella vista categorie
    if not menu.currentCategory then
        for i, cat in ipairs(categories) do
            local row = math.floor((i-1)/cols)
            local col = (i-1)%cols
            local tx = startX + col*(thumbSize+spacing)
            local ty = startY + row*(thumbSize+spacing)
            if y >= ty and y <= ty+thumbSize and x >= tx and x <= tx+thumbSize then
                sound.play('select_image')
                menu.currentCategory = cat
                scrollY = 0
                menu.loadImages()
                return nil
            end
        end
    else
        -- Pulsante indietro
        local backW, backH = 120, 44
        local backX, backY = 30, 30
        if x >= backX and x <= backX+backW and y >= backY and y <= backY+backH then
            sound.play('button')
            menu.currentCategory = nil
            scrollY = 0
            menu.loadImages()
            return nil
        end
        -- Selezione immagine
        for i, thumb in ipairs(thumbs) do
            local row = math.floor((i-1)/cols)
            local col = (i-1)%cols
            local tx = startX + col*(thumbSize+spacing)
            local ty = startY + row*(thumbSize+spacing)
            if y >= ty and y <= ty+thumbSize and x >= tx and x <= tx+thumbSize then
                sound.play('select_image')
                return menu.currentCategory.."/"..images[i]
            end
        end
    end
    -- Pulsante Settings
    if x >= btnX and x <= btnX+btnW and y >= btnY and y <= btnY+btnH then
        sound.play('button')
        menu.showSettings = true
        return nil
    end
    -- Pulsante Esci
    local btnExitW, btnExitH = 120, 48
    local btnExitX, btnExitY = w - btnExitW - 30, h - btnExitH - 30
    if x >= btnExitX and x <= btnExitX+btnExitW and y >= btnExitY and y <= btnExitY+btnExitH then
        sound.play('cancel')
        love.event.quit()
        return nil
    end
    return nil
end

function menu.mousereleased(x, y, button)
    if menu.showCredits then return end
    if _G and _G.state == "resume_popup" then return end
    scrollbarDragging = false
    if button == 1 then
        mouseDragging = false
        lastTouchY = nil
    end
end

function menu.mousemoved(x, y, dx, dy)
    if menu.showCredits then return end
    if _G and _G.state == "resume_popup" then return end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local rows = math.ceil(#thumbs/cols)
    local menuAreaH = h - 2*spacing
    local visibleRows = math.floor(menuAreaH / (thumbSize + spacing))
    if scrollbarDragging and rows > visibleRows then
        local barH = menuAreaH * visibleRows / rows
        local barY = spacing + (menuAreaH-barH) * (scrollY / math.max(1, (rows-visibleRows)*(thumbSize+spacing)))
        local newBarY = y - scrollbarDragOffset
        newBarY = math.max(spacing, math.min(newBarY, spacing + menuAreaH - barH))
        local percent = (newBarY - spacing) / (menuAreaH - barH)
        local maxScroll = math.max(0, (rows-visibleRows)*(thumbSize+spacing))
        scrollY = percent * maxScroll
    end
    -- AGGIUNTA: Simula lo scroll touch col mouse
    if mouseDragging and lastTouchY then
        local logoH = 0
        if logo then
            local lw, lh = logo:getWidth(), logo:getHeight()
            local scale = math.min(w*0.25/lw, 120/lh, 1)
            logoH = lh*scale + 24
        end
        local menuAreaH2 = h - (logoH + 24) - 40
        local visibleRows2 = math.floor(menuAreaH2 / (thumbSize + spacing))
        local maxScroll = math.max(0, (rows-visibleRows2)*(thumbSize+spacing))
        scrollY = math.max(0, math.min(scrollY - (y - lastTouchY), maxScroll))
        lastTouchY = y
    end
end

function menu.touchpressed(id, x, y, dx, dy, pressure)
    if menu.showCredits then return end
    if _G and _G.state == "resume_popup" then return end
    lastTouchY = y
end

function menu.touchmoved(id, x, y, dx, dy, pressure)
    if menu.showCredits then return end
    if _G and _G.state == "resume_popup" then return end
    if lastTouchY then
        local h = love.graphics.getHeight()
        local rows = math.ceil(#thumbs/cols)
        local logoH = 0
        if logo then
            local w = love.graphics.getWidth()
            local lw, lh = logo:getWidth(), logo:getHeight()
            local scale = math.min(w*0.25/lw, 120/lh, 1)
            logoH = lh*scale + 24
        end
        local menuAreaH = h - (logoH + 24) - 40
        local visibleRows = math.floor(menuAreaH / (thumbSize + spacing))
        local maxScroll = math.max(0, (rows-visibleRows)*(thumbSize+spacing))
        scrollY = math.max(0, math.min(scrollY - (y - lastTouchY), maxScroll))
        lastTouchY = y
    end
end

function menu.touchreleased(id, x, y, dx, dy, pressure)
    if menu.showCredits then return end
    if _G and _G.state == "resume_popup" then return end
    lastTouchY = nil
end

function menu.wheelmoved(x, y)
    if menu.showCredits then
        local pw, ph = 540, 420
        local textAreaH = ph-120
        local font = love.graphics.getFont()
        local textAreaW = pw-64
        if creditsText then
            local _, wrapped = font:getWrap(creditsText, textAreaW)
            local textHeight = #wrapped * font:getHeight()
            if textHeight > textAreaH then
                creditsScroll = math.max(0, math.min(creditsScroll - y*40, textHeight-textAreaH))
            end
        end
        return
    end
    if _G and _G.state == "resume_popup" then return end
    if menu.showSettings then return end
    local rows = math.ceil(#thumbs/cols)
    local h = love.graphics.getHeight()
    -- Calcolo logoH come nel draw
    local logoH = 0
    if logo then
        local w = love.graphics.getWidth()
        local lw, lh = logo:getWidth(), logo:getHeight()
        local scale = math.min(w*0.25/lw, 120/lh, 1)
        logoH = lh*scale + 24
    end
    local menuAreaH = h - (logoH + 24) - 40 -- spazio effettivo per la griglia
    local visibleRows = math.floor(menuAreaH / (thumbSize + spacing))
    local maxScroll = math.max(0, (rows-visibleRows)*(thumbSize+spacing))
    scrollY = math.max(0, math.min(scrollY - y*40, maxScroll))
end

function menu.keypressed(key)
    if menu.showCredits then return end
    if _G and _G.state == "resume_popup" then return end
    local rows = math.ceil(#thumbs/cols)
    local maxScroll = math.max(0, (rows-visibleRows)*(thumbSize+spacing))
    if key == "down" then
        scrollY = math.min(scrollY + thumbSize + spacing, maxScroll)
    elseif key == "up" then
        scrollY = math.max(scrollY - (thumbSize + spacing), 0)
    end
end

return menu 