--!strict
local Players=game:GetService("Players")
local ServerStorage=game:GetService("ServerStorage")
local Config=require(game.ReplicatedStorage.Config.GrandArcadeConfig)
local StageState=require(game.ReplicatedStorage.Shared.TournamentStageState)
local Service={}
local stage: Model?
local staging: any
local racers: any
local race: any
local replicas: {[number]: Model}={}
local cacheOrder={}
local pending: {[number]:boolean}={}
local latestTournament=""
local knownCourses={}
local courses: any
local function courseModel(courseId: string): Model?
 local library=ServerStorage:FindFirstChild("CourseLibrary")
 if library then
  for _,model in library:GetChildren() do
   local info=model:FindFirstChild("CourseInfo")
   if model:IsA("Model") and (model:GetAttribute("CourseId")==courseId or (info and info:GetAttribute("CourseId")==courseId)) then return model end
  end
 end
 if courses and courses.GetActiveCourseId()==courseId then return courses.GetActiveCourseModel() end
 return nil
end
local function miniature(bay: Instance,courseId: string?)
 local previous=bay:FindFirstChild("CourseMiniature")
 if previous and previous:GetAttribute("RaceFlowGenerated")~=true then return end
 if previous and previous:GetAttribute("CourseId")==courseId then return end
 if previous then previous:Destroy() end
 if not courseId then return end
 local source=courseModel(courseId)
 if not source then return end
 local start,finish=source:FindFirstChild("Start"),source:FindFirstChild("Finish")
 if not start or not start:IsA("BasePart") or not finish or not finish:IsA("BasePart") then return end
 local checkpoints={}
 local folder=source:FindFirstChild("Checkpoints")
 if folder then
  for _,part in folder:GetChildren() do
   local index=tonumber(part.Name:match("^Checkpoint_(%d+)$"))
   if index and part:IsA("BasePart") then table.insert(checkpoints,{index=index,part=part}) end
  end
 end
 table.sort(checkpoints,function(a,b) return a.index<b.index end)
 local route={start}
 for _,row in checkpoints do table.insert(route,row.part) end
 table.insert(route,finish)
 local samples=StageState.RouteSamples(route,15)
 local low,high=samples[1].Position,samples[1].Position
 for _,part in samples do low=low:Min(part.Position);high=high:Max(part.Position) end
 local center=(low+high)/2;local extent=high-low
 local scale=8/math.max(extent.X,extent.Y,extent.Z,1)
 local model=Instance.new("Model");model.Name="CourseMiniature"
 model:SetAttribute("RaceFlowGenerated",true);model:SetAttribute("CourseId",courseId)
 model:SetAttribute("Representation","Start, sampled ordered checkpoints, finish")
 local panel=bay:FindFirstChild("MapPanel") :: BasePart
 local frame=panel.CFrame*CFrame.new(0,.7,6)
 local previousPosition: Vector3?=nil
 local function part(name: string,size: Vector3,cframe: CFrame,color: Color3)
  local item=Instance.new("Part");item.Name,item.Size,item.CFrame,item.Color=name,size,cframe,color
  item.Anchored,item.CanCollide,item.CanTouch,item.CanQuery=true,false,false,false
  item.Material,item.Parent=Enum.Material.Neon,model
 end
 for index,marker in samples do
  local position=frame:PointToWorldSpace((marker.Position-center)*scale)
  local color=if index==1 then Color3.fromRGB(120,240,160) elseif index==#samples then Color3.fromRGB(255,146,126) else Color3.fromRGB(255,217,111)
  part(marker.Name,Vector3.new(.35,.22,.35),CFrame.new(position),color)
  if previousPosition and (position-previousPosition).Magnitude>.01 then
   local length=(position-previousPosition).Magnitude
   part("RouteSegment"..index,Vector3.new(.08,.08,length),CFrame.lookAt((position+previousPosition)/2,position),Color3.fromRGB(140,194,230))
  end
  previousPosition=position
 end
 model.Parent=bay
