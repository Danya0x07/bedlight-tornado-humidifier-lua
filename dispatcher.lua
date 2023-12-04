local tornado = require('tornado')


local M = {
    callback_on_new_status = function (new_status)
        
    end
}

function M.on_new_sensordata(data)
    
end

function M.set_humidity_threshold(new_threshold)
    return true
end

function M.on_1press()

end

function M.on_2press()

end

function M.on_3press()

end

function M.on_longpress()

end

return M