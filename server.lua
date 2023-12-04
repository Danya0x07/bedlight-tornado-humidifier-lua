local M = {
    callback_update_wifi_credentials = function (new_creds) return true end,
    callback_update_humidity_threshold = function (new_thresh) return true end,
    callback_set_tornado_state = function (new_state) return true end,
    callback_set_colors = function (c0, c1, c2, c3) return true end,
    callback_set_lighteffect = function (new_effect) return true end
}

local cs = coap.Server()

function M.on_connection_established()
    cs:listen(5683)
end

function M.on_connection_closed()
    cs:close()
end

local sensordata = ''
local status = ''

function M.update_sensordata(new_sensordata)
    sensordata = sjson.encode(new_sensordata)
end

function M.update_status(new_status)
    status = sjson.encode(new_status)
end

cs:var('sensordata', coap.JSON)
cs:var('status', coap.JSON)

local function wificredentials(payload)
    local ok, crs = pcall(sjson.decode(payload))

    if not ok then
        return 'Bad json'
    end

    if type(crs.ssid) == 'string' and type(crs.pwd) == 'string' then
        if M.callback_update_wifi_credentials(crs) then
            return 'Station configuration updated.'
        end
    end

    return 'Bad creds'
end

local function humthreshold(payload)
    local thresh = tonumber(payload)

    if thresh ~= nil then
        if M.callback_update_humidity_threshold(thresh) then
            return 'Humidity threshold updated.'
        end
    end

    return 'Bad threshold'
end

local function tornadoctl(payload)
    local state = tonumber(payload)

    if state == 0 or state == 1 then
        if M.callback_set_tornado_state(state) then
            return 'Tornado state updated.'
        else
            return 'Water not enough'
        end
    end

    return 'Bad state value'
end

local function colors(payload)
    if payload:len() ~= 4 then
        return 'Bad color format'
    end

    local c0 = payload:sub(1, 1)
    local c1 = payload:sub(2, 2)
    local c2 = payload:sub(3, 3)
    local c3 = payload:sub(4, 4)

    return M.callback_set_colors(c0, c1, c2, c3) and 'Ok.' or 'Bad color'
end

local function lighteffect(payload)
    return M.callback_set_lighteffect(payload) and 'Ok.' or 'Bad effect'
end

cs:func('wificredentials')
cs:func('humthreshold')
cs:func('tornadoctl')
cs:func('colors')
cs:func('lighteffect')

return M