--!strict
local Icons = {}
local assets = {
 Gold="rbxassetid://96023015516097", Keys="rbxassetid://132360820543921",
 Shop="rbxassetid://106083374168010", MyRacer="rbxassetid://77076668228165",
 Records="rbxassetid://112664416206266", Settings="rbxassetid://96887777594635",
 Clock="rbxassetid://84965117445536", Check="rbxassetid://131366992809603",
 Chevron="rbxassetid://86042545292339",
}
Icons.Assets = assets
type Sprite = {bounds: Rect, height: number, canvas: Vector2?}
local sprites: {[string]: Sprite} = {
 Gold={bounds=Rect.new(288,233,1018,952),height=63},
 Keys={bounds=Rect.new(414,232,997,998),height=61},
 Shop={bounds=Rect.new(277,191,1034,1007),height=61},
 MyRacer={bounds=Rect.new(307,259,1005,944),height=60},
 Records={bounds=Rect.new(238,247,1074,976),height=58},
 Settings={bounds=Rect.new(278,270,1034,1005),height=59},
 Clock={bounds=Rect.new(94,106,1160,1173),height=64,canvas=Vector2.new(1254,1254)},
 Check={bounds=Rect.new(285,242,1021,969),height=60},
 Chevron={bounds=Rect.new(586,405,812,792),height=52},
}
local canvas = Vector2.new(1312,1199)
function Icons.Create(parent: Instance, kind: string, position: UDim2, size: number): Frame
 local frame = Instance.new("Frame")
 frame.Name,frame.Position,frame.Size = kind.."Icon",position,UDim2.fromOffset(64,64)
 frame.BackgroundTransparency,frame.Parent = 1,parent
 local scale = Instance.new("UIScale")
 scale.Scale,scale.Parent = size/64,frame
 local asset = (assets :: {[string]:string})[kind]
 local sprite = sprites[kind]
 if asset and sprite then
  local clip = Instance.new("Frame")
  clip.Name,clip.BackgroundTransparency,clip.ClipsDescendants = "Sprite",1,true
  clip.Position,clip.Size,clip.Parent = UDim2.fromOffset(-4,-2),UDim2.fromOffset(72,68),frame
  local bounds = sprite.bounds
  local extent,center = bounds.Max-bounds.Min,(bounds.Min+bounds.Max)/2
  -- Use visible pixels so transparent padding never changes an icon's apparent size.
  local unit = math.min(sprite.height/extent.Y,68/extent.X)
  local spriteCanvas = sprite.canvas or canvas
  local image = Instance.new("ImageLabel")
  image.Name,image.Image,image.BackgroundTransparency = "Artwork",asset,1
  image.Position = UDim2.fromOffset(36-center.X*unit,34-center.Y*unit)
  image.Size,image.ScaleType,image.Parent = UDim2.fromOffset(spriteCanvas.X*unit,spriteCanvas.Y*unit),Enum.ScaleType.Stretch,clip
 end
 return frame
end
return Icons
