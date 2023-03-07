fsproxy = component.proxy(component.proxy(component.list("eeprom")()).getData())
gpuproxy = component.proxy(component.list("gpu")())

gpuproxy.bind(component.list("screen")(), true)

sw, sh = gpuproxy.getResolution()
version = "0.1a (Full) " .. _VERSION

function endswith(str, ending)
    return string.sub(str, -#ending) == ending
end

function normalcolour()
    gpuproxy.setBackground(0x0)
	gpuproxy.setForeground(0xFFFFFF)
end

function disabledcolour()
    gpuproxy.setBackground(0x0)
	gpuproxy.setForeground(0x878787)
end

function inversioncolour()
    gpuproxy.setBackground(0xFFFFFF) 
	gpuproxy.setForeground(0x0)
end

function centralize(text)
	return math.floor(sw / 2 - #tostring(text) / 2)
end

function drawTitle()
    normalcolour()
    gpuproxy.fill(1, 1, sw, sh, " ")

    gpuproxy.set(1, 1, "╒") 
    gpuproxy.set(sw, 1, "╕")
    gpuproxy.set(1, 4, "└")
    gpuproxy.set(sw, 4, "┘")

    gpuproxy.fill(2, 1, sw - 2, 1, "═")
    gpuproxy.fill(2, 4, sw - 2, 1, "─")
    gpuproxy.fill(sw, 2, 1, 2, "│")
    gpuproxy.fill(1, 2, 1, 2, "│")

    gpuproxy.set(2, 2, "repairIt " .. version)

    gpuproxy.set(1, sh - 2, "╒")
    gpuproxy.set(sw, sh - 2, "╕")
    gpuproxy.set(1, sh, "└")
    gpuproxy.set(sw, sh, "┘")

    gpuproxy.fill(2, sh - 2, sw - 2, 1, "═")
    gpuproxy.fill(2, sh, sw - 2, 1, "─")
    gpuproxy.set(sw, sh - 1, "│")
    gpuproxy.set(1, sh - 1, "│")

    gpuproxy.set(2, sh - 1, "Moving: ⇅, Choose: Enter, Return: M, Reload: R")
end

function drawBar(percent)
    local pos = math.floor(percent * sw / 100)
    if percent > 0 then
        gpuproxy.fill(1, sh, pos, 1, "█")
        gpuproxy.set(pos, sh, "█▓▒░")
    else
        gpuproxy.fill(1, sh, sw, 1, " ")
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
			if chunk then data = data .. chunk else break end
		end
		fsproxy.close(stream)
		local result, reason = load(data, "=" .. path)
		if result then return result() else error(reason) end
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
                gpuproxy.bind(signal[2], true)
                sw, sh = gpuproxy.getResolution()
                drawTitle()
                module.draw()
            end
        elseif signal[1] == "component_removed" then
            if signal[3] == "screen" then
                local cmpnnt = component.list("screen")()
                if cmpnnt then
                    gpuproxy.bind(cmpnnt, true)
                    sw, sh = gpuproxy.getResolution()
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
