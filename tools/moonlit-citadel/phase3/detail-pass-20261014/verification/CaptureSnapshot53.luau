--!nonstrict
local Snapshot = {}
local Schema = {["boundary"]="All reflected properties attempted; unavailable properties are recorded. Attributes and tags are captured separately. Derived motion/readings and engine-generated identities are excluded explicitly.",["classProperties"]={["Atmosphere"]={"Archivable","AttributesReplicate","Capabilities","ClassName","Color","Decay","DefinesCapabilities","Density","Glare","Haze","IsInSandbox","Name","Offset","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SourceAssetId","archivable","className","numExpectedDirectChildren"},["Attachment"]={"Archivable","AttributesReplicate","Axis","CFrame","Capabilities","ClassName","DefinesCapabilities","IsInSandbox","Name","Orientation","Parent","Position","PredictionMode","PropertyStatusStudio","RobloxLocked","Rotation","Sandboxed","SecondaryAxis","SourceAssetId","Visible","WorldAxis","WorldCFrame","WorldOrientation","WorldPosition","WorldRotation","WorldSecondaryAxis","archivable","className","numExpectedDirectChildren"},["Beam"]={"Archivable","Attachment0","Attachment1","AttributesReplicate","Brightness","Capabilities","ClassName","Color","CurveSize0","CurveSize1","DefinesCapabilities","Enabled","FaceCamera","IsInSandbox","LightEmission","LightInfluence","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","Segments","SourceAssetId","Texture","TextureContent","TextureLength","TextureMode","TextureSpeed","Transparency","Width0","Width1","ZOffset","archivable","className","numExpectedDirectChildren"},["BloomEffect"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","Enabled","Intensity","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","Size","SourceAssetId","Threshold","archivable","className","numExpectedDirectChildren"},["BlurEffect"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","Enabled","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","Size","SourceAssetId","archivable","className","numExpectedDirectChildren"},["Camera"]={"Archivable","AttributesReplicate","CFrame","CameraSubject","CameraType","Capabilities","ClassName","CoordinateFrame","DefinesCapabilities","DiagonalFieldOfView","FieldOfView","FieldOfViewMode","Focus","HeadLocked","HeadScale","IsInSandbox","MaxAxisFieldOfView","Name","NearPlaneZ","Origin","Parent","Pivot Offset","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SourceAssetId","VRTiltAndRollEnabled","ViewportSize","archivable","className","focus","numExpectedDirectChildren"},["ColorCorrectionEffect"]={"Archivable","AttributesReplicate","Brightness","Capabilities","ClassName","Contrast","DefinesCapabilities","Enabled","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","Saturation","SourceAssetId","TintColor","archivable","className","numExpectedDirectChildren"},["DepthOfFieldEffect"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","Enabled","FarIntensity","FocusDistance","InFocusRadius","IsInSandbox","Name","NearIntensity","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SourceAssetId","archivable","className","numExpectedDirectChildren"},["Folder"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","ReplicatedGuiInsertionOrder","RobloxLocked","Sandboxed","SourceAssetId","archivable","className","numExpectedDirectChildren"},["Lighting"]={"Ambient","Archivable","AttributesReplicate","Brightness","Capabilities","ClassName","ClockTime","ColorShift_Bottom","ColorShift_Top","DefinesCapabilities","EnvironmentDiffuseScale","EnvironmentSpecularScale","ExposureCompensation","ExtendLightRangeTo120","FogColor","FogEnd","FogStart","GeographicLatitude","GlobalShadows","IsInSandbox","LightingStyle","Name","OutdoorAmbient","Outlines","Parent","PredictionMode","PrioritizeLightingQuality","PropertyStatusStudio","RobloxLocked","Sandboxed","ShadowColor","ShadowSoftness","SourceAssetId","Technology","TimeOfDay","archivable","className","numExpectedDirectChildren"},["MeshPart"]={"AeroMeshData","AlternateMeshHash","Anchored","Archivable","AssemblyCenterOfMass","AssemblyMass","AssemblyRootPart","AttributesReplicate","AudioCanCollide","BackParamA","BackParamB","BackSurface","BackSurfaceInput","BottomParamA","BottomParamB","BottomSurface","BottomSurfaceInput","BrickColor","CFrame","CanCollide","CanQuery","CanTouch","Capabilities","CastShadow","CenterOfMass","ClassName","CollisionFidelity","CollisionGroup","CollisionGroupId","CollisionGroupReplicate","Color","Color3uint8","ConvexDecompHolder","CurrentPhysicalProperties","CustomPhysicalProperties","DefinesCapabilities","DoubleSided","DraggingV1","Elasticity","EnableFluidForces","ExtentsCFrame","ExtentsSize","FluidFidelity","FluidFidelityInternal","Friction","FrontParamA","FrontParamB","FrontSurface","FrontSurfaceInput","HasJointOffset","HasSkinnedMesh","InertiaMigrated","InitialSize","IsInSandbox","JointOffset","LeftParamA","LeftParamB","LeftSurface","LeftSurfaceInput","Locked","Mass","Massless","Material","MaterialVariant","MaterialVariantSerialized","MeshContent","MeshID","MeshId","MeshSize","Name","NetworkIsSleeping","NetworkOwnershipRule","Orientation","Origin","Parent","PhysicalConfigData","PhysicsData","PhysicsRepRootPart","Pivot Offset","PivotOffset","Position","PredictionMode","PropertyStatusStudio","Reflectance","RenderFidelity","RenderFidelityReplicate","ResizeIncrement","ResizeableFaces","RightParamA","RightParamB","RightSurface","RightSurfaceInput","RobloxLocked","RootPriority","Rotation","Sandboxed","Size","SolidMeshHolder","SourceAssetId","SpecificGravity","TextureContent","TextureID","TopParamA","TopParamB","TopSurface","TopSurfaceInput","Transparency","UnscaledCofm","UnscaledVolInertiaDiags","UnscaledVolInertiaOffDiags","UnscaledVolume","VertexCount","archivable","brickColor","className","numExpectedDirectChildren","siz","size"},["Model"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","IsInSandbox","LevelOfDetail","LodEntity","ModelMeshCFrame","ModelMeshData","ModelMeshSize","ModelStreamingMode","Name","NeedsPivotMigration","Origin","Parent","Pivot Offset","PredictionMode","PrimaryPart","PropertyStatusStudio","RobloxLocked","Sandboxed","Scale","ScaleFactor","SlimAnimationTarget","SlimHash","SourceAssetId","WorldPivot","WorldPivotData","archivable","className","numExpectedDirectChildren"},["ObjectValue"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SourceAssetId","Value","archivable","className","numExpectedDirectChildren"},["Part"]={"Anchored","Archivable","AssemblyCenterOfMass","AssemblyMass","AssemblyRootPart","AttributesReplicate","AudioCanCollide","BackParamA","BackParamB","BackSurface","BackSurfaceInput","BottomParamA","BottomParamB","BottomSurface","BottomSurfaceInput","BrickColor","CFrame","CanCollide","CanQuery","CanTouch","Capabilities","CastShadow","CenterOfMass","ClassName","CollisionGroup","CollisionGroupId","CollisionGroupReplicate","Color","Color3uint8","CurrentPhysicalProperties","CustomPhysicalProperties","DefinesCapabilities","DraggingV1","Elasticity","EnableFluidForces","ExtentsCFrame","ExtentsSize","FormFactor","Friction","FrontParamA","FrontParamB","FrontSurface","FrontSurfaceInput","IsInSandbox","LeftParamA","LeftParamB","LeftSurface","LeftSurfaceInput","Locked","Mass","Massless","Material","MaterialVariant","MaterialVariantSerialized","Name","NetworkIsSleeping","NetworkOwnershipRule","Orientation","Origin","Parent","PhysicsRepRootPart","Pivot Offset","PivotOffset","Position","PredictionMode","PropertyStatusStudio","Reflectance","ResizeIncrement","ResizeableFaces","RightParamA","RightParamB","RightSurface","RightSurfaceInput","RobloxLocked","RootPriority","Rotation","Sandboxed","Shape","Size","SourceAssetId","SpecificGravity","TopParamA","TopParamB","TopSurface","TopSurfaceInput","Transparency","archivable","brickColor","className","formFactor","formFactorRaw","numExpectedDirectChildren","shap","shape","siz","size"},["PointLight"]={"Archivable","AttributesReplicate","Brightness","Capabilities","ClassName","Color","DefinesCapabilities","Enabled","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","Range","RobloxLocked","Sandboxed","Shadows","SourceAssetId","archivable","className","numExpectedDirectChildren"},["Sky"]={"Archivable","AttributesReplicate","Capabilities","CelestialBodiesShown","ClassName","DefinesCapabilities","IsInSandbox","MoonAngularSize","MoonTextureContent","MoonTextureId","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SkyboxBackContent","SkyboxBk","SkyboxDn","SkyboxDownContent","SkyboxFrontContent","SkyboxFt","SkyboxLeftContent","SkyboxLf","SkyboxOrientation","SkyboxRightContent","SkyboxRt","SkyboxUp","SkyboxUpContent","SourceAssetId","StarCount","SunAngularSize","SunTextureContent","SunTextureId","archivable","className","numExpectedDirectChildren"},["StringValue"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SourceAssetId","Value","archivable","className","numExpectedDirectChildren"},["SunRaysEffect"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","Enabled","Intensity","IsInSandbox","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SourceAssetId","Spread","archivable","className","numExpectedDirectChildren"},["SurfaceGui"]={"AbsolutePosition","AbsoluteRotation","AbsoluteSize","Active","ActiveQueryNames","Adornee","AlwaysOnTop","Archivable","AttributesReplicate","AutoLocalize","Brightness","CanvasSize","Capabilities","ClassName","ClippedRect","ClipsDescendants","DefinesCapabilities","Enabled","Face","HorizontalCurvature","IsInSandbox","IsNotOccluded","LightInfluence","Localize","MaxDistance","Name","Parent","PixelsPerStud","PredictionMode","PropertyStatusStudio","RawRect2D","ReplicatedInsertionOrder","ResetOnSpawn","RobloxLocked","RootLocalizationTable","Sandboxed","SelectionBehaviorDown","SelectionBehaviorLeft","SelectionBehaviorRight","SelectionBehaviorUp","SelectionGroup","Shape","SizingMode","SourceAssetId","TabKeyboardNavigation","ToolPunchThroughDistance","TotalGroupScale","ZIndexBehavior","ZOffset","archivable","className","numExpectedDirectChildren"},["TextLabel"]={"AbsolutePosition","AbsoluteRotation","AbsoluteSize","Active","ActiveQueryNames","AnchorPoint","Archivable","AttributesReplicate","AutoLocalize","AutomaticSize","BackgroundColor","BackgroundColor3","BackgroundTransparency","BorderColor","BorderColor3","BorderMode","BorderSizePixel","Capabilities","ClassName","ClippedRect","ClipsDescendants","Confidential","ContentText","DefinesCapabilities","DragBeginConnectionCount","DragStoppedConnectionCount","Draggable","Font","FontFace","FontSize","GuiState","InputSink","Interactable","IsInSandbox","IsNotOccluded","LayoutOrder","LineHeight","LocalizationMatchIdentifier","LocalizationMatchedSourceText","Localize","LocalizedText","MaxVisibleGraphemes","MouseEnterConnectionCount","MouseLeaveConnectionCount","MouseMovedConnectionCount","MouseWheelBackwardConnectionCount","MouseWheelForwardConnectionCount","Name","NextSelectionDown","NextSelectionLeft","NextSelectionRight","NextSelectionUp","OpenTypeFeatures","OpenTypeFeaturesError","Parent","Position","PredictionMode","PropertyStatusStudio","RawRect2D","ReplicatedInsertionOrder","RichText","RobloxLocked","RootLocalizationTable","Rotation","Sandboxed","Selectable","SelectionBehaviorDown","SelectionBehaviorLeft","SelectionBehaviorRight","SelectionBehaviorUp","SelectionGroup","SelectionImageObject","SelectionOrder","SelectionRect2D","Size","SizeConstraint","SourceAssetId","Text","TextBounds","TextColor","TextColor3","TextDirection","TextFits","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency","TextTransparency","TextTruncate","TextWrap","TextWrapped","TextXAlignment","TextYAlignment","TotalGroupScale","Transparency","Visible","ZIndex","archivable","className","numExpectedDirectChildren"},["UITextSizeConstraint"]={"Archivable","AttributesReplicate","Capabilities","ClassName","DefinesCapabilities","IsInSandbox","MaxTextSize","MinTextSize","Name","Parent","PredictionMode","PropertyStatusStudio","RobloxLocked","Sandboxed","SourceAssetId","archivable","className","numExpectedDirectChildren"}},["excludedDerivedOrIdentityProperties"]={["AssemblyAngularVelocity"]=true,["AssemblyLinearVelocity"]=true,["Attributes"]=true,["AttributesSerialize"]=true,["CurrentAngle"]=true,["CurrentDistance"]=true,["CurrentPosition"]=true,["CurrentSpeed"]=true,["DataCost"]=true,["HistoryId"]=true,["IsLoaded"]=true,["IsPaused"]=true,["IsPlaying"]=true,["LocalTransparencyModifier"]=true,["MoveDirection"]=true,["PlaybackLoudness"]=true,["Playing"]=true,["ReceiveAge"]=true,["RotVelocity"]=true,["Tags"]=true,["TimePosition"]=true,["UniqueId"]=true,["Velocity"]=true},["sourceSHA256"]="e8ce7eb4516de347dd5fb186f6fee5635c357e78079288bd8e6105a536b8062c",["sourceSavedModel"]="docs/artifacts/moonlit-citadel/phase3/closeout-20261014/final/source52-models.rbxm"}
Snapshot.Schema = Schema