end
local function host(parent,frame)
 local model=Instance.new("Model");model.Name="Presenter"
 for _,row in {{"Torso",Vector3.new(2,2,1),Vector3.new(0,3,0),Color3.fromRGB(20,42,74)},
  {"Head",Vector3.new(1.8,1.2,1.2),Vector3.new(0,4.6,0),Color3.fromRGB(255,224,174)},
  {"LeftArm",Vector3.new(1,2,1),Vector3.new(-1.5,3,0),Color3.fromRGB(245,235,210)},
  {"RightArm",Vector3.new(1,2,1),Vector3.new(1.5,3,0),Color3.fromRGB(245,235,210)},
  {"LeftLeg",Vector3.new(1,2,1),Vector3.new(-.5,1,0),Color3.fromRGB(20,42,74)},
  {"RightLeg",Vector3.new(1,2,1),Vector3.new(.5,1,0),Color3.fromRGB(20,42,74)}} do
  local p=Instance.new("Part");p.Name,p.Size,p.CFrame,p.Color=row[1],row[2],frame*CFrame.new(row[3]),row[4]
  p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false;p.Parent=model
  if p.Name=="Head" then
   local mesh=Instance.new("SpecialMesh");mesh.MeshType,mesh.Parent=Enum.MeshType.Head,p
   local face=Instance.new("Decal");face.Name,face.Texture,face.Face,face.Parent="Face","rbxasset://textures/face.png",Enum.NormalId.Front,p
  end
 end
 model.WorldPivot=frame;model.Parent=parent
 return model
end
local function template(userId: number): Model?
 if replicas[userId] then return replicas[userId] end
 if pending[userId] then
  local deadline=os.clock()+10
  repeat task.wait(.05) until not pending[userId] or os.clock()>=deadline
  return replicas[userId]
 end
 pending[userId]=true
 local ok,result=pcall(function()
  local player=Players:GetPlayerByUserId(userId)
  local humanoid=player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  local description=if humanoid then humanoid:GetAppliedDescription() else Players:GetHumanoidDescriptionFromUserIdAsync(userId)
  description.HatAccessory,description.HairAccessory,description.FaceAccessory="","",""
  description.NeckAccessory,description.ShouldersAccessory,description.FrontAccessory,description.BackAccessory,description.WaistAccessory="","","","",""
  local model=Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R6)
  description:Destroy()
  for _,item in model:GetDescendants() do
   if item:IsA("LuaSourceContainer") or item:IsA("Accessory") or item:IsA("Humanoid") or item:IsA("Motor6D") then item:Destroy()
   elseif item:IsA("BasePart") then item.Anchored,item.CanCollide,item.CanTouch,item.CanQuery=true,false,false,false end
  end
  model:ScaleTo(Config.MiniatureScale)
  return model
 end)
 pending[userId]=nil
 if not ok then return nil end
 replicas[userId]=result
 table.insert(cacheOrder,userId)
 if #cacheOrder>32 then local oldest=table.remove(cacheOrder,1);if replicas[oldest] then replicas[oldest]:Destroy();replicas[oldest]=nil end end
 return result
end
function Service.Init(context: any)
 courses=context.Services.CourseService
 staging=context.Services.StagingService
 racers=context.Services.PlayerRaceService
 race=context.Services.RaceService
 local installed=workspace:FindFirstChild("GrandArcade")
 stage=if installed and installed:IsA("Model") then installed else nil
 if not stage then warn("Grand Arcade stage is not installed; restore the saved native model") end
end
function Service.Start()
 if not stage then return end
 local marker=stage.Displays.HostSpot
 if not stage:FindFirstChild("Presenter") then host(stage,marker.CFrame) end
 local cooldown: {[Player]:number}={}
 stage.FallReturn.Touched:Connect(function(hit)
  local character=hit:FindFirstAncestorOfClass("Model")
  local player=character and Players:GetPlayerFromCharacter(character)
  if not player or not character then return end
  if race and race.IsRaceActive() and racers.IsOfficialRacer(player) then return end
  local root=character:FindFirstChild("HumanoidRootPart")
  if not root or not root:IsA("BasePart") or math.abs(root.Position.Y-stage.FallReturn.Position.Y)>12 then return end
  if os.clock()-(cooldown[player] or 0)<2 then return end
  cooldown[player]=os.clock()
  if staging then staging.ReturnPlayersToLobby({player},"Stage safety return") end
 end)
 Players.PlayerRemoving:Connect(function(player) cooldown[player]=nil end)
end
function Service.IsAvailable(): boolean return stage~=nil end
-- Arch screen looks (UI overhaul "Next course"): race-number badge, status pill, an Up next glow,
-- dimmed upcoming arches and a winner chip. What each screen shows and when it updates is unchanged.
local NAVY,SUN,MINT=Color3.fromHex("10215C"),Color3.fromHex("FFD338"),Color3.fromHex("2EE6A6")
local function rounded(item: GuiObject,radius: number)
 if item:FindFirstChildOfClass("UICorner") then return end
 local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(0,radius),item
