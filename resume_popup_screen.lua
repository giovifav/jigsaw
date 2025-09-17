local menu = require "menu"
local ui = require "ui"
local lang = require "lang"
local puzzle = require "puzzle"

local ResumePopupScreen = {}
ResumePopupScreen.selectedImage = nil
ResumePopupScreen.pendingStartN = nil
ResumePopupScreen.pendingHardcore = nil
ResumePopupScreen._hoveredBtn = nil
ResumePopupScreen.changeStateWithFade = nil -- deve essere assegnata da main.lua

function ResumePopupScreen.updateHover(mx, my)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local pw, ph = 420, 220
    local px, py = (w-pw)/2, (h-ph)/2
    local btnW, btnH = 160, 50
    local btnY = py+ph-70
    ResumePopupScreen._hoveredBtn = nil
    if mx >= px+30 and mx <= px+30+btnW and my >= btnY and my <= btnY+btnH then
        ResumePopupScreen._hoveredBtn = "resume"
    elseif mx >= px+pw-btnW-30 and mx <= px+pw-30 and my >= btnY and my <= btnY+btnH then
        ResumePopupScreen._hoveredBtn = "new"
    end
end

function ResumePopupScreen.setCursor()
    if ResumePopupScreen._hoveredBtn then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
end

function ResumePopupScreen.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local pw, ph = 420, 220
    local px, py = (w-pw)/2, (h-ph)/2
    local grad = love.graphics.newMesh({
        {0,0, 0,0, 0.96,0.97,0.98,0.75},
        {w,0, 1,0, 0.92,0.93,0.95,0.75},
        {w,h, 1,1, 0.89,0.89,0.91,0.75},
        {0,h, 0,1, 0.98,0.98,0.99,0.75}
    }, "fan")
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad,0,0)
    ui.drawWindow(px, py, pw, ph, lang.t("resume_popup"), {titleFontSize=26, radius=9})
    ui.setFont(18)
    local btnW, btnH = 160, 50
    local btnY = py+ph-70
    local resumeState = ResumePopupScreen._hoveredBtn=="resume" and "hover" or nil
    local newState = ResumePopupScreen._hoveredBtn=="new" and "hover" or nil
    ui.drawButton(px+30, btnY, btnW, btnH, lang.t("riprendi"), resumeState, {fontSize=18, radius=9})
    ui.drawButton(px+pw-btnW-30, btnY, btnW, btnH, lang.t("nuova_partita"), newState, {fontSize=18, radius=9})
    love.graphics.setColor(1,1,1,1)
end

function ResumePopupScreen.mousepressed(x, y, button)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local pw, ph = 420, 220
    local px, py = (w-pw)/2, (h-ph)/2
    local btnW, btnH = 160, 50
    local btnY = py+ph-70
    if x >= px+30 and x <= px+30+btnW and y >= btnY and y <= btnY+btnH then
        print("[DEBUG] ResumePopupScreen.mousepressed: chiamo changeStateWithFade('gioco')")
        puzzle.load("img/"..ResumePopupScreen.selectedImage, ResumePopupScreen.pendingStartN, ResumePopupScreen.pendingHardcore)
        if ResumePopupScreen.changeStateWithFade then
            ResumePopupScreen.changeStateWithFade("gioco")
        end
        -- Chiudo il popup
        ResumePopupScreen.selectedImage = nil
        ResumePopupScreen.pendingStartN = nil
        ResumePopupScreen.pendingHardcore = nil
        print("[DEBUG] ResumePopupScreen: popup chiuso, stato impostato a 'gioco'")
        return true
    end
    if x >= px+pw-btnW-30 and x <= px+pw-30 and y >= btnY and y <= btnY+btnH then
        local fname = "save_"..ResumePopupScreen.selectedImage..".json"
        if love.filesystem.getInfo(fname) then
            love.filesystem.remove(fname)
        end
        print("[DEBUG] ResumePopupScreen.mousepressed: chiamo changeStateWithFade('gioco')")
        puzzle.load("img/"..ResumePopupScreen.selectedImage, ResumePopupScreen.pendingStartN, ResumePopupScreen.pendingHardcore, true)
        if ResumePopupScreen.changeStateWithFade then
            ResumePopupScreen.changeStateWithFade("gioco")
        end
        -- Chiudo il popup
        ResumePopupScreen.selectedImage = nil
        ResumePopupScreen.pendingStartN = nil
        ResumePopupScreen.pendingHardcore = nil
        print("[DEBUG] ResumePopupScreen: popup chiuso, stato impostato a 'gioco'")
        return true
    end
    return nil
end

function ResumePopupScreen.mousemoved(x, y, dx, dy)
    ResumePopupScreen.updateHover(x, y)
    ResumePopupScreen.setCursor()
end

function ResumePopupScreen.wheelmoved(x, y) end
function ResumePopupScreen.mousereleased(x, y, button) end
function ResumePopupScreen.touchpressed(id, x, y, dx, dy, pressure) end
function ResumePopupScreen.touchmoved(id, x, y, dx, dy, pressure) end
function ResumePopupScreen.touchreleased(id, x, y, dx, dy, pressure) end

return ResumePopupScreen
