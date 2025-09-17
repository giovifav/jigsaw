local utils = {}

local json = require("dkjson")

function utils.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function utils.save_json(filename, data)
    local str = json.encode(data, { indent = false })
    return love.filesystem.write(filename, str)
end

function utils.load_json(filename)
    if love.filesystem.getInfo(filename) then
        local str = love.filesystem.read(filename)
        return json.decode(str)
    end
    return nil
end

return utils 