local function encode(value, paths)
    local kind = typeof(value)
    if value == nil then return {_type="nil"} end
    if kind == "boolean" or kind == "string" then return value end
    if kind == "number" then
        if value ~= value or math.abs(value) == math.huge then return {_type="number",value=tostring(value)} end
        return value
    end
    if kind == "Instance" then return {_type=kind,value=paths[value] or "external:"..value:GetFullName()} end
    if kind == "CFrame" then return {_type=kind,value={value:GetComponents()}} end
    if kind == "Vector3" or kind == "Vector3int16" then return {_type=kind,value={value.X,value.Y,value.Z}} end
    if kind == "Vector2" or kind == "Vector2int16" then return {_type=kind,value={value.X,value.Y}} end
    if kind == "Color3" then return {_type=kind,value={value.R,value.G,value.B}} end
    if kind == "BrickColor" then return {_type=kind,value=value.Number} end
    if kind == "UDim" then return {_type=kind,value={value.Scale,value.Offset}} end
    if kind == "UDim2" then return {_type=kind,value={value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}} end
    if kind == "NumberRange" then return {_type=kind,value={value.Min,value.Max}} end
    if kind == "Rect" then return {_type=kind,value={value.Min.X,value.Min.Y,value.Max.X,value.Max.Y}} end
    if kind == "PhysicalProperties" then return {_type=kind,value={value.Density,value.Friction,value.Elasticity,value.FrictionWeight,value.ElasticityWeight}} end
    if kind == "NumberSequence" or kind == "ColorSequence" then
        local points={};for _,point in value.Keypoints do table.insert(points,{point.Time,encode(point.Value,paths),if kind=="NumberSequence" then point.Envelope else nil}) end
        return {_type=kind,value=points}
    end
    if kind == "table" then local result={};for key,item in value do result[key]=encode(item,paths) end;return result end
    return {_type=kind,value=tostring(value)}
