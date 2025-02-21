function getAllTouches()
    local touchArr = love.touch.getTouches()
    local touches = {}
    for i,v in ipairs(touchArr) do
        local x, y = love.touch.getPosition(v)
        touches[v] = {id = v, x = x, y = y}
    end
    if love.mouse.isDown(1) and love.system.getOS() == "Windows" then
        local x, y = love.mouse.getPosition()
        touches["mouse"] = {id = "mouse", x = x, y = y}
    end
    return touches
end