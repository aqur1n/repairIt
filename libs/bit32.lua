local bit32 = {}

local function trim(n)
    return n & 0xFFFFFFFF
end

function bit32.lshift(x, disp)
    return trim(x << disp)
end

return bit32
