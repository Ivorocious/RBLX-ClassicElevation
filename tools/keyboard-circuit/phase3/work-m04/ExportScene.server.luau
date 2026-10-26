--!strict
assert(game.PlaceId==85558151074819 and not game.RunService:IsRunning())
local c=workspace:FindFirstChild("KeyboardCircuit_P3_M04_01") or game.ServerStorage.KeyboardCircuitPhase2Archive.Phase3FinalTuning20261009.KeyboardCircuit_P3_M04_01
local parts,labels,rectangles={}, {}, {}
local function guiFor(item)
 local current=item.Parent
 while current and current~=c do
  if current:IsA("SurfaceGui") then return current end
  if current:IsA("GuiObject") and not current.Visible then return nil end
  current=current.Parent
 end
 return nil
end
local function frame(item,gui)
 if item==gui then return CFrame.identity,gui.CanvasSize end
 local parentTransform,parentSize=frame(item.Parent,gui)
 local size=Vector2.new(parentSize.X*item.Size.X.Scale+item.Size.X.Offset,parentSize.Y*item.Size.Y.Scale+item.Size.Y.Offset)
 local center=Vector2.new(parentSize.X*item.Position.X.Scale+item.Position.X.Offset+(0.5-item.AnchorPoint.X)*size.X,
  parentSize.Y*item.Position.Y.Scale+item.Position.Y.Offset+(0.5-item.AnchorPoint.Y)*size.Y)
 local pose=parentTransform*CFrame.new(center.X,center.Y,0)*CFrame.Angles(0,0,math.rad(item.Rotation))
 return pose*CFrame.new(-size.X/2,-size.Y/2,0),size
end
local function placement(item,gui)
 local pose,size=frame(item,gui)
 local center=pose:PointToWorldSpace(Vector3.new(size.X/2,size.Y/2,0))
 return {center={center.X/gui.CanvasSize.X,center.Y/gui.CanvasSize.Y},size={size.X/gui.CanvasSize.X,size.Y/gui.CanvasSize.Y},
 rotation=math.atan2(pose.RightVector.Y,pose.RightVector.X)}
end
for _,item in c:GetDescendants() do
 if item:IsA("BasePart") then
  table.insert(parts,{name=item.Name,path=item:GetFullName():sub(#c:GetFullName()+2),class=item.ClassName,
   cf={item.CFrame:GetComponents()},size={item.Size.X,item.Size.Y,item.Size.Z},color={item.Color.R,item.Color.G,item.Color.B},
   material=item.Material.Name,transparency=item.Transparency,castShadow=item.CastShadow,effectKind=item:GetAttribute("ArchiveEffectKind"),activeTransparency=item:GetAttribute("ActiveTransparency"),effectFamily=item:GetAttribute("ArchiveEffectFamily"),shape=if item:IsA("Part") then item.Shape.Name else "Block",
   artwork=item:IsDescendantOf(c.MapEnvironment)})
 elseif item:IsA("GuiObject") and item.Visible then
  local gui=guiFor(item)
  if not gui or not gui.Enabled or not gui.Parent:IsA("BasePart") then continue end
  local data=placement(item,gui)
  data.partPath=gui.Parent:GetFullName():sub(#c:GetFullName()+2)
  data.path=item:GetFullName():sub(#c:GetFullName()+2)
  data.face=gui.Face.Name
  if item:IsA("TextLabel") and item.Text~="" and item.TextTransparency<1 then
   data.text=item.Text
   data.color={item.TextColor3.R,item.TextColor3.G,item.TextColor3.B}
   data.align=item.TextXAlignment.Name
   data.font=item.Font.Name
   data.wrapped=item.TextWrapped
   table.insert(labels,data)
  elseif item:IsA("Frame") and item.BackgroundTransparency<.9 then
   data.color={item.BackgroundColor3.R,item.BackgroundColor3.G,item.BackgroundColor3.B}
   table.insert(rectangles,data)
  end
 end
end
local origin=c:GetAttribute("Origin")
local data={candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),origin={origin.X,origin.Y,origin.Z},
 parts=parts,labels=labels,rectangles=rectangles,
 limits="Native geometry and GUI text/layout exported without moving Studio camera. Offline reconstruction uses existing K02 source mesh; fonts, lighting, transparency and rounded GUI corners are approximations. Edit warning displays are intentionally STOPPED; live state transitions verified separately."}
local encoding=game:GetService("EncodingService")
shared.KCP3M04SceneExport02=buffer.tostring(encoding:Base64Encode(encoding:CompressBuffer(buffer.fromstring(game.HttpService:JSONEncode(data)),Enum.CompressionAlgorithm.Zstd,3)))
return game.HttpService:JSONEncode({parts=#parts,labels=#labels,rectangles=#rectangles,base64Chars=#shared.KCP3M04SceneExport02,limits=data.limits})
