local component = require("component")
local io = require("io")
local internet = require("internet")
local shell = require("shell")
local filesystem = require("filesystem")

local rawGithubUrl = "https://raw.githubusercontent.com/aqur1n/repairIt"

if not component.isAvailable("internet") then
    return io.write("Internet card is required for installation\n")
end

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

-- функции
local function download(url, path)
    local file, rsn = filesystem.open(path, "wb")
    if not file then
        return io.write("Failed opening file for writing: " .. rsn)
    end

    local rslt, rspns = pcall(internet.request, url, nil, {["user-agent"]="Wget/OpenComputers"})
    if rslt then
        for chunk in rspns do
            file:write(chunk)
        end
    else
        io.write("HTTP request failed: " .. rspns .. "\n")
        return false
    end
    file:close()
    return true
end

local function cfg(path)
	local file, rsn = filesystem.open(path, "r")
	if file then
		local d, c = ""
		while true do
			c = file:read(math.huge)
			if c then 
                d = d .. c 
            else 
                break 
            end
		end
		file:close()

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

-- ----------------------------------------

local function installerGetVersion(fileslist)
    if #fileslist.versions == 1 then
        return fileslist.versions[1]
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
            return fileslist.versions[tonumber(sv)]
        end
    end
end

local function installerGetBuild(builds)
    if #builds == 1 then
        return builds[1]
    else
        io.write("What build do you want to install?\n")
        for i, v in ipairs(builds) do
            print(i .. ") " .. v)
        end

        io.write("Please enter a build number (\"q\" to exit) [1.." .. #builds .. "/q] ")
        local sb = io.read()
        if sb == "q" then 
            io.write("Installation cancelled\n")
            return 
        else
            return builds[tonumber(sb)]
        end
    end
end

local function wipeData()
    for _, file in ipairs(selectedFilesystem.list("")) do
        if file ~= "tmp/" then
            selectedFilesystem.remove(file)
        end
    end
end

local unpackData = ""
local function readBlock(file)
    local d, c, blck = unpackData .. "", "", ""
    while true do
        c = file:read(512)
    	if c then 
            d = d .. c 
            c = ""
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
    return d
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
            filedata = nil
        else
            error("Failed to create the file: " .. rsn)
        end

    else
        io.write("Unknown data: " .. string.sub(blck, 1, 50) .. "...\n")
    end
end

local function unpackBuild(path)
    io.write("Unpacking the archive...\n")

    local file, rsn = filesystem.open(path, "r")
    local blck
	if file then
        while true do
            blck = readBlock(file)
            if blck == "" then
                break
            end
            unpack(blck)
            blck = nil
        end
		file:close()
	else
        error("Failed to unpack the file: " .. rsn)
	end
end

local args, _ = shell.parse(...)
if not args[1] then
    download(rawGithubUrl .. "/master/installer/fileslist.cfg", "/tmp/fileslist.cfg")
    local fileslist = cfg("/tmp/fileslist.cfg")

    local version = installerGetVersion(fileslist)
    if not version then return end
    local build = installerGetBuild(fileslist.builds[version])
    if not build then return end

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

    io.write("Downloading the archive...\n")
    if download("https://github.com/aqur1n/repairIt/releases/download/" .. build .. "/" .. version .. ".rbf", "/tmp/build.rbf") then
        wipeData()  
        unpackBuild("/tmp/build.rbf")
    else
        io.write("Installation cancelled by error\n")
        return
    end
else
    while true do
        io.write("Install repairIt from the package?\n")
        io.write("It's wipe all the data on " .. (selectedFilesystem.getLabel() or string.sub(availableDisks[tonumber(sf)], 1, 8)) .. " [Y/n] ")
        local r = string.lower(io.read() or "")

        if r == "y" then
            break
        elseif r == "n" then
            io.write("Installation cancelled\n")
            return
        end
    end
    wipeData()
    unpackBuild(args[1])
end
io.write("Installation complete\n")
