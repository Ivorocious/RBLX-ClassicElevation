-- Export the frozen C11 course, owner objects and archives after visual review.
local Export = {}
function Export.Run(baseUrl)
    assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
    assert(not game.ServerStorage:FindFirstChild("__CityRunSkyPreviewBackup"), "Restore the temporary preview first")
    local course = workspace.Course_CityRun
    assert(course:GetAttribute("ReviewBuildId") == "C11_02" and course:GetAttribute("VisualReviewPassed") == true)
    local http, serializer = game:GetService("HttpService"), game:GetService("SerializationService")
    local priorHttp, restored = http.HttpEnabled, nil
    local ok, result = xpcall(function()
        http.HttpEnabled = true
        local audit = loadstring(http:GetAsync(baseUrl .. "/audit.luau"))()
        local roots = {}
        for _, object in workspace:GetChildren() do
            if (object:IsA("Model") and object.Name ~= "Lobby" and object.Name ~= "AncientPillar")
                or (object:IsA("BasePart") and not object:IsA("Terrain") and object.Position.X >= 3100 and object.Position.X <= 4050) then
                table.insert(roots, object)
            end
        end
        for _, name in {"CityRun_C08_ReplacedGeneratedParts", "CityRun_C09_Archive", "CityRun_C10_Archive", "CityRun_C11_Archive"} do
            table.insert(roots, game.ServerStorage[name])
        end
        local original = audit.Snapshot(roots)
        local bytes = buffer.tostring(serializer:SerializeInstancesAsync(roots))
        local url = baseUrl .. "/city-run-c11-final.rbxm"
        local response = http:RequestAsync({Url=url, Method="POST", Headers={["Content-Type"]="application/octet-stream"}, Body=bytes})
        assert(response.Success, response.StatusCode)
        local readback = http:GetAsync(url, true)
        assert(readback == bytes, "Saved backup bytes differ")
        restored = serializer:DeserializeInstancesAsync(buffer.fromstring(readback))
        local copy = audit.Snapshot(restored)
        assert(#copy == #original, "Restored instance count differs")
        local receipt = http:JSONDecode(response.Body)
        local payload = {build=course:GetAttribute("ReviewBuildId"), roots=#roots, original=original, restored=copy, receipt=receipt, exactSavedBytes=true}
        local saved = http:RequestAsync({Url=baseUrl .. "/c11-final-audit.json", Method="POST", Headers={["Content-Type"]="application/json"}, Body=http:JSONEncode(payload)})
        assert(saved.Success, saved.StatusCode)
        return {build=payload.build, roots=#roots, records=#original, receipt=receipt, exactSavedBytes=true}
    end, debug.traceback)
    if restored then for _, object in restored do object:Destroy() end end
    http.HttpEnabled = priorHttp
    assert(ok, result)
    return result
end
return Export
