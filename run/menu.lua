local menu = {}

local slctd = 1
local lst = {"Information about components", "Disks", "Repair OS/BIOS", " ", "Reboot", "Shutdown"}

function menu.init()
    slctd = 1
    menu.draw()
end

function menu.draw() 
    for i = 1, #lst do
        if i == slctd and lst[i] ~= " " then inversioncolour()
        else normalcolour() end
        gpupoxy.set(centralize(lst[i]), 5 + i, lst[i])
    end

    normalcolour()

    gpupoxy.set(2, 3, "Main menu. Select options")
end

function menu.signal(signal) 
    if signal[1] == "key_down" then
        if signal[4] == 208 then
            slctd = slctd + 1
            if lst[slctd] == " " then
                slctd = slctd + 1
            elseif slctd > #lst then
                slctd = #lst
            end
            menu.draw()
        elseif signal[4] == 200 then
            slctd = slctd - 1
            if lst[slctd] == " " then
                slctd = slctd - 1
            elseif slctd < 1 then
                slctd = 1
            end
            menu.draw()
        elseif signal[4] == 28 then
            if not endswith(lst[slctd], "]") then
                stmdl(slctd)
            end
        end
    end
end

function menu.update() end

return menu
