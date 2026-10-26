--!strict
assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
local c=workspace.KeyboardCircuit_P3_M02_01
local art, panels, labels = {}, {}, {}
local minimumContrast = math.huge
local function relative(item: Instance): string return item:GetFullName():sub(#c:GetFullName()+2) end
local function luminance(color: Color3): number
	local function channel(v: number): number return if v<=.04045 then v/12.92 else ((v+.055)/1.055)^2.4 end
	return .2126*channel(color.R)+.7152*channel(color.G)+.0722*channel(color.B)
end
for _, item in c.MapEnvironment:GetDescendants() do if item:IsA("BasePart") and item.Transparency < .9 then table.insert(art,item) end end
for _, item in c:GetDescendants() do
	if item:IsA("BasePart") and (item.Name:find("Sign") or item.Name=="ExpertCommitment" or item.Name=="NormalAlternative" or item.Name=="StartLapFinish" or item.Name=="Flag" or item.Name=="DisplayPanel") then
		table.insert(panels,item)
		for _, gui in item:GetChildren() do if gui:IsA("SurfaceGui") then
			for _, label in gui:GetDescendants() do if label:IsA("TextLabel") and label.Visible then
				local background, parent = item.Color, label.Parent
				while parent ~= gui do
					if parent:IsA("GuiObject") and parent.BackgroundTransparency < .1 then background=parent.BackgroundColor3; break end
					parent = parent.Parent
				end
				local a,b=luminance(background),luminance(label.TextColor3)
				local contrast=(math.max(a,b)+.05)/(math.min(a,b)+.05)
				minimumContrast=math.min(minimumContrast,contrast)
				table.insert(labels,{part=relative(item),text=label.Text,contrast=contrast})
			end end
		end end
	end
end
local function intersects(part: BasePart, eye: Vector3, target: Vector3): boolean
	local origin=part.CFrame:PointToObjectSpace(eye)
	local direction=part.CFrame:VectorToObjectSpace(target-eye)
	local low,high=.001,.999
	for _, axis in {"X","Y","Z"} do
		local size=part.Size[axis]/2
		if math.abs(direction[axis])<.00001 then if math.abs(origin[axis])>size then return false end
		else
			local a,b=(-size-origin[axis])/direction[axis],(size-origin[axis])/direction[axis]
			low,high=math.max(low,math.min(a,b)),math.min(high,math.max(a,b))
			if low>high then return false end
		end
	end
	return true
end
local failures, observations = {}, {}
local rays=0
local function check(category: string, label: string, eye: Vector3, points: {Vector3}, sign: BasePart?)
	local blockers={}
	for _, point in points do
		rays+=1
		for _, other in art do if other~=sign and intersects(other,eye,point) then blockers[relative(other)]=true end end
		if sign then for _, other in panels do if other~=sign and intersects(other,eye,point) then blockers[relative(other)]=true end end end
	end
	local blocked={}
	for path in blockers do table.insert(blocked,path) end
	table.sort(blocked)
	local row={category=category,target=label,eye={eye.X,eye.Y,eye.Z},points=#points,blockers=blocked}
	table.insert(observations,row)
	if #blocked>0 then table.insert(failures,row) end
end
for _, pad in c.RecoveryPads:GetChildren() do
	local host=if pad:FindFirstChild("HostContact") then pad.HostContact.Value else c.CheckpointBays[pad.Name].BankContact
	local spawn=pad.BankContact:GetAttribute("SpawnCFrame")
	local rows,columns=pad.BankContact:GetAttribute("SlotRows") or 4,pad.BankContact:GetAttribute("SlotColumns") or 5
	local eyes={host.CFrame:PointToWorldSpace(Vector3.new(-host.Size.X/2+1,4.5,0))}
	for row=1,rows do for column=1,columns do
		table.insert(eyes,(spawn*CFrame.new((column-(columns+1)/2)*(pad.BankContact:GetAttribute("SlotSpacingX") or 4.5),1.2,(row-(rows+1)/2)*(pad.BankContact:GetAttribute("SlotSpacingZ") or 4))).Position)
	end end
	local targets={}
	local station=c.MapEnvironment.Wayfinding:FindFirstChild("CheckpointStation_"..pad.Name)
	assert(station,"Every recovery requires a numbered station")
	for _, panel in panels do
		if panel:IsDescendantOf(station) then table.insert(targets,panel) end
	end
	assert(#targets>=2,"Number and checkpoint panels must be audited")
	for _, eye in eyes do for _, target in targets do
		local points={}
		local x,y=target.Size.X*.43,target.Size.Y*.35
		for _, offset in {Vector3.zero,Vector3.new(-x,y,0),Vector3.new(x,y,0),Vector3.new(-x,-y,0),Vector3.new(x,-y,0)} do table.insert(points,target.CFrame:PointToWorldSpace(offset+Vector3.new(0,0,-target.Size.Z/2-.02))) end
		check("RecoveryAndChoice",pad.Name..":"..relative(target),eye,points,target)
	end end
end
local function endpoint(unit: Model, departing: boolean): BasePart
	if unit:FindFirstChild("BankContact") then return unit.BankContact end
	return (unit:FindFirstChild(departing and "ExitBank" or "EntryBank") or unit:FindFirstChild(departing and "Exit" or "Entry")).BankContact
end
local contacts={}
for _, item in c:GetDescendants() do
	if item:IsA("BasePart") and item.CanCollide and (item.Name=="BankContact" or item.Name=="KeyContact") then table.insert(contacts,item) end
end
for _, contact in contacts do
	local forward=contact.CFrame.RightVector
	local eye=contact.CFrame:PointToWorldSpace(Vector3.new(-contact.Size.X/2+1,contact.Size.Y/2+4.5,0))
	for _, length in {8,14,22} do for _, yaw in {-35,0,35} do
		local direction=CFrame.Angles(0,math.rad(yaw),0):VectorToWorldSpace(forward)
		check("CameraCorridor",relative(contact),eye,{eye-direction*length+Vector3.new(0,7,0)})
	end end
end
for _, edge in c.RouteEdges:GetChildren() do
	local a,b=edge.From.Value,edge.To.Value
	if a:GetAttribute("ExpertId") or b:GetAttribute("ExpertId") then continue end
	local departure,arrival=endpoint(a,true),endpoint(b,false)
	local direction=(arrival.Position-departure.Position)*Vector3.new(1,0,1)
	if direction.Magnitude < .001 then continue end
	direction=direction.Unit
	local localDirection=departure.CFrame:VectorToObjectSpace(direction)
	local extent=math.min(if math.abs(localDirection.X)>.001 then (departure.Size.X/2-.8)/math.abs(localDirection.X) else math.huge,if math.abs(localDirection.Z)>.001 then (departure.Size.Z/2-.8)/math.abs(localDirection.Z) else math.huge)
	local eye=departure.Position+direction*extent+Vector3.new(0,4.5,0)
	local targets={}
	for _, x in {-arrival.Size.X/2+.8,0,arrival.Size.X/2-.8} do table.insert(targets,arrival.CFrame:PointToWorldSpace(Vector3.new(x,arrival.Size.Y/2+.45,0))) end
	check("ReceivingEdges",edge.Name,eye,targets)
end
for _, unit in c.Districts:GetDescendants() do
	if not unit:IsA("Model") or not unit:GetAttribute("MechanismId") then continue end
	local bank=endpoint(unit,false)
	local eye=bank.CFrame:PointToWorldSpace(Vector3.new(-bank.Size.X/2+1,4.5,0))
	local points={}
	for _, warning in unit:GetDescendants() do if warning:IsA("BasePart") and warning:GetAttribute("KCWarning") then table.insert(points,warning.Position) end end
	check("HazardWarnings",unit:GetAttribute("MechanismId"),eye,points)
end
local displayBoards = 0
for _, sign in c.MapEnvironment.HazardIndicators:GetChildren() do
	local source = (sign.SourceMechanism :: ObjectValue).Value :: Model
	local role = sign:GetAttribute("IndicatorRole")
	local host = endpoint(source,role=="Exit")
	local panel = sign.PrimaryPart :: BasePart
	local eyes = {}
	for _, offset in {Vector3.new(-host.Size.X/2+1,4.5,0),Vector3.new(-host.Size.X*.3,4.5,-host.Size.Z*.3),Vector3.new(-host.Size.X*.3,4.5,host.Size.Z*.3),Vector3.new(host.Size.X*.3,4.5,0)} do
		table.insert(eyes,host.CFrame:PointToWorldSpace(offset))
	end
	local points={}
	for _, offset in {Vector3.zero,Vector3.new(-panel.Size.X*.43,panel.Size.Y*.35,0),Vector3.new(panel.Size.X*.43,panel.Size.Y*.35,0),Vector3.new(-panel.Size.X*.43,-panel.Size.Y*.35,0),Vector3.new(panel.Size.X*.43,-panel.Size.Y*.35,0)} do
		table.insert(points,panel.CFrame:PointToWorldSpace(offset+Vector3.new(0,0,-panel.Size.Z/2-.02)))
	end
	for _, eye in eyes do check("HazardDisplayFaces",sign.Name,eye,points,panel) end
	displayBoards+=1
end
assert(displayBoards==17,"Every new warning display must be checked")
local enterTurns = 0
for _, unit in c.Districts:GetDescendants() do
	if unit:IsA("Model") and (unit:GetAttribute("SequenceId")=="O04" or unit:GetAttribute("SequenceId")=="O08") then
		local entry=endpoint(unit,false)
		local points={}
		for _, item in unit:GetDescendants() do
			if item:IsA("BasePart") and item.Name=="KeyTop" then
				local x,z=math.max(0,item.Size.X/2-.5),math.max(0,item.Size.Z/2-.5)
				for _, offset in {Vector3.zero,Vector3.new(-x,0,-z),Vector3.new(-x,0,z),Vector3.new(x,0,-z),Vector3.new(x,0,z)} do
					table.insert(points,item.CFrame:PointToWorldSpace(offset+Vector3.new(0,item.Size.Y/2+.12,0)))
				end
			end
		end
		assert(#points>=10,"Enter turn must include both keytops and nonempty target coverage")
		enterTurns+=1
		check("EnterTurn",unit.Name,entry.Position+Vector3.new(0,4.5,0),points)
	end
end
assert(enterTurns==2,"Both actual Enter encounters must be checked")
local result={passed=#failures==0 and minimumContrast>=4.5,candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),minimumContrast=minimumContrast,labels=labels,observations=observations,rays=rays,failures=failures,enterTurns=enterTurns,displayBoards=displayBoards,
	boundary="Geometric OBB segment checks against all new visible scenery including translucent switch shell. All eight recovery regions and their 116 slots plus approaches; checkpoint/choice text regions; all physical key-contact camera corridors at 8/14/22 studs with three yaws; receiving edges, hazard warnings and both Enter turns. Sign checks additionally include other panels. Added scenery occlusion proof, not rendered camera or human readability certification."}
shared.KCP3M02Visibility01=result
return game.HttpService:JSONEncode({passed=result.passed,failures=failures,observations=#observations,rays=rays,minimumContrast=minimumContrast,labels=#labels,displayBoards=displayBoards})
