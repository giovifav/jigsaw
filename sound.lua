local sound = {}

local sources = {}
local events = {
    button = {"sounds/cursor1.ogg",
              "sounds/cursor2.ogg",
              "sounds/cursor3.ogg",
              "sounds/cursor4.ogg",
              "sounds/cursor5.ogg"},
    select_image = {"sounds/select1.ogg"},
    swap_piece = {"sounds/swipe1.ogg", "sounds/swipe2.ogg"},
    error = {"sounds/error1.ogg"},
    cancel = {"sounds/cancel1.ogg", "sounds/cancel2.ogg"},
    popup_open = {"sounds/popup_open1.ogg"},
    popup_close = {"sounds/popup_close1.ogg"},
    select_piece = {"sounds/select2.ogg"},
    win = {"sounds/select1.ogg"}
}

local soundMuted = false

function sound.isMuted()
    return soundMuted
end

function sound.setMuted(val)
    soundMuted = val and true or false
end

function sound.loadMuteState()
    -- Vuota: la persistenza è gestita da menu.loadSettings()
end

function sound.saveMuteState()
    -- Vuota: la persistenza è gestita da menu.saveSettings()
end

function sound.load()
    for event, files in pairs(events) do
        sources[event] = {}
        for _, file in ipairs(files) do
            if love.filesystem.getInfo(file) then
                table.insert(sources[event], love.audio.newSource(file, "static"))
            end
        end
    end
    sound.loadMuteState()
end

function sound.play(event)
    if soundMuted then return end
    if sources[event] and #sources[event] > 0 then
        -- Scegli un suono casuale tra quelli disponibili per l'evento
        local idx = math.random(1, #sources[event])
        local src = sources[event][idx]
        src:stop()
        src:play()
    end
end

return sound 