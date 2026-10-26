--!nonstrict
local RestStops={Revision="ER_P3_REST_STOPS_A02"}
local V=Vector3.new
local cream=Color3.fromRGB(255,240,202)
local mint=Color3.fromRGB(104,205,176)
local honey=Color3.fromRGB(185,123,67)
local ink=Color3.fromRGB(46,66,81)

local function padFor(course,name)
 return if name=="Start" then course.Start else course.Obstacles[name]
end

local function part(parent,name,size,frame,color)
 local p=Instance.new("Part")
 p.Name,p.Size,p.CFrame,p.Color=name,size,frame,color
 p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
 p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 p:SetAttribute("ERWorldRole","ContainedRestStopTrim")
 p.Parent=parent
 return p
end

local function graphic(group,pad)
 local gui=Instance.new("SurfaceGui")
 gui.Name="DeckMarking"
 gui:SetAttribute("TargetPad",pad.Name)
 gui.Adornee,gui.Face,gui.CanvasSize=pad,Enum.NormalId.Top,Vector2.new(pad.Size.Z*40,pad.Size.X*40)
 gui.LightInfluence,gui.SizingMode=1,Enum.SurfaceGuiSizingMode.FixedSize
 gui.ZOffset=.02
 gui.Parent=group
 return gui
end

local function stripe(gui,name,position,size,color)
 local frame=Instance.new("Frame")
 frame.Name,frame.Position,frame.Size=name,position,size
 frame.BackgroundColor3,frame.BorderSizePixel=color,0
 frame.Parent=gui
 return frame
end

local function deck(group,pad)
 local top=pad.CFrame*CFrame.new(0,pad.Size.Y/2,0)
 local w,d=pad.Size.X,pad.Size.Z
 part(group,"MintApron",V(w-.12,.7,d-.12),top*CFrame.new(0,-2.15,0),mint)
 part(group,"HoneyReveal",V(w-.8,.25,d-.8),top*CFrame.new(0,-2.625,0),honey)
 for _,side in {-1,1}do
  part(group,"SideInlay"..side,V(.12,.9,d*.56),top*CFrame.new(side*(w/2-.035),-1,0),mint)
 end
 return graphic(group,pad)
end

function RestStops.Bind(course,world)
 local group=assert(world:FindFirstChild("RestStops"))
 course.Start.Color=cream
 for index=1,4 do
  local pad=course.Obstacles["CP"..index.."_Pocket"]
  local trigger=course.Checkpoints[string.format("Checkpoint_%03d",index)]
  pad.Color=cream
  trigger.Transparency=1
  for _,gui in trigger:GetDescendants()do
   if gui:IsA("SurfaceGui")then gui.Enabled=false end
  end
 end
 for _,post in course.StartPen.GateSupports:GetChildren()do
  if post:IsA("BasePart")and post.Name=="GatePost"then post.Color=mint end
 end
 for _,gui in group:GetDescendants()do
  if gui:IsA("SurfaceGui")then gui.Adornee=padFor(course,gui:GetAttribute("TargetPad"))end
 end
end

function RestStops.Apply(course,world)
 assert(not world:FindFirstChild("RestStops"),"Preserve the installed rest-stop presentation")
 local group=Instance.new("Model")
 group.Name,group.WorldPivot="RestStops",course:GetPivot()
 group:SetAttribute("ERPresentationRevision",RestStops.Revision)
 group:SetAttribute("ERWorldRole","ContainedRestStopTrim")
 group.Parent=world
 for index=1,4 do
  local pad=course.Obstacles["CP"..index.."_Pocket"]
  local station=Instance.new("Model")
  station.Name,station.WorldPivot="Checkpoint"..index,pad.CFrame
  station.Parent=group
  local gui=deck(station,pad)
  for _,side in {0,1}do
   stripe(gui,"ArrivalBand"..side,UDim2.fromScale(.04,if side==0 then .06 else .89),UDim2.fromScale(.92,.05),mint)
  end
  for _,x in {.035,.94}do
   stripe(gui,"Corner"..x,UDim2.fromScale(x,.19),UDim2.fromScale(.025,.13),honey)
   stripe(gui,"CornerReturn"..x,UDim2.fromScale(x,.68),UDim2.fromScale(.025,.13),honey)
  end
  local number=Instance.new("TextLabel")
  number.Name,number.BackgroundTransparency="CheckpointNumber",1
  number.AnchorPoint=Vector2.new(.5,.5)
  number.Position,number.Size=UDim2.fromScale(.5,.5),UDim2.fromOffset(220,220)
  number.Rotation=90
  number.Text,number.Font,number.TextColor3=tostring(index),Enum.Font.GothamBlack,ink
  number.TextScaled=true
  number.Parent=gui
 end
 local start=Instance.new("Model")
 start.Name,start.WorldPivot="StartCourt",course.Start.CFrame
 start.Parent=group
 local gui=deck(start,course.Start)
 for _,x in {.035,.94}do
  stripe(gui,"GridLane"..x,UDim2.fromScale(x,.06),UDim2.fromScale(.025,.88),mint)
  for index=0,4 do
   stripe(gui,"GridMark"..x.."_"..index,UDim2.fromScale(if x<.5 then .06 else .89,.16+index*.14),UDim2.fromScale(.05,.018),honey)
  end
 end
 local lintel=course.StartPen.GateVisuals.GateLintel
 part(start,"HeaderCoping",V(lintel.Size.X+.12,.3,lintel.Size.Z+.12),lintel.CFrame*CFrame.new(0,lintel.Size.Y/2+.15,0),honey)
 RestStops.Bind(course,world)
 return group
end

return RestStops
