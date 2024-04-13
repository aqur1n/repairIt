local cmpData = {}

function cmpData.def()
    gpu.set(3, 7, "No information available")
end

local function eepromtest(cmp) cmp.set(cmp.get()) end
function cmpData.eeprom(cmp)
    gpu.set(4, 7, "Label: " .. cmp.getLabel())
    gpu.set(4, 8, "Size: " .. cmp.getSize() .. " bytes")

    gpu.set(4, 9, "Read-only: loading...")
    gpu.set(4, 9, "Read-only: " .. tostring(not pcall(eepromtest, cmp)) .. "      ")
end

function cmpData.gpu(cmp)
    if cmp.getScreen() then
        local maxx, maxy = cmp.maxResolution()
        local x, y = cmp.getResolution()

        gpu.set(4, 7, "Screen: " .. cmp.getScreen())
        gpu.set(4, 8, "Max Depth: " .. cmp.maxDepth())
        gpu.set(4, 9, "Max resolution: " .. maxx .. "x" .. maxy)

        gpu.set(4, 11, "Current depth: " .. cmp.getDepth())
        gpu.set(4, 12, "Current resolution: " .. x .. "x" .. y)
    else -- If there is no connected monitor, then all data received from the gpu is nil
        gpu.set(4, 7, "Screen: nil")

        gpu.set(4, 9, "Could not get information about the GPU")
    end
end

function cmpData.filesystemLabel(cmp) return string.format(" (%s)", cmp.getLabel()) end
function cmpData.filesystem(cmp)
    gpu.set(4, 7, "Label: " .. tostring(cmp.getLabel()))
    gpu.set(4, 8, "Total space: " .. cmp.spaceTotal() .. " bytes")
    gpu.set(4, 9, "Used space: " .. cmp.spaceUsed() .. " bytes")
    gpu.set(4, 10, "Read-only: " .. tostring(cmp.isReadOnly()))
end

function cmpData.driveLabel(cmp) return string.format(" (%s)", cmp.getLabel()) end
function cmpData.drive(cmp)
    gpu.set(4, 7, "Label: " .. cmp.getLabel())
    gpu.set(4, 8, "Sector size: " .. cmp.getSectorSize() .. " bytes")
end

function cmpData.screen(cmp)
    local x, y = cmp.getAspectRatio()
    gpu.set(4, 7, "Enabled: " .. tostring(cmp.isOn()))
    gpu.set(4, 8, "Aspect ratio: " .. x .. "x" .. y)
    gpu.set(4, 9, "High precision mode: " .. tostring(cmp.isPrecise()))
end

function cmpData.computerUpd() 
    gpu.set(4, 7, "Memory: " .. computer.totalMemory() - computer.freeMemory() .. "/" .. computer.totalMemory() .. " bytes ")
    gpu.set(4, 8, "Uptime: " .. computer.uptime() .. " s ")
end
function cmpData.computer(cmp)
    cmpData.computerUpd()
end

function cmpData.internet(cmp)
    gpu.set(4, 7, "Tcp enabled: " .. tostring(cmp.isTcpEnabled()))
    gpu.set(4, 8, "Http enabled: " .. tostring(cmp.isHttpEnabled()))
end

function cmpData.printer3d(cmp)
    gpu.set(4, 7, "Label: " .. cmp.getLabel())
    gpu.set(4, 8, "Button mode: " .. tostring(cmp.isButtonMode()))
    gpu.set(4, 9, "Redstone emitter: " .. tostring(cmp.isRedstoneEmitter()))

    gpu.set(4, 11, "Shape count: " .. cmp.getShapeCount())
    gpu.set(4, 12, "Max shape count: " .. cmp.getMaxShapeCount())
end

function cmpData.abstract_bus(cmp)
    gpu.set(4, 7, "Enabled: " .. tostring(cmp.getEnabled()))
    gpu.set(4, 8, "Address: " .. cmp.getAddress())
    gpu.set(4, 9, "Max packet size: " .. cmp.maxPacketSize())
end

function cmpData.access_point(cmp)
    gpu.set(4, 7, "Strength: " .. cmp.getStrength())
    gpu.set(4, 8, "Repeater: " .. tostring(cmp.isRepeater()))
end

function cmpData.geolyzer(cmp)
    gpu.set(4, 7, "See sky: " .. tostring(cmp.canSeeSky()))
    gpu.set(4, 8, "Sun visible: " .. tostring(cmp.isSunVisible()))
end

function cmpData.hologram(cmp)
    gpu.set(4, 7, "Scale: " .. cmp.getScale())
    gpu.set(4, 8, "Max depth: " .. cmp.maxDepth())
end

function cmpData.microcontroller(cmp)
    gpu.set(4, 7, "Running: " .. tostring(cmp.isRunning()))
    gpu.set(4, 8, "Last error:")
    gpu.set(6, 9, tostring(cmp.lastError()))
