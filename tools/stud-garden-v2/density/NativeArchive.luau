return function(root, filename, fingerprint)
    assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
    assert(filename:match("^[a-z0-9%-]+%.rbxm$"))
    local serializer = game:GetService("SerializationService")
    local http = game:GetService("HttpService")
    local priorHttp = http.HttpEnabled
    local restored
    local ok, result = xpcall(function()
        local before = fingerprint(root)
        local bytes = buffer.tostring(serializer:SerializeInstancesAsync({root}))
        http.HttpEnabled = true
        local url = "http://127.0.0.1:8768/" .. filename
        local response = http:RequestAsync({Url=url, Method="POST", Headers={["Content-Type"]="application/octet-stream"}, Body=bytes})
        assert(response.Success, response.StatusMessage)
        local readback = http:GetAsync(url, true)
        assert(readback == bytes, "Saved bytes differ")
        restored = serializer:DeserializeInstancesAsync(buffer.fromstring(readback))
        assert(#restored == 1)
        local after = fingerprint(restored[1])
        for _,key in {"contentHash","instances","parts","meshes","colliders","scripts","sourceBytes","stringBytes"} do
            assert(before[key] == after[key], "Restored " .. key .. " differs")
        end
        assert(before.geometry.hash == after.geometry.hash, "Restored geometry differs")
        return {receipt=http:JSONDecode(response.Body), before=before, restored=after, verified=true}
    end, debug.traceback)
    if restored then for _,object in restored do object:Destroy() end end
    http.HttpEnabled = priorHttp
    assert(ok, result)
    return result
end

