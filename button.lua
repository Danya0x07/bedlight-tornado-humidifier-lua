local M = {
    -- callback_1press = function () print('Press') end,
    -- callback_2press = function () print('DoublePress') end,
    -- callback_3press = function () print('TripplePress') end,
    -- callback_longpress = function () print('LongPress') end
}

local PIN_BTN = 1

local timer = tmr.create()
local timestamp = 0
local presscount = 0

local function check_will_stay_pressed()
    local cb = M.callback_longpress
    timer:alarm(60, tmr.ALARM_SINGLE, cb)
    presscount = 0
end

local function check_will_not_transit()
    local cb
    if presscount == 1 then
        cb = M.callback_1press
    elseif presscount == 2 then
        cb = M.callback_2press
    else
        cb = M.callback_3press
    end
    timer:alarm(60, tmr.ALARM_SINGLE, cb)
    presscount = 0
end

local function on_trig(level, when, eventcount)
    if when - timestamp >= 5000 then
        level = gpio.read(PIN_BTN)
        if level == gpio.HIGH then  -- press
            presscount = presscount + 1

            if presscount == 1 then
                timer:alarm(2500, tmr.ALARM_SINGLE, check_will_stay_pressed)
            elseif presscount < 3 then
                timer:alarm(250, tmr.ALARM_SINGLE, check_will_not_transit)
            end
        else  -- release

            if presscount > 0 then
                timer:alarm(250, tmr.ALARM_SINGLE, check_will_not_transit)
            end
        end
        timestamp = when
    end
end

gpio.mode(PIN_BTN, gpio.INT)
gpio.trig(PIN_BTN, 'both', on_trig)

return M