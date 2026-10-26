--!nonstrict
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Protected = {}
local RelabelAttributes = {SourceRevision=true,BuildRevision=true,SourcePacketHash=true,CandidateId=true,
	Phase3WorldApplied=true,WorkLighting=true,MoonlitNightAmbience=true}
local CommonPart = {"CFrame","Size","Anchored","CanCollide","CanTouch","CanQuery","CollisionGroup","Transparency",
	"Color","Material","MaterialVariant","CastShadow","Shape","TopSurface","BottomSurface","PivotOffset","CustomPhysicalProperties"}
local Specific = {
	MeshPart={"MeshId","TextureID","DoubleSided","RenderFidelity","CollisionFidelity"},
	Attachment={"CFrame","Axis","SecondaryAxis"}, Beam={"Width0","Width1","FaceCamera","Enabled","Texture","Attachment0","Attachment1","Color","Transparency"},
	SurfaceGui={"Face","AlwaysOnTop","LightInfluence","MaxDistance","PixelsPerStud","SizingMode","Enabled","Active","Adornee"},
	TextLabel={"Text","TextColor3","TextTransparency","Font","TextScaled","TextWrapped","RichText","Size","Position","AnchorPoint","BackgroundTransparency"},
	UITextSizeConstraint={"MinTextSize","MaxTextSize"}, Sound={"SoundId","Volume","PlaybackSpeed","Looped","RollOffMinDistance","RollOffMaxDistance"},
	SpecialMesh={"MeshId","TextureId","MeshType","Scale","Offset","VertexColor"},
}
local function path(root,item)
	if item==root then return "" end
	local pieces={}
	while item and item~=root do
		local name=item.Name
		if item.Parent then
			local count,index=0,0
			for _,sibling in item.Parent:GetChildren() do
				if sibling.Name~=item.Name then continue end
				count+=1;if sibling==item then index=count end
			end
			if count>1 then name..="["..index.."]" end
		end
		table.insert(pieces,1,name);item=item.Parent
	end
	return if item==root then table.concat(pieces,"/") else nil
end
local function encode(value,root)
	local kind=typeof(value)
	if kind=="CFrame" then return {_type=kind,value={value:GetComponents()}} end
	if kind=="Vector3" then return {_type=kind,value={value.X,value.Y,value.Z}} end
	if kind=="Vector2" then return {_type=kind,value={value.X,value.Y}} end
	if kind=="Color3" then return {_type=kind,value={value.R,value.G,value.B}} end
	if kind=="UDim2" then return {_type=kind,value={value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}} end
	if kind=="Instance" then return {_type=kind,value=path(root,value) or value:GetFullName()} end
	if kind=="EnumItem" then return tostring(value) end
	if kind=="PhysicalProperties" then return {_type=kind,value={value.Density,value.Friction,value.Elasticity,value.FrictionWeight,value.ElasticityWeight}} end
	if kind=="NumberSequence" or kind=="ColorSequence" then
		local values={};for _,key in value.Keypoints do table.insert(values,{key.Time,encode(key.Value,root),if kind=="NumberSequence" then key.Envelope else nil}) end
		return {_type=kind,value=values}
	end
	if kind=="boolean" or kind=="string" or kind=="number" or value==nil then return value end
	return {_type=kind,value=tostring(value)}
