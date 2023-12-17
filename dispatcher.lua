print(node.heap())
tornado = require('tornado')
print(node.heap())
sensors = require('sensors')
print(node.heap())
button = require('button')
print(node.heap())
wificonn = require('wificonn')
print(node.heap())
server = require('server')
print(node.heap())
ledstrip = require('ledstrip')
print(node.heap())

local tornado_confs = {
    {
        genstate = tornado.GENERATOR_OFF,
        fanlvl = tornado.FAN_OFF,
        mistmode = tornado.MIST_OFF
    },
    {
        genstate = tornado.GENERATOR_ON,
        fanlvl = tornado.FAN_LVL2,
        mistmode = tornado.MIST_FULL
    },
    {
        genstate = tornado.GENERATOR_ON,
        fanlvl = tornado.FAN_LVL3,
        mistmode = tornado.MIST_FULL
    },
    {
        genstate = tornado.GENERATOR_ON,
        fanlvl = tornado.FAN_LVL7,
        mistmode = tornado.MIST_FULL
    }
}

local tornado_state = 0
local humidity_threshold = 100
local auto_ctl = false

local device_status = {
    twister = false,
    autoctl = false,
    light = false,
    humthresh = 100
}

local SETTING_LIGHT = 0
local SETTING_TORNADO = 1

local setting = SETTING_LIGHT
local setting_timer = tmr.create()

local function update_status()
    device_status.twister = tornado_state ~= 0
    device_status.humthresh = humidity_threshold
    device_status.autoctl = auto_ctl
    device_status.light = ledstrip.enabled()
    server.update_status(device_status)
end

local function tornado_set_state(state)
    if state == tornado_state then
        return
    end
    
    local conf = tornado_confs[state + 1]

    tornado.gen(conf.genstate)
    tornado.fan(conf.fanlvl)
    tornado.mist(conf.mistmode)

    tornado_state = state
    update_status()
end

sensors.callback = function (data)
    server.update_sensordata(data)

    local state = tornado_state

    if auto_ctl then
        if sensors.data.humidity >= humidity_threshold then
            state = 0
        elseif state == 0 then
            state = 1
        end
    end

    if not sensors.data.water_enough then
        state = 0
        ledstrip.on_low_water()
    end
    tornado_set_state(state)
end

button.callback_1press = function ()
    if setting == SETTING_LIGHT then
        ledstrip.next_lighting()
        update_status()
    elseif setting == SETTING_TORNADO then
        local new_state = (tornado_state + 1) % #tornado_confs
        tornado_set_state(new_state)
        setting_timer:start(true)
    end
end

button.callback_2press = function ()
    if setting == SETTING_LIGHT then
        ledstrip.next_brightness()
    elseif setting == SETTING_TORNADO then
        auto_ctl = not auto_ctl
        ledstrip.on_autoctl_change(auto_ctl)
        update_status()
        setting_timer:start(true)
    end
end

button.callback_3press = function ()
    if setting == SETTING_LIGHT then
        setting = SETTING_TORNADO
        ledstrip.on_setting_tornado()
        setting_timer:start(true)
    end
end

local timestamp_longpress = 0
local effect_cnt = 0

button.callback_longpress = function ()
    if setting == SETTING_LIGHT then
        effect_cnt = 1 - effect_cnt
        ledstrip.effect_set(effect_cnt)
        update_status()
    elseif setting == SETTING_TORNADO then
        if wificonn.enabled() then
            if wifi.getmode() ~= wifi.SOFTAP and tmr.time() - timestamp_longpress <= 12 then
                wificonn.enable_ap()
            else
                wificonn.disable()
            end
        else
            wificonn.enable_sta()
            timestamp_longpress = tmr.time()
        end
        setting_timer:start(true)
    end
end

wificonn.callback_on_ap = function ()
    server.on_connection_established()
    ledstrip.on_ap()
end

wificonn.callback_on_connecting = function ()
    server.on_connection_closed()
    ledstrip.on_connecting()
end

wificonn.callback_on_connected = function ()
    server.on_connection_established()
    ledstrip.on_connected()
end

wificonn.callback_on_wifi_off = function ()
    server.on_connection_closed()
    ledstrip.on_wifi_off()
end

server.callback_update_wifi_credentials = function (new_creds) 
    return wificonn.reconf_sta(new_creds) and server.OK or server.NA
end

local timestamp_humidity = 0

server.callback_update_humidity_threshold = function (new_thresh)
    if new_thresh < 0 or 100 < new_thresh then
        return server.BADVAL
    end

    auto_ctl = true

    local fd = file.open('humthresh.txt', 'w')
    if fd and tmr.time() - timestamp_humidity >= 10 then
        humidity_threshold = new_thresh
        update_status()
        fd:write(tostring(humidity_threshold))
        fd:close()
        timestamp_humidity = tmr.time()
        return server.OK
    end

    update_status()
    return server.NA
end

server.callback_set_tornado_state = function (new_state)
    if new_state < 0 or (#tornado_confs - 1) < new_state then
        return server.BADVAL
    end
    if not sensors.data.water_enough then
        return server.NA
    end

    tornado_set_state(new_state)
    auto_ctl = false
    update_status()
    return server.OK
end

server.callback_set_colors = function (c0, c1, c2, c3)
    return ledstrip.set_levels_colors(c0, c1, c2, c3) and server.OK or server.BADVAL
end

server.callback_set_lighteffect = function (new_effect) 
    return ledstrip.effect_set(new_effect) and server.OK or server.BADVAL
end

local fd = file.open('humthresh.txt', 'r')
if fd then
    humidity_threshold = tonumber(fd:read(10)) or 100
    update_status()
    fd:close()
end

setting_timer:register(7000, tmr.ALARM_SEMI, function ()
    setting = SETTING_LIGHT
    ledstrip.on_setting_light()
end)