end
Snapshot.Encode = encode

local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for key,value in a do if not equal(value,b[key]) then return false end end
    for key in b do if a[key]==nil then return false end end
    return true
end
Snapshot.Equal = equal

local function stableSignature(item, cache)
    if cache[item] then return cache[item] end
    local fields={item.ClassName}
    for _,name in {"CFrame","Size","Text","Value","Source","MeshId","TextureID"} do
        local ok,value=pcall(function() return item[name] end)
        if ok then
            if typeof(value)=="CFrame" then local numbers={};for _,number in {value:GetComponents()} do table.insert(numbers,string.format("%.17g",number)) end;value=table.concat(numbers,",") end
            table.insert(fields,name..":"..tostring(value))
        end
    end
    local attributes={};for name,value in item:GetAttributes() do table.insert(attributes,name..":"..tostring(value)) end
    table.sort(attributes);for _,value in attributes do table.insert(fields,value) end
    local children={};for _,child in item:GetChildren() do table.insert(children,child.Name..":"..stableSignature(child,cache)) end
    table.sort(children);for _,value in children do table.insert(fields,value) end
    cache[item]=table.concat(fields,"\n");return cache[item]
end

local function paths(root)
    local byInstance,byPath,ambiguous={},{},{}
    local signatures={}
    local function visit(item,path)
        assert(not byPath[path],"Snapshot path collision "..path)
        byInstance[item],byPath[path]=path,item
        local groups={};for _,child in item:GetChildren() do groups[child.Name]=groups[child.Name] or {};table.insert(groups[child.Name],child) end
        for name,group in groups do
            if #group>1 then
                table.sort(group,function(a,b) return stableSignature(a,signatures)<stableSignature(b,signatures) end)
                for index=2,#group do if stableSignature(group[index-1],signatures)==stableSignature(group[index],signatures) then
                    table.insert(ambiguous,{parent=path,name=name,class=group[index].ClassName})
                end end
            end
            for index,child in group do visit(child,(if path=="" then "" else path.."/")..name..(if #group>1 then "["..index.."]" else "")) end
        end
    end
    visit(root,"");return byInstance,byPath,ambiguous
end

function Snapshot.CaptureModel(root,options)
    options=options or {}
    local byInstance,byPath,ambiguous=paths(root)
    local result={schema=1,rootName=root.Name,rootClass=root.ClassName,records={},ambiguousDuplicateGroups=ambiguous,
        counts={instances=0,properties=0,unavailableProperties=0,parts=0,meshes=0,colliders=0,walkables=0,hazards=0,arrows=0,artUnits=0,artMeshes=0},
        boundary="All reflected properties are attempted; stored attributes/tags and unavailable-property presence are exact. Listed derived readings and engine identities are excluded."}
    for path,item in byPath do
        local names=assert(Schema.classProperties[item.ClassName],"Unbound snapshot class "..item.ClassName)
        local record={class=item.ClassName,name=item.Name,attrs={},props={},unavailable={},tags={}}
        for name,value in item:GetAttributes() do record.attrs[name]=encode(value,byInstance) end
        for _,name in names do
            local ok,value=pcall(function() return item[name] end)
            if ok then record.props[name]=encode(value,byInstance);result.counts.properties+=1
            else record.unavailable[name]=true;result.counts.unavailableProperties+=1 end
        end
        local ok,tags=pcall(function() return item:GetTags() end)
        if not ok and options.getTags then ok,tags=pcall(options.getTags,item) end
        assert(ok,"Read tags for every captured object")
        record.tags=tags;table.sort(record.tags)
        if item:IsA("Model") then
            local readable,pivot=pcall(function() return item:GetPivot() end)
            if not readable then readable,pivot=pcall(function() return item.WorldPivot end) end
            if not readable or typeof(pivot)~="CFrame" then pivot=item.WorldPivotData end
            if typeof(pivot)=="CFrame" then record.props.CapturedPivot=encode(pivot,byInstance) end
        end
        result.records[path]=record;result.counts.instances+=1
        if item:IsA("BasePart") then
            result.counts.parts+=1
            if item:IsA("MeshPart") then result.counts.meshes+=1 end
            if item.CanCollide then result.counts.colliders+=1 end
            if item:GetAttribute("MCWalkable")==true then result.counts.walkables+=1 end
            if item:GetAttribute("MoonlitHazard")==true then result.counts.hazards+=1 end
            if item:GetAttribute("GuidanceKind")=="SolidMeshArrow" then result.counts.arrows+=1 end
            if item:IsA("MeshPart") and path:sub(1,23)=="Decoration/Phase3World/" then result.counts.artMeshes+=1 end
        end
        if item:IsA("Model") and item:GetAttribute("MCEditUnit") and path:sub(1,23)=="Decoration/Phase3World/" then result.counts.artUnits+=1 end
        if result.counts.instances%250==0 and task and task.wait then task.wait() end
    end
    return result
end

function Snapshot.CaptureSession(context)
    assert(context and context.editable and context.stored,"Provide both actual course roots")
    assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Capture only the intended Studio Edit state")
    assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177,"Verify intended Obby Tournament")
    local result={schema=1,editable=Snapshot.CaptureModel(context.editable),stored=Snapshot.CaptureModel(context.stored),
        lighting=Snapshot.CaptureModel(game:GetService("Lighting")),capturedCurrentCamera=workspace.CurrentCamera~=nil,
        propertySchema=Schema,studio={place=game.PlaceId,universe=game.GameId,creator=game.CreatorId,edit=true}}
    if workspace.CurrentCamera then result.camera=Snapshot.CaptureModel(workspace.CurrentCamera) end
    return result
end

local function hash(raw)
    local digest=game:GetService("EncodingService"):ComputeBufferHash(buffer.fromstring(raw),Enum.HashAlgorithm.Sha256)
    local pieces={};for index=0,buffer.len(digest)-1 do table.insert(pieces,string.format("%02x",buffer.readu8(digest,index))) end
    return table.concat(pieces)
end

function Snapshot.SaveChunks(parent,name,state)
    assert(parent and not parent:FindFirstChild(name),"Preserve prior snapshot recovery")
    local raw=game:GetService("HttpService"):JSONEncode(state)
    local folder=Instance.new("Folder");folder.Name,folder.Parent=name,parent
    local count=0
    for offset=1,#raw,180000 do
        count+=1;local item=Instance.new("StringValue")
        item.Name,item.Value,item.Parent=string.format("%04d",count),raw:sub(offset,offset+179999),folder
        if count%20==0 and task and task.wait then task.wait() end
    end
    local receipt={bytes=#raw,sha256=hash(raw),chunks=count,path=folder:GetFullName(),schema=1,
        editable=state.editable.counts,stored=state.stored.counts,includesLighting=true,includesCamera=state.capturedCurrentCamera}
    folder:SetAttribute("SnapshotSHA256",receipt.sha256);folder:SetAttribute("SnapshotBytes",receipt.bytes);folder:SetAttribute("SnapshotSchema",1)
    return receipt,raw
end

function Snapshot.ReadChunks(folder)
    local children=folder:GetChildren();table.sort(children,function(a,b) return a.Name<b.Name end)
    local pieces={};for _,item in children do assert(item:IsA("StringValue"));table.insert(pieces,item.Value) end
    local raw=table.concat(pieces)
    assert(#raw==folder:GetAttribute("SnapshotBytes") and hash(raw)==folder:GetAttribute("SnapshotSHA256"),"Exact snapshot recovery chunks required")
    return game:GetService("HttpService"):JSONDecode(raw),raw
end
return Snapshot
