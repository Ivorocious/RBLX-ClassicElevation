--!nonstrict
local Builder = {}
local V = Vector3.new
local origin = V(1544, 388, -1134)
local cream = Color3.fromRGB(255, 240, 202)
local violet = Color3.fromRGB(173, 117, 207)

local function moveFragment(course, index, position, heading)
 local group = course.Obstacles.S3_ShellApproach
 local pad = group[string.format("S3_ShellApproach_%03d", index)]
 local old = CFrame.new(pad:GetAttribute("ERTop")) * pad.CFrame.Rotation
 local target = CFrame.lookAt(position, position + heading)
 local delta = target * old:Inverse()
 for _, part in group:GetChildren() do
  if part:IsA("BasePart") and (part == pad or part.Name:sub(1, #pad.Name + 9) == pad.Name .. "_Shoulder") then
   part.CFrame = delta * part.CFrame
   part:SetAttribute("ERTop", position)
  end
 end
 local art = course.Decoration.Shellworks_R01
 for _, item in art:GetChildren() do
  if item:IsA("Model") and item.Name == "ShellFragment" and (item:GetPivot().Position - old.Position).Magnitude < .1 then
   item:PivotTo(delta * item:GetPivot())
  elseif item:IsA("BasePart") and item.Name == "SelectedStuds" and (item.Position - old.Position).Magnitude < .1 then
   item.CFrame = delta * item.CFrame
  end
 end
 local bank = art:FindFirstChild(({"ApproachShoulder", "ApproachTurnRock", "FragmentRock3", "FragmentRock4"})[index])
 if bank then bank:PivotTo(CFrame.new(position - V(0, 2.4, 0)) * target.Rotation) end
end

local function choice(course, name, part, incoming, text)
 local forward = Vector3.new(incoming.X, 0, incoming.Z).Unit
 local right = forward:Cross(Vector3.yAxis)
 local position = part:GetAttribute("ERTop") + right * (part.Size.X / 2 + 2) + V(0, 3.3, 0)
 local face = Instance.new("Part")
 face.Name = name
 face.Size = V(10, 2.5, .25)
 face.CFrame = CFrame.lookAt(position, position - forward)
 face.Color = violet
 face.Anchored, face.CanCollide, face.CanTouch, face.CanQuery = true, false, false, false
 local gui = Instance.new("SurfaceGui")
 gui.Face, gui.CanvasSize, gui.Parent = Enum.NormalId.Front, Vector2.new(800, 200), face
 local label = Instance.new("TextLabel")
 label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
 label.Font, label.TextScaled, label.TextColor3, label.Text = Enum.Font.GothamBold, true, cream, text
 label.Parent = gui
 face.Parent = course.RouteMarkers
end

function Builder.Create(kit, accepted)
 assert(game:GetService("RunService"):IsStudio(), "Author this candidate in Studio")
 local root = if accepted then accepted:Clone() else require(script.Parent.Parent.RestartR01.Study).Build(kit)
 assert(root:GetAttribute("CandidateId") == "ER_P1_R01" and root:GetAttribute("FullBodyContacts"), "Use the accepted foundation")
 root.Name = "Course_EggRush"
 local pivot = root:GetPivot()
 local function world(point) return pivot:PointToWorldSpace(point - origin) end
 local positions = {V(1441,400,-1242), V(1449,401,-1251), V(1461,402,-1252), V(1472,403,-1247)}
 local previous = root.Obstacles.CP2_Pocket:GetAttribute("ERTop")
 for i, position in positions do positions[i] = world(position) end
 for i, position in positions do
  local following = positions[i + 1] or root.Obstacles.Shell_ForkWait:GetAttribute("ERTop")
  local incoming = (position - (positions[i - 1] or previous)) * V(1,0,1)
  local outgoing = (following - position) * V(1,0,1)
  moveFragment(root, i, position, incoming.Unit + outgoing.Unit)
 end
 local a, b = positions[2], positions[3]
 local middle = (a + b) / 2 + V(0,.5,0)
 root.Obstacles.Shellworks_RedHop.CFrame = CFrame.lookAt(middle, middle + (b-a)*V(1,0,1))
 root.Start.Size = V(root.Start.Size.X, root.Start.Size.Y, 32)
 for _, part in root:GetDescendants() do
  if part:IsA("BasePart") then
   if part:GetAttribute("ERRoute") == "Expert" then part.Color = violet end
   if part.Name:match("_WarningPost$") then part.CanCollide, part.CanTouch, part.CanQuery = false, false, false end
  elseif part:IsA("TextLabel") and part.Text == "PHASE 1 STUDY  /  3 LAPS" then
   part.Text = "EGG RUSH CIRCUIT  /  3 LAPS"
  end
 end
 local o = root.Obstacles
 local turn = o.S5_Rookery.S5_Rookery_004
 local offset = pivot:VectorToWorldSpace(V(2,0,-2))
 turn.CFrame += offset
 turn:SetAttribute("ERTop",turn:GetAttribute("ERTop")+offset)
 local support = root.Decoration.RoughSupports.S5_Rookery_004_Rock
 support.CFrame += offset
 for _, name in {"S6_ShellSpill_002", "S6_ShellSpill_007"} do
  local landing = o.S6_ShellSpill[name]
  landing.Size = V(landing.Size.X,landing.Size.Y,5.5)
  landing:SetAttribute("ERForwardDepth",5.5)
 end
 choice(root, "Choice_RimSprint", o.S1_Nestyard.S1_Nestyard_001, o.S1_Nestyard.S1_Nestyard_001.Position-root.Start.Position, "VIOLET: RIM SPRINT\nTURNING JUMPS / SHORTER ROUTE")
 local rimSign = root.RouteMarkers.Choice_RimSprint
 rimSign.Size = V(6,1.5,rimSign.Size.Z)
 rimSign.CFrame += pivot.UpVector*1.5
 choice(root, "Choice_ChuteCut", o.CP1_Pocket, o.CP1_Pocket.CFrame.LookVector, "VIOLET: CHUTE CUT\nTIGHT TURNS / SAME EGG BANDS")
 choice(root, "Choice_RoostCut", o.CP3_Pocket, o.CP3_Pocket.CFrame.LookVector, "VIOLET: ROOST CUT\nLONGER DROPS / SAME TAIL")
 for _, sign in root.RouteMarkers:GetChildren() do
  if sign:IsA("BasePart") and (sign.Name:match("^Choice_NORMAL") or sign.Name:match("^Choice_EXPERT")) then
   local localPosition = pivot:PointToObjectSpace(sign.Position)
   sign.Size = V(6,1.5,sign.Size.Z)
   sign.CFrame = CFrame.new(pivot:PointToWorldSpace(V(-56,23,localPosition.Z))) * sign.CFrame.Rotation
  end
 end
 for _, name in {"S2_EggRollers_004", "S2_EggRollers_010", "E2_ChuteCut_003", "E2_ChuteCut_008"} do
  local wait = assert(o:FindFirstChild(name,true))
  local width = if name=="S2_EggRollers_010" then 8.5 elseif wait:GetAttribute("ERRoute")=="Expert" then 11 else 14
  wait.Size = V(width,wait.Size.Y,wait.Size.Z)
  wait:SetAttribute("ERPurpose","Sideways egg waiting and passing space")
 end
 require(script.Parent.Presentation).Apply(root,kit)
 root:SetAttribute("CandidateId", "ER_P2_R01_C05")
 root:SetAttribute("Phase", 2)
 root:SetAttribute("OwnerAcceptance", "Pending Phase 2 review")
 root:SetAttribute("Phase2Revision", 5)
 root:SetAttribute("PresentationRevision", "V03")
 root:SetAttribute("Phase1Scope", "Accepted foundation preserved in EggRushHistory_Restart20261021")
 root:SetAttribute("StudySource", "Accepted R01/R03/T01 foundation with scoped Phase2 patches")
 root.CourseInfo:SetAttribute("DisplayName", "Egg Rush Circuit")
 root.CourseInfo:SetAttribute("Enabled", true)
 local revision=require(script.Parent.RevisionR02)
 root:PivotTo(CFrame.new(revision.Origin))
 local revised,retired=revision.Apply(root,kit)
 local final,r03Retired=require(script.Parent.RevisionR03).Apply(revised)
 retired.Parent=r03Retired
 local chicken,chickenRetired=require(script.Parent.ChickenR04).Apply(final)
 r03Retired.Parent=chickenRetired
 require(script.Parent.Parent.Phase3.World).Apply(chicken)
 return chicken,chickenRetired
end

return Builder
