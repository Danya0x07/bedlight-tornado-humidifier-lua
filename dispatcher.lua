tornado = require('tornado')
sensors = require('sensors')
button = require('button')
wificonn = require('wificonn')
server = require('server')

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

local function init()
    local fd = file.open('humthresh.txt', 'r')
    if fd then
        humidity_threshold = tonumber(fd:read(10)) or 100
        device_status.humthresh = humidity_threshold
        server.update_status(device_status)
        fd:close()
    end
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
    device_status.twister = tornado_state ~= 0
    server.update_status(device_status)
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
    end
    tornado_set_state(state)
end

button.callback_1press = function ()
end

button.callback_2press = function ()
    local new_state = (tornado_state + 1) % #tornado_confs
    tornado_set_state(new_state)
end

button.callback_3press = function ()
    auto_ctl = not auto_ctl
    device_status.autoctl = auto_ctl
    server.update_status(device_status)
end

local timestamp_longpress = 0

button.callback_longpress = function ()
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
end

wificonn.callback_on_ap = function ()
    server.on_connection_established()
end

wificonn.callback_on_connecting = function ()
    server.on_connection_closed()
end

wificonn.callback_on_connected = function ()
    server.on_connection_established()
end

wificonn.callback_on_wifi_off = function ()
    server.on_connection_closed()
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
    device_status.autoctl = auto_ctl
    server.update_status(device_status)

    local fd = file.open('humthresh.txt', 'w')
    if fd and tmr.time() - timestamp_humidity >= 10 then
        humidity_threshold = new_thresh
        fd:write(tostring(humidity_threshold))
        fd:close()
        device_status.humthresh = humidity_threshold
        server.update_status(device_status)
        timestamp_humidity = tmr.time()
        return server.OK
    else
        return server.NA
    end
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
    device_status.autoctl = auto_ctl
    server.update_status(device_status)
    return server.OK
end

server.callback_set_colors = function (c0, c1, c2, c3)
    return server.OK
end

server.callback_set_lighteffect = function (new_effect) 
    return server.OK
end

init()
