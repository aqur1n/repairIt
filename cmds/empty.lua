local empty = {
    session = true
}

function empty.start() 
    luaPrint("123")
end

-- if session == true then
function empty.stringSignal(str) 
    luaPrint(str)
end

function empty.exit() 
    luaPrint(">exit")
end

return empty
