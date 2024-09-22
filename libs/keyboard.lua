local keyboard = {
    M = 50,
    R = 19,
    Z = 44,
    --
    L_CONTROL = 29,
    R_CONTROL = 157,
    L_SHIFT = 42,
    R_SHIFT = 54,
    L_ALT = 56,
    R_ALT = 184,
    WINDOWS = 219,
    BACKSPACE = 14,
    ENTER = 28,
    CAPS = 58,
    -- Arrow Keys
    ARRW_UP = 200,
    ARRW_DOWN = 208,
    ARRW_RIGHT = 205,
    ARRW_LEFT = 203
}

function keyboard.waitChar(wait)
    local signal = nil
    while true do
        signal = {computer.pullSignal(wait or 1)}
        if signal then
            if signal[1] == "key_down" then
                return signal[3], signal[4]
            elseif signal[1] ~= "key_up" then
                if progressSignal(signal) then
                    return nil, nil
                elseif wait ~= nil then
                    return nil, nil
                end
            end
        end
    end
end

function keyboard.waitCharWDown()
    local signal = nil
    while true do
        signal = {computer.pullSignal(1)}
        if signal then
            if signal[1] == "key_down" then
                return signal[3], signal[4]
            elseif signal[1] == "key_up" then
                return nil, nil
            else
                if progressSignal(signal) then
                    return nil, nil
                end
            end
        end
    end
end

local ignoreCharacters = {
    [29] = true, 
    [157] = true, 
    [42] = true, 
    [54] = true, 
    [56] = true, 
    [58] = true, 
    [184] = true, 
    [219] = true, 
    [14] = true, 
    [28] = true, 
    [200] = true, 
    [208] = true, 
    [205] = true, 
    [203] = true
}

function keyboard.isAlphabet(code)    
    --                                           F1-F10                    F11-F12
    if ignoreCharacters[code] == nil and (code < 59 or code > 68) and code ~= 87 and code ~= 88 then
        return true
    else
        return false
    end
    --return code == 57 or (code >= 2 and code <= 11) or (code >= 16 and code <= 25) or (code >= 30 and code<= 38) or (code >= 44 and code <= 50) 
end

return keyboard
