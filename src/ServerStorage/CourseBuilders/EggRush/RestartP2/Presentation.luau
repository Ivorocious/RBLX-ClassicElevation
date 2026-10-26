--!nonstrict
local Presentation = {}
local V = Vector3.new
local function skin(kit, name, parent, frame, scale)
 local model = assert(kit:FindFirstChild(name), "Missing inspected unit " .. name):Clone()
 scale = scale or Vector3.one
 for _, part in model:GetDescendants() do
  if part:IsA("BasePart") then
   part.Size *= scale
   part.CFrame = frame * CFrame.new(part.CFrame.Position * scale) * part.CFrame.Rotation
   part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
  end
 end
 model.WorldPivot = frame
 model:SetAttribute("ERArt", true)
 model.Parent = parent
 return model
end
local function lethal(model)
 for _, part in model:GetDescendants() do
  if part:IsA("BasePart") then
   assert(part:IsA("MeshPart") and part.CollisionFidelity == Enum.CollisionFidelity.PreciseConvexDecomposition, "Use inspected visible contact meshes")
   part:SetAttribute("ERLethal", true)
   part.CanQuery = true
  end
 end
end
local function retireContact(part)
 part:SetAttribute("ERLethal", nil)
 part.Transparency, part.CanQuery, part.CanTouch = 1, false, false
end
function Presentation.Apply(root, kit)
 assert(not root.Decoration:FindFirstChild("Phase2Assembly"), "Apply to the accepted foundation once")
 local art = Instance.new("Folder")
 art.Name, art.Parent = "Phase2Assembly", root.Decoration
 local mechanisms = root.Obstacles.Mechanisms
 for index, name in {"EggCoral", "EggMint"} do
  local mechanism = mechanisms["EggBand" .. index]
  lethal(skin(kit, name, mechanism, mechanism:GetPivot() * CFrame.new(0,-4,0), V(7/6,1,7/6)))
  retireContact(mechanism.RoughEgg)
  skin(kit, "EggChute", art, mechanism:GetPivot() * CFrame.new(-16,-4.6,0) * CFrame.Angles(0,-math.pi/2,0))
 end
 local tail = mechanisms.GuardianTail
 lethal(skin(kit, "GuardianSweepTail", tail, tail:GetPivot()))
 retireContact(tail.RoughTail)
 local fan = tail:GetPivot() * CFrame.Angles(0,-math.pi/2,0)
 local body = fan * CFrame.new(0,-4.5,4.1)
 skin(kit,"GuardianBody",art,body)
 skin(kit,"GuardianTail",art,fan)
 skin(kit,"RockSupportLow",art,body,V(1.5,.8,2))
 local tray = mechanisms.SidewaysTray
 local contact = tray.TrayContact
 local top = tray:GetPivot()
 local trayArt = skin(kit,"SlidingTray",tray,top*CFrame.new(0,-.9,0),V(1.2,1,2.25))
 for _, part in trayArt:GetDescendants() do
  if part:IsA("BasePart") and part:GetAttribute("ERMaterial") == "Mint" then
   -- Both boarding edges stay open on the course's longer passenger deck.
   part.Transparency = 1
  end
 end
 contact.Size, contact.CFrame, contact.Transparency = V(12,.9,18), top*CFrame.new(0,-.45,0), 1
 local studs = Instance.new("Part")
 studs.Name, studs.Size, studs.CFrame = "TrayStudTop", V(11.4,.08,17.4), top*CFrame.new(0,.04,0)
 studs.Color = Color3.fromRGB(255,240,202)
 studs.TopSurface = Enum.SurfaceType.Studs
 studs.Anchored, studs.CanCollide, studs.CanTouch, studs.CanQuery = true, false, false, false
 studs.Parent = tray
 skin(kit,"RailPair",art,top*CFrame.new(0,-2.55,10.5),V(1.2,1,2))
 for _, part in root.Decoration:GetChildren() do
  if part:IsA("BasePart") and part.Name == "ExposedRail" then part.Transparency = 1 end
 end
 for _, column in root.Decoration.RoughSupports:GetChildren() do
  if column:IsA("BasePart") then
   local name = column.Name:gsub("_Rock$", "")
   local landing = root.Obstacles:FindFirstChild(name,true)
   if landing and landing:IsA("BasePart") and landing:GetAttribute("ERTop") then
    column.Transparency = 1
    local frame = CFrame.new(landing:GetAttribute("ERTop")-V(0,2,0))*landing.CFrame.Rotation
    local base = skin(kit,"RockSupportLow",art,frame,V((landing.Size.X-.6)/10,.75,(landing.Size.Z-.5)/6))
    base.Name = name .. "_Island"
    for _, part in base:GetDescendants() do
     if part:IsA("BasePart") and part:GetAttribute("ERMaterial") == "Green" then part.Color = Color3.fromRGB(232,212,168) end
    end
   end
  end
 end
 local pivot = root:GetPivot()
 local function W(x,y,z) return pivot*CFrame.new(x*.75,y,z*.75) end
 for _, tier in root.Decoration.CentralLandmark:GetChildren() do
  if tier:IsA("BasePart") then tier.Transparency, tier.CanCollide, tier.CanTouch, tier.CanQuery = 1,false,false,false end
 end
 local landmark = skin(kit,"EggCoral",art,W(0,0,10),Vector3.one*5.75)
 landmark.Name = "CentralEgg"
 for _, part in landmark:GetDescendants() do
  if part:IsA("BasePart") then part.Color = Color3.fromRGB(255,240,202) end
 end
 skin(kit,"NestRing",art,W(0,-1,10),Vector3.one*3.3)
 local masses={W(-115,0,105),W(-224,3,-65),W(118,26,-107),W(181,24,79)}
 local names={"NurseryWallBay","SortingShed","MintArchWindow","NurseryWallBay"}
 for index, frame in masses do skin(kit,names[index],art,frame) end
 for _, part in root.Decoration:GetChildren() do
  if part:IsA("BasePart") and part.Name=="DistrictRoughMass" then part.Transparency=1 end
 end
 root:SetAttribute("ERMechanismArt",true)
 root:SetAttribute("Phase2Assembly","Approved kit with deliberately reassessed ER_GUARDIAN_SWEEP_C03 add-on")
end
return Presentation
