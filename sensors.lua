local M = {
    debug = false,
    data = {
        water_enough = true,
        temperature = -273,
        humidity = -1
    },
    callback = function(data) end
}

local PIN_DHT = 2

local timer = tmr.create()

local function water_is_enough(sample)
    return sample > 300
end

local function measure()
    local sample = adc.read(0)
    
    if M.debug then
        print('ADC sample: '..sample)
    end
    M.data.water_enough = water_is_enough(sample)

    status, temp, hum, temp_dec, hum_dec = dht.read(PIN_DHT)
    if status ~= dht.OK then
        print('DHT error: '..status)
    else
        if M.debug then
            print('Temperature: '..temp..'.'..temp_dec..'\tHumidity: '..hum..'.'..hum_dec)
        end
        M.data.temperature = temp
        M.data.humidity = hum
    end
    M.callback(M.data)
end

timer:alarm(10000, tmr.ALARM_AUTO, measure)

return M