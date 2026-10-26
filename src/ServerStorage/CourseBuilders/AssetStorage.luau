--!strict
local ServerStorage = game:GetService("ServerStorage")
local AssetStorage = {}

function AssetStorage.Folder(name: string): Folder
    local existing = ServerStorage:FindFirstChild(name)
    if existing then
        assert(existing:IsA("Folder"), "Expected asset folder " .. name)
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = name, ServerStorage
    return folder
end

return AssetStorage
