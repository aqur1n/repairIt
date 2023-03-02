local cmpnnts = {}

function cmpnnts.def(adr)
    return string.format(
        "(%s) No information available", 
        string.sub(adr, 1, 4)
    )
end

local function eepromtest(cmp, adr) cmp.set(cmp.get()) end
function cmpnnts.eeprom(cmp, adr)
    return string.format(
        "(%s) Label: %s | Max Size: %db | Read-only: %s", 
        string.sub(adr, 1, 4), cmp.getLabel(), cmp.getSize(), not pcall(eepromtest, cmp, adr)
    )
end

function cmpnnts.gpu(cmp, adr)
    local maxx, maxy = cmp.maxResolution()
    if cmp.getScreen() then
        local x, y = cmp.getResolution()
        return string.format(
            "(%s) Max Depth: %d | Max resolution: %dx%d | Current depth: %d | Current resolution: %dx%d | Screen: %s", 
            string.sub(adr, 1, 4), cmp.maxDepth(), maxx, maxy, cmp.getDepth(), x, y, string.sub(cmp.getScreen(), 1, 4)
        )
    else
        return string.format(
            "(%s) Screen: None", 
            string.sub(adr, 1, 4)
        )
    end
end

function cmpnnts.filesystem(cmp, adr)
    return string.format(
        "(%s) Label: %s | Total space: %db | Used space: %db | Read-only: %s", 
        string.sub(adr, 1, 4), cmp.getLabel(), cmp.spaceTotal(), cmp.spaceUsed(), cmp.isReadOnly()
    )
end

function cmpnnts.drive(cmp, adr) -- test
    return string.format(
        "(%s) Label: %s | Sector size: %db", 
        string.sub(adr, 1, 4), string.sub(cmp.getLabel(), 1, 10), cmp.getSectorSize()
    )
end

function cmpnnts.screen(cmp, adr)
    local x, y = cmp.getAspectRatio()
    return string.format(
        "(%s) Enabled: %s | Aspect ratio: %dx%d | High precision mode: %s", 
        string.sub(adr, 1, 4), cmp.isOn(), x, y, cmp.isPrecise()
    )
end

function cmpnnts.computer(cmp, adr)
    return string.format(
        "(%s) Total memory: %db | Free memory: %db | Uptime: %.1fs", 
        string.sub(adr, 1, 4), computer.totalMemory(), computer.freeMemory(), computer.uptime()
    )
end

function cmpnnts.internet(cmp, adr)
    return string.format(
        "(%s) Tcp enabled: %s | Http enabled: %s", 
        string.sub(adr, 1, 4), cmp.isTcpEnabled(), cmp.isHttpEnabled()
    )
end


local info = {}

local data, page = {}, 0

function info.init()
    gpupoxy.set(2, 3, "Information about PC components")
    gpupoxy.set(2, 5, "Reading...")
    data = {}

    for k, v in pairs(component.list()) do
        if cmpnnts[v] then
            if data[v] then data[v][k] = cmpnnts[v](component.proxy(k), k)
            else data[v] = {[k] = cmpnnts[v](component.proxy(k), k)} end
        else
            if data[v] then data[v][k] = cmpnnts.def(k)
            else data[v] = {[k] = cmpnnts.def(k)} end
        end
    end

    gpupoxy.fill(2, 5, 10, 1, " ")
    info.draw()
end

local function gpuset(x, y, str)
    if y < 5 or y > sh - 3 then return end
    gpupoxy.set(x, y, str)
end

function info.draw() 
    normalcolour()
    gpupoxy.fill(1, 5, sw, sh - 7, " ")

    local i = 0 - page
    for n, t in pairs(data) do
        gpuset(2, 5 + i, string.upper(n) .. ": ")
        for k, c in pairs(t) do
            if i >= sh - 8 then break
            elseif #c > sw - 4 then
                c = "   " .. c
                for y = 0, math.floor(#c / (sw - 4)) do
                    gpuset(1, 6 + i, string.sub(c, (sw + 1) * y))
                    i = i + 1
                end
            else
                gpuset(4, 6 + i, c)
                i = i + 1
            end
        end
        i = i + 2
    end
end

function info.signal(signal) 
    if signal[1] == "key_down" then
        if signal[4] == 208 then
            page = page + 1
            info.draw()
        elseif signal[4] == 200 then
            if page > 0 then
                page = page - 1
                info.draw()
            end
        end
    elseif signal[1] == "component_added" then
        if cmpnnts[signal[3]] then
            if data[signal[3]] then
                data[signal[3]][signal[2]] = cmpnnts[signal[3]](component.proxy(signal[2]), signal[2])
            else
                data[signal[3]] = {[signal[2]] = cmpnnts[signal[3]](component.proxy(signal[2]), signal[2])}
            end
        else
            if data[signal[3]] then 
                data[signal[3]][signal[2]] = cmpnnts.def(signal[2])
            else 
                data[signal[3]] = {[signal[2]] = cmpnnts.def(signal[2])}
            end
        end
        info.draw()
    elseif signal[1] == "component_removed" then
        if data[signal[3]] then
            data[signal[3]][signal[2]] = nil

            local d = true
            for k, _ in pairs(data[signal[3]]) do if k then d = false end break end
            if d then data[signal[3]] = nil end
            d = nil

            info.draw()
        end
    end
end

function info.update() 
    if data["computer"] then
        for adr in component.list("computer") do
            data["computer"][adr] = cmpnnts["computer"](component.proxy(adr), adr)
        end
    end
end

return info