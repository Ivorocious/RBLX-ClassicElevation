--!strict
local Builder={}
local Navy=Color3.fromRGB(13,30,52)
local Cream=Color3.fromRGB(250,241,217)
local Gold=Color3.fromRGB(217,174,69)
local function part(parent,name,frame,size,color)
 local p=Instance.new("Part")
 p.Name,p.Size,p.CFrame,p.Color=name,size,frame,color
 p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
 p.Material,p.Parent=Enum.Material.SmoothPlastic,parent
 return p
end
local function surface(p,face,size)
 local gui=Instance.new("SurfaceGui")
 gui.Name,gui.Face,gui.CanvasSize,gui.LightInfluence,gui.Parent="Display",face,size,0,p
 gui.MaxDistance=110
 return gui
end
local function label(parent,name,text,position,size,font,color)
 local l=Instance.new("TextLabel")
 l.Name,l.Text,l.Position,l.Size=name,text,position,size
 l.Font,l.TextColor3,l.BackgroundTransparency=font or Enum.Font.GothamBold,color or Cream,1
 l.TextScaled,l.TextTruncate,l.Parent=true,Enum.TextTruncate.AtEnd,parent
 local limits=Instance.new("UITextSizeConstraint");limits.MaxTextSize,limits.MinTextSize,limits.Parent=64,16,l
 return l
end
local function board(parent,name,model,title,subtitle)
 local source
 for _,p in model:GetDescendants() do if p:IsA("BasePart") and p.Name:find("__DeepBlue__",1,true) then source=p;break end end
 if not source then return end
 local faceY=source.CFrame:PointToObjectSpace(model:GetPivot().Position).Y+8
 local plate=part(parent,name,source.CFrame*CFrame.new(0,faceY,-source.Size.Z/2-.04),Vector3.new(source.Size.X-.9,11.4,.07),Navy)
 local gui=surface(plate,Enum.NormalId.Front,Vector2.new(1000,640))
 label(gui,"Heading",title,UDim2.fromScale(.06,.045),UDim2.fromScale(.88,.09),Enum.Font.FredokaOne)
 label(gui,"Subtitle",subtitle,UDim2.fromScale(.08,.15),UDim2.fromScale(.84,.08),nil,Gold)
 local empty=label(gui,"Empty","No completed races yet",UDim2.fromScale(.08,.43),UDim2.fromScale(.84,.1))
 for i=1,5 do
  local row=Instance.new("Frame");row.Name,row.BackgroundTransparency,row.Size,row.Position,row.Visible,row.Parent="Row"..i,1,UDim2.fromScale(.86,.115),UDim2.fromScale(.07,.28+(i-1)*.127),false,gui
  label(row,"Rank",tostring(i),UDim2.new(),UDim2.fromScale(.08,.8),nil,Gold)
  local racer=label(row,"Racer","",UDim2.fromScale(.12,0),UDim2.fromScale(.64,.8));racer.TextXAlignment=Enum.TextXAlignment.Left
  local value=label(row,"Value","",UDim2.fromScale(.77,0),UDim2.fromScale(.23,.8));value.TextXAlignment=Enum.TextXAlignment.Right
  local line=Instance.new("Frame");line.Size,line.Position,line.BorderSizePixel,line.BackgroundColor3,line.BackgroundTransparency,line.Parent=UDim2.new(1,0,0,1),UDim2.fromScale(0,.96),0,Cream,.85,row
 end
 return plate
end
local function sign(parent,name,position,floorY,rows,backRows)
 local frame=CFrame.new(position)
 local plate=part(parent,name,frame,Vector3.new(5.4,2.6,.18),Cream)
 part(parent,name.."Trim",frame,Vector3.new(5.58,2.78,.12),Gold)
 local postHeight=position.Y-1.3-floorY+.1
 for _,x in {-2.05,2.05} do
  part(parent,name.."Post"..(if x<0 then "Left" else "Right"),CFrame.new(position.X+x,floorY+postHeight/2-.05,position.Z),Vector3.new(.18,postHeight,.18),Navy)
 end
 for _,definition in {{Enum.NormalId.Back,rows},{Enum.NormalId.Front,backRows or rows}} do
  local gui=surface(plate,definition[1],Vector2.new(680,380))
  local count=#definition[2]
  for i,text in definition[2] do label(gui,"Direction"..i,text,UDim2.fromScale(.05,.06+(i-1)*(.88/count)),UDim2.fromScale(.9,.8/count),Enum.Font.FredokaOne,Navy) end
 end