end

function cmpData.data(cmp)
    local tier = 1
    if cmp.generateKeyPair ~= nil then
        tier = 3
    elseif cmp.encrypt ~= nil then
        tier = 2
    end

    gpu.set(4, 7, "Limit: " .. cmp.getLimit())
    gpu.set(4, 8, "Tier: " .. tier)
end

local components, data, up, dl = {}, {}, 0, 0
local stype, saddr = nil, nil

local function gpuset(x, y, str)
    if y < 5 or y > sh - 3 then return end
    gpu.set(x, y, str)
end

local function updData()
    workspaceClear()
    gpu.set(sw / 2 - 3, 6, "Reading...")

    data, dl = {}, 0
    local cmps, i = cmp.list(), 1
    for k, v in pairs(cmps) do
        if data[v] == nil then
            data[v] = {}
            dl = dl + 1
        end
        table.insert(data[v], k)
        ui.progressbar(i / 16, math.floor(sh / 2))
        i = i + 1
    end
end

local function drawMenu()
    workspaceClear()
    gpu.set(2, 3, "Select the component type")
    local i, si = 0, 0
    if up > sh - 9 then si = up - sh + 9 end
    for k, _ in pairs(data) do
        if up == i then 
            color.inversion()
        else 
            color.normal() 
        end
        local n = k .. " (" .. tostring(#data[k]) .. ")"
        gpuset(centralize(n), 6 + i - si, n)
        i = i + 1
    end

    color.normal() 
    if i - si > sh - 8 then gpu.set(sw, sh - 3, "▼") end
    if si > 1 then gpu.set(sw, 5, "▲") end
end

local function drawInfo()
    if data[stype] == nil or #data[stype] == 0 then 
        stype = nil
        return drawMenu() 
    end

    workspaceClear()
    gpu.set(2, 3, "Select " .. stype)
    for i, v in ipairs(data[stype]) do
        if up + 1 == i then 
            color.inversion()
        else 
            color.normal() 
        end  
        
        if cmpData[stype .. "Label"] ~= nil then
            gpuset(2, 5 + i, v .. cmpData[stype .. "Label"](cmp.proxy(v)))
        else
            gpuset(v, 5 + i, v)
        end
    end
end

local function drawData()
    workspaceClear()
    gpu.set(2, 3, "Information about " .. stype)

    color.grey()
    gpu.set(2, 6, string.upper(stype) .. " " .. saddr)

    color.normal()
    if cmpData[stype] ~= nil then
        cmpData[stype](cmp.proxy(saddr))
    else
        cmpData.def()
    end
end


function components.init() 
    screenClear()
    ui.title()

    up = 0
    updData()
    components.draw() 
end

function components.draw() 
    if saddr ~= nil then
        drawData()
    elseif stype ~= nil then
        drawInfo()
    else
        drawMenu()
    end
end

function components.upd()
    if stype ~= nil and saddr ~= nil then
        if cmpData[stype .. "Upd"] ~= nil then
            cmpData[stype .. "Upd"]()
        end
    end
end

function components.back()
    if stype ~= nil then
        if saddr ~= nil then
            up, saddr = 0, nil
            if #data[stype] > 1 then
                updData()
                drawInfo()
            else
                stype = nil
                updData()
                drawMenu()
            end
        else
            up, stype = 0, nil
            updData()
            drawMenu()
        end
    else
        loadModule("menu")
    end
end

function components.keySignal(signal) 
    if signal[4] == keyboard.ARRW_DOWN then
        if stype ~= nil and saddr == nil then
            if up + 1 < #data[stype] then 
                up = up + 1
            else
                up = 0
            end
            components.draw() 
        elseif saddr == nil then
            if up + 1 < dl then 
                up = up + 1
            else
                up = 0
            end
            components.draw()
        end
    elseif signal[4] == keyboard.ARRW_UP then
        if up > 0 then 
            up = up - 1
            components.draw() 
        else
            if stype ~= nil and saddr == nil then
                up = #data[stype] - 1
                components.draw() 
            elseif saddr == nil then
                up = dl - 1
                components.draw() 
            end
        end
    elseif signal[4] == keyboard.ENTER then
        if stype == nil then
            local i = 0
            for k, _ in pairs(data) do
                if i == up then
                    stype = k
                    if #data[k] == 1 then
                        saddr = data[k][1]
                        drawData()
                    else 
                        up = 0
                        drawInfo()
                    end 
                end
                i = i + 1
            end
        elseif saddr == nil then
            saddr = data[stype][up+1]
            drawData()
        end
    end
end

function components.signal(signal) 
    if signal[1] == "component_added" then
        updData()
        components.draw()
    elseif signal[1] == "component_removed" then
        if signal[2] == saddr then saddr = nil end
        updData()
        components.draw()
    end
end

return components
