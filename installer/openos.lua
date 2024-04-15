local component = require("component")
local io = require("io")
local internet = require("internet")

local rawGithubUrl = "https://raw.githubusercontent.com/aqur1n/repairIt"

if not component.isAvailable("internet") then
    return io.write("Internet card is required for installation\n")
end

-- Выбор диска для установки
io.write("Preparing for installation...\n")

local availableDisks = {}
for addr, tp in component.list("filesystem") do
    if component.invoke(addr, "spaceTotal") >= 512 * 1024 then -- Место на диске
        if not component.invoke(addr, "isReadOnly") then
            table.insert(availableDisks, addr)
        end
    end
end

io.write("Where do you want to install to?\n")
local label
for i, addr in ipairs(availableDisks) do
    label = component.invoke(addr, "getLabel")
    if not label then
        print(i .. ") " .. string.sub(addr, 1, 8))
    else
        print(i .. ") " .. label .. " (" .. string.sub(addr, 1, 8) .. ")")
    end
end

local selectedFilesystem
io.write("Please enter a disk number (\"q\" to exit) [1.." .. #availableDisks .. "/q] ")
local sf = io.read()
if sf == "q" then 
    io.write("Installation cancelled\n")
    return 
else
    selectedFilesystem = component.proxy(availableDisks[tonumber(sf)])
end

-- функции говна
local function request(url, chunkCall)
    local rslt, rspns = pcall(internet.request, url, nil, {["user-agent"]="Wget/OpenComputers"})
    if rslt then
        for chunk in rspns do
            chunkCall(chunk)
        end
    else
        io.write("HTTP request failed: " .. rspns .. "\n")
        return false
    end
    return true
end

local function download(url, path)
    local strm, rsn = selectedFilesystem.open(path, "wb")
    if not strm then
        return io.write("Failed opening file for writing: " .. rsn)
    end

    local rslt, rspns = pcall(internet.request, url, nil, {["user-agent"]="Wget/OpenComputers"})
    if rslt then
        for chunk in rspns do
            selectedFilesystem.write(strm, chunk)
        end
    else
        io.write("HTTP request failed: " .. rspns .. "\n")
        return false
    end
    selectedFilesystem.close(strm)
    return true
end

local function cfg(path)
	local strm, rsn = selectedFilesystem.open(path, "r")
	if strm then
		local d, c = ""
		while true do
			c = selectedFilesystem.read(strm, math.huge)
			if c then 
                d = d .. c 
            else 
                break 
            end
		end
		selectedFilesystem.close(strm)

		local r, rsn = load("return " .. d, "=" .. path) -- Спизжено с майноси (тут все спижено с майноси)
		if r then 
            return r() 
        else 
            error("Failed to import the file:" .. rsn) 
        end
	else
        error("Failed to import the file:" .. rsn)
	end
end

local function len(table)
    local c = 0
    for _, _ in pairs(table) do c = c + 1 end
    return c
end

local function split(str, sep)
    local t = {}
    for s in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, s)
    end
    return t
end

local function join(str, tbl)
    local d = ""
    for _, v in ipairs(tbl) do
        d = d .. v .. str
    end
    return d
end

selectedFilesystem.makeDirectory("/tmp")
download(rawGithubUrl .. "/master/installer/fileslist.cfg", "/tmp/fileslist.cfg")
local fileslist = cfg("/tmp/fileslist.cfg")

-- Выбор версии для установки 
local version
if #fileslist.versions == 1 then
    version = fileslist.versions[1]
else
    io.write("What version do you want to install?\n")
    for i, v in ipairs(fileslist.versions) do
        print(i .. ") " .. v)
    end

    io.write("Please enter a version number (\"q\" to exit) [1.." .. #fileslist.versions .. "/q] ")
    local sv = io.read()
    if sv == "q" then 
        io.write("Installation cancelled\n")
        return 
    else
        version = fileslist.versions[tonumber(sv)]
    end
end

-- Выбор билда для установки
local build
if #fileslist.builds[version] == 1 then
    build = fileslist.builds[version][1]
else
    io.write("What build do you want to install?\n")
    for i, v in ipairs(fileslist.builds[version]) do
        print(i .. ") " .. v)
    end

    io.write("Please enter a build number (\"q\" to exit) [1.." .. #fileslist.builds[version] .. "/q] ")
    local sb = io.read()
    if sb == "q" then 
        io.write("Installation cancelled\n")
        return 
    else
        build = fileslist.builds[version][tonumber(sb)]
    end
end

-- Установка

while true do
    io.write("Install repairIt " .. build .. " (" .. version  .. ")?\n")
    io.write("It's wipe all the data on " .. (selectedFilesystem.getLabel() or string.sub(availableDisks[tonumber(sf)], 1, 8)) .. " [Y/n] ")
    local r = string.lower(io.read() or "")

    if r == "y" then
        break
    elseif r == "n" then
        io.write("Installation cancelled\n")
        return
    end
end

for _, file in ipairs(selectedFilesystem.list("")) do
    if file ~= "tmp/" then
        selectedFilesystem.remove(file)
    end
end

local unpackData = ""
local function readBlock(strm)
    local d, c, blck = unpackData .. "", "", ""
    while true do
        c = selectedFilesystem.read(strm, math.huge)
    	if c then 
            d = d .. c 
        elseif unpackData == "" then
            break 
        end

        for cs in string.gmatch(d, ".") do
            blck = blck .. cs

            if cs == "" then 
                unpackData = string.sub(d, #blck + 1) 
                return blck
            end
        end
        blck = ""
    end
    return blck
end

local function unpack(blck)
    if string.sub(blck, 1, 6) == "dirs" then
        for _, fn in ipairs(split(string.sub(blck, 7, -2), ",")) do
            if #fn > 1 then
                io.write("Creating a directory: " .. fn .. "\n")
                selectedFilesystem.makeDirectory(fn)
            end
        end
    elseif string.sub(blck, 1, 5) == "file" then
        local d = split(string.sub(blck, 7, -2), "")
        io.write("Unpacking the file: " .. d[1] .. "\n")

        local strm, rsn = selectedFilesystem.open(d[1], "w")
        if strm then
            local filedata = ""
            for cs in string.gmatch(d[2], ".") do
                if cs == "" then
                    filedata = filedata .. "\n"
                else
                    filedata = filedata .. cs
                end
            end
            selectedFilesystem.write(strm, filedata)
            selectedFilesystem.close(strm)
        else
            error("Failed to create the file: " .. rsn)
        end

    else
        io.write("Unknown data: " .. string.sub(blck, 1, 50) .. "...\n")
    end
end

local function unpackBuild()
    io.write("Unpacking the archive...\n")

    local strm, rsn = selectedFilesystem.open("/tmp/build.rbf", "r")
    local blck
	if strm then
        while true do
            blck = readBlock(strm)
            if blck == "" then
                break
            end
            unpack(blck)
        end
		selectedFilesystem.close(strm)
	else
        error("Failed to unpack the file: " .. rsn)
	end
end

io.write("Downloading the archive...\n")
if download("https://github.com/aqur1n/repairIt/releases/download/" .. build .. "/" .. version .. ".rbf", "/tmp/build.rbf") then
    unpackBuild()

    io.write("Deleting temporary files...\n")
    selectedFilesystem.remove("tmp/")

    io.write("Installation complete\n")
else
    io.write("Installation cancelled by error\n")
end
