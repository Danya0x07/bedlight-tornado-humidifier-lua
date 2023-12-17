local M = {
    OK = 0,
    NA = 1,
    BADVAL = 2,
    -- callback_update_wifi_credentials = function (new_creds) return 0 end,
    -- callback_update_humidity_threshold = function (new_thresh) return 0 end,
    -- callback_set_tornado_state = function (new_state) return 0 end,
    -- callback_set_colors = function (c1, c2, c3, c4) return 0 end,
    -- callback_set_lighteffect = function (new_effect) return 0 end,
    -- debug = false
}
local retstrings = {
    [M.OK] = 'OK',
    [M.NA] = 'NA',
    [M.BADVAL] = 'BADVAL'
}

local cs = coap.Server()

function M.on_connection_established()
    cs:listen(5683)
end

function M.on_connection_closed()
    cs:close()
end

sensordata = ''
status = ''

function M.update_sensordata(new_sensordata)
    sensordata = sjson.encode(new_sensordata)
end

function M.update_status(new_status)
    status = sjson.encode(new_status)
    -- if M.debug then
        -- print(status)
    -- end
end

cs:var('sensordata', coap.JSON)
cs:var('status', coap.JSON)

function wificredentials(payload)
    local ok, crs = pcall(sjson.decode, payload)

    if not ok then
        return crs
    end

    if type(crs.ssid) == 'string' and type(crs.pwd) == 'string' then
        local retcode = M.callback_update_wifi_credentials(crs)
        return retstrings[retcode]
    end

    return retstrings[M.BADVAL]
end

function humthreshold(payload)
    local thresh = tonumber(payload) or -1
    local retcode = M.callback_update_humidity_threshold(thresh)

    return retstrings[retcode]
end

function tornadoctl(payload)
    local state = tonumber(payload) or -1
    local retcode = M.callback_set_tornado_state(state)

    return retstrings[retcode]
end

function colors(payload)
    if payload:len() ~= 4 then
        return retstrings[M.BADVAL]
    end

    local c1 = payload:sub(1, 1)
    local c2 = payload:sub(2, 2)
    local c3 = payload:sub(3, 3)
    local c4 = payload:sub(4, 4)

    local retcode = M.callback_set_colors(c1, c2, c3, c4)
    return retstrings[retcode]
end

function lighteffect(payload)
    local retcode = M.callback_set_lighteffect(tonumber(payload))
    return retstrings[retcode]
end

cs:func('wificredentials')
cs:func('humthreshold')
cs:func('tornadoctl')
cs:func('colors')
cs:func('lighteffect')

return M