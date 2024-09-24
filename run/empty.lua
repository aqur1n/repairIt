local empty = {}

function empty.init() 
    screenClear()
    ui.title()
end

function empty.draw() end

function empty.upd() end

function empty.keySignal(signal) end

function empty.signal(signal) end

return empty
