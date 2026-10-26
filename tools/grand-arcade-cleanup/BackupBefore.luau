assert(game.PlaceId==85558151074819 and not game.RunService:IsRunning())
local fingerprint=(function()
return function(root, roots, ignored)
    local function number(n)
        return string.format("%.5f", if math.abs(n)<.000005 then 0 else n)
    end
    local function value(v)
        if typeof(v)=="number" then return number(v) end
        if typeof(v)=="CFrame" then
            local components={v:GetComponents()}
            for i,n in components do components[i]=number(n) end
            return table.concat(components,",")
        end
        if typeof(v)=="Vector3" then return number(v.X)..","..number(v.Y)..","..number(v.Z) end
        if typeof(v)=="Color3" then return number(v.R)..","..number(v.G)..","..number(v.B) end
        return tostring(v)
    end
    local function reference(o)
        if not o then return "nil" end
        for _,r in roots do
            if o==r or o:IsDescendantOf(r) then
                return r.ClassName..":"..r.Name.."/"..(if o==r then "." else o:GetFullName():sub(#r:GetFullName()+2))
            end
        end
        return "external:"..o:GetFullName()
    end
    local function hash(rows)
        table.sort(rows)
        local h=2166136261
        for _,row in rows do
            for i=1,#row do
                local x=bit32.bxor(h,string.byte(row,i))
                local low,high=bit32.band(x,65535),bit32.rshift(x,16)
                h=(low*403+bit32.band(low*256+high*403,65535)*65536)%4294967296
            end
        end
        return string.format("%08x",h)
    end
    local result={name=root.Name,class=root.ClassName,instances=0,parts=0,colliders=0,scripts=0,objectReferences=0}
    local rows,geometry={},{}
    local all=root:GetDescendants();table.insert(all,root)
    for _,o in all do
        if ignored and ignored[o] then continue end
        local path=if o==root then "." else o:GetFullName():sub(#root:GetFullName()+2)
        result.instances+=1
        table.insert(rows,path.."/class="..o.ClassName.."/archivable="..tostring(o.Archivable))
        for k,v in o:GetAttributes() do table.insert(rows,path.."/@"..k.."="..value(v)) end
        for _,tag in o:GetTags() do table.insert(rows,path.."/tag="..tag) end
        local props={}
        if o:IsA("BasePart") then
            result.parts+=1
            if o.CanCollide then result.colliders+=1 end
            props={"CFrame","Size","Color","Transparency","Material","MaterialVariant","Reflectance","Anchored","CanCollide","CanTouch","CanQuery","CastShadow","CollisionGroup","Massless","TopSurface","BottomSurface","LeftSurface","RightSurface","FrontSurface","BackSurface"}
        elseif o:IsA("Model") then
            table.insert(rows,path.."/pivot="..value(o:GetPivot()).."/scale="..number(o:GetScale()).."/primary="..reference(o.PrimaryPart))
        elseif o:IsA("LuaSourceContainer") then result.scripts+=1;props={"Source"}
        elseif o:IsA("ObjectValue") then result.objectReferences+=1;table.insert(rows,path.."/value="..reference(o.Value))
        elseif o:IsA("ValueBase") then props={"Value"}
        elseif o:IsA("TextLabel") then props={"Text","TextColor3","Font","TextScaled","TextWrapped","Size","Position","Visible"}
        elseif o:IsA("ImageLabel") then props={"Image","ImageColor3","ImageTransparency","Size","Position","Visible"}
        end
        if o:IsA("MeshPart") then
            for _,key in {"MeshId","TextureID","DoubleSided","RenderFidelity","CollisionFidelity"} do table.insert(props,key) end
        end
        for _,key in props do
            local row=path.."/"..key.."="..value(o[key]);table.insert(rows,row)
            if o:IsA("BasePart") then table.insert(geometry,row) end
        end
    end
    result.contentHash,result.geometryHash=hash(rows),hash(geometry)
    return result
end


end)()
local roots={assert(game.Workspace.GrandArcade),
 assert(game.Workspace.Lobby),
 assert(game.ServerStorage.CourseBuilders.GrandArcade),
 assert(game.ServerStorage.CourseBuilders.LobbyBuilders.GrandArcadeConnection),
 assert(game.ServerStorage.__GrandArcadeConnectionRecoveryFixture),
 assert(game.ServerStorage.GrandArcadeRepairRecoveryR01),
 assert(game.ServerStorage.GrandArcade_R01_Props),
 assert(game.ServerStorage.GrandArcade_R01_Bay3),
 assert(game.ServerStorage.GrandArcade_R01_PreparedBay3),
 assert(game.ServerStorage.GrandArcade_R01_Entrance),
 assert(game.ServerStorage.GrandArcade_R01_PreparedEntrance),
 assert(game.ServerStorage.GrandArcade_R01_PreparedProps),
 assert(game.ServerStorage.GrandArcade_R01_BaysRemaining),
 assert(game.ServerStorage.GrandArcade_R01_PreparedBaysRemaining),
 assert(game.ServerStorage.AssetImports.GrandArcade_A01),
 assert(game.ServerStorage.AssetImports.GrandArcadeConnection_C01),
 assert(game.ServerStorage.AssetImports.GrandArcadeQuality_Q01),
 assert(game.ServerStorage.DeveloperArchives.GrandArcadeConnection)}
local http=game.HttpService;local prior=http.HttpEnabled;local restored
local ok,result=xpcall(function()
 local before={};local expected={}
 for _,r in roots do local f=fingerprint(r,roots);table.insert(before,{path=r:GetFullName(),fingerprint=f});expected[f.class..":"..f.name]=f end
 local serial=game:GetService("SerializationService")
 local bytes=buffer.tostring(serial:SerializeInstancesAsync(roots))
 http.HttpEnabled=true
 local url="http://127.0.0.1:8768/grand-arcade-before-cleanup.rbxm"
 local response=http:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=bytes})
 assert(response.Success,response.StatusMessage)
 local readback=http:GetAsync(url,true);assert(readback==bytes,"Archive bytes differ")
 restored=serial:DeserializeInstancesAsync(buffer.fromstring(readback));assert(#restored==#roots)
 local reopened={}
 for _,r in restored do
  local f=fingerprint(r,restored);table.insert(reopened,f)
  local e=assert(expected[f.class..":"..f.name],"Unknown archive root")
  assert(f.contentHash==e.contentHash and f.geometryHash==e.geometryHash,"Reopen mismatch: "..r.Name.." "..e.contentHash.." / "..f.contentHash)
 end
 local ignored={[workspace.Lobby.GrandArcadeConnection.Recovery]=true}
 local preserve={}
 for _,r in {workspace.GrandArcade,workspace.Lobby,workspace.Lobby.GrandArcadeConnection,workspace.SGV2_Phase3_F04}do preserve[r:GetFullName()]=fingerprint(r,roots,ignored)end
 local unrelated={}
 for _,p in {game.ServerStorage,game.ServerStorage.AssetImports,game.ServerStorage.DeveloperArchives,game.ServerStorage.CourseBuilders,game.ServerStorage.CourseBuilders.LobbyBuilders}do
  for _,o in p:GetChildren()do
   if not o.Name:lower():find("grandarcade") then unrelated[o:GetFullName()]=#o:GetDescendants()+1 end
  end
 end
 return {verified=true,receipt=http:JSONDecode(response.Body),before=before,reopened=reopened,preserve=preserve,unrelated=unrelated,excludedArchiveObjects=0}
end,debug.traceback)
if restored then for _,r in restored do r:Destroy()end end
http.HttpEnabled=prior;assert(ok,result)
return http:JSONEncode(result)
