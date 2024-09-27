-- Пожалуйста, кто-нибудь, перепишите это дермище
local drives = {}
local sfs, us, fsc, spth = nil, 1, 0, nil
local spm, spf = 0, nil

-- ----------------------------------------------------------

local function dltFile()
    if ui.infoBox("Are you sure? Press ENTER to confirm or another button to cancel", true, true) then
        cmp.invoke(sfs, "remove", spth)
    end
end

local fileMenu = {
    ["edit"] = {function() dofile("/run/edit.lua").edit(spth) end, true},
    ["delete"] = {dltFile, true}
}
local fposes = {"edit", "delete"}

local function drawFileMenu()
    gpu.set(2, 3, spth)
    local fn = ui.select(fposes)
    if fn ~= nil then
        if cmp.invoke(sfs, "isReadOnly") and fileMenu[fn][2] then
            ui.warn({"This action is not", "possible:", "Read-only disk"})
            drives.draw()
        else
            fileMenu[fn][1]()
        end
    end
    drives.back()
end

-- ----------------------------------------------------------

local function rename()
    ui.drawBox("Rename", 30)
    gpu.set(2, 3, "Rename " .. string.sub(sfs, 1, 8))

    color.grey()
    gpu.set(sw / 2 - 14, sh / 2 - 2, "Enter - save label")
    gpu.set(sw / 2 - 14, sh / 2 - 1, "Arrows - undo changes")
    gpu.set(sw / 2 - 14, sh / 2, "Backspace for deletion")
    gpu.set(sw / 2 - 14, sh / 2 + 1, "Empty string - deleting")
    gpu.set(sw / 2 - 14, sh / 2 + 2, "the label")

    local l = cmp.invoke(sfs, "getLabel")
    if l == nil then l = "" end

    local chr, cd, c
    while true do
        color.inversion()
        gpu.fill(sw / 2 - 14, sh / 2 + 4, 29, 1, " ")
        gpu.set(centralize(l), sh / 2 + 4, l)
        if #l < 28 then
            gpu.set(sw / 2 + math.floor(#l / 2), sh / 2 + 4, "┃")
        end

        chr, cd = keyboard.waitChar() 
        if cd == keyboard.BACKSPACE then
            l = string.sub(l, 1, -2)
        elseif cd == keyboard.ENTER then
            if l == "" then l = nil end
            local rs, err = pcall(cmp.invoke, sfs, "setLabel", l)
            if not rs then
                ui.errorBox(err)
            end
            drives.draw()
            return  
        elseif chr == nil or (cd >= 200 and cd <= 208) then
            drives.draw()
            return
        elseif keyboard.isAlphabet(cd) then
            if #l < 28 then
                c = unicode.char(chr)
                if #c > 1 then c = "?" end
                l = l .. c
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
        if chr == nil then
            drives.draw()
            return
        elseif cd == keyboard.ARRW_LEFT then
            if s > 1 then s = s - 1
            else s = 2 end
        elseif cd == keyboard.ARRW_RIGHT then
            if s < 2 then s = s + 1
            else s = 1 end
        elseif cd == keyboard.ENTER then
            if s == 2 then
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
            else
                drives.draw()
                return
            end
        end
    end
end

-- ----------------------------------------------------------

local function drawInfoBox()
    gpu.fill(sw - 24, 5, 24, 9, " ")
    gpu.fill(sw - 24, 5, 24, 1, "═")
    gpu.fill(sw - 24, 13, 24, 1, "─")
    gpu.fill(sw - 24, 5, 1, 9, "│")
    gpu.fill(sw, 5, 1, 9, "│")
    gpu.set(sw - 24, 5, "╒")
    gpu.set(sw, 5, "╕") 
    gpu.set(sw - 24, 13, "└")
    gpu.set(sw, 13, "┘")
end

local function drawExplorer()
    if spth == nil or spth == "" then
        us = 1
        spth = "/"
    elseif string.sub(spth, 1, 1) ~= "/" then
        spth = "/" .. spth
    end

    workspaceClear()
    if #spth < sw - 2 then
        gpu.set(2, 3, spth)
    else
        gpu.set(2, 3, "..." .. string.sub(spth, -sw - 3))
    end

    local si = 0
    if us > sh - 8 then si = us - sh + 8 end

    if us - 1 == 0 then 
        color.inversion()
    else 
        color.normal() 
    end
    ui.gpuSet(2, 6 - si, "...")

    spm = 0
    for i, file in ipairs(cmp.invoke(sfs, "list", spth)) do
        if us - 1 == i then 
            color.inversion()
            spf = spth .. file
        else 
            color.normal() 
        end

        ui.gpuSet(2, 6 + i - si, file)
        spm = i
    end

    color.normal()
    drawInfoBox()

    if us > 1 then
        if cmp.invoke(sfs, "exists", spf) then
            if not cmp.invoke(sfs, "isDirectory", spf) then
                gpu.set(sw - 23, 8, "Size:")
                gpu.set(sw - 19, 9, tostring(cmp.invoke(sfs, "size", spf)) .. " bytes")
            end
            gpu.set(sw - 23, 6, "Last modified:")
            gpu.set(sw - 19, 7, tostring(cmp.invoke(sfs, "lastModified", spf)))
        end
    else
        gpu.set(sw - 23, 6, "Return")
    end

    if spm - si > sh - 9 then gpu.set(sw - 25, sh - 3, "▼") end
    if si > 1 then gpu.set(sw - 25, 5, "▲") end
end

local driveMenu = {
    {"explorer", drawExplorer, false},
    {"rename", rename, true},
    {"wipe all data", wipe, true}
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

    drawInfoBox()

    local dp = cmp.proxy(sfs)
    gpu.set(sw - 23, 6, "Label: " .. tostring(dp.getLabel()))
    gpu.set(sw - 23, 7, "Read-only: " .. tostring(dp.isReadOnly()))

    gpu.set(sw - 23, 9, "Total space: " .. dp.spaceTotal() .. " b")
    gpu.set(sw - 23, 10, "Used space: " .. dp.spaceUsed() .. " b")
    gpu.set(sw - 11, 11, "(" .. math.floor(dp.spaceUsed() / dp.spaceTotal() * 100) .. "%)")

    for i, v in ipairs(driveMenu) do
        if us == i then 
            color.inversion()
        elseif v[3] and cmp.invoke(sfs, "isReadOnly") then
            color.grey()
        else
            color.normal() 
        end
        gpu.set(2, 5 + i, v[1])
    end
end

-- ----------------------------------------------------------

function drives.init() 
    screenClear()
    ui.title()
    drives.draw() 
end

function drives.draw() 
    if sfs == nil then
        drawDisks()
    elseif spth == nil then
        drawMenu()
    else
        if cmp.invoke(sfs, "isDirectory", spth or "/") then
            drawExplorer()
        else
            drawFileMenu()
        end
    end
end

function drives.upd() end

function drives.back() 
    us = 1
    if sfs == nil then
        loadModule("menu")
    elseif spth == nil then
        sfs = nil
        drives.draw() 
    else
        if spth == "/" then
            spth = nil
            drives.draw() 
        else
            local drs = string.split(spth, "/")
            table.remove(drs, #drs)
            spth = string.join("/", drs)
            drives.draw()
        end
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
        elseif spth == nil then
            if us < #driveMenu then
                us = us + 1
            else
                us = 1
            end
        else
            if us < spm + 1 then
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
        elseif spth == nil then
            if us > 1 then
                us = us - 1
            else
                us = #driveMenu
            end
        else
            if us > 1 then
                us = us - 1
            else
                us = spm + 1
            end
        end
        drives.draw() 
    elseif signal[4] == keyboard.ENTER then
        if sfs == nil then
            sfs = fsc[us]
            us = 1
            drives.draw()
        elseif spth == nil then
            if cmp.invoke(sfs, "isReadOnly") and driveMenu[us][3] then
                ui.warn({"This action is not", "possible:", "Read-only disk"})
                drives.draw()
            else
                driveMenu[us][2]()
            end
        else
            if spth ~= "/" and us == 1 then
                local drs = string.split(spth, "/")
                table.remove(drs, #drs)
                spth = string.join("/", drs)
                drives.draw()
            elseif spth == "/" and us == 1 then
                drives.back()
            else
                us = 1
                spth = spf
                drives.draw()
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
