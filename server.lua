local M = {
    OK = 0,
    NA = 1,
    BADVAL = 2,
    callback_update_wifi_credentials = function (new_creds) return 0 end,
    callback_update_humidity_threshold = function (new_thresh) return 0 end,
    callback_set_tornado_state = function (new_state) return 0 end,
    callback_set_colors = function (c0, c1, c2, c3) return 0 end,
    callback_set_lighteffect = function (new_effect) return 0 end,
    debug = false
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
    if M.debug then
        print(status)
    end
end

cs:var('sensordata', coap.JSON)
cs:var('status', coap.JSON)

function wificredentials(payload)
    local ok, crs = pcall(sjson.decode, payload)

    if not ok then
        return crs
    end

    if type(crs.ssid) == 'string' and type(crs.pwd) == 'string' then
        local ret = M.callback_update_wifi_credentials(crs)

        if ret == M.OK then
            return 'Station configuration updated.'
        elseif ret == M.NA then
            return 'Try later'
        end
    end

    return 'Bad creds'
end

function humthreshold(payload)
    local thresh = tonumber(payload) or -1
    local ret = M.callback_update_humidity_threshold(thresh)

    if ret == M.OK then
        return 'Humidity threshold updated.'
    elseif ret == M.NA then
        return 'Try later'
    else
        return 'Bad threshold'
    end
end

function tornadoctl(payload)
    local state = tonumber(payload) or -1
    local ret = M.callback_set_tornado_state(state)

    if ret == M.OK then
        return 'Tornado state updated.'
    elseif ret == M.NA then
        return 'Water not enough'
    else
        return 'Bad state value'
    end
end

function colors(payload)
    if payload:len() ~= 4 then
        return 'Bad color format'
    end

    local c0 = payload:sub(1, 1)
    local c1 = payload:sub(2, 2)
    local c2 = payload:sub(3, 3)
    local c3 = payload:sub(4, 4)

    return M.callback_set_colors(c0, c1, c2, c3) == M.OK and 'Ok.' or 'Bad color'
end

function lighteffect(payload)
    return M.callback_set_lighteffect(payload) == M.OK and 'Ok.' or 'Bad effect'
end

cs:func('wificredentials')
cs:func('humthreshold')
cs:func('tornadoctl')
cs:func('colors')
cs:func('lighteffect')

return M