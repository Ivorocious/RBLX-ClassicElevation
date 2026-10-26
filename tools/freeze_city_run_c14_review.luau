local Review={}
function Review.Run(baseUrl)
 assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
 local course=workspace.Course_CityRun
 assert(course:GetAttribute("ReviewBuildId")=="C14_05")
 local http=game:GetService("HttpService")
 local prior=http.HttpEnabled
 local ok,result=xpcall(function()
 http.HttpEnabled=true
        local audit = loadstring("local Audit = {}\n\nlocal function value(v)\n\tlocal kind = typeof(v)\n\tif kind == \"Vector3\" then return {v.X, v.Y, v.Z}\n\telseif kind == \"Vector2\" then return {v.X, v.Y}\n\telseif kind == \"Color3\" then return {v.R, v.G, v.B}\n\telseif kind == \"CFrame\" then return {v:GetComponents()}\n\telseif kind == \"EnumItem\" then return tostring(v)\n\telse return v end\nend\n\nfunction Audit.Snapshot(roots)\n\tlocal records = {}\n\tlocal function visit(object, path)\n\t\tlocal attrs = {}\n\t\tfor key, attribute in object:GetAttributes() do\n\t\t\tattrs[key] = value(attribute)\n\t\tend\n\t\tlocal record = { path = path, class = object.ClassName, attrs = attrs }\n\t\tif object:IsA(\"BasePart\") then\n\t\t\trecord.cf = { object.CFrame:GetComponents() }\n\t\t\trecord.size = { object.Size.X, object.Size.Y, object.Size.Z }\n\t\t\trecord.color = { object.Color.R, object.Color.G, object.Color.B }\n\t\t\tfor _, key in { \"Transparency\", \"Anchored\", \"CanCollide\", \"CanTouch\", \"CanQuery\", \"CastShadow\", \"CollisionGroup\", \"Material\" } do\n\t\t\t\trecord[key] = if typeof(object[key]) == \"EnumItem\" then tostring(object[key]) else object[key]\n\t\t\tend\n\t\t\tif object:IsA(\"Part\") then record.shape = tostring(object.Shape) end\n\t\t\tif object:IsA(\"MeshPart\") then record.mesh = object.MeshId; record.texture = object.TextureID; record.DoubleSided = object.DoubleSided end\n\t\telseif object:IsA(\"Model\") then\n\t\t\trecord.pivot = { object:GetPivot():GetComponents() }\n\t\tend\n\t\tif object:IsA(\"TextLabel\") or object:IsA(\"TextButton\") then\n\t\t\trecord.text = object.Text; record.textColor = value(object.TextColor3)\n\t\t\trecord.textScaled = object.TextScaled; record.font = tostring(object.Font)\n\t\telseif object:IsA(\"SurfaceGui\") then\n\t\t\trecord.face = tostring(object.Face); record.canvas = value(object.CanvasSize)\n\t\tend\n\t\tif object:IsA(\"LuaSourceContainer\") then record.source = object.Source end\n\t\ttable.insert(records, record)\n\t\tfor _, child in object:GetChildren() do visit(child, path .. \"/\" .. child.Name) end\n\tend\n\tfor _, root in roots do visit(root, root.Name) end\n\treturn records\nend\n\nreturn Audit\n")()
        local roots = {}
        for _, object in workspace:GetChildren() do
            if (object:IsA("Model") and object.Name ~= "Lobby" and object.Name ~= "AncientPillar")
                or (object:IsA("BasePart") and not object:IsA("Terrain") and object.Position.X >= 3100 and object.Position.X <= 4050) then
                table.insert(roots, object)
            end
        end
        for _, name in {"CityRun_C08_ReplacedGeneratedParts", "CityRun_C09_Archive", "CityRun_C10_Archive", "CityRun_C11_Archive", "CityRun_C12_Archive", "CityRun_C13_Archive", "CityRun_C14_Archive"} do
            table.insert(roots, game.ServerStorage[name])
        end
        for _,root in roots do for _,object in root:GetDescendants() do assert(not object:IsA("LuaSourceContainer"),"Geometry backup refuses script source") end end

 local records=audit.Snapshot(roots)
 local payload={build=course:GetAttribute("ReviewBuildId"),records=records,roots=#roots}
 local response=http:RequestAsync({Url=baseUrl.."/review.json",Method="POST",Headers={["Content-Type"]="application/json"},Body=http:JSONEncode(payload)})
 assert(response.Success,response.StatusCode)
 return {build=payload.build,records=#records,roots=#roots,receipt=http:JSONDecode(response.Body)}
 end,debug.traceback)
 http.HttpEnabled=prior
 assert(ok,result)
 return result
end
return Review
