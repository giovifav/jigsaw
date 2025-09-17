local music = {}
local tracks = {}
local currentSource = nil
local currentIndex = nil
local FADE_TIME = 1 -- secondi per il fade
local fadeState = nil -- nil, 'out', 'in'
local fadeTimer = 0
local nextIndex = nil
local musicMuted = false

-- Carica tutte le tracce dalla cartella music/
function music.load()
    local files = love.filesystem.getDirectoryItems("music")
    for _, file in ipairs(files) do
        if file:match("%.mp3$") then
            table.insert(tracks, "music/"..file)
        end
    end
    music.loadMuteState()
    if #tracks > 0 and not musicMuted then
        music.playRandom(true)
    end
end

function music.playRandom(immediate)
    if #tracks == 0 or musicMuted then return end
    -- Shuffle e scegli una traccia diversa da quella attuale
    local idx = love.math.random(1, #tracks)
    if #tracks > 1 and idx == currentIndex then
        idx = (idx % #tracks) + 1
    end
    if immediate then
        -- Avvia subito senza fade
        if currentSource then currentSource:stop() end
        currentIndex = idx
        currentSource = love.audio.newSource(tracks[idx], "stream")
        currentSource:setLooping(false)
        currentSource:setVolume(0.5)
        currentSource:play()
        fadeState = nil
        fadeTimer = 0
        nextIndex = nil
    else
        -- Avvia fade out
        fadeState = 'out'
        fadeTimer = 0
        nextIndex = idx
    end
end

function music.update(dt)
    if fadeState == 'out' and currentSource then
        fadeTimer = fadeTimer + dt
        local v = math.max(0, 0.5 * (1 - fadeTimer / FADE_TIME))
        currentSource:setVolume(v)
        if fadeTimer >= FADE_TIME then
            currentSource:stop()
            -- Avvia la nuova traccia con volume 0
            currentIndex = nextIndex
            currentSource = love.audio.newSource(tracks[nextIndex], "stream")
            currentSource:setLooping(false)
            currentSource:setVolume(0)
            currentSource:play()
            fadeState = 'in'
            fadeTimer = 0
        end
    elseif fadeState == 'in' and currentSource then
        fadeTimer = fadeTimer + dt
        local v = math.min(0.5, 0.5 * (fadeTimer / FADE_TIME))
        currentSource:setVolume(v)
        if fadeTimer >= FADE_TIME then
            currentSource:setVolume(0.5)
            fadeState = nil
            fadeTimer = 0
            nextIndex = nil
        end
    elseif currentSource and not currentSource:isPlaying() and fadeState == nil then
        music.playRandom(false)
    end
end

function music.stop()
    if currentSource then
        currentSource:stop()
    end
    fadeState = nil
    fadeTimer = 0
    nextIndex = nil
end

function music.isPlaying()
    return currentSource ~= nil and currentSource:isPlaying() and fadeState ~= 'out'
end

function music.isMuted()
    return musicMuted
end

function music.setMuted(val)
    musicMuted = val and true or false
    if musicMuted then
        music.stop()
    else
        if not music.isPlaying() then
            music.playRandom(true)
        end
    end
end

function music.loadMuteState()
    -- Vuota: la persistenza è gestita da menu.loadSettings()
end

function music.saveMuteState()
    -- Vuota: la persistenza è gestita da menu.saveSettings()
end

return music 