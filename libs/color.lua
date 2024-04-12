local color = {}

function color.normal()
    gpu.setBackground(0x0)
	gpu.setForeground(0xFFFFFF)
end

function color.inversion()
    gpu.setBackground(0xFFFFFF) 
	gpu.setForeground(0x0)
end

function color.grey()
    gpu.setBackground(0x0)
	gpu.setForeground(0x878787)
end

return color
