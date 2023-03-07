local disks = {}

local fs, pth, indx, lst, page = nil, "/", 1, 0, {}, 0

local function getkeys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do table.insert(keys, key) end
    return keys
end

local function gpuset(x, y, str)
    if y < 5 or y > sh - 3 then return end
    gpuproxy.set(x, y, str)
end

local function remove(str) 
    local tb = {}
    for i in string.gmatch(str, "([^\\/]+)") do 
        if i ~= "" then
            table.insert(tb, i .. "/") 
        end
    end
    table.remove(tb)
    return tb
end

function disks.init()
    fs, pth, indx, lst, page = nil, "/", 1, getkeys(component.list("filesystem")), 0
    disks.draw() 
end

function disks.draw() 
    normalcolour()
    gpuproxy.fill(2, 3, sw - 2, 1, " ")
    gpuproxy.fill(1, 5, sw, sh - 7, " ")
    if fs then gpuproxy.set(2, 3, pth)
    else gpuproxy.set(2, 3, "Disk and File Manager") end

    for i = 1, #lst do
        if i >= sh - 7 + page then break
        elseif i == indx then inversioncolour() 
        else normalcolour() 
        end
        gpuset(1, 5 + i - page, lst[i])
    end
end

function disks.signal(signal)
    if signal[1] == "key_down" then
        if signal[4] == 208 then -- down
            if indx < #lst then 
                indx = indx + 1 
                if indx >= sh - 7 then 
                    page = page + 1
                end
            end
        elseif signal[4] == 200 then  -- up
            if indx > 1 then 
                indx = indx - 1 
                if indx - page <= 0 and page > 0 then 
                    page = page - 1
                end
            end
        elseif signal[4] == 28 then -- enter
            if fs then
                if lst[indx] == "..." then
                    if pth == "/" then 
                        -- disks.init calling disks.draw
                        fs, pth, indx, lst, page = nil, "/", 1, getkeys(component.list("filesystem")), 0
                    else 
                        pth = "/" .. table.concat(remove(pth))
                        indx, lst, page = 1, fs.list(pth), 0
                        table.insert(lst, 1, "...")
                    end
                else
                    if fs.isDirectory(pth .. lst[indx]) then
                        pth = pth .. lst[indx]
                        indx, lst, page = 1, fs.list(pth), 0
                        table.insert(lst, 1, "...")
                    else
                        -- TODO
                    end
                end
            else 
                fs = component.proxy(lst[indx]) 
                if fs then 
                    indx, lst, page = 1, fs.list(pth), 0
                    table.insert(lst, 1, "...")
                end
            end
        end
        disks.draw() 
    -- elseif signal[1] == "component_added" then
    --     if signal[3] == "filesystem" then
    --         disks.draw() 
    --     end
    elseif signal[1] == "component_removed" then
        if signal[3] == "filesystem" and signal[2] == fs.address then
            disks.init()
        end
    end 
end

function disks.update() end

return disks