end
local function screenLooks(panel: Instance,index: number,status: string,winner: any?)
 local dim=panel:FindFirstChild("Dim")
 if not dim then
  dim=Instance.new("Frame");dim.Name,dim.BorderSizePixel,dim.BackgroundColor3,dim.Size,dim.ZIndex,dim.Parent="Dim",0,NAVY,UDim2.fromScale(1,1),2,panel
 end
 dim.BackgroundTransparency=if status=="Upcoming" then .5 else 1
 local glow=panel:FindFirstChild("Glow")
 if not glow then
  glow=Instance.new("Frame");glow.Name,glow.BackgroundTransparency,glow.Size,glow.ZIndex,glow.Parent="Glow",1,UDim2.fromScale(1,1),3,panel
  local edge=Instance.new("UIStroke");edge.Thickness,edge.Color,edge.ApplyStrokeMode,edge.Parent=14,SUN,Enum.ApplyStrokeMode.Border,glow
 end
 glow.Visible=status=="Active" or status=="Preparing"
 local badge=panel:FindFirstChild("NumberBadge")
 if not badge then
  badge=Instance.new("TextLabel");badge.Name,badge.Size,badge.Position,badge.ZIndex="NumberBadge",UDim2.fromOffset(84,84),UDim2.fromOffset(22,22),4
  badge.BackgroundColor3,badge.TextColor3,badge.Font,badge.TextSize=SUN,NAVY,Enum.Font.LuckiestGuy,52
  rounded(badge,42)
  local edge=Instance.new("UIStroke");edge.Thickness,edge.Color,edge.ApplyStrokeMode,edge.Parent=6,NAVY,Enum.ApplyStrokeMode.Border,badge
  badge.Parent=panel
 end
 badge.Text=tostring(index)
 local tag=panel:FindFirstChild("UpNext")
 if not tag then
  tag=Instance.new("TextLabel");tag.Name,tag.AnchorPoint,tag.Position,tag.Size,tag.ZIndex="UpNext",Vector2.new(1,0),UDim2.new(1,-22,0,30),UDim2.fromOffset(220,64),4
  tag.BackgroundColor3,tag.TextColor3,tag.Font,tag.TextSize=SUN,NAVY,Enum.Font.LuckiestGuy,40
  rounded(tag,32)
  local edge=Instance.new("UIStroke");edge.Thickness,edge.Color,edge.ApplyStrokeMode,edge.Parent=5,NAVY,Enum.ApplyStrokeMode.Border,tag
  tag.Parent=panel
 end
 tag.Visible=status=="Active" or status=="Preparing"
 tag.Text=if status=="Active" then "RACING" else "UP NEXT"
 local chip=panel:FindFirstChild("WinnerChip")
 if not chip then
  chip=Instance.new("Frame");chip.Name,chip.AnchorPoint,chip.Position,chip.Size,chip.ZIndex="WinnerChip",Vector2.new(.5,1),UDim2.new(.5,0,.82,-8),UDim2.fromOffset(420,76),4
  chip.BackgroundColor3=SUN
  rounded(chip,38)
  local edge=Instance.new("UIStroke");edge.Thickness,edge.Color,edge.ApplyStrokeMode,edge.Parent=5,NAVY,Enum.ApplyStrokeMode.Border,chip
  local head=Instance.new("ImageLabel");head.Name,head.Size,head.Position,head.BackgroundColor3,head.ZIndex="Headshot",UDim2.fromOffset(60,60),UDim2.fromOffset(8,8),Color3.fromHex("DCE6FF"),5
  rounded(head,30);head.Parent=chip
  local text=Instance.new("TextLabel");text.Name,text.BackgroundTransparency,text.Position,text.Size,text.ZIndex="Text",1,UDim2.fromOffset(78,0),UDim2.new(1,-92,1,0),5
  text.Font,text.TextColor3,text.TextScaled,text.TextXAlignment=Enum.Font.FredokaOne,NAVY,true,Enum.TextXAlignment.Left
  local limit=Instance.new("UITextSizeConstraint");limit.MaxTextSize,limit.Parent=34,text
  text.Parent=chip
  chip.Parent=panel
 end
 chip.Visible=winner~=nil
 if winner then
  local seconds=winner.finishTime or 0
  ;(chip:FindFirstChild("Text") :: TextLabel).Text=tostring(winner.displayName or winner.name or ("Player "..tostring(winner.userId))).." · "..string.format("%d:%04.1f",math.floor(seconds/60),seconds%60)
  ;(chip:FindFirstChild("Headshot") :: ImageLabel).Image=if typeof(winner.userId)=="number" and winner.userId>0 then "rbxthumb://type=AvatarHeadShot&id="..winner.userId.."&w=150&h=150" else ""
 end
