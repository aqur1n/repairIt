cmp = component
fs, gpu = cmp.proxy(cmp.proxy(cmp.list("eeprom")()).getData()), cmp.proxy(cmp.list("gpu")())

gpu.bind(cmp.list("screen")(), true)
sw, sh = gpu.getResolution()

function dofile(path)
	local strm, rsn = fs.open(path, "r")
	if strm then
		local d, c = ""
		while true do
			c = fs.read(strm, math.huge)
			if c then d = d .. c else break end
		end
		fs.close(strm)

		local r, rsn = load(d, "=" .. path)
		if r then return r() else error(rsn) end
	else
		error(rsn)
	end
end

function centralize(text)
	return math.floor(sw / 2 - #tostring(text) / 2)
end

string.split = function(str, sep)
    local t = {}
    for s in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, s)
    end
    return t
end

string.join = function(str, tbl)
    local d = ""
    for _, v in ipairs(tbl) do
        d = d .. v .. str
    end
    return d
end

function tkeys(t)
    local nwt = {}
    for k, _ in pairs(t) do
        nwt[#nwt+1] = k
    end
    return nwt 
end


VERSION = "0.3a (%REPAIRIT_VERSION%)"
if fs.getLabel() ~= VERSION then
    fs.setLabel(VERSION)
end
VERSION = VERSION .. " " .. _VERSION

-- loading libraries into globals
color = dofile("/libs/color.lua")
keyboard = dofile("/libs/keyboard.lua")
ui = dofile("/libs/ui.lua")

function screenClear()
    color.normal()
    gpu.fill(1, 1, sw, sh, " ")
end

function workspaceClear()
    color.normal()
    gpu.fill(1, 5, sw, sh-7, " ")
    gpu.fill(2, 3, sw - 2, 1, " ")
end

screenClear()
ui.title()

local mdl, signal = nil

function progressSignal(signal)
    if signal[1] == "component_added" then
        if signal[3] == "screen" then
            gpu.bind(signal[2], true)
            sw, sh = gpu.getResolution()

            ui.title()
            mdl.draw()

            return true
        end
    elseif signal[1] == "component_removed" then
        if signal[3] == "screen" then
            local cmpnnt = component.list("screen")()
            if cmpnnt then
                gpu.bind(cmpnnt, true)
                sw, sh = gpu.getResolution()

                ui.title()
                mdl.draw()
            end
            return true
        end
    end
    return false
end

function loadModule(name)
    mdl = dofile("/run/" .. string.lower(name) .. ".lua")
    mdl.init()
end

loadModule("menu")

while true do
    if mdl.upd ~= nil then
        mdl.upd()
    end

    signal = {computer.pullSignal(0.2)}
    if signal then
        if signal[1] == "key_down" then
            if signal[4] == keyboard.M then
                if mdl.back ~= nil then
                    mdl.back()
                else
                    loadModule("menu")
                end
            elseif signal[4] == keyboard.R then
                mdl.init()
            else
                if mdl.keySignal ~= nil then
                    mdl.keySignal(signal)
                end
            end
        elseif signal[1] ~= "key_up" then
            progressSignal(signal)
            if mdl.signal ~= nil then
                mdl.signal(signal)
            end
        end
    end
end
