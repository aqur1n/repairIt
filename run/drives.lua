local drives = {}
local sfs, us, fsc = nil, 1, 0


local function rename()
    ui.drawBox("Rename")
    gpu.set(2, 3, "Rename " .. string.sub(sfs, 1, 8))

    color.grey()
    gpu.set(sw / 2 - 11, sh / 2 - 2, "Enter - save label")
    gpu.set(sw / 2 - 11, sh / 2 - 1, "Arrows - undo changes")
    gpu.set(sw / 2 - 11, sh / 2, "Backspace for deletion")
    gpu.set(sw / 2 - 11, sh / 2 + 1, "Empty string - deleting")
    gpu.set(sw / 2 - 11, sh / 2 + 2, "the label")

    local l = cmp.invoke(sfs, "getLabel")
    if l == nil then l = "" end

    local chr, cd
    while true do
        color.inversion()
        gpu.fill(sw / 2 - 11, sh / 2 + 4, 23, 1, " ")
        gpu.set(centralize(l), sh / 2 + 4, l)
        if #l < 16 then
            gpu.set(sw / 2 + math.floor(#l / 2), sh / 2 + 4, "┃")
        end

        chr, cd = keyboard.waitChar() 

        if cd == keyboard.BACKSPACE then
            l = string.sub(l, 1, -2)
        elseif cd == keyboard.ENTER then
            if l == "" then l = nil end
            cmp.invoke(sfs, "setLabel", l)
            drives.draw()
            return  
        elseif cd >= 200 and cd <= 208 then
            drives.draw()
            return
        elseif cd == 57 or keyboard.isAlphabet(cd) then
            if #l < 16 then
                l = l .. unicode.char(chr)
            end
        end
    end
end

local function wipe()
    ui.drawBox("Wipe disk")
    gpu.set(sw / 2 - 11, sh / 2 - 2, "This action cannot be")
    gpu.set(sw / 2 - 11, sh / 2 - 1, "undone")

    local s, lst = 1, {"Back", "Wipe"}
    local chr, cd
    while true do
        for i, v in ipairs(lst) do
            if i == s then 
                color.inversion()
            else 
                color.normal()
            end

            gpu.set(sw / 2 - 6 + ((i - 1) * 8), sh / 2 + 5, v)
        end

        chr, cd = keyboard.waitChar() 
        if cd == keyboard.ARRW_LEFT then
            if s > 1 then s = s - 1
            else s = 2 end
        elseif cd == keyboard.ARRW_RIGHT then
            if s < 2 then s = s + 1
            else s = 1 end
        elseif cd == keyboard.ENTER then
            if s == 1 then
                drives.draw()
                return
            else
                color.normal()
                gpu.fill(sw / 2 - 11, sh / 2 - 2, 23, 3, " ")
                gpu.set(sw / 2 - 11, sh / 2 - 2, "Deleting")
                for _, file in ipairs(cmp.invoke(sfs, "list", "")) do
                    gpu.fill(sw / 2 - 11, sh / 2 - 1, 23, 1, " ")
                    gpu.set(sw / 2 - 11, sh / 2 - 1, string.sub(file, 1, 22))
                    cmp.invoke(sfs, "remove", file)
                end
                drives.draw()
                return
            end
        end
    end
end

local menu = {
    {"explorer", nil},
    {"rename", rename},
    {"wipe all data", wipe}
}

local function drawDisks()
    workspaceClear()
    gpu.set(2, 3, "Select a disk drive")

    local i, l = 1, nil
    fsc = {}
    for addr, _ in pairs(cmp.list("filesystem")) do
        if us == i then 
            color.inversion()
        else 
            color.normal() 
        end

        l = cmp.proxy(addr).getLabel()
        if l ~= nil then 
            l = l .. " (" .. string.sub(addr, 1, 8) .. ")"
            gpu.set(centralize(l), 5 + i, l)
        else 
            gpu.set(centralize(addr), 5 + i, addr)
        end

        table.insert(fsc, addr)
        i = i + 1
    end
    
end

local function drawMenu()
    workspaceClear()
    gpu.set(2, 3, "Select an action")

    gpu.fill(sw - 24, 5, 24, 9, " ")
    gpu.fill(sw - 24, 5, 24, 1, "═")
    gpu.fill(sw - 24, 13, 24, 1, "─")
    gpu.fill(sw - 24, 5, 1, 9, "│")
    gpu.fill(sw, 5, 1, 9, "│")
    gpu.set(sw - 24, 5, "╒")
    gpu.set(sw, 5, "╕") 
    gpu.set(sw - 24, 13, "└")
    gpu.set(sw, 13, "┘")

    local dp = cmp.proxy(sfs)
    gpu.set(sw - 23, 6, "Label: " .. tostring(dp.getLabel()))
    gpu.set(sw - 23, 7, "Read-only: " .. tostring(dp.isReadOnly()))

    gpu.set(sw - 23, 9, "Total space: " .. dp.spaceTotal() .. " b")
    gpu.set(sw - 23, 10, "Used space: " .. dp.spaceUsed() .. " b")

    for i, v in ipairs(menu) do
        if us == i then 
            color.inversion()
        elseif cmp.invoke(sfs, "isReadOnly") and i > 1 then
            color.grey()
        else
            color.normal() 
        end
        gpu.set(2, 5 + i, v[1])
    end
end

function drives.init() 
    screenClear()
    ui.title()
    drives.draw() 
end

function drives.draw() 
    if sfs == nil then
        drawDisks()
    else
        drawMenu()
    end
end

function drives.upd() end

function drives.back() 
    if sfs == nil then
        loadModule("menu")
    else
        us = 1
        sfs = nil
        drawDisks()
    end
end

function drives.keySignal(signal) 
    if signal[4] == keyboard.ARRW_DOWN then
        if sfs == nil then
            if us < #fsc then
                us = us + 1
            else
                us = 1
            end
        else
            if us < #menu then
                us = us + 1
            else
                us = 1
            end
        end
        drives.draw() 
    elseif signal[4] == keyboard.ARRW_UP then
        if sfs == nil then
            if us > 1 then
                us = us - 1
            else
                us = #fsc
            end
        else
            if us > 1 then
                us = us - 1
            else
                us = #menu
            end
        end
        drives.draw() 
    elseif signal[4] == keyboard.ENTER then
        if sfs == nil then
            sfs = fsc[us]
            us = 1
            drives.draw()
        else
            if cmp.invoke(sfs, "isReadOnly") and us > 1 then
                ui.warn({"This action is not", "possible:", "Read-only disk"})
                drives.draw()
            else
                menu[us][2]()
            end
        end
    end
end

function drives.signal(signal) 
    if signal[3] == "filesystem" then
        if signal[1] == "component_added" then
            if sfs == nil then
                us = 1
                drives.draw()
            end
        elseif signal[1] == "component_removed" then
            if sfs == signal[2] then 
                us = 1
                sfs = nil 
                drives.draw()
            elseif sfs == nil then
                us = 1
                drives.draw() 
            end
        end
    end
end

return drives
