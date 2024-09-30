local repair = {}
local ms = 1

local bioses = {
    ["Vanilla BIOS"] = "lua.bs",
--build:ignore=LITE
    ["BetterBIOS by KeyTwoZero"] = "better.bs" -- by KeyTwoZero https://codeberg.org/KeyTwoZero/BetterBIOS
--build:end
}
local osHashes = {
    ["OpenOS"] = "openos.hss",
--build:ignore=LITE
    -- TODO
--build:end
}

-- --------------------------------------

local function eeprominstall(cmp, bios) cmp.set(bios) cmp.setData("") end
local function repairBios(bname)
    ui.infoBox("Installing "..bname.."...")
    local strm, rsn = fs.open("bios/"..bioses[bname], "r")
	if strm then
		local d, c = ""
		while true do
			c = fs.read(strm, math.huge)
			if c then d = d .. c else break end
		end
		fs.close(strm)

		if pcall(eeprominstall, cmp.proxy(cmp.list("eeprom")()), d) then
            ui.infoBox("The installation is complete", true)
        else
            ui.errorBox("BIOS is read-only")
        end

	else
		ui.errorBox("BIOS file was not found")
    end
end

local function hash(str) -- djb2
    h = 5381
    for c in str:gmatch"." do
        h = (bit32.lshift(h, 5) + h) + string.byte(c)
    end
    return h
end

local function repairOS(wfs, osname)
end

-- --------------------------------------

local function sBios()
    ui.setDescr("Select the BIOS that you want to install/repair")
    local bname = ui.select(tkeys(bioses))
    if bname ~= nil then
        if ui.infoBox("Are you sure? Press ENTER to confirm or another button to cancel", true, true) then
            repairBios(bname)
        end
    end
    repair.init()
end

local function sOs()
    ui.setDescr(2, 3, "Select ...")
end

-- --------------------------------------

local repairMenu = {
    -- name, func, description
    {"Repair/Install BIOS", sBios, "Repair or reinstall BIOS on your EEPROM"},
    --{"Check and repair OS", sOs, ""}
}


function repair.init() 
    screenClear()
    ui.title()
    repair.draw()
end

function repair.draw() 
    color.normal()
    for i, v in ipairs(repairMenu) do
        if ms == i then 
            ui.setDescr(v[3])
            color.inversion() 
        else 
            color.normal() 
        end
        gpu.set(centralize(v[1]), 6 + i, v[1])
    end
end

function repair.keySignal(signal) 
    if signal[4] == keyboard.ARRW_DOWN then
        if ms >= #repairMenu then 
            ms = 1 
        else 
            ms = ms + 1 
        end
        repair.draw()
    elseif signal[4] == keyboard.ARRW_UP then
        if ms <= 1 then 
            ms = #repairMenu
        else 
            ms = ms - 1 
        end
        repair.draw()
    elseif signal[4] == keyboard.ENTER then
        repairMenu[ms][2]()
    end
end

return repair
