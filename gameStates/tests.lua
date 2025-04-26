local thisState = {}

local touchMovementArr = {}
local ignoreNextTouch = {}

local consoleBuffer = {}
local MAX_CONSOLE_BUFFER_SIZE = 10

local startTimer = love.timer.getTime()
local timer = 0

local BLOCK_SPEED = 250
local HIT_TRESHOLD = 0.2
--[[
local blocks = {
    {direction="right",time=2.5, draw=false},
    {direction="down",time=3, draw=false},
    {direction="left",time=3.5, draw=false},
    {direction="up",time=4, draw=false},
    {direction="tap",time=4.5, draw=false},
}
]]

local blocks = {}
for i = 1, 1 do
    local dirTable = {"right", "down", "left", "up", "tap"}
    local dir = dirTable[math.random(5,5)]

    table.insert(blocks, {direction=dir, time=i + 3, draw=false})
end
local drawBlocks = {}

--ARRUMAR ESSA PORRA
local function drawCenteredFix(_Draw, _X, _Y, _R, _Sx , _Sy)
    local draw = img[_Draw]
    local width, height = draw:getDimensions()
    love.graphics.draw(draw, _X, _Y, _R, _Sx, _Sy ,width/2, height/2)
end

function onHit(_Direction, _Diff)
    screenPrint(string.format("Block %s hit, diff: %f", _Direction, _Diff))
end
function onMiss(_Direction, _Diff)
    screenPrint(string.format("Block %s missed, diff: %f", _Direction, _Diff))
end
function onBlockForget(_Time)
    screenPrint("Block forgotten: ".._Time)
end
function onNotHit()
    screenPrint("No block hit")
end

function handleTouchRaw(_Id, _StartX, _StartY, _DeltaX, _DeltaY)
    local dx, dy = _DeltaX, _DeltaY

    local angle = math.getAngle(0,0,dx,dy) % (2*math.pi)
    local distance = math.getDistance(0,0,dx,dy)

    if distance < 50 then
        handleTouch("tap", _Id, _DeltaX, _DeltaY)
        return
    end

    local treshold = math.pi/8
    if inLimits(angle, 0 - treshold, 0 + treshold) then
        handleTouch("right", _Id, _DeltaX, _DeltaY) return
    end
    if inLimits(angle, math.pi/2 - treshold, math.pi/2 + treshold) then
        handleTouch("down", _Id, _DeltaX, _DeltaY) return
    end
    if inLimits(angle, math.pi - treshold, math.pi + treshold) then
        handleTouch("left", _Id, _DeltaX, _DeltaY) return
    end
    if inLimits(angle, 3*math.pi/2 - treshold, 3*math.pi/2 + treshold) then
        handleTouch("up", _Id, _DeltaX, _DeltaY) return
    end
end

function handleTouch(_Direction, _Id, _DeltaX, _DeltaY)
    local hasHitBlock = false

    for i,v in pairs(ignoreNextTouch) do
        print(i,v,_Id)
        if v == _Id then
            table.remove(ignoreNextTouch,i)
            return
        end
    end
    print("-----", timer)
    print(_Direction)
    for i,v in pairs(blocks) do
        print("block",i, v.time)
        local diff = timer - v.time
        if inLimits(diff, -HIT_TRESHOLD, HIT_TRESHOLD) then
            print("hit", v.time)
            hasHitBlock = true
            if v.direction == _Direction then
                onHit(v.direction, diff)
            else
                onMiss(v.direction, diff)
            end
            table.remove(blocks, i) print("deleted", i, v.time)
            break
        end

        if inLimits(diff, -2*HIT_TRESHOLD, 2*HIT_TRESHOLD) then
            print("miss", v.time)
            onMiss(v.direction, diff)
            table.remove(blocks, i) print("deleted", i, v.time)
            break
        end
    end

    if not hasHitBlock then
        onNotHit()
    end
end

function screenPrint(msg)
    table.insert(consoleBuffer, msg)
    if #consoleBuffer > MAX_CONSOLE_BUFFER_SIZE then
        table.remove(consoleBuffer, 1)
    end
