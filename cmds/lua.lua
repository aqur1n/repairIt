local lua = {
    session = true,
    char = "-"
}
local code = ""
local lstStr = ""

print = luaPrint

function lua.start() 
end

function lua.stringSignal(str) 
    if str ~= "" then
        code = code .. "\n" .. lstStr
        lstStr = str
        luaPrint("- "..str)
    else
        local st, v = pcall(load(code .. "\nreturn " .. lstStr))
        if v then
            luaPrint(v)
        end
        code = ""
        lstStr = ""
    end
end

function lua.exit() 
    print = nil
    luaPrint("exit")
end

return lua
