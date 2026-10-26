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
        if root.Name=="Lobby" and o.ClassName=="Status" then
            assert(path=="Podium.Slots.First.Avatar.Humanoid.Status" or path=="Podium.Slots.Second.Avatar.Humanoid.Status" or path=="Podium.Slots.Third.Avatar.Humanoid.Status")
            assert(#o:GetChildren()==0 and next(o:GetAttributes())==nil and not o.Archivable)
            continue
        end
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
local function resolve(path)local o=game;for name in path:gmatch("[^.]+")do o=o:FindFirstChild(name);if not o then return nil end end;return o end
local expected=game.HttpService:JSONDecode([====[{"before":[{"fingerprint":{"class":"Model","instances":425,"objectReferences":0,"name":"GrandArcade","scripts":0,"contentHash":"da21ef67","geometryHash":"7c234aa6","colliders":122,"parts":281},"path":"Workspace.GrandArcade"},{"fingerprint":{"class":"Model","instances":2355,"objectReferences":1,"name":"Lobby","scripts":3,"contentHash":"84687e54","geometryHash":"339a8b1b","colliders":518,"parts":1243},"path":"Workspace.Lobby"},{"fingerprint":{"class":"Folder","instances":5,"objectReferences":0,"name":"GrandArcade","scripts":4,"contentHash":"eb6c5edd","geometryHash":"811c9dc5","colliders":0,"parts":0},"path":"ServerStorage.CourseBuilders.GrandArcade"},{"fingerprint":{"class":"ModuleScript","instances":1,"objectReferences":0,"name":"GrandArcadeConnection","scripts":1,"contentHash":"296a6613","geometryHash":"811c9dc5","colliders":0,"parts":0},"path":"ServerStorage.CourseBuilders.LobbyBuilders.GrandArcadeConnection"},{"fingerprint":{"class":"Folder","instances":1,"objectReferences":0,"name":"__GrandArcadeConnectionRecoveryFixture","scripts":0,"contentHash":"8684a31c","geometryHash":"811c9dc5","colliders":0,"parts":0},"path":"ServerStorage.__GrandArcadeConnectionRecoveryFixture"},{"fingerprint":{"class":"Folder","instances":776,"objectReferences":135,"name":"GrandArcadeRepairRecoveryR01","scripts":0,"contentHash":"939f136b","geometryHash":"909ed953","colliders":145,"parts":402},"path":"ServerStorage.GrandArcadeRepairRecoveryR01"},{"fingerprint":{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_Props","scripts":0,"contentHash":"90334b57","geometryHash":"16b41262","colliders":10,"parts":10},"path":"ServerStorage.GrandArcade_R01_Props"},{"fingerprint":{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_Bay3","scripts":0,"contentHash":"eb5037db","geometryHash":"f7a29ef4","colliders":10,"parts":10},"path":"ServerStorage.GrandArcade_R01_Bay3"},{"fingerprint":{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_PreparedBay3","scripts":0,"contentHash":"877f5fe3","geometryHash":"14d2de23","colliders":0,"parts":10},"path":"ServerStorage.GrandArcade_R01_PreparedBay3"},{"fingerprint":{"class":"Model","instances":14,"objectReferences":0,"name":"GrandArcade_R01_Entrance","scripts":0,"contentHash":"1859230a","geometryHash":"8b5afd04","colliders":12,"parts":12},"path":"ServerStorage.GrandArcade_R01_Entrance"},{"fingerprint":{"class":"Model","instances":14,"objectReferences":0,"name":"GrandArcade_R01_PreparedEntrance","scripts":0,"contentHash":"42a05f6a","geometryHash":"844b6330","colliders":0,"parts":12},"path":"ServerStorage.GrandArcade_R01_PreparedEntrance"},{"fingerprint":{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_PreparedProps","scripts":0,"contentHash":"c27f82af","geometryHash":"24ea898c","colliders":0,"parts":10},"path":"ServerStorage.GrandArcade_R01_PreparedProps"},{"fingerprint":{"class":"Model","instances":30,"objectReferences":0,"name":"GrandArcade_R01_BaysRemaining","scripts":0,"contentHash":"136228f0","geometryHash":"3f9c6428","colliders":28,"parts":28},"path":"ServerStorage.GrandArcade_R01_BaysRemaining"},{"fingerprint":{"class":"Model","instances":30,"objectReferences":0,"name":"GrandArcade_R01_PreparedBaysRemaining","scripts":0,"contentHash":"64a12c7b","geometryHash":"f0395338","colliders":0,"parts":28},"path":"ServerStorage.GrandArcade_R01_PreparedBaysRemaining"},{"fingerprint":{"class":"Model","instances":96,"objectReferences":0,"name":"GrandArcade_A01","scripts":0,"contentHash":"e81a8daf","geometryHash":"22bd8ac4","colliders":94,"parts":94},"path":"ServerStorage.AssetImports.GrandArcade_A01"},{"fingerprint":{"class":"Model","instances":40,"objectReferences":0,"name":"GrandArcadeConnection_C01","scripts":0,"contentHash":"6ee13f14","geometryHash":"641495f2","colliders":38,"parts":38},"path":"ServerStorage.AssetImports.GrandArcadeConnection_C01"},{"fingerprint":{"class":"Model","instances":38,"objectReferences":0,"name":"GrandArcadeQuality_Q01","scripts":0,"contentHash":"94992fcd","geometryHash":"48aa161a","colliders":36,"parts":36},"path":"ServerStorage.AssetImports.GrandArcadeQuality_Q01"},{"fingerprint":{"class":"Folder","instances":107,"objectReferences":35,"name":"GrandArcadeConnection","scripts":0,"contentHash":"87186fe1","geometryHash":"72244edf","colliders":12,"parts":35},"path":"ServerStorage.DeveloperArchives.GrandArcadeConnection"}],"exclusion":"Three empty nonarchivable Lobby podium Humanoid.Status containers only","excludedArchiveObjects":3,"unrelated":{"ServerStorage.CourseBuilders.ManualObstacleCreative":1,"ServerStorage.CourseBuilders.StudGardenV2":8,"ServerStorage.CourseLibrary":6038,"ServerStorage.CourseBuilders.AscentV7PropManifest":1,"ServerStorage.CourseBuilders.AscentDetails":1,"ServerStorage.CourseBuilders.AscentRiverFinishPass":1,"ServerStorage.AssetLibraries":329,"ServerStorage.CourseBuilders.AscentDepthPass":1,"ServerStorage.__Rojo_SessionLock":1,"ServerStorage.AssetImports.LobbyPropsImport":6,"ServerStorage.CourseBuilders.LobbyBuilders.BlenderManifest":1,"ServerStorage.CourseBuilders.AscentLayout":1,"ServerStorage.AssetImports.SkycourtB10Import":500,"ServerStorage.CourseBuilders.AscentEnvironment":1,"ServerStorage.CourseBuilders.ManualObstacleKit":1,"ServerStorage.CourseBuilders.AssetStorage":1,"ServerStorage.CourseBuilders.AscentProps":1,"ServerStorage.AssetImports.AscentPropsImportV5":30,"ServerStorage.CourseBuilders.CityRun":47,"ServerStorage.CourseBuilders.ClassicAscentPointToPoint":1,"ServerStorage.CourseBuilders.AscentObstacles":1,"ServerStorage.CourseBuilders.AscentEditing":1,"ServerStorage.CourseBuilders.ManualObstacleMotion":1,"ServerStorage.CourseBuilders.ShipwreckCove":12,"ServerStorage.AssetImports.AscentPropsImportV7":7,"ServerStorage.CourseBuilders.LobbyBuilders.SkyLobby":1,"ServerStorage.CourseBuilders.LobbyBuilders.LobbyAmenities":1,"ServerStorage.CourseBuilders.LobbyBuilders.BlenderComparison":1,"ServerStorage.CourseBuilders.LobbyBuilders.LobbyProps":1,"ServerStorage.CourseBuilders.LobbyBuilders.LobbyParts":1,"ServerStorage.LobbyAmenityIterations":155,"ServerStorage.DeveloperAssets":261,"ServerStorage.Archive":111021,"ServerStorage.CourseBuilders.DepthIllusionKit":1,"ServerStorage.__LobbyPreservationProbe":9,"ServerStorage.CourseBuilders.AscentWorld":1,"ServerStorage.CourseBuilders.AscentSignAdjustments":1,"ServerStorage.CourseBuilders.AscentPropManifest":1},"preserve":{"Workspace.SGV2_Phase3_F04":{"class":"Model","instances":8796,"objectReferences":0,"name":"SGV2_Phase3_F04","scripts":0,"contentHash":"165f8c00","geometryHash":"c4e53945","colliders":3751,"parts":8015},"Workspace.GrandArcade":{"class":"Model","instances":425,"objectReferences":0,"name":"GrandArcade","scripts":0,"contentHash":"da21ef67","geometryHash":"7c234aa6","colliders":122,"parts":281},"Workspace.Lobby.GrandArcadeConnection":{"class":"Model","instances":85,"objectReferences":0,"name":"GrandArcadeConnection","scripts":0,"contentHash":"487e1feb","geometryHash":"c1616e0f","colliders":25,"parts":79},"Workspace.Lobby":{"class":"Model","instances":2354,"objectReferences":0,"name":"Lobby","scripts":3,"contentHash":"05f72d5f","geometryHash":"339a8b1b","colliders":518,"parts":1243}},"verified":true,"reopened":[{"class":"Model","instances":425,"objectReferences":0,"name":"GrandArcade","scripts":0,"contentHash":"da21ef67","geometryHash":"7c234aa6","colliders":122,"parts":281},{"class":"Model","instances":2355,"objectReferences":1,"name":"Lobby","scripts":3,"contentHash":"84687e54","geometryHash":"339a8b1b","colliders":518,"parts":1243},{"class":"Folder","instances":5,"objectReferences":0,"name":"GrandArcade","scripts":4,"contentHash":"eb6c5edd","geometryHash":"811c9dc5","colliders":0,"parts":0},{"class":"ModuleScript","instances":1,"objectReferences":0,"name":"GrandArcadeConnection","scripts":1,"contentHash":"296a6613","geometryHash":"811c9dc5","colliders":0,"parts":0},{"class":"Folder","instances":1,"objectReferences":0,"name":"__GrandArcadeConnectionRecoveryFixture","scripts":0,"contentHash":"8684a31c","geometryHash":"811c9dc5","colliders":0,"parts":0},{"class":"Folder","instances":776,"objectReferences":135,"name":"GrandArcadeRepairRecoveryR01","scripts":0,"contentHash":"939f136b","geometryHash":"909ed953","colliders":145,"parts":402},{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_Props","scripts":0,"contentHash":"90334b57","geometryHash":"16b41262","colliders":10,"parts":10},{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_Bay3","scripts":0,"contentHash":"eb5037db","geometryHash":"f7a29ef4","colliders":10,"parts":10},{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_PreparedBay3","scripts":0,"contentHash":"877f5fe3","geometryHash":"14d2de23","colliders":0,"parts":10},{"class":"Model","instances":14,"objectReferences":0,"name":"GrandArcade_R01_Entrance","scripts":0,"contentHash":"1859230a","geometryHash":"8b5afd04","colliders":12,"parts":12},{"class":"Model","instances":14,"objectReferences":0,"name":"GrandArcade_R01_PreparedEntrance","scripts":0,"contentHash":"42a05f6a","geometryHash":"844b6330","colliders":0,"parts":12},{"class":"Model","instances":12,"objectReferences":0,"name":"GrandArcade_R01_PreparedProps","scripts":0,"contentHash":"c27f82af","geometryHash":"24ea898c","colliders":0,"parts":10},{"class":"Model","instances":30,"objectReferences":0,"name":"GrandArcade_R01_BaysRemaining","scripts":0,"contentHash":"136228f0","geometryHash":"3f9c6428","colliders":28,"parts":28},{"class":"Model","instances":30,"objectReferences":0,"name":"GrandArcade_R01_PreparedBaysRemaining","scripts":0,"contentHash":"64a12c7b","geometryHash":"f0395338","colliders":0,"parts":28},{"class":"Model","instances":96,"objectReferences":0,"name":"GrandArcade_A01","scripts":0,"contentHash":"e81a8daf","geometryHash":"22bd8ac4","colliders":94,"parts":94},{"class":"Model","instances":40,"objectReferences":0,"name":"GrandArcadeConnection_C01","scripts":0,"contentHash":"6ee13f14","geometryHash":"641495f2","colliders":38,"parts":38},{"class":"Model","instances":38,"objectReferences":0,"name":"GrandArcadeQuality_Q01","scripts":0,"contentHash":"94992fcd","geometryHash":"48aa161a","colliders":36,"parts":36},{"class":"Folder","instances":107,"objectReferences":35,"name":"GrandArcadeConnection","scripts":0,"contentHash":"87186fe1","geometryHash":"72244edf","colliders":12,"parts":35}],"file":"grand-arcade-before-cleanup.rbxm"}]====])
local removedPaths=game.HttpService:JSONDecode([====[["ServerStorage.CourseBuilders.GrandArcade","ServerStorage.CourseBuilders.LobbyBuilders.GrandArcadeConnection","ServerStorage.__GrandArcadeConnectionRecoveryFixture","ServerStorage.GrandArcadeRepairRecoveryR01","ServerStorage.GrandArcade_R01_Props","ServerStorage.GrandArcade_R01_Bay3","ServerStorage.GrandArcade_R01_PreparedBay3","ServerStorage.GrandArcade_R01_Entrance","ServerStorage.GrandArcade_R01_PreparedEntrance","ServerStorage.GrandArcade_R01_PreparedProps","ServerStorage.GrandArcade_R01_BaysRemaining","ServerStorage.GrandArcade_R01_PreparedBaysRemaining","ServerStorage.AssetImports.GrandArcade_A01","ServerStorage.AssetImports.GrandArcadeConnection_C01","ServerStorage.AssetImports.GrandArcadeQuality_Q01","ServerStorage.DeveloperArchives.GrandArcadeConnection"]]====])
local roots={}
for _,row in expected.before do table.insert(roots,(assert(resolve(row.path),row.path)))end
for _,row in expected.before do local f=fingerprint(resolve(row.path),roots);assert(f.contentHash==row.fingerprint.contentHash and f.geometryHash==row.fingerprint.geometryHash,"Changed since backup: "..row.path)end
local sources=[====[--!strict
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.GrandArcadeConfig)
local Service={}
local stage: Model?
local staging: any
local racers: any
local race: any
local replicas: {[number]: Model}={}
local cacheOrder={}
local pending: {[number]:boolean}={}
local latestTournament=""
local knownCourses={}
local function host(parent,frame)
 local model=Instance.new("Model");model.Name="Presenter"
 for _,row in {{"Torso",Vector3.new(2,2,1),Vector3.new(0,3,0),Color3.fromRGB(20,42,74)},
  {"Head",Vector3.new(1.8,1.2,1.2),Vector3.new(0,4.6,0),Color3.fromRGB(255,224,174)},
  {"LeftArm",Vector3.new(1,2,1),Vector3.new(-1.5,3,0),Color3.fromRGB(245,235,210)},
  {"RightArm",Vector3.new(1,2,1),Vector3.new(1.5,3,0),Color3.fromRGB(245,235,210)},
  {"LeftLeg",Vector3.new(1,2,1),Vector3.new(-.5,1,0),Color3.fromRGB(20,42,74)},
  {"RightLeg",Vector3.new(1,2,1),Vector3.new(.5,1,0),Color3.fromRGB(20,42,74)}} do
  local p=Instance.new("Part");p.Name,p.Size,p.CFrame,p.Color=row[1],row[2],frame*CFrame.new(row[3]),row[4]
  p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false;p.Parent=model
  if p.Name=="Head" then
   local mesh=Instance.new("SpecialMesh");mesh.MeshType,mesh.Parent=Enum.MeshType.Head,p
   local face=Instance.new("Decal");face.Name,face.Texture,face.Face,face.Parent="Face","rbxasset://textures/face.png",Enum.NormalId.Front,p
  end
 end
 model.WorldPivot=frame;model.Parent=parent
 return model
end
local function template(userId: number): Model?
 if replicas[userId] then return replicas[userId] end
 if pending[userId] then
  local deadline=os.clock()+10
  repeat task.wait(.05) until not pending[userId] or os.clock()>=deadline
  return replicas[userId]
 end
 pending[userId]=true
 local ok,result=pcall(function()
  local player=Players:GetPlayerByUserId(userId)
  local humanoid=player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  local description=if humanoid then humanoid:GetAppliedDescription() else Players:GetHumanoidDescriptionFromUserIdAsync(userId)
  description.HatAccessory,description.HairAccessory,description.FaceAccessory="","",""
  description.NeckAccessory,description.ShouldersAccessory,description.FrontAccessory,description.BackAccessory,description.WaistAccessory="","","","",""
  local model=Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
  description:Destroy()
  for _,item in model:GetDescendants() do
   if item:IsA("LuaSourceContainer") or item:IsA("Accessory") or item:IsA("Humanoid") or item:IsA("Motor6D") then item:Destroy()
   elseif item:IsA("BasePart") then item.Anchored,item.CanCollide,item.CanTouch,item.CanQuery=true,false,false,false end
  end
  model:ScaleTo(Config.MiniatureScale)
  return model
 end)
 pending[userId]=nil
 if not ok then return nil end
 replicas[userId]=result
 table.insert(cacheOrder,userId)
 if #cacheOrder>32 then local oldest=table.remove(cacheOrder,1);if replicas[oldest] then replicas[oldest]:Destroy();replicas[oldest]=nil end end
 return result
end
function Service.Init(context: any)
 staging=context.Services.StagingService
 racers=context.Services.PlayerRaceService
 race=context.Services.RaceService
 local installed=workspace:FindFirstChild("GrandArcade")
 stage=if installed and installed:IsA("Model") then installed else nil
 if not stage then warn("Grand Arcade stage is not installed; restore the saved native model") end
end
function Service.Start()
 if not stage then return end
 local marker=stage.Displays.HostSpot
 if not stage:FindFirstChild("Presenter") then host(stage,marker.CFrame) end
 local cooldown: {[Player]:number}={}
 stage.FallReturn.Touched:Connect(function(hit)
  local character=hit:FindFirstAncestorOfClass("Model")
  local player=character and Players:GetPlayerFromCharacter(character)
  if not player or not character then return end
  if race and race.IsRaceActive() and racers.IsOfficialRacer(player) then return end
  local root=character:FindFirstChild("HumanoidRootPart")
  if not root or not root:IsA("BasePart") or math.abs(root.Position.Y-stage.FallReturn.Position.Y)>12 then return end
  if os.clock()-(cooldown[player] or 0)<2 then return end
  cooldown[player]=os.clock()
  if staging then staging.ReturnPlayersToLobby({player},"Stage safety return") end
 end)
 Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil end)
end
function Service.IsAvailable(): boolean return stage~=nil end
function Service.Render(snapshot: any)
 if not stage then return end
 stage:SetAttribute("TournamentId",snapshot.tournamentId)
 stage:SetAttribute("Preparation",snapshot.preparation and snapshot.preparation.status or "Idle")
 stage:SetAttribute("PresentationStartedAt",snapshot.preparation and snapshot.preparation.startedAt or 0)
 local reset=latestTournament~=snapshot.tournamentId
 latestTournament=snapshot.tournamentId
 local byId={};for _,row in snapshot.catalog or {} do byId[row.id]=row;knownCourses[row.id]=row end
 local lineup=snapshot.lineup or {}
 local resolved=#lineup==5
 local available=#(snapshot.catalog or {})
 stage:SetAttribute("ResolvedLineup",resolved)
 stage:SetAttribute("EligibleCourseCount",available)
 for index=1,5 do
  local bay=stage.Displays:FindFirstChild("Bay"..index)
  local id=resolved and lineup[index] or nil
  local row=if id then byId[id] or knownCourses[id] else (snapshot.catalog or {})[index]
  local panel=bay.MapPanel.Display
  local crest=panel:FindFirstChild("NeutralCrest")
  if not crest then
   crest=Instance.new("Frame");crest.Name,crest.BackgroundTransparency="NeutralCrest",1
   crest.Size,crest.Position,crest.Parent=UDim2.fromScale(.45,.3),UDim2.fromScale(.275,.09),panel
  end
  if crest:IsA("TextLabel") then crest.Text="" end
  if not crest:FindFirstChild("Diamond") then
   local diamond=Instance.new("Frame")
   diamond.Name,diamond.AnchorPoint,diamond.Position,diamond.Size="Diamond",Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromScale(.3,.7)
   diamond.Rotation,diamond.BorderSizePixel,diamond.BackgroundColor3,diamond.Parent=45,0,Color3.fromRGB(226,181,70),crest
   local aspect=Instance.new("UIAspectRatioConstraint");aspect.AspectRatio,aspect.Parent=1,diamond
   local inset=Instance.new("Frame")
   inset.Position,inset.Size,inset.BorderSizePixel,inset.BackgroundColor3,inset.Parent=UDim2.fromScale(.18,.18),UDim2.fromScale(.64,.64),0,Color3.fromRGB(8,20,42),diamond
  end
  panel.Artwork.Image=row and row.image or ""
  local fallback=not row or not row.image or row.image==""
  crest.Visible=fallback
  panel.Fallback.Visible=fallback
  panel.Fallback.Text=if row then row.name elseif available<5 then available.." courses available\nFive needed for a tournament" else "Vote for your next tournament"
  panel.Fallback.Position,panel.Fallback.Size=UDim2.fromScale(.08,.46),UDim2.fromScale(.84,.38)
  bay.Plaque.Display.Title.Text=if resolved and row then "RACE "..index.."  ·  "..row.name elseif row then row.name else "GRAND ARCADE"
  bay:SetAttribute("CourseId",row and row.id or id or "")
  bay:SetAttribute("CurrentRace",resolved and snapshot.phase=="Racing" and snapshot.raceIndex==index)
  local result=snapshot.results and snapshot.results[index]
  for rank=1,3 do
   local slot=bay:FindFirstChild("Slot"..rank)
   local winner
   if result then for _,entry in result.finishers do if entry.placement==rank then winner=entry end end end
   bay:FindFirstChild("Rank"..rank).Display.Finisher.Text=winner and (winner.displayName or winner.name) or ""
   local userId=winner and winner.userId or 0
   if reset or slot:GetAttribute("WinnerUserId")~=userId then
    local generation=(slot:GetAttribute("AppearanceGeneration") or 0)+1
    slot:SetAttribute("AppearanceGeneration",generation)
    slot:SetAttribute("WinnerUserId",userId)
    local old=slot:FindFirstChild("Finisher");if old then old:Destroy() end
    if winner then
     local fallback=host(slot,slot.CFrame*CFrame.Angles(0,math.pi,0));fallback.Name="Finisher";fallback:ScaleTo(Config.MiniatureScale)
     local tournamentId=snapshot.tournamentId
     task.spawn(function()
      local source=template(userId)
      if not source or latestTournament~=tournamentId or slot:GetAttribute("WinnerUserId")~=userId
       or slot:GetAttribute("AppearanceGeneration")~=generation then return end
      local copy=source:Clone();copy.Name="Finisher"
      local box,size=copy:GetBoundingBox()
      copy:PivotTo(slot.CFrame*CFrame.Angles(0,math.pi,0)*CFrame.new(0,size.Y/2,0)*box:ToObjectSpace(copy:GetPivot()))
      if fallback.Parent then fallback:Destroy() end
      copy.Parent=slot
     end)
    end
   end
  end
 end
end
return Service]====]
assert(loadstring(sources),"Source does not compile")
local service=game.ServerScriptService.Services.GrandArcadeService
service.Source=sources
assert(service.Source==sources)
local removed={};local parts,instances=0,0
for _,path in removedPaths do
 local root=assert(resolve(path))
 local f=fingerprint(root,roots);parts+=f.parts;instances+=f.instances
 table.insert(removed,{path=path,parts=f.parts,instances=f.instances})
 root:Destroy()
end
local recovery=workspace.Lobby.GrandArcadeConnection:FindFirstChild("Recovery")
assert(recovery and recovery:IsA("ObjectValue"))
recovery:Destroy()
local preserved={}
for path,e in expected.preserve do
 local r=assert(resolve(path));local f=fingerprint(r,roots)
 assert(f.geometryHash==e.geometryHash and f.contentHash==e.contentHash,"Preservation mismatch: "..path)
 preserved[path]=f
end
for path,n in expected.unrelated do assert(resolve(path)and #resolve(path):GetDescendants()+1==n,"Unrelated storage changed: "..path)end
return game.HttpService:JSONEncode({ok=true,removed=removed,removedParts=parts,removedInstances=instances,obsoleteRecoveryPointerRemoved=true,preserved=preserved,unrelatedStorageUnchanged=true,serviceCompiled=true})

