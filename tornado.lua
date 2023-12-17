local M = {
    GENERATOR_OFF = 0,
    GENERATOR_ON = 1,

    MIST_OFF = 0,
    MIST_LOW1 = 1,
    MIST_LOW2 = 2,
    MIST_LOW3 = 4,
    MIST_MEDIUM1 = 3,
    MIST_MEDIUM2 = 5,
    MIST_MEDIUM3 = 6,
    MIST_FULL = 7,

    FAN_OFF = 0,
    FAN_LVL1 = 1, -- 62 Ohm
    FAN_LVL2 = 2, -- 43 Ohm
    FAN_LVL3 = 4, -- 27 Ohm
    FAN_LVL4 = 3, -- 62||43 ≈ 25 Ohm
    FAN_LVL5 = 5, -- 62||27 ≈ 18 Ohm
    FAN_LVL6 = 6, -- 43||27 ≈ 17 Ohm
    FAN_LVL7 = 7,  -- 62||43||27 ≈ 13 Ohm

    -- debug = false
}

local PIN_DATA = 5
local PIN_CLK = 7
local PIN_LATCH = 6

local genstate = M.GENERATOR_OFF
local mistmode = M.MIST_OFF
local fanlvl = M.FAN_OFF

local prev_ctlbyte = 0

local function shiftreg_transfer(byte)
    gpio.write(PIN_LATCH, gpio.LOW)
    for i = 1, 8 do
        local b = bit.band(byte, 0x80)
        gpio.write(PIN_CLK, gpio.LOW)
        gpio.write(PIN_DATA, b ~= 0 and gpio.HIGH or gpio.LOW)
        gpio.write(PIN_CLK, gpio.HIGH)
        byte = bit.lshift(byte, 1)
    end
    gpio.write(PIN_LATCH, gpio.HIGH)
end

local function update_shiftreg()
    local ctlbyte = bit.bor(bit.lshift(fanlvl, 5), bit.lshift(genstate, 4), bit.lshift(mistmode, 1))
    if ctlbyte ~= prev_ctlbyte then
        shiftreg_transfer(ctlbyte)
        prev_ctlbyte = ctlbyte
    end
end

--[[
local function debug_print(...)
    if M.debug then
        print(...)
    end
end --]]

function M.gen(state)
    genstate = bit.band(state, 1)
    if genstate == M.GENERATOR_OFF then
        -- debug_print('Generator off')
        if mistmode ~= M.MIST_OFF then
            -- debug_print('Mist off')
            mistmode = M.MIST_OFF
        end
    else
        -- debug_print('Generator on')
    end
    update_shiftreg()
end

function M.mist(mode)
    mistmode = bit.band(mode, 7)
    if mistmode ~= M.MIST_OFF then
        -- debug_print('Mist mode '..mistmode)
        if genstate == M.GENERATOR_OFF then
            -- debug_print('Generator on')
            genstate = M.GENERATOR_ON
        end
        if fanlvl == M.FAN_OFF then
            -- debug_print('Fan on')
            fanlvl = M.FAN_LVL2 -- 1 is too low
        end
    else
        -- debug_print('Mist off')
    end
    update_shiftreg()
end

function M.fan(level)
    fanlvl = bit.band(level, 7)
    if fanlvl == M.FAN_OFF then
        -- debug_print('Fan off')
        if mistmode ~= M.MIST_OFF then
            -- debug_print('Mist off')
            mistmode = M.MIST_OFF
        end
    else
        -- debug_print('Fan level '..fanlvl)
    end
    update_shiftreg()
end

gpio.mode(PIN_LATCH, gpio.OUTPUT)
gpio.mode(PIN_CLK, gpio.OUTPUT)
gpio.mode(PIN_DATA, gpio.OUTPUT)
gpio.write(PIN_LATCH, gpio.HIGH)
gpio.write(PIN_CLK, gpio.HIGH)
gpio.write(PIN_DATA, gpio.LOW)
shiftreg_transfer(0)

return M