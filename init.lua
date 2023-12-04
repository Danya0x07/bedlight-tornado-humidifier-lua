tornado = require('tornado')
sensors = require('sensors')
button = require('button')
wificonn = require('wificonn')
server = require('server')

dispatcher = require('dispatcher')


sensors.callback = function (data)
    server.update_sensordata(data)
    dispatcher.on_new_sensordata(data)
end

button.callback_1press = function ()
    dispatcher.on_1press()
end

button.callback_2press = function ()
    dispatcher.on_2press()
end

button.callback_3press = function ()
    dispatcher.on_3press()
end

button.callback_longpress = function ()
    dispatcher.on_longpress()
end

dispatcher.callback_on_new_status = function (new_status)
    server.update_status(new_status) 
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
    return wificonn.reconf_sta(new_creds)
end

server.callback_update_humidity_threshold = function (new_thresh) 
    return dispatcher.set_humidity_threshold(new_thresh)
end

server.callback_set_tornado_state = function (new_state)
    return true
end

server.callback_set_colors = function (c0, c1, c2, c3)
    return true
end

server.callback_set_lighteffect = function (new_effect) 
    return true
end
