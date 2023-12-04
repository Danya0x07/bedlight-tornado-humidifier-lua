local M = {
    callback_on_connecting = function() print('Connecting...') end,
    callback_on_connected = function() print('Connected.') end,
    callback_on_ap = function() print('Acess Point enabled.') end,
    callback_on_wifi_off = function () print('Wifi off.') end
}

local timer_tryconn = tmr.create()

if wifi.getdefaultmode() ~= wifi.NULLMODE then
    wifi.setmode(wifi.NULLMODE)
end

----[[
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
    print("\n\tSTA - CONNECTED" .. "\n\tSSID: " .. T.SSID .. "\n\tBSSID: " ..
        T.BSSID .. "\n\tChannel: " .. T.channel)
    timer_tryconn:stop()
    M.callback_on_connected()
end)

----[[
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
    print("\n\tSTA - DISCONNECTED" .. "\n\tSSID: " .. T.SSID .. "\n\tBSSID: " ..
        T.BSSID .. "\n\treason: " .. T.reason)
    M.callback_on_connecting()
    timer_tryconn:start()
end)

--[[
wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, function(T)
    print("\n\tSTA - AUTHMODE CHANGE" .. "\n\told_auth_mode: " ..
        T.old_auth_mode .. "\n\tnew_auth_mode: " .. T.new_auth_mode)
end) --]]

----[[
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("\n\tSTA - GOT IP" .. "\n\tStation IP: " .. T.IP .. "\n\tSubnet mask: " ..
        T.netmask .. "\n\tGateway IP: " .. T.gateway)
end) --]]

----[[
wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function()
    print("\n\tSTA - DHCP TIMEOUT")
end) --]]

----[[
wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
    print("\n\tAP - STATION CONNECTED" .. "\n\tMAC: " .. T.MAC .. "\n\tAID: " .. T.AID)
end) --]]

----[[
wifi.eventmon.register(wifi.eventmon.AP_STADISCONNECTED, function(T)
    print("\n\tAP - STATION DISCONNECTED" .. "\n\tMAC: " .. T.MAC .. "\n\tAID: " .. T.AID)
end) --]]

--[[
wifi.eventmon.register(wifi.eventmon.AP_PROBEREQRECVED, function(T)
    print("\n\tAP - PROBE REQUEST RECEIVED" .. "\n\tMAC: " .. T.MAC .. "\n\tRSSI: " .. T.RSSI)
end) --]]

----[[
wifi.eventmon.register(wifi.eventmon.WIFI_MODE_CHANGED, function(T)
    print("\n\tSTA - WIFI MODE CHANGED" .. "\n\told_mode: " ..
        T.old_mode .. "\n\tnew_mode: " .. T.new_mode)
    if T.new_mode == wifi.STATION then
        M.callback_on_connecting()
    elseif T.new_mode == wifi.SOFTAP then
        M.callback_on_ap()
    else
        M.callback_on_wifi_off()
    end
end) --]]

local ap_conf = {
    ssid = 'BTH_SM_E',
    pwd = '',
    auth = wifi.WPA2_PSK,
    max = 2,
    save = false,
}

local sta_conf = {
    ssid = 'Err00000',
    pwd = '',
    auto = false,
    save = false
}

function M.wifi_enabled()
    return wifi.getmode() ~= wifi.NULLMODE
end

function M.enable_sta()
    local fd = file.open('home_router_conf.json', 'r')
    if fd then
        local str = fd:read(256)
        local conf = sjson.decode(str)
        sta_conf.ssid = conf.ssid
        sta_conf.pwd = conf.pwd
        fd:close()
        print('STA_SSID: '..sta_conf.ssid..'\tSTA_PWD: '..sta_conf.pwd)
    end

    wifi.setmode(wifi.STATION, false)
    wifi.sta.config(sta_conf)
    wifi.sta.connect()
    timer_tryconn:start()
end

function M.enable_ap()
    local fd = file.open('default_ap_conf.json', 'r')
    if fd then
        local str = fd:read(256)
        local conf = sjson.decode(str)
        ap_conf.ssid = conf.ssid
        ap_conf.pwd = conf.pwd
        fd:close()
        print('AP_SSID: '..ap_conf.ssid..'\tAP_PWD: '..ap_conf.pwd)
    end

    wifi.setmode(wifi.SOFTAP, false)
    wifi.ap.config(ap_conf)
end

function M.disable_wifi()
    wifi.setmode(wifi.NULLMODE, false)
end

local timestamp = 0

function M.reconf_sta(new_sta)
    sta_conf.ssid = new_sta.ssid
    sta_conf.pwd = new_sta.pwd

    local jstr = sjson.encode(sta_conf)
    print(jstr)

    local now = tmr.time()
    if now - timestamp >= 10 then
        local fd = file.open('home_router_conf.json', 'w')
        if fd then
            fd:write(jstr)
            fd:close()
        end
        print('New STA configuration written to Flash.')
        timestamp = now
    else
        print('New STA configuration discarded.')
    end
end

timer_tryconn:register(10000, tmr.ALARM_SEMI, M.enable_ap)

return M
