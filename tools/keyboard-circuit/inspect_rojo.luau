local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local roots = roblox.deserializeModel(fs.readFile(".tools/rojo-7.7.1-download/Rojo.rbxm"))
for _,root in roots do
	for _,object in root:GetDescendants() do
		if object:IsA("LuaSourceContainer") then
			local source=object.Source
			if source:find("localhost",1,true) or source:find("GetSetting",1,true) or source:find("SetSetting",1,true) then
				print(object:GetFullName())
				for line in source:gmatch("[^\r\n]+") do
					if line:find("localhost",1,true) or line:find("Host",1,true) or line:find("Port",1,true) or line:find("GetSetting",1,true) or line:find("SetSetting",1,true) then print(line) end
				end
			end
		end
	end
end
