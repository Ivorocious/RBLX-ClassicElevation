local roblox = require("@lune/roblox")
local db = roblox.getReflectionDatabase()
for _, className in { "BasePart", "MeshPart" } do
    local class = db:GetClass(className)
    print("CLASS", className)
    for propertyName, property in class.Properties do
        print("PROPERTY", propertyName, tostring(property.Name), tostring(property.Datatype))
    end
end
