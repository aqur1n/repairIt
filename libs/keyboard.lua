local keyboard = {
    M = 50,
    R = 19,

    BACKSPACE = 14,
    ENTER = 28,
    -- Arrow Keys
    ARRW_UP = 200,
    ARRW_DOWN = 208,
    ARRW_RIGHT = 205,
    ARRW_LEFT = 203
}

function keyboard.waitChar()
    local signal = nil
    while true do
        signal = {computer.pullSignal(1)}
        if signal then
            if signal[1] == "key_down" then
                return signal[3], signal[4]
            elseif signal[1] ~= "key_up" then
                if progressSignal(signal) then
                    return nil, nil
                end
            end
        end
    end
end

function keyboard.isAlphabet(code) 
    return (code >= 2 and code <= 11) or (code >= 16 and code <= 25) or (code >= 30 and code<= 38) or (code >= 44 and code <= 50) 
end

return keyboard
