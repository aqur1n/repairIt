local reboot = {}

function reboot.init()
    reboot.draw()

    computer.beep()
    computer.shutdown(true)
end

function reboot.draw()
    normalcolour() 
    gpupoxy.set(2, 3, "Reboot...")
end

function reboot.signal(signal) end

function reboot.update() end

return reboot