end
function Builder.Ensure(lobby: Model): Folder?
 local existing=lobby:FindFirstChild("LobbyAmenities")
 if existing then return existing :: Folder end
 local editable=lobby:FindFirstChild("Editable")
 local marker=lobby:FindFirstChild("LobbySpawnPadMarker") or lobby:FindFirstChild("PreviewSpawn")
 if not editable or not marker or not marker:IsA("BasePart") then return nil end
 local lower=editable:FindFirstChild("01_Lower")
 local architecture=editable:FindFirstChild("05_Architecture")
 local room=architecture and architecture:FindFirstChild("ShopRoom")
 local wins=lower and lower:FindFirstChild("Lower_Board_Wins")
 local times=lower and lower:FindFirstChild("Lower_Board_Times")
 if not room or not wins or not times then return nil end
 local folder=Instance.new("Folder");folder.Name="LobbyAmenities";folder:SetAttribute("Revision","L1");folder.Parent=lobby
 local boards=Instance.new("Folder");boards.Name,boards.Parent="Records",folder
 board(boards,"SessionWins",wins,"SESSION WINS","This server")
 board(boards,"LatestRace",times,"LATEST RACE","")
 local origin=marker.Position
 local signs=Instance.new("Folder");signs.Name,signs.Parent="Signs",folder
 sign(signs,"Arrival",origin+Vector3.new(12,3.45,-6),origin.Y,{"↓  Grand Arcade","↓  Records","↗  Style"},{"↓  Grand Arcade","↓  Records","↖  Style"})
 sign(signs,"LowerJunction",origin+Vector3.new(11,-14.55,-35),origin.Y-18,{"↑  Grand Arcade","↓  Records"},{"↑  Records","↓  Grand Arcade"})
 sign(signs,"StyleStairs",origin+Vector3.new(28,3.45,-9),origin.Y,{"↑  Style","Upstairs"})
 local shops=Instance.new("Folder");shops.Name,shops.Parent="Shops",folder
 local style=room:FindFirstChild("Collider315")
 if style and style:IsA("BasePart") then
  local trigger=part(shops,"Style",style.CFrame*CFrame.new(0,2.5,-2.25),Vector3.new(.2,.2,.2),Cream);trigger.Transparency=1
  local attachment=Instance.new("Attachment");attachment.Name,attachment.Parent="Interaction",trigger
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name,prompt.ActionText,prompt.ObjectText,prompt.HoldDuration="EditRacer","Change look","Style",.15
  prompt:SetAttribute("LobbyStylePrompt",true)
  prompt.KeyboardKeyCode,prompt.GamepadKeyCode=Enum.KeyCode.E,Enum.KeyCode.ButtonX
  prompt.MaxActivationDistance,prompt.RequiresLineOfSight,prompt.Enabled,prompt.Parent=9,true,false,attachment
 end
 for _,definition in {{"Trails","Collider316"},{"Gear","Collider317"}} do
  local counter=room:FindFirstChild(definition[2])
  if counter and counter:IsA("BasePart") then
   local plaque=part(shops,definition[1].."ComingLater",counter.CFrame*CFrame.new(0,.1,-1.79),Vector3.new(6.4,1.65,.06),Navy)
   label(surface(plaque,Enum.NormalId.Front,Vector2.new(530,130)),"ComingLater","Coming later",UDim2.fromScale(.07,.12),UDim2.fromScale(.86,.76),Enum.Font.FredokaOne,Cream)
  end
 end
 return folder
end
return Builder
