fsproxy = component.proxy(component.proxy(component.list("eeprom")()).getData())
gpupoxy = component.proxy(component.list("gpu")())

gpupoxy.bind(component.list("screen")(), true)

sw, sh = gpupoxy.getResolution()
version = "0.1a (Full)"

function endswith(str, ending)
    return string.sub(str, -#ending) == ending
end

function normalcolour()
    gpupoxy.setBackground(0x0)
	gpupoxy.setForeground(0xFFFFFF)
end

function disabledcolour()
    gpupoxy.setBackground(0x0)
	gpupoxy.setForeground(0x878787)
end

function inversioncolour()
    gpupoxy.setBackground(0xFFFFFF) 
	gpupoxy.setForeground(0x0)
end

function centralize(text)
	return math.floor(sw / 2 - #tostring(text) / 2)
end

function drawTitle()
    gpupoxy.fill(1, 1, sw, sh, " ")

    gpupoxy.set(1, 1, "╒")
    gpupoxy.set(sw - 6, 1, "╕")

    gpupoxy.fill(2, 1, sw - 8, 1, "═")
    gpupoxy.fill(2, 4, sw - 8, 1, "─")

    gpupoxy.fill(sw - 6, 2, 1, 3, "│")
    gpupoxy.fill(1, 2, 1, 3, "│")

    gpupoxy.set(1, 4, "└")
    gpupoxy.set(sw - 6, 4, "┘")

    gpupoxy.set(2, 2, "repairIt " .. version)

    -- --

    gpupoxy.set(1, sh - 2, "╒")
    gpupoxy.set(sw - 6, sh - 2, "╕")

    gpupoxy.fill(2, sh - 2, sw - 8, 1, "═")
    gpupoxy.fill(2, sh, sw - 8, 1, "─")

    gpupoxy.set(sw - 6, sh - 1, "│")
    gpupoxy.set(1, sh - 1, "│")

    gpupoxy.set(1, sh, "└")
    gpupoxy.set(sw - 6, sh, "┘")

    gpupoxy.set(2, sh - 1, "Moving: ⇅, Choose: Enter, Return: M, Reload: R")
end

function drawBar(percent)
    local pos = math.floor(percent * sw / 100)
    if percent > 0 then
        gpupoxy.fill(1, sh, pos, 1, "█")
        gpupoxy.set(pos, sh, "█▓▒░")
    else
        gpupoxy.fill(1, sh, sw, 1, " ")
    end
    computer.pullSignal(0)
end

if fsproxy.getLabel() ~= "repairIt" then
    fsproxy.setLabel("repairIt")
end

function dfl(path)
	local stream, reason = fsproxy.open(path, "r")
	if stream then
		local data, chunk = ""
		while true do
			chunk = fsproxy.read(stream, math.huge)
			if chunk then data = data .. chunk
            else break end
		end
		fsproxy.close(stream)
		local result, reason = load(data, "=" .. path)
		if result then return result()
        else error(reason) end
	end
end

if computer.totalMemory() / 1000 < 200 then
    imprt = dfl
else
    loaded = {}
    function imprt(module)
        if loaded[module] then return loaded[module] end
        local result = dfl(module)
        loaded[module] = result
        return result
    end


    local files = fsproxy.list("/run/")
    for i, f in ipairs(files) do
        if endswith(f, ".lua") then
            imprt("/run/" .. f)
        end
        drawBar(math.floor(#files / i * 100))
    end
end

local module = nil
function stmdl(name)
    module = imprt("/run/" .. name .. ".lua")

    if module then
        drawTitle()
        module.init()
    else 
        stmdl("menu")
    end
end

drawBar(0)

local upd, upt, signal = 0, 0, nil
while true do
    if not module then stmdl("menu") end

    upt = computer.uptime()
    if upd <= upt then
        upd = upt + 2
        module.update()
    end

    signal = {computer.pullSignal(2)}
    if signal then
        if signal[1] == "component_added" then
            if signal[3] == "screen" then
                gpupoxy.bind(signal[2], true)
                sw, sh = gpupoxy.getResolution()
                drawTitle()
                module.draw()
            end
        elseif signal[1] == "component_removed" then
            if signal[3] == "screen" then
                local cmpnnt = component.list("screen")()
                if cmpnnt then
                    gpupoxy.bind(cmpnnt, true)
                    sw, sh = gpupoxy.getResolution()
                    drawTitle()
                    module.draw()
                end
            end
        elseif signal[1] == "key_down" then
            if signal[4] == 50 then
                stmdl("menu")
            elseif signal[4] == 19 then
                module.init()
            end
        end

        module.signal(signal)
    end
end
