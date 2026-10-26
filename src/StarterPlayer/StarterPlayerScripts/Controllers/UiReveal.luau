--!strict
local Reveal = {}
local function properties(item: Instance): {string}
 local names = {}
 if item:IsA("GuiObject") then table.insert(names,"BackgroundTransparency") end
 if item:IsA("TextLabel") or item:IsA("TextButton") then
  table.insert(names,"TextTransparency"); table.insert(names,"TextStrokeTransparency")
 elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then table.insert(names,"ImageTransparency")
 elseif item:IsA("UIStroke") then table.insert(names,"Transparency") end
 return names
end

function Reveal.Create(groups: {any})
 local targets = {}
 local function capture()
  table.clear(targets)
  for _, group in groups do
   group.position = group.frame.Position
   local entries = {group.frame}
   for _, item in group.frame:GetDescendants() do table.insert(entries,item) end
   group.targets = {}
   for _, item in entries do
    for _, property in properties(item) do
     table.insert(group.targets,{item=item,property=property,value=(item :: any)[property]})
    end
   end
   table.insert(targets,group)
  end
 end
 local function restore()
  for _, group in targets do
			group.frame.Position = group.position
			group.frame:SetAttribute("RevealAlpha",1)
			group.frame:SetAttribute("RevealOffset",0)
   for _, target in group.targets do
    if target.item.Parent then (target.item :: any)[target.property] = target.value end
   end
  end
 end
 local function apply(elapsed: number, motion: boolean): boolean
  local duration = if motion then .3 else .18
  for _, group in targets do
   local delay = if motion then group.delay else 0
   local t = math.clamp((elapsed-delay)/duration,0,1)
   local alpha = 1-(1-t)^3
   local offset = if motion then group.direction*16*(1-alpha) else Vector2.zero
   group.frame.Position = group.position+UDim2.fromOffset(offset.X,offset.Y)
   group.frame:SetAttribute("RevealAlpha",alpha)
   group.frame:SetAttribute("RevealOffset",offset.Magnitude)
   for _, target in group.targets do
    if target.item.Parent then (target.item :: any)[target.property] = 1-(1-target.value)*alpha end
   end
  end
  return elapsed >= (if motion then .48 else .18)
 end
 capture()
 return {Capture=capture,Restore=restore,Apply=apply}
end
return Reveal
