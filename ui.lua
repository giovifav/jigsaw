local ui = {}

-- Palette colori chiari e naturali
ui.colors = {
    bg1 = {0.96,0.97,0.98,1},
    bg2 = {0.92,0.93,0.95,1},
    bg3 = {0.89,0.89,0.91,1},
    bg4 = {0.98,0.98,0.99,1},
    border = {0.7,0.7,0.7,1},
    text = {0,0,0,1},
    shadow = {0,0,0,0.10},
    button_hover = {0.8,0.85,0.9,1},
    button_selected = {0.7,0.8,0.9,1},
}

-- Gradienti standard
ui.gradients = {
    button = function(w, h)
        return love.graphics.newMesh({
            {0,0, 0,0, unpack(ui.colors.bg4)},
            {w,0, 1,0, unpack(ui.colors.bg2)},
            {w,h, 1,1, unpack(ui.colors.bg3)},
            {0,h, 0,1, unpack(ui.colors.bg1)}
        }, "fan")
    end,
    window = function(w, h)
        return love.graphics.newMesh({
            {0,0, 0,0, 0.99,0.99,0.99,1},
            {w,0, 1,0, 0.97,0.97,0.97,1},
            {w,h, 1,1, 0.95,0.95,0.95,1},
            {0,h, 0,1, 0.99,0.99,0.99,1}
        }, "fan")
    end
}

-- Font centralizzato (richiede che venga caricato in main.lua e assegnato a ui.fonts)
ui.fonts = nil -- verrà assegnato a _G.caviarFont
local currentFontSize = 18

function ui.setFontGlobale(size)
    if ui.fonts and ui.fonts[size] then
        love.graphics.setFont(ui.fonts[size])
        currentFontSize = size
    end
end

function ui.getFontGlobale()
    return currentFontSize
end

function ui.setFont(size)
    ui.setFontGlobale(size)
end

-- Disegna un bottone standard
function ui.drawButton(x, y, w, h, testo, stato, opts)
    opts = opts or {}
    local grad = ui.gradients.button(w, h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad, x, y)
    love.graphics.setColor(ui.colors.border)
    love.graphics.setLineWidth(opts.lineWidth or 2)
    love.graphics.rectangle("line", x, y, w, h, opts.radius or 9, opts.radius or 9)
    love.graphics.setLineWidth(1)
    if stato == "hover" then
        love.graphics.setColor(ui.colors.button_hover)
        love.graphics.rectangle("fill", x, y, w, h, opts.radius or 9, opts.radius or 9)
    elseif stato == "selected" then
        love.graphics.setColor(ui.colors.button_selected)
        love.graphics.rectangle("fill", x, y, w, h, opts.radius or 9, opts.radius or 9)
    end
    love.graphics.setColor(ui.colors.text)
    ui.setFont(opts.fontSize or 18)
    love.graphics.printf(testo, x, y + (h-(opts.fontSize or 18))/2, w, "center")
    love.graphics.setColor(1,1,1,1)
end

-- Disegna una finestra/popup standard
function ui.drawWindow(x, y, w, h, titolo, opts)
    opts = opts or {}
    local grad = ui.gradients.window(w, h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(grad, x, y)
    love.graphics.setColor(ui.colors.border)
    love.graphics.setLineWidth(opts.lineWidth or 4)
    love.graphics.rectangle("line", x, y, w, h, opts.radius or 9, opts.radius or 9)
    love.graphics.setLineWidth(1)
    if titolo then
        love.graphics.setColor(ui.colors.text)
        ui.setFont(opts.titleFontSize or 26)
        love.graphics.printf(titolo, x, y+20, w, "center")
        love.graphics.setColor(1,1,1,1)
    end
end

-- Disegna una checkbox con etichetta
function ui.drawCheckbox(x, y, size, checked, label, opts)
    opts = opts or {}
    -- Box
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", x, y, size, size, 6, 6)
    love.graphics.setColor(ui.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, size, size, 6, 6)
    love.graphics.setLineWidth(1)
    -- Spunta
    if checked then
        love.graphics.setColor(0.2, 0.6, 1, 1)
        love.graphics.setLineWidth(4)
        love.graphics.line(x+5, y+size/2, x+size/2, y+size-5, x+size-5, y+5)
        love.graphics.setLineWidth(1)
    end
    -- Etichetta
    love.graphics.setColor(ui.colors.text)
    ui.setFont(opts.fontSize or 22)
    love.graphics.print(label, x + size + 16, y + size/2 - (opts.fontSize or 22)/2)
    love.graphics.setColor(1,1,1,1)
end

function ui.loadFonts()
    ui.fonts = {}
    ui.fonts[16] = love.graphics.newFont("assets/caviar.ttf", 16)
    ui.fonts[18] = love.graphics.newFont("assets/caviar.ttf", 18)
    ui.fonts[22] = love.graphics.newFont("assets/caviar.ttf", 22)
    ui.fonts[24] = love.graphics.newFont("assets/caviar.ttf", 24)
    ui.fonts[26] = love.graphics.newFont("assets/caviar.ttf", 26)
    ui.fonts[32] = love.graphics.newFont("assets/caviar.ttf", 32)
    ui.fonts[36] = love.graphics.newFont("assets/caviar.ttf", 36)
    ui.fonts[38] = love.graphics.newFont("assets/caviar.ttf", 38)
    ui.fonts[40] = love.graphics.newFont("assets/caviar.ttf", 40)
    ui.fonts[54] = love.graphics.newFont("assets/caviar.ttf", 54)
end

return ui 