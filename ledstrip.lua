local M = {}

local levels = {
    {1, 9},
    {10, 21},
    {34, 45},
    {22, 33}
}

local brightness_divs = {
    4, 2, 1
}
local brightness_div_no = 0

local COLOR_OFF = {0, 0, 0}
local COLOR_RED = {255, 0, 0}
local COLOR_GREEN = {0, 255, 0}
local COLOR_BLUE = {0, 0, 255}
local COLOR_YELLOW = {255, 255, 0}
local COLOR_VIOLET = {255, 0, 255}
local COLOR_CYAN = {0, 255, 255}
local COLOR_WHITE = {255, 255, 255}
local COLOR_WHITEWARM = {255, 220, 170}
local COLOR_ORANGE = {255, 86, 0}

local levels_colors = {COLOR_OFF, COLOR_OFF, COLOR_OFF, COLOR_OFF}

local lighting_confs = {
    {COLOR_OFF, COLOR_OFF},
    {COLOR_OFF, COLOR_WHITEWARM},
    {COLOR_WHITEWARM, COLOR_WHITEWARM},
    {COLOR_OFF, COLOR_WHITE},
    {COLOR_BLUE, COLOR_CYAN},
    {COLOR_BLUE, COLOR_VIOLET},
    {COLOR_RED, COLOR_VIOLET},
    {COLOR_RED, COLOR_ORANGE},
    {COLOR_GREEN, COLOR_CYAN},
    {COLOR_GREEN, COLOR_YELLOW},
}
local lighting_state = 0

local timer = tmr.create()
--[[
local effect_angle = 0
local function effect_cb()
    local a1 = effect_angle
    local a2 = effect_angle + 30
    local a3 = effect_angle + 60
    local a4 = effect_angle + 120
    
    a1 = a1 < 360 and a1 or a1 - 360
    a2 = a2 < 360 and a2 or a2 - 360
    a3 = a3 < 360 and a3 or a3 - 360
    a4 = a4 < 360 and a4 or a4 - 360

    effect_angle = (effect_angle + 1) % 360
    
    local g, r, b
    g, r, b = color_utils.colorWheel(a1)
    local c1 = {r, g, b}
    g, r, b = color_utils.colorWheel(a2)
    local c2 = {r, g, b}
    g, r, b = color_utils.colorWheel(a3)
    local c3 = {r, g, b}
    g, r, b = color_utils.colorWheel(a4)
    local c4 = {r, g, b}

    M.set_level_color(1, c1)
    M.set_level_color(2, c2)
    M.set_level_color(3, c3)
    M.set_level_color(4, c4, true)
end --]]

local buffer = pixbuf.newBuffer(45, 3)

function M.set_level_color(lvl, col, refresh)
    local div = brightness_divs[brightness_div_no + 1]
    for ledno = levels[lvl][1], levels[lvl][2] do
        buffer:set(ledno, 
            col[2] / div, 
            col[1] / div,
            col[3] / div)
    end
    levels_colors[lvl] = col

    if refresh then
        ws2812.write(buffer)
    end
end

function M.set_levels_colors(c1, c2, c3, c4)
    local colortable = {
        ['0'] = COLOR_OFF,
        ['r'] = COLOR_RED,
        ['g'] = COLOR_GREEN,
        ['b'] = COLOR_BLUE,
        ['y'] = COLOR_YELLOW,
        ['c'] = COLOR_CYAN,
        ['v'] = COLOR_VIOLET,
        ['o'] = COLOR_ORANGE
    }
    c1 = colortable[c1]
    c2 = colortable[c2]
    c3 = colortable[c3]
    c4 = colortable[c4]

    if c1 and c2 and c3 and c4 then
        M.set_level_color(1, c1)
        M.set_level_color(2, c2)
        M.set_level_color(3, c3)
        M.set_level_color(4, c4, true)
        return true
    else
        return false
    end
end

function M.on_setting_light()
    M.set_level_color(1, COLOR_OFF, true)
end

function M.on_setting_tornado()
    M.set_level_color(1, COLOR_BLUE, true)
end

function M.on_autoctl_change(autoctl)
    if autoctl then
        M.set_level_color(1, COLOR_VIOLET, true)
    else
        M.set_level_color(1, COLOR_YELLOW, true)
    end
    timer:alarm(300, tmr.ALARM_SINGLE, function ()
        M.set_level_color(1, COLOR_BLUE, true)
    end)
end

function M.on_low_water()
    M.set_level_color(1, COLOR_RED, true)
end

function M.on_ap()
    M.set_level_color(4, COLOR_BLUE, true)
end

function M.on_connecting()
    M.set_level_color(4, COLOR_RED, true)
end

function M.on_connected()
    M.set_level_color(4, COLOR_GREEN, true)
end

function M.on_wifi_off()
    M.set_level_color(4, COLOR_OFF, true)
end

function M.next_lighting()
    lighting_state = (lighting_state + 1) % #lighting_confs
    local conf = lighting_confs[lighting_state + 1]

    M.set_level_color(2, conf[1])
    M.set_level_color(3, conf[2], true)
end

function M.next_brightness()
    brightness_div_no = (brightness_div_no + 1) % #brightness_divs
    M.set_level_color(1, levels_colors[1])
    M.set_level_color(2, levels_colors[2])
    M.set_level_color(3, levels_colors[3])
    M.set_level_color(4, levels_colors[4], true)
end

function M.effect_set(effect_no)
    --[[
    if effect_no == 1 then
        timer:alarm(50, tmr.ALARM_AUTO, effect_cb)
    else
        timer:stop()
        M.set_level_color(1, COLOR_OFF)
        if wifi.getmode() == wifi.STATION then
            M.set_level_color(4, COLOR_GREEN, true)
        elseif wifi.getmode() == wifi.SOFT_AP then
            M.set_level_color(4, COLOR_BLUE, true)
        else
            M.set_level_color(4, COLOR_OFF, true)
        end
    end
    --]]
end

function M.enabled()
    return levels_colors[3] ~= COLOR_OFF
end

ws2812.init()
buffer:fill(0, 0, 0)
ws2812.write(buffer)

return M