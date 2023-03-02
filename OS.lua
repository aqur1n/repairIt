local pr = component.proxy(component.proxy(component.list("eeprom")()).getData())
local stream, reason = pr.open("/init.lua", "r")
if stream then
	local data, chunk = ""
	while true do
		chunk = pr.read(stream, math.huge)
		if chunk then data = data .. chunk
		else break end
	end
	pr.close(stream)
	local result, reason = load(data, "=/init.lua")
	if result then result()
	else error(reason) end
end