end

function thisState.load()
    print(json.encode(img))
end

function thisState.update(_Dt)
    -- Para cada toque
    local touches = getAllTouches()
    for i,v in pairs(touches) do
        -- Se já existir no arr desenha linha, senão cria no array
        if touchMovementArr[v.id] then
            --touchMovementArr[v.id].endPos = {x = v.x, y = v.y} -- Atualiza a posição final
        else
            touchMovementArr[v.id] = {
                start={x = v.x, y = v.y}, 
                endPos={x = v.x, y = v.y}, 
                maxPos={x = v.x, y=v.y}
            }
        end
        touchMovementArr[v.id].endPos = {x = v.x, y = v.y} -- Atualiza a posição final
        local localMove = touchMovementArr[v.id]

        local endDist =  math.getDistance(
            localMove.start.x,
            localMove.start.y,
            localMove.endPos.x,
            localMove.endPos.y
        )
        local maxDist =  math.getDistance(
            localMove.start.x,
            localMove.start.y,
            localMove.maxPos.x,
            localMove.maxPos.y
        )
        localMove.endPos.dist = endDist
        localMove.maxPos.dist = maxDist
        if endDist > maxDist then
            localMove.maxPos = {
                x = localMove.endPos.x,
                y = localMove.endPos.y
            }
        end

    end
    -- Para cada toque no array dos movimentos
    for i,v in pairs(touchMovementArr) do
        local maxDist = v.maxPos.dist or 0
        local endDist = v.endPos.dist or 0
        if maxDist > 50 and endDist < 20 then
            handleTouch("testeNovo",i,0,0)
            table.insert(ignoreNextTouch,i)
            touchMovementArr[i] = nil
        end
        
        if not touches[i] then -- Se não existir mais no array de toques, remove do array de movimentos
            local x = v.endPos.x - v.start.x
            local y = v.endPos.y - v.start.y

            handleTouchRaw(i, v.start.x, v.start.y, x, y)
            touchMovementArr[i] = nil
        end


    end

    timer = love.timer.getTime() - startTimer

    for i,v in ipairs(blocks) do
        local timeToReach = 500 / BLOCK_SPEED
        if timer > blocks[i].time - timeToReach and not blocks[i].draw then
            table.insert(drawBlocks, blocks[i])
            blocks[i].draw = true
        end

        local diff = timer - v.time
        if diff > HIT_TRESHOLD then
            onBlockForget(v.time)
            table.remove(blocks, i) print("deleted", i, v.time)
        end
    end


end

function thisState.draw()
    -- Desenha o console
    for i,v in ipairs(consoleBuffer) do
        love.graphics.print(v, 0, i*12)
    end
    
    local lineY = 500
    local centerX = love.graphics.getWidth() / 2
    love.graphics.line(0, lineY, love.graphics.getWidth(), lineY)
    for i,v in ipairs(drawBlocks) do
        local diff = timer - v.time
        local x = centerX
        local y = lineY + diff * BLOCK_SPEED

        love.graphics.circle("line", x, y, 10)
        love.graphics.print(v.direction, x, y+30)
        love.graphics.print(v.time, x, y + 40)

        if v.direction == "tap" then
            drawCenteredFix("circle_block", x, y,0,0.3,0.3)
        else
            local strToAngle = {
                right = 0,
                down = math.pi/2,
                left = math.pi,
                up = 3*math.pi/2
            }
            local direction = strToAngle[v.direction]
            drawCenteredFix("direction_block", x, y, direction, 0.3, 0.3)
        end

    end

    for i,v in pairs(blocks) do
        love.graphics.print(v.time, 200, i*12)
    end

    for i,v in pairs(touchMovementArr) do
        love.graphics.line(
            v.start.x,
            v.start.y,
            v.endPos.x,
            v.endPos.y
        )

        love.graphics.circle(
            "fill",
            v.maxPos.x,
            v.maxPos.y,
            20
        )
    end

    love.graphics.print("Timer: "..timer, 200, 0)
end

return thisState