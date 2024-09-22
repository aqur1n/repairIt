local lua = {
    session = true
}
local code = ""
local lstStr = ""

function lua.start() 
    --luaPrint("123")
end

-- if session == true then
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
    luaPrint(">exit")
end

return lua
