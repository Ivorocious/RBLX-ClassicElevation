--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Artwork = require(ReplicatedStorage.Config.VotingArtwork)
local Capsule = {}

local function frame(parent: Instance, name: string): Frame
 local item = Instance.new("Frame")
 item.Name,item.BackgroundTransparency,item.BorderSizePixel,item.Parent = name,1,0,parent
 return item
end

local function rounded(item: GuiObject, radius: number)
 local corner = Instance.new("UICorner")
 corner.CornerRadius,corner.Parent = UDim.new(0,radius),item
end

local function enamel(item: GuiObject, top: Color3, bottom: Color3)
 local gradient = Instance.new("UIGradient")
 gradient.Name,gradient.Rotation,gradient.Color,gradient.Parent = "Enamel",90,ColorSequence.new(top,bottom),item
end

local function label(parent: Instance, name: string, text: string, size: number): TextLabel
 local item = Instance.new("TextLabel")
 item.Name,item.Text,item.TextSize,item.Font = name,text,size,Enum.Font.FredokaOne
 item.BackgroundTransparency,item.BorderSizePixel,item.TextColor3 = 1,0,Color3.fromRGB(9,30,88)
 item:SetAttribute("BaseTextSize",size)
 item.TextTruncate,item.Parent = Enum.TextTruncate.None,parent
 return item
end

function Capsule.Create(parent: Instance, name: string)
 local root = frame(parent,name)
 root.BackgroundTransparency,root.BackgroundColor3 = 0,Color3.fromRGB(253,254,255)
 rounded(root,25)
 local rim = Instance.new("UIStroke")
 rim.Name,rim.ApplyStrokeMode,rim.Color,rim.Thickness,rim.Parent = "Rim",Enum.ApplyStrokeMode.Border,Color3.fromRGB(9,30,88),3,root
 enamel(root,Color3.new(1,1,1),Color3.fromRGB(241,246,255))
 local scale = Instance.new("UIScale")
 scale.Name,scale.Parent = "LayoutScale",root
 local clock = Instance.new("ImageLabel")
 clock.Name,clock.BackgroundTransparency,clock.BorderSizePixel = "ClockArtwork",1,0
 clock.Image,clock.ImageRectOffset,clock.ImageRectSize = Artwork.Clock,Artwork.ClockBounds.Min,Artwork.ClockBounds.Max-Artwork.ClockBounds.Min
 clock.ScaleType,clock.Parent = Enum.ScaleType.Fit,root
 local heading = label(root,"Heading","WAITING",19)
 local time = label(root,"Timer","Waiting",40)
 local track = frame(root,"ProgressTrack")
 track.BackgroundTransparency,track.BackgroundColor3 = 0,Color3.fromRGB(205,213,227)
 rounded(track,20)
 local remaining = frame(track,"Remaining")
 remaining.BackgroundTransparency,remaining.BackgroundColor3 = 0,Color3.fromRGB(129,163,255)
 rounded(remaining,20)
 enamel(remaining,Color3.fromRGB(176,203,255),Color3.fromRGB(103,128,255))
 return {Root=root,Scale=scale,Clock=clock,Heading=heading,Time=time,Track=track,Remaining=remaining}
end

function Capsule.Resize(ui: any, width: number, height: number, compact: boolean?)
 ui.Root.Size = UDim2.fromOffset(width,height)
 local small = compact == true
 local short = not small and height<90
 ui.Clock.Position = if small then UDim2.fromOffset(8,4) elseif short then UDim2.fromOffset(12,10) else UDim2.fromOffset(17,10)
 local clockSize = if small then 32 elseif short then 40 else 58
 ui.Clock.Size = UDim2.fromOffset(clockSize,clockSize)
 ui.Heading.Position = if small then UDim2.fromOffset(48,4) elseif short then UDim2.fromOffset(56,4) else UDim2.fromOffset(90,4)
 ui.Heading.Size = UDim2.fromOffset(if small then 84 elseif short then width-66 else width-118,24)
 ui.Time.Position = if small then UDim2.fromOffset(132,0) elseif short then UDim2.fromOffset(54,25) else UDim2.fromOffset(90,24)
 ui.Time.Size = UDim2.fromOffset(if small then width-140 elseif short then width-64 else width-118,if small or short then 34 else 44)
 ui.Track.Position = UDim2.new(0,if small then 48 elseif short then 12 else 18,1,if small then -9 elseif short then -15 else -20)
 ui.Track.Size = UDim2.new(1,if small then -60 elseif short then -24 else -36,0,if small then 4 elseif short then 6 else 11)
end

function Capsule.DesktopScale(width: number, height: number): number
 return math.min(width/1650,height/880)
end

function Capsule.UseDesktopLayout(width: number, height: number): boolean
 return width>=900 and height>=550
end

return Capsule
