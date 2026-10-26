return function()
    local course = workspace.Course_HeartwoodAscent
    local library = game.ServerStorage.AssetLibraries.HeartwoodV1HA04
    assert(course:GetAttribute('HeartwoodBuild') == 'HA_V1_04')
    local data = game:GetService('SerializationService'):SerializeInstancesAsync({course, library})
    local bytes = buffer.len(data)
    local hex = table.create(bytes)
    for i = 0, bytes - 1 do hex[i + 1] = string.format('%02x', buffer.readu8(data, i)) end
    local content = table.concat(hex)
    local folder = Instance.new('Folder')
    folder.Name = 'HeartwoodExportSnapshot_HA04_' .. game:GetService('HttpService'):GenerateGUID(false)
    folder:SetAttribute('Bytes', bytes)
    folder:SetAttribute('Chunks', math.ceil(#content / 6000))
    folder.Parent = game.ServerStorage
    for offset = 1, #content, 6000 do
        local value = Instance.new('StringValue')
        value.Name = tostring(math.floor((offset - 1) / 6000) + 1)
        value.Value = string.sub(content, offset, offset + 5999)
        value.Parent = folder
    end
    return {folder = folder.Name, bytes = bytes, chunks = folder:GetAttribute('Chunks')}
end
