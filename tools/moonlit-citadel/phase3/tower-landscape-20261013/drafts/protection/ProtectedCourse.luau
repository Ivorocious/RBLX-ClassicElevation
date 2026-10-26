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
local signatures,ranks,ambiguous,includeWorldLights={},{},{},false
local function namePath(item)
	local names={};while item do table.insert(names,1,item.Name);item=item.Parent end
	return table.concat(names,"/")
end
local function number(value) return string.format("%.17g",value) end
local function components(values)
	local result={};for _,value in values do table.insert(result,number(value)) end;return table.concat(result,",")
end
local function referenceToken(item)
	local token=namePath(item)..":"..item.ClassName
	if item:IsA("BasePart") then token..=":"..components({item.CFrame:GetComponents()})..":"..components({item.Size.X,item.Size.Y,item.Size.Z}) end
	if item:IsA("Attachment") then
		token..=":"..components({item.CFrame:GetComponents()})
		if item.Parent and item.Parent:IsA("BasePart") then token..=":"..components({item.Parent.CFrame:GetComponents()}) end
	end
	if item:IsA("Model") then token..=":"..components({item:GetPivot():GetComponents()}) end
	return token
end
local function valueToken(value)
	local kind=typeof(value)
	if kind=="Instance" then return "ref:"..referenceToken(value) end
	if kind=="CFrame" then return "cf:"..components({value:GetComponents()}) end
	if kind=="Vector3" then return "v3:"..components({value.X,value.Y,value.Z}) end
	if kind=="Vector2" then return "v2:"..components({value.X,value.Y}) end
	if kind=="Color3" then return "c3:"..components({value.R,value.G,value.B}) end
	if kind=="UDim2" then return "u2:"..components({value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}) end
	if kind=="PhysicalProperties" then return "physical:"..components({value.Density,value.Friction,value.Elasticity,value.FrictionWeight,value.ElasticityWeight}) end
	if kind=="NumberSequence" or kind=="ColorSequence" then
		local entries={};for _,key in value.Keypoints do table.insert(entries,number(key.Time)..":"..valueToken(key.Value)..":"..(if kind=="NumberSequence" then number(key.Envelope) else "")) end
		return kind..":"..table.concat(entries,";")
	end
	if kind=="number" then return number(value) end
	return kind..":"..tostring(value)
end
local function signature(item)
	if signatures[item] then return signatures[item] end
	local fields={"class:"..item.ClassName}
	local function read(properties)
		for _,key in properties do local ok,value=pcall(function()return item[key] end);if ok and value~=nil then table.insert(fields,"prop:"..key.."="..valueToken(value)) end end
	end
	if item:IsA("BasePart") then read(CommonPart) end
	if Specific[item.ClassName] then read(Specific[item.ClassName]) end
	if item:IsA("ValueBase") then read({"Value"}) end
	if item:IsA("Model") then table.insert(fields,"pivot:"..valueToken(item:GetPivot()));read({"PrimaryPart"}) end
	if item:IsA("JointInstance") then read({"C0","C1","Part0","Part1","Enabled"}) end
	if item:IsA("Constraint") then read({"Enabled","Attachment0","Attachment1"}) end
	if item:IsA("LuaSourceContainer") then read({"Source"}) end
	for key,value in item:GetAttributes() do table.insert(fields,"attr:"..key.."="..valueToken(value)) end
	for _,tag in CollectionService:GetTags(item) do table.insert(fields,"tag:"..tag) end
	for _,child in item:GetChildren() do
		if not includeWorldLights and child:IsA("Light") and child:GetAttribute("MoonlitWorldLight")==true then continue end
		table.insert(fields,"child:"..child.Name.."="..signature(child))
	end
	table.sort(fields)
	local result=table.concat(fields,"\n")
	signatures[item]=result
	return result
end
local function siblingIndex(item)
	local parent=item.Parent;if not parent then return nil end
	ranks[parent]=ranks[parent] or {}
	local group=ranks[parent][item.Name]
	if not group then
		local siblings={}
		for _,sibling in parent:GetChildren() do if sibling.Name==item.Name then table.insert(siblings,{item=sibling}) end end
		group={count=#siblings,index={}}
		if #siblings>1 then
			for _,sibling in siblings do sibling.key=signature(sibling.item) end
			table.sort(siblings,function(a,b)return a.key<b.key end)
			for index,sibling in siblings do
				group.index[sibling.item]=index
				if index>1 and sibling.key==siblings[index-1].key then
					table.insert(ambiguous,{parent=namePath(parent),name=item.Name,class=sibling.item.ClassName})
				end
			end
		end
		ranks[parent][item.Name]=group
	end
	return if group.count>1 then group.index[item] else nil
end
local function path(root,item)
	if item==root then return "" end
	local pieces={}
	while item and item~=root do
		local name=item.Name
		local index=siblingIndex(item);if index then name..="["..index.."]" end
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
	signatures,ranks,ambiguous,includeWorldLights={},{},{},isKit
	if not isKit then assert(course:IsA("Model") and course:GetAttribute("CourseId")=="moonlit_citadel","Explicit intended Moonlit model required") end
	local snapshot={schema=2,pathScheme="duplicate-property-signature-rank",identity={path=course:GetFullName(),source=course:GetAttribute("SourceRevision"),build=course:GetAttribute("BuildRevision"),
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
	snapshot.ambiguousDuplicateGroups=ambiguous
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
function Protected.CaptureFrozenPhase1Model(model)
	assert(model.Name=="MoonlitCitadelPhase1_BL02" or model.Name=="BeforePhase1Current43","Pass the exact current accepted Phase1 model or the lead's fresh Source43 recovery clone")
	return capture(model,true)
end
local function changes(a,b,prefix,out)
	if type(a)~=type(b) then table.insert(out,prefix);return end
	if type(a)~="table" then if a~=b then table.insert(out,prefix) end;return end
	local keys={};for key in a do keys[key]=true end;for key in b do keys[key]=true end
	for key in keys do changes(a[key],b[key],prefix.."/"..tostring(key),out) end
end
function Protected.Compare(before,after)
	assert(before.schema==2 and after.schema==2,"Fresh Source43 schema2 captures required; do not relabel older occurrence-indexed baselines")
	local report={exactChanges={},missing={},added={},arrowCount=#after.arrowIds,baselineIdentity=before.identity,currentIdentity=after.identity}
	for key,row in before.records do
		if not after.records[key] then table.insert(report.missing,key) else changes(row,after.records[key],key,report.exactChanges) end
	end
	for key in after.records do if not before.records[key] then table.insert(report.added,key) end end
	changes(before.arrowIds,after.arrowIds,"ArrowIds",report.exactChanges)
	table.sort(report.exactChanges);table.sort(report.missing);table.sort(report.added)
	report.ambiguousDuplicateGroupsBefore=before.ambiguousDuplicateGroups or {}
	report.ambiguousDuplicateGroupsAfter=after.ambiguousDuplicateGroups or {}
	report.pass=#report.exactChanges==0 and #report.missing==0 and #report.added==0 and #report.ambiguousDuplicateGroupsBefore==0
		and #report.ambiguousDuplicateGroupsAfter==0 and (before.kind=="AcceptedKit" or report.arrowCount==19)
	return report
end
return Protected
