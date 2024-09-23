local cmd = {}
local mcmmds, cs, cur, m, mi = {""}, {}, 1, false, 1
local cmds

local commands = {
    clear = function() 
        cs = {}
        luaPrint("") 
    end
}

local function tString(obj)
    local t = type(obj)
    if t == "string" then
        return obj
    elseif t == "table" then
        local s = "{"
        for k, v in pairs(obj) do
            s = s..tostring(k).."="..tostring(v)..","
        end
        if string.sub(s, -1) == "," then s = string.sub(s, 1, -2) end
        return s .. "}"
    elseif t == "function" then
        -- TODO
        return "function" .. tostring(obj)
    else
        return tostring(obj)
    end
end

function luaPrint(str)
    str = tString(str)
    for i = 1, math.floor(#str / sh) + 1 do
        cs[#cs + 1] = string.sub(str, sw * (i - 1), sw * i - 1)

        if cs[#cs] == "" then
            table.remove(cs, #cs)
        end
        if #cs > sh - 6 then
            table.remove(cs, 1)
        end
    end

    gpu.fill(1, 5, sw, sh, " ")

    for l, v in ipairs(cs) do
        gpu.set(1, l + 4, v)
    end
end

local function loadFile()
    cmds = dofile("/cmds/" .. mcmmds[mi] .. ".lua")
end

local function loadCommand()
    local res = commands[mcmmds[mi]]
    if res ~= nil then
        res()
    else
        local err
        res, err = pcall(loadFile)
        if res then
            cmds.start()
            if cmds.session == false then
                cmds.exit()
                cmds = nil
            end
        elseif mcmmds[mi] ~= "" then
            luaPrint("“" .. mcmmds[mi] .. "” is not an command or executable program.")
        end
    end
end

function cmd.init() 
    screenClear()
    ui.header()
    cmd.draw() 

    local chr, cd, uchr
    while true do
        chr, cd = keyboard.waitChar(0.5) 
        if chr == nil then
            --
        elseif cd == keyboard.L_CONTROL then
            local _, ccd = keyboard.waitCharWDown()
            if ccd == keyboard.M then
                loadModule("menu")
                break
            elseif ccd == keyboard.Z then
                if cmds ~= nil and cmds.session then
                    cmds.exit()
                    cmds = nil
                end
            end
        elseif cd == keyboard.ENTER then
            if cmds ~= nil then
                if mcmmds[mi] == "exit" then
                    cmds.exit()
                    cmds = nil
                else
                    cmds.stringSignal(mcmmds[mi])
                end
                mcmmds[mi] = ""
            else
                luaPrint(">" .. mcmmds[mi])
                loadCommand()

                if mcmmds[#mcmmds] ~= "" then
                    mi = #mcmmds + 1
                else
                    mi = #mcmmds
                end
                cur = 1
                mcmmds[mi] = ""
            end
        elseif cd == keyboard.BACKSPACE then
            if cur == 1 then
                mcmmds[mi] = string.sub(mcmmds[mi], 1, -2)
            else
                mcmmds[mi] = string.sub(mcmmds[mi], 1, -cur - 1) .. string.sub(mcmmds[mi], -cur + 1)
            end
        elseif cd == keyboard.ARRW_UP then
            cur = 1
            if mi > 1 then
                mi = mi - 1
            else
                mi = #mcmmds
            end
        elseif cd == keyboard.ARRW_DOWN then
            cur = 1
            if mi < #mcmmds then
                mi = mi + 1
            end
        elseif cd == keyboard.ARRW_LEFT then
            if cur < #mcmmds[mi] + 1 then
                cur = cur + 1
            end
        elseif cd == keyboard.ARRW_RIGHT then
            if cur > 1 then
                cur = cur - 1
            end
        elseif keyboard.isAlphabet(cd) then
            if mi < #mcmmds then
                mcmmds[#mcmmds] = mcmmds[mi]
                mi = #mcmmds
            end

            uchr = unicode.char(chr) -- Пожалуйста помогите с ру буквами...
            if #uchr > 1 then 
                uchr = "?" 
            end

            if cur == 1 then
                mcmmds[mi] = mcmmds[mi] .. uchr
            else
                mcmmds[mi] = string.sub(mcmmds[mi], 1, -cur) .. uchr .. string.sub(mcmmds[mi], -cur + 1)
            end
        end
        cmd.draw()
    end
end

function cmd.draw() 
    gpu.fill(1, sh - 1, sw, 1, "_")
    gpu.fill(1, sh, sw, 1, " ")
    gpu.set(2, 3, "Use CTRL+M to return to the main menu")
    gpu.set(1, sh, (cmds and cmds.char or ">") .. " ")
    gpu.set(3, sh, string.sub(mcmmds[mi], -sw - cur + 4))

    local pos = 4 + #mcmmds[mi] - cur
    if pos > sw then pos = sw end
    local chr, _, _, _, _ = gpu.get(pos, sh)
    if m then
        color.inversion()
        m = false
    else
        m = true
    end
    gpu.set(pos, sh, chr)
    color.normal()
end

return cmd