end
local function artOnly(root,item,allowOuterWorld)
	if item:IsA("Light") and item:GetAttribute("MoonlitWorldLight")==true then return true end
	if item:IsA("LuaSourceContainer") then return false end
	local ancestor=item
	while ancestor and ancestor~=root do
		if ancestor:GetAttribute("MCWalkable")==true or ancestor:GetAttribute("MoonlitHazard")==true
			or ancestor:GetAttribute("CheckpointIndex")~=nil or ancestor:GetAttribute("Travel")~=nil
			or ancestor:GetAttribute("PivotPosition")~=nil then return false end
		ancestor=ancestor.Parent
	end
	local relative=path(root,item) or ""
	for _,prefix in {"Decoration/Phase3World",if allowOuterWorld then "Decoration/Phase3OuterWorld" else ""} do
		if prefix~="" and (relative==prefix or string.sub(relative,1,#prefix+1)==prefix.."/") then return true end
	end
	return false
end
local function capture(course,isKit,options)
	assert(not RunService:IsRunning(),"Capture accepted course in Edit/rest state, not while mechanisms are moving")
	if not isKit then assert(course:IsA("Model") and course:GetAttribute("CourseId")=="moonlit_citadel","Explicit intended Moonlit model required") end
	local snapshot={schema=1,identity={path=course:GetFullName(),source=course:GetAttribute("SourceRevision"),build=course:GetAttribute("BuildRevision"),
		packet=course:GetAttribute("SourcePacketHash")},records={},artParts={},worldLights={},arrowIds={},counts={},kind=if isKit then "AcceptedKit" else "Course"}
	local arrows={}
	local objects={course};for _,item in course:GetDescendants() do table.insert(objects,item) end
	for _,item in objects do
		local relative=path(course,item)
		if not isKit and item:IsA("Light") and item:GetAttribute("MoonlitWorldLight")==true then
			table.insert(snapshot.worldLights,{path=relative,class=item.ClassName,color={item.Color.R,item.Color.G,item.Color.B},
				brightness=item.Brightness,range=item.Range,shadows=item.Shadows,enabled=item.Enabled})
			continue
		end
		if not isKit and artOnly(course,item,options and options.allowPhase3OuterWorld==true) then
			if item:IsA("BasePart") then table.insert(snapshot.artParts,{path=relative,frame={item.CFrame:GetComponents()},size={item.Size.X,item.Size.Y,item.Size.Z},
				collide=item.CanCollide,query=item.CanQuery,touch=item.CanTouch,anchored=item.Anchored,transparency=item.Transparency}) end
			continue
		end
		local row={class=item.ClassName,attrs={},props={},tags=CollectionService:GetTags(item)}
		table.sort(row.tags)
		for key,value in item:GetAttributes() do
			if not isKit and item==course and RelabelAttributes[key] then continue end
			row.attrs[key]=encode(value,course)
		end
		local function read(properties)
			for _,key in properties do local ok,value=pcall(function() return item[key] end);if ok and value~=nil then row.props[key]=encode(value,course) end end
		end
		if item:IsA("BasePart") then read(CommonPart) end
		if item:IsA("Light") then read({"Color","Brightness","Range","Shadows","Enabled","Angle","Face"}) end
		if Specific[item.ClassName] then read(Specific[item.ClassName]) end
		if item:IsA("ValueBase") then read({"Value"}) end
		if item:IsA("JointInstance") then read({"C0","C1","Part0","Part1","Enabled"}) end
		if item:IsA("Constraint") then read({"Enabled","Attachment0","Attachment1"}) end
		if item:IsA("Model") then
			row.props.Pivot=encode(item:GetPivot(),course);row.props.PrimaryPart=encode(item.PrimaryPart,course)
			local ok,scale=pcall(function()return item:GetScale() end);if ok then row.props.Scale=scale end
		end
		if item:IsA("LuaSourceContainer") then row.props.Source=item.Source end
		assert(not snapshot.records[relative],"Canonical protected path collision "..relative)
		snapshot.records[relative]=row
		local arrowId=item:GetAttribute("ArrowId")
		if arrowId then arrows[arrowId]=true end
		snapshot.counts[item.ClassName]=(snapshot.counts[item.ClassName] or 0)+1
	end
	for id in arrows do table.insert(snapshot.arrowIds,id) end
	table.sort(snapshot.arrowIds)
	table.sort(snapshot.artParts,function(a,b)return a.path<b.path end)
	return snapshot
end
function Protected.Capture(course,options) return capture(course,false,options) end
function Protected.CaptureAcceptedKit(kit)
	assert(kit.Name=="MoonlitCitadel_BL02Library","Pass the exact accepted Phase1 BL02 library")
	return capture(kit,true)
end
function Protected.CaptureArrowTemplate(asset)
	assert(asset.Name=="MC_P3_Rework_ArrowMount" or asset.Name=="MC_P3_Rework_SolidArrow","Pass an exact accepted arrow template")
	return capture(asset,true)
end
local function changes(a,b,prefix,out)
	if type(a)~=type(b) then table.insert(out,prefix);return end
	if type(a)~="table" then if a~=b then table.insert(out,prefix) end;return end
	local keys={};for key in a do keys[key]=true end;for key in b do keys[key]=true end
	for key in keys do changes(a[key],b[key],prefix.."/"..tostring(key),out) end
end
function Protected.Compare(before,after)
	assert(before.schema==1 and after.schema==1,"Unsupported protected baseline schema")
	local report={exactChanges={},missing={},added={},arrowCount=#after.arrowIds,baselineIdentity=before.identity,currentIdentity=after.identity}
	for key,row in before.records do
		if not after.records[key] then table.insert(report.missing,key) else changes(row,after.records[key],key,report.exactChanges) end
	end
	for key in after.records do if not before.records[key] then table.insert(report.added,key) end end
	changes(before.arrowIds,after.arrowIds,"ArrowIds",report.exactChanges)
	table.sort(report.exactChanges);table.sort(report.missing);table.sort(report.added)
	report.pass=#report.exactChanges==0 and #report.missing==0 and #report.added==0 and (before.kind=="AcceptedKit" or report.arrowCount==19)
	return report
end
return Protected
