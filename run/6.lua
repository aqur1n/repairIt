local shutdown = {}

function shutdown.init()
    shutdown.draw()
    
    computer.beep()
    computer.shutdown()
end

function shutdown.draw() 
    normalcolour()
    gpuproxy.set(2, 3, "Shutdown...")
end

function shutdown.signal(signal) end

function shutdown.update() end

return shutdown