end
function Service.Render(snapshot: any)
 if not stage then return end
 local displayId=snapshot.displayTournamentId or snapshot.tournamentId
 stage:SetAttribute("TournamentId",displayId)
 stage:SetAttribute("Preparation",snapshot.preparation and snapshot.preparation.status or "Idle")
 stage:SetAttribute("PresentationStartedAt",snapshot.preparation and snapshot.preparation.startedAt or 0)
 local reset=latestTournament~=displayId
 latestTournament=displayId
 -- Arch screens show player-facing names without build-version tags ("City Run V3" -> "City Run").
 local byId={}
 for _,row in snapshot.catalog or {} do
  local shown=table.clone(row);shown.name=(string.gsub(tostring(row.name),"%s+[Vv]%d+$",""))
  byId[row.id]=shown;knownCourses[row.id]=shown
 end
 local lineup=snapshot.displayLineup or snapshot.lineup or {}
 local resolved=#lineup>0
 local available=#(snapshot.catalog or {})
 stage:SetAttribute("ResolvedLineup",resolved)
 stage:SetAttribute("EligibleCourseCount",available)
 for index=1,5 do
  local bay=stage.Displays:FindFirstChild("Bay"..index)
  if not bay then continue end
  local id=resolved and lineup[index] or nil
  local row=if id then byId[id] or knownCourses[id] else nil
  miniature(bay,id)
  local panel=bay.MapPanel.Display
  local presentation=StageState.BayPresentation(snapshot,index)
  local status=panel:FindFirstChild("CourseStatus")
  if not status then
   status=Instance.new("TextLabel");status.Name="CourseStatus"
   status.Font,status.BackgroundColor3,status.BackgroundTransparency=Enum.Font.FredokaOne,NAVY,.08
   status.TextScaled,status.TextWrapped,status.ZIndex=true,true,4
   status.Position,status.Size,status.Parent=UDim2.fromScale(.05,.85),UDim2.fromScale(.9,.11),panel
   rounded(status,30)
   local padding=Instance.new("UIPadding");padding.PaddingLeft,padding.PaddingRight,padding.PaddingTop,padding.PaddingBottom=UDim.new(0,18),UDim.new(0,18),UDim.new(0,8),UDim.new(0,8);padding.Parent=status
  end
  local color=if presentation.status=="Completed" then Color3.fromRGB(130,235,170)
   elseif presentation.status=="Active" then Color3.fromRGB(255,213,103)
   elseif presentation.status=="Preparing" then Color3.fromRGB(145,210,255) else Color3.fromRGB(230,237,245)
  status.Text,status.TextColor3=presentation.text,if presentation.status=="Completed" then MINT elseif presentation.status=="Active" or presentation.status=="Preparing" then SUN else color
  local light=bay.MapPanel:FindFirstChild("EventArchLight")
  if not light then light=Instance.new("PointLight");light.Name,light.Range,light.Shadows,light.Parent="EventArchLight",20,false,bay.MapPanel end
  light.Color=color;light.Brightness=if presentation.status=="Active" then 1.8 elseif presentation.status=="Completed" then .8 else .25
  bay:SetAttribute("EventState",presentation.status)
  local crest=panel:FindFirstChild("NeutralCrest")
  if not crest then
   crest=Instance.new("Frame");crest.Name,crest.BackgroundTransparency="NeutralCrest",1
   crest.Size,crest.Position,crest.Parent=UDim2.fromScale(.45,.3),UDim2.fromScale(.275,.09),panel
  end
  if crest:IsA("TextLabel") then crest.Text="" end
  -- Without course art the screen shows a "mystery course" badge in the HUD's style.
  if not crest:FindFirstChild("Mystery") then
   local badge=Instance.new("Frame")
   badge.Name,badge.AnchorPoint,badge.Position,badge.Size,badge.BackgroundColor3="Mystery",Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromScale(.85,.85),SUN
   local aspect=Instance.new("UIAspectRatioConstraint");aspect.AspectRatio,aspect.Parent=1,badge
   rounded(badge,999)
   local edge=Instance.new("UIStroke");edge.Thickness,edge.Color,edge.ApplyStrokeMode,edge.Parent=8,NAVY,Enum.ApplyStrokeMode.Border,badge
   local mark=Instance.new("TextLabel")
   mark.Name,mark.BackgroundTransparency,mark.AnchorPoint,mark.Position,mark.Size="Mark",1,Vector2.new(.5,.5),UDim2.fromScale(.5,.54),UDim2.fromScale(.7,.7)
   mark.Font,mark.Text,mark.TextScaled,mark.TextColor3,mark.Parent=Enum.Font.LuckiestGuy,"?",true,NAVY,badge
   badge.Parent=crest
  end
  -- Panel is the SurfaceGui; this gradient sits behind the artwork in place of the bare navy part.
  if not panel:FindFirstChild("Sky") then
   local sky=Instance.new("Frame");sky.Name,sky.Size,sky.BorderSizePixel,sky.BackgroundColor3,sky.ZIndex="Sky",UDim2.fromScale(1,1),0,Color3.new(1,1,1),0
   local fill=Instance.new("UIGradient");fill.Rotation,fill.Color,fill.Parent=90,ColorSequence.new(Color3.fromHex("2F5BD6"),NAVY),sky
   sky.Parent=panel
  end
  panel.Fallback.TextColor3=Color3.fromHex("EAF4FF")
  bay.Plaque.Display.Title.Font=Enum.Font.LuckiestGuy
  panel.Artwork.Image=row and row.image or ""
  local fallback=not row or not row.image or row.image==""
  crest.Visible=fallback
  panel.Fallback.Visible=fallback
  panel.Fallback.Text=if row then row.name else "Choose an opening course\n"..available.." courses available"
  panel.Fallback.Position,panel.Fallback.Size=UDim2.fromScale(.08,.46),UDim2.fromScale(.84,.38)
  bay.Plaque.Display.Title.Text=if resolved and row then "RACE "..index.."  ·  "..row.name elseif row then row.name else "GRAND ARCADE"
  bay:SetAttribute("CourseId",row and row.id or id or "")
  bay:SetAttribute("CurrentRace",presentation.status=="Active" or presentation.status=="Preparing")
  local result=snapshot.results and snapshot.results[index]
  local champion=nil
  if result then for _,entry in result.finishers do if entry.placement==1 then champion=entry end end end
  screenLooks(panel,index,presentation.status,champion)
  for rank=1,3 do
   local slot=bay:FindFirstChild("Slot"..rank)
   local winner
   if result then for _,entry in result.finishers do if entry.placement==rank then winner=entry end end end
   local finisher=bay:FindFirstChild("Rank"..rank).Display.Finisher
   local seconds=winner and winner.finishTime or 0
   finisher.Text=if winner then (winner.displayName or winner.name or ("Player "..winner.userId)).."\n"..string.format("%d:%05.2f",math.floor(seconds/60),seconds%60) else ""
   finisher.Position,finisher.Size=UDim2.fromScale(.04,.50),UDim2.fromScale(.92,.46)
   local userId=winner and winner.userId or 0
   if reset or slot:GetAttribute("WinnerUserId")~=userId then
    local generation=(slot:GetAttribute("AppearanceGeneration") or 0)+1
    slot:SetAttribute("AppearanceGeneration",generation)
    slot:SetAttribute("WinnerUserId",userId)
    local old=slot:FindFirstChild("Finisher");if old then old:Destroy() end
    if winner then
     local fallback=host(slot,slot.CFrame*CFrame.Angles(0,math.pi,0));fallback.Name="Finisher";fallback:ScaleTo(Config.MiniatureScale)
     local tournamentId=displayId
     task.spawn(function()
      local source=template(userId)
      if not source or latestTournament~=tournamentId or slot:GetAttribute("WinnerUserId")~=userId
       or slot:GetAttribute("AppearanceGeneration")~=generation then return end
      local copy=source:Clone();copy.Name="Finisher"
      local box,size=copy:GetBoundingBox()
      copy:PivotTo(slot.CFrame*CFrame.Angles(0,math.pi,0)*CFrame.new(0,size.Y/2,0)*box:ToObjectSpace(copy:GetPivot()))
      if fallback.Parent then fallback:Destroy() end
      copy.Parent=slot
     end)
    end
   end
  end
 end
end
return Service
