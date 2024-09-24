local ui = {}

function ui.header()
    gpu.set(1, 1, "╒") 
    gpu.set(sw, 1, "╕")
    gpu.set(1, 4, "└")
    gpu.set(sw, 4, "┘")

    gpu.fill(2, 1, sw - 2, 1, "═")
    gpu.fill(2, 4, sw - 2, 1, "─")
    gpu.fill(sw, 2, 1, 2, "│")
    gpu.fill(1, 2, 1, 2, "│")

    gpu.set(2, 2, "repairIt " .. VERSION)
end

function ui.title()
    ui.header()

    gpu.set(1, sh - 2, "╒")
    gpu.set(sw, sh - 2, "╕")
    gpu.set(1, sh, "└")
    gpu.set(sw, sh, "┘")

    gpu.fill(2, sh - 2, sw - 2, 1, "═")
    gpu.fill(2, sh, sw - 2, 1, "─")
    gpu.set(sw, sh - 1, "│")
    gpu.set(1, sh - 1, "│")

    gpu.set(2, sh - 1, "Moving: ⇅, Choose: Enter, Return: M, Reload: R")
end

function ui.progressbar(percent, posy)
    local pos = math.floor(percent * sw)
    if percent * sw > 0 then
        gpu.fill(1, posy, pos, 1, "█")
        gpu.set(pos, posy, "█▓▒░")
    else
        gpu.fill(1, posy, sw, 1, " ")
    end
    computer.pullSignal(0)
end

function ui.drawBox(title)
    color.normal()
    gpu.fill(sw / 2 - 12, sh / 2 - 3, 24, 8, " ")

    gpu.fill(sw / 2 - 11, sh / 2 - 3, 23, 1, "═")
    gpu.fill(sw / 2 - 11, sh / 2 + 5, 23, 1, "─")

    gpu.fill(sw / 2 - 12, sh / 2 - 3, 1, 8, "│")
    gpu.fill(sw / 2 + 12, sh / 2 - 3, 1, 8, "│")

    gpu.set(sw / 2 - 12, sh / 2 - 3, "╒")
    gpu.set(sw / 2 + 12, sh / 2 - 3, "╕")

    gpu.set(sw / 2 - 12, sh / 2 + 5, "└")
    gpu.set(sw / 2 + 12, sh / 2 + 5, "┘")

    gpu.set(centralize(title), sh / 2 - 3, title)
end

function ui.infoBox(text, wait, confirm)
    ui.drawBox("Info")
    for i = 1, math.floor(#text / 22) + 1 do
        gpu.set(sw / 2 - 11, sh / 2 - 3 + i, string.sub(text, (22 + 1) * (i - 1), 22 * i))
    end
    if wait then
        color.inversion()
        gpu.set(sw / 2 - 1, sh / 2 + 5, "OK")
        while true do
            chr, cd = keyboard.waitChar()
            if cd == keyboard.ENTER then 
                return true
            elseif confirm then 
                return false
            end
        end
    end
end

function ui.errorBox(err)
    ui.drawBox("Error")
    for i = 1, math.floor(#err / 22) + 1 do
        gpu.set(sw / 2 - 11, sh / 2 - 3 + i, string.sub(err, (22 + 1) * (i - 1), 22 * i))
    end
    color.inversion()
    gpu.set(sw / 2 - 1, sh / 2 + 5, "OK")
    while true do
        chr, cd = keyboard.waitChar()
        if cd == keyboard.ENTER then return end
    end
end

function ui.warn(lines)
    ui.drawBox("Warning")
    for i, v in ipairs(lines) do 
        gpu.set(sw / 2 - 11, sh / 2 - 3 + i, v)
    end
    color.inversion()
    gpu.set(sw / 2 - 1, sh / 2 + 5, "OK")

    keyboard.waitChar() 
    return
end

function ui.gpuSet(x, y, str)
    if y < 5 or y > sh - 3 then return end
    gpu.set(x, y, str)
end

function ui.setDescr(text)
    color.normal()
    gpu.fill(2, 3, sw - 3, 1, " ")
    gpu.set(2, 3, text)
end

function ui.select(l, checker, fReason)
    local chr, cd
    local s, mh = 1, 0

    while true do
        color.normal() 
        gpu.fill(2, 5, sw - 3, sh - 7, " ")
        for i, v in ipairs(l) do
            if s == i then 
                color.inversion() 
            else 
                color.normal() 
            end
            ui.gpuSet(centralize(l[i]), 5 + i - mh, l[i])
        end

        chr, cd = keyboard.waitChar() 
        if cd == keyboard.ENTER then
            if checker and not checker(l[s]) then
                ui.errorBox(fReason)
            else
                return l[s]
            end
        elseif cd == keyboard.M then
            return
        elseif cd == keyboard.ARRW_UP then
            if s > 1 then
                s = s - 1
            end
        elseif cd == keyboard.ARRW_DOWN then
            if s < #l then
                s = s + 1
            end
        end

        if s > sh - 8 then 
            mh = s - sh + 8 
        elseif s < sh - 7 then
            mh = 0
        end
    end
end

return ui
