local thisState = {}

local touchMovementArr = {}
local consoleBuffer = {}
local MAX_CONSOLE_BUFFER_SIZE = 10
function screenPrint(msg)
    table.insert(consoleBuffer, msg)
    if #consoleBuffer > MAX_CONSOLE_BUFFER_SIZE then
        table.remove(consoleBuffer, 1)
    end
end

function thisState.load()

end

function thisState.update(_Dt)

end

function thisState.draw()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local str = string.format("Screen Size: %f x %f", screenWidth, screenHeight)
    love.graphics.print(str, 0, 0)

    -- Para cada toque
    local touches = getAllTouches()
    for i,v in pairs(touches) do

        -- Se já existir no arr desenha linha, senão cria no array
        if touchMovementArr[v.id] then
            love.graphics.line(touchMovementArr[v.id].start.x, touchMovementArr[v.id].start.y, v.x, v.y)
        else
            touchMovementArr[v.id] = {start={x = v.x, y = v.y}, endPos={x = v.x, y = v.y}}
        end
        touchMovementArr[v.id].endPos = {x = v.x, y = v.y} -- Atualiza a posição final
    end

    -- Para cada toque no array dos movimentos
    for i,v in pairs(touchMovementArr) do
        if not touches[i] then -- Se não existir mais no array de toques, remove do array de movimentos
            local x = v.endPos.x - v.start.x
            local y = v.endPos.y - v.start.y

            local str = string.format("%s: %s x %s", i, x, y)
            print(str)
            screenPrint(str)
            touchMovementArr[i] = nil
        end
    end

    -- Desenha o console
    for i,v in ipairs(consoleBuffer) do
        love.graphics.print(v, 0, i*12)
    end
end

return thisState