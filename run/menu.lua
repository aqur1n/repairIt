local menu, index = {}, 1
local options = {
    -- lua name, name, description, position
    {"components", "information about components", "Information about components", 0},
    {"drives", "drives", "Drive management", 1},
--build:ignore=MINIMAL
    {"repair", "repair OS/BIOS", "Repair OS/BIOS", 2},
--build:end
    {"cmd", "console", "Using commands and lua", 3},

    {nil, "reboot", "Reboot the computer", 5},
    {nil, "shutdown", "Shutdown the computer", 6}
}


function menu.init()
    screenClear()
    ui.title()
    menu.draw()
end

function menu.draw()
    color.normal() 
    gpu.fill(2, 3, sw - 3, 1, " ")
    for i, v in ipairs(options) do
        if index == i then 
            gpu.set(2, 3, v[3])
            color.inversion() 
        else 
            color.normal() 
        end
        gpu.set(centralize(v[2]), 6 + v[4], v[2])
    end
end

function menu.keySignal(signal)
    if signal[4] == keyboard.ARRW_DOWN then
        if index >= #options then 
            index = 1 
        else 
            index = index + 1 
        end
        menu.draw()
    elseif signal[4] == keyboard.ARRW_UP then
        if index <= 1 then 
            index = #options
        else 
            index = index - 1 
        end
        menu.draw()
    elseif signal[4] == keyboard.ENTER then
        local cmp = options[index]
        if cmp[1] == nil then
            computer.beep()
            if cmp[2] == "reboot" then
                computer.shutdown(true)
            elseif cmp[2] == "shutdown" then
                computer.shutdown()
            end
        else
            loadModule(cmp[1])
        end
    end
end

return menu
