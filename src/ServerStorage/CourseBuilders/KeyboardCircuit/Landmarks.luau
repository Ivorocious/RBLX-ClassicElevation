--!strict
local Parts = require(script.Parent.Parts)
local Landmarks = {}
local function decoration(unit: Model)
 for _,p in unit:GetDescendants() do if p:IsA("BasePart") then p.CanCollide,p.CanQuery,p.CanTouch=false,false,false; p:SetAttribute("Role","Decoration") end end
end
function Landmarks.Magazine(parent: Instance, cf: CFrame, template: MeshPart): Model
 local unit=Parts.Model(parent,"CapMagazine")
 local sand,teal=Parts.Palette.Thocky[1],Parts.Palette.Thocky[2]
 Parts.Block(unit,"BackHousing",Vector3.new(11,22,4),cf*CFrame.new(0,11,2),teal,false)
 for _,x in {-5.8,5.8} do
  Parts.Block(unit,"SideHousing",Vector3.new(2.5,24,8),cf*CFrame.new(x,12,0),teal,false)
  Parts.Block(unit,"SideInsert",Vector3.new(.3,5,3.5),cf*CFrame.new(x*1.23,13,0),sand,false)
  Parts.Block(unit,"Foot",Vector3.new(4,2,9),cf*CFrame.new(x,0,0),Parts.Charcoal,false)
 end
 for i=1,3 do
  local y=5+i*5
  local tray=Parts.Model(unit,"Drawer"..i)
  Parts.Bank(tray,"StoredCaps",template,cf*CFrame.new(0,y,-4),7,4,if i==1 then "Creamy" else if i==2 then "Thocky" else "Clacky")
  Parts.Block(tray,"DrawerFront",Vector3.new(10,.9,.6),cf*CFrame.new(0,y-.7,-7),sand,false)
  for _,x in {-5,5} do Parts.Block(tray,"DrawerSide",Vector3.new(.6,1.4,6),cf*CFrame.new(x,y-.7,-4),sand,false) end
 end
 Parts.Block(unit,"TopCap",Vector3.new(9,1.2,5),cf*CFrame.new(0,24,0),sand,false)
 Parts.Block(unit,"Outlet",Vector3.new(5,4,.4),cf*CFrame.new(0,3,-2.3),Parts.Charcoal,false)
 Parts.Block(unit,"OutletLip",Vector3.new(5.8,.6,3),cf*CFrame.new(0,1,-3.3),teal,false)
 decoration(unit)
 unit.WorldPivot=cf
 return unit
end
function Landmarks.Rack(parent: Instance, cf: CFrame, template: MeshPart): Model
 local unit=Parts.Model(parent,"KeyboardRack")
 unit.WorldPivot=cf
 for _,x in {-8,8} do
  Parts.Block(unit,"RackPost",Vector3.new(2,18,3),cf*CFrame.new(x,7,1)*CFrame.Angles(-.15,0,0),Parts.Charcoal,false)
  Parts.Block(unit,"Foot",Vector3.new(4,1.5,8),cf*CFrame.new(x,-2,0),Parts.Charcoal,false)
 end
 for i=1,2 do
  local tray=Parts.Bank(unit,"KeyboardTray"..i,template,cf*CFrame.new(0,3+i*6,-1)*CFrame.Angles(.35,0,0),11,5,"Creamy")
  for _,x in {-7.8,7.8} do Parts.Cylinder(tray,"Pivot",cf*CFrame.new(x,3+i*6,0),.8,2.5,Parts.Palette.Thocky[1]) end
 end
 decoration(unit)
 return unit
end
function Landmarks.USB(parent: Instance, cf: CFrame): Model
 local unit=Parts.Model(parent,"USBPortal")
 unit.WorldPivot=cf
 for _,x in {-8,8} do
  Parts.Block(unit,"Housing",Vector3.new(4,17,6),cf*CFrame.new(x,8.5,0),Parts.Charcoal,false)
  Parts.Warning(unit,cf*CFrame.new(x,7,-3.05)*CFrame.Angles(math.pi/2,0,0),Vector3.new(2.5,.2,6))
 end
 Parts.Block(unit,"Connector",Vector3.new(20,5,8),cf*CFrame.new(0,18,0),Color3.fromRGB(188,198,208),false)
 Parts.Block(unit,"DarkSocket",Vector3.new(13,3,.3),cf*CFrame.new(0,17.8,-4.2),Parts.Charcoal,false)
 for i=1,4 do Parts.Block(unit,"Contact",Vector3.new(1.5,2,.7),cf*CFrame.new((i-2.5)*3,17.5,-4.5),Parts.Yellow,false) end
 decoration(unit)
 return unit
end
function Landmarks.SplitShell(parent: Instance, cf: CFrame, template: MeshPart): Model
 local unit=Parts.Model(parent,"SplitKeyboardShells")
 unit.WorldPivot=cf
 for _,side in {-1,1} do
  local half=Parts.Model(unit,if side==-1 then "LeftShell" else "RightShell")
  local pose=cf*CFrame.new(side*7,3,0)*CFrame.Angles(.2,side*.25,side*.12)
  Parts.Block(half,"Housing",Vector3.new(10,5,13),pose,Parts.Palette.Clacky[2],false)
  Parts.Bank(half,"KeyboardFace",template,pose*CFrame.new(0,3.4,0),6,8,"Clacky")
  Parts.Block(half,"Port",Vector3.new(5,1.5,.3),pose*CFrame.new(0,0,-6.6),Parts.Charcoal,false)
 end
 decoration(unit)
 return unit
end
function Landmarks.Dial(parent: Instance, cf: CFrame): Model
 local unit=Parts.Model(parent,"RotaryDial")
 unit.WorldPivot=cf
 Parts.Support(unit,cf*CFrame.new(0,7,0),6,Parts.Palette.Clicky[2])
 Parts.Cylinder(unit,"CoralBase",cf*CFrame.new(0,7,0)*CFrame.Angles(0,0,math.pi/2),2,11,Parts.Palette.Clicky[3])
 Parts.Cylinder(unit,"Dial",cf*CFrame.new(0,11,0)*CFrame.Angles(0,0,math.pi/2),7,9,Parts.Palette.Clicky[2])
 for i=1,10 do
  local angle=i*math.pi/5
  Parts.Block(unit,"Grip",Vector3.new(1,6,1),cf*CFrame.new(math.cos(angle)*4.5,11,math.sin(angle)*4.5)*CFrame.Angles(0,-angle,0),Parts.Palette.Clicky[2],false)
 end
 Parts.Block(unit,"Indicator",Vector3.new(.6,.2,3),cf*CFrame.new(0,14.6,-1),Parts.Palette.Clicky[1],false)
 decoration(unit)
 return unit
end
return Landmarks

