--!strict
local Kit = require(script.Parent.UiKit)
local Icons = require(script.Parent.LobbyIcons)
local FinishTicket = require(script.Parent.FinishTicketView)
local Coach = require(script.Parent.VisitCoachView)
local Practice = require(script.Parent.PracticeView)
local EventEnd = require(script.Parent.EventEndView)
local GuiService=game:GetService("GuiService")
local UserInputService=game:GetService("UserInputService")
local ContextActionService=game:GetService("ContextActionService")
local TextService=game:GetService("TextService")
local View = {}
-- Race options (brief "Race options"): a slide-up Sky Rush ticket sized to its content. The model's
-- first button is the large main action; the rest sit in a two-column grid.
local WIDTH,PAD,LINE_TEXT,ICON=600,24,17,24
local SLANT=Kit.SkySlant("L")
-- Buttons that step away from racing read as a white button rather than the yellow call to action.
local QUIET={Break=true,StopWatching=true,ExitFinale=true,SkipIntro=true,Lobby=true,ExitPractice=true}
-- The model only carries text, so each line's icon follows its wording.
local function lineIcon(line: string): string
 local lower=string.lower(line)
 local function has(word: string): boolean return string.find(lower,word,1,true)~=nil end
 if has(" entered · ") then return "MyRacer" end
 if has("still racing") then return "Clock" end
 if has("target") or has("checkpoint") then return "Flag" end
 if string.sub(lower,1,6)=="place " or has("fastest") or has("best") then return "Records" end
 if string.sub(lower,1,9)=="practice " or string.sub(lower,1,4)=="lap " then return "Clock" end
 if has("portal") or has("practice") then return "Check" end
 return "Chevron"
end
-- `host` draws everything into an existing frame instead of a new ScreenGui (UI Labs stories use it).
function View.Create(player: Player, activate: (string) -> (), host: GuiObject?): any
 local gui: GuiBase2d
 if host then gui=host else
  local screen=Instance.new("ScreenGui")
  screen.Name,screen.ResetOnSpawn,screen.DisplayOrder="RaceFlowChoices",false,35
  screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
  screen.Enabled=false
  screen.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
  screen.Parent=player:WaitForChild("PlayerGui")
  gui=screen
 end
 local function enable() if gui:IsA("ScreenGui") then gui.Enabled=true end end
 local function enabled(): boolean return not gui:IsA("ScreenGui") or gui.Enabled end
 local holder=Kit.Frame(gui,"TicketHolder",UDim2.fromOffset(WIDTH,300),UDim2.new(.5,0,1,-22))
 holder.AnchorPoint=Vector2.new(.5,1)
 local layoutScale=Instance.new("UIScale"); layoutScale.Name,layoutScale.Parent="LayoutScale",holder
 local panel=Kit.SkyPlate(holder,"Ticket",UDim2.fromScale(1,1),UDim2.new(),{class="L",stripes=true})
 Kit.Sheen(panel,7)
 panel.Visible=false
 local content=Kit.Content(panel)
 local heading=Kit.SkyBig(content,"Title","",36)
 Kit.SetBigAlignment(heading,Enum.TextXAlignment.Left)
 local close=Kit.SkyButton(content,"Close","×",UDim2.fromOffset(46,46),UDim2.new(),function() activate("Close") end,"Light",26)
 local enrollment=Kit.Chip(content,"Enrollment","",16)
 local lineRows: {Frame}={}
 local buttons: {[string]: TextButton}={}
 local signature=""
 local choices: {any}={}
 local panelHeight=300
 local lastFocus: GuiObject?=nil
 local finish=FinishTicket.Create(gui,activate)
 local coach=Coach.Create(gui,activate)
 local practice=Practice.Create(gui,activate)
 local practiceRunning=false
 local eventEnd=EventEnd.Create(gui,activate,function() activate("CloseEventEnd") end)
 -- The panel and close button that keyboard/controller navigation currently drives.
 local activePanel: GuiObject=panel
 local activeClose: GuiObject=close
 local activeButtons: {[string]: GuiObject}=buttons
 -- The coach card's Skip introduction stands in for the close button while the guide runs.
 local closeAction="Close"
 local notePlate=Kit.SkyPlate(gui,"DepartureNotice",UDim2.fromOffset(420,48),UDim2.new(.5,0,0,104),{fill="Navy",class="S"})
 notePlate.AnchorPoint,notePlate.Visible=Vector2.new(.5,0),false
 local note=Kit.Body(Kit.Content(notePlate),"Text","",LINE_TEXT,Kit.White)
 note.Size,note.Position,note.TextWrapped=UDim2.new(1,-44,1,-12),UDim2.fromOffset(22,6),true
 local launcher=Kit.SkyButton(gui,"RaceOptionsLauncher","Race options",UDim2.fromOffset(176,48),UDim2.new(1,-16,.14,0),function() activate("Open") end,"Alt",18)
 launcher.AnchorPoint=Vector2.new(1,0); launcher.Visible=false
 local launcherSlot: Vector2?=nil
 local function resize()
  local size=gui.AbsoluteSize
  local large=Kit.LargeText()
  local design=math.clamp(math.min(size.X/1280,size.Y/720),.6,1.2)*(if large then 1.1 else 1)
  layoutScale.Scale=math.min(design,(size.X-24)/WIDTH,(size.Y-44)/panelHeight)
  notePlate.Size=UDim2.fromOffset(math.min(440,math.max(240,size.X-24)),math.max(48,note.TextBounds.Y+20))
  FinishTicket.Layout(finish,size,large)
  Coach.Layout(coach,size,large)
  Practice.Layout(practice,size,large)
  EventEnd.Layout(eventEnd,size,large)
 end
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize); resize()
 player:GetAttributeChangedSignal("LargeText"):Connect(resize)
 note:GetPropertyChangedSignal("TextBounds"):Connect(resize)
 local function lineRow(index: number): Frame
  local row=lineRows[index]
  if row then return row end
  row=Kit.Frame(content,"Line"..index,UDim2.new(),UDim2.new())
  local label=Kit.Body(row,"Text","",LINE_TEXT,Kit.White)
  label.TextXAlignment,label.TextYAlignment,label.TextWrapped=Enum.TextXAlignment.Left,Enum.TextYAlignment.Top,true
  label.Position=UDim2.fromOffset(ICON+10,2)
  -- A soft navy edge keeps white text readable on the light top of the sky gradient.
  local edge=Kit.Stroke(label,Kit.Navy,1.2,false); edge.Transparency=.35
  lineRows[index]=row
  return row
 end
 local function setLine(row: Frame, line: string)
  local kind=lineIcon(line)
  if row:GetAttribute("Icon")~=kind then
   local old=row:FindFirstChild("Icon")
   if old then old:Destroy() end
   local icon: GuiObject=if kind=="Flag" then Kit.Icon(row,"Icon",Kit.Images.CheckpointFlag,ICON) else Icons.Create(row,kind,UDim2.new(),ICON)
   icon.Name="Icon"
   row:SetAttribute("Icon",kind)
  end
  (row:FindFirstChild("Text") :: TextLabel).Text=line
 end
 -- Lays the ticket out top to bottom; each row starts just inside the slanted left edge at its height.
 local function place(lines: {string})
  local textWidth=WIDTH-SLANT-PAD*2-ICON-10
  local rows: {{items: {GuiObject}, height: number, gap: number, kind: string}}={}
  table.insert(rows,{items={heading},height=44,gap=10,kind="Title"})
  table.insert(rows,{items={enrollment},height=30,gap=12,kind="Chip"})
  for index,line in lines do
   local row=lineRow(index)
   row.Visible=true
   setLine(row,line)
   local measured=TextService:GetTextSize(line,LINE_TEXT,Enum.Font.FredokaOne,Vector2.new(textWidth,1000))
   table.insert(rows,{items={row},height=math.max(ICON+2,measured.Y+4),gap=if index==#lines then 14 else 6,kind="Line"})
  end
  for index=#lines+1,#lineRows do lineRows[index].Visible=false end
  for index,definition in choices do
   local button=buttons[definition.id]
   if index==1 then table.insert(rows,{items={button},height=60,gap=10,kind="Main"})
   elseif index%2==0 then table.insert(rows,{items={button},height=48,gap=10,kind="Grid"})
   else table.insert(rows[#rows].items,button) end
  end
  local height=20+24
  for index,row in rows do height+=row.height+(if index<#rows then row.gap else 0) end
  panelHeight=height
  holder.Size=UDim2.fromOffset(WIDTH,height)
  local y=20
  for _,row in rows do
   local middle=(y+row.height/2)/height
   local left=SLANT*(1-middle)+PAD
   local right=WIDTH-SLANT*middle-PAD
   local first=row.items[1]
   if row.kind=="Title" then
    close.Position=UDim2.fromOffset(right-46,y-2)
    local room=right-left-60
    first.Position,first.Size=UDim2.fromOffset(left,y),UDim2.fromOffset(room,44)
    local labels=Kit.BigLabels(first)
    local measured=TextService:GetTextSize(labels[1].Text,36,Enum.Font.LuckiestGuy,Vector2.new(10000,100))
    for _,label in labels do label.TextSize=math.max(20,math.min(36,math.floor(36*room/math.max(1,measured.X)))) end
   elseif row.kind=="Chip" then
    first.Position=UDim2.fromOffset(left,y+1)
   elseif row.kind=="Line" then
    first.Position,first.Size=UDim2.fromOffset(left,y),UDim2.fromOffset(right-left,row.height)
    local icon=first:FindFirstChild("Icon") :: GuiObject?
    if icon then icon.Position=UDim2.fromOffset(0,math.max(0,(math.min(row.height,ICON+4)-ICON)/2)) end
    ;(first:FindFirstChild("Text") :: TextLabel).Size=UDim2.fromOffset(right-left-ICON-10,row.height)
   elseif row.kind=="Main" then
    first.Position,first.Size=UDim2.fromOffset(left,y),UDim2.fromOffset(right-left,row.height)
   else
    local pair=#row.items==2
    local cell=if pair then (right-left-12)/2 else right-left
    for index,item in row.items do
     item.Position,item.Size=UDim2.fromOffset(left+(index-1)*(cell+12),y),UDim2.fromOffset(cell,row.height)
    end
   end
   y+=row.height+row.gap
  end
  resize()
 end
 local navigation="RaceFlowNavigation"
 ContextActionService:BindActionAtPriority(navigation,function(_,state,input)
  if state~=Enum.UserInputState.Begin or not activePanel.Visible or not enabled() or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
  local key=input.KeyCode
  if key==Enum.KeyCode.Escape or key==Enum.KeyCode.ButtonB then activate(closeAction); return Enum.ContextActionResult.Sink end
  local selected=GuiService.SelectedObject
  if key==Enum.KeyCode.Return or key==Enum.KeyCode.Space then
   if selected==activeClose then activate(closeAction); return Enum.ContextActionResult.Sink end
   for _,definition in choices do if selected==activeButtons[definition.id] and selected:GetAttribute("Available")~=false then activate(definition.id); return Enum.ContextActionResult.Sink end end
   return Enum.ContextActionResult.Pass
  end
  if key~=Enum.KeyCode.Tab and key~=Enum.KeyCode.Up and key~=Enum.KeyCode.Down then return Enum.ContextActionResult.Pass end
  local available: {GuiObject}={activeClose}
  for _,definition in choices do local button=activeButtons[definition.id]; if button and button:GetAttribute("Available")~=false then table.insert(available,button) end end
  local index=table.find(available,selected) or 0
  local direction=if key==Enum.KeyCode.Up or (key==Enum.KeyCode.Tab and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))) then -1 else 1
  GuiService.SelectedObject=available[((index-1+direction)%#available)+1]
  return Enum.ContextActionResult.Sink
 end,false,3100,Enum.KeyCode.Tab,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Return,Enum.KeyCode.Space,Enum.KeyCode.Escape,Enum.KeyCode.ButtonB)
 gui.Destroying:Connect(function() ContextActionService:UnbindAction(navigation) end)
 local function slideIn(target: GuiObject)
  if not Kit.Motion() then return end
  local home=target.Position
  target.Position=home+UDim2.fromOffset(0,380)
  Kit.Tween(target,.56,{Position=home},"Pop")
  Kit.Play("Whoosh")
 end
 return {
  CloseChoices=function()
   if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) and not GuiService.SelectedObject:IsDescendantOf(launcher) then GuiService.SelectedObject=nil end
   lastFocus=nil; panel.Visible=false; finish.plate.Visible=false; coach.plate.Visible=false
   Practice.ShowModal(practice,nil,nil,false,false,false)
  end,
  Show=function(model: any,visible: boolean,pending: boolean,message: string?)
   enable()
   local practiceScreen=model.practiceScreen
   local practiceModal=practiceScreen~=nil and practiceScreen.mode~="Running"
   local mode=if model.coach then "Coach" elseif practiceModal then "Practice" elseif model.ticket~=nil then "Finish" else "Panel"
   local practicePlate: GuiObject=if practiceScreen and practiceScreen.mode=="Finished" then practice.finished else practice.lines
   local plates: {[string]: GuiObject}={Panel=panel,Finish=finish.plate,Coach=coach.plate,Practice=practicePlate}
   if mode~="Practice" and (practice.lines.Visible or practice.finished.Visible) then Practice.ShowModal(practice,nil,nil,false,false,false) end
   local target=plates[mode]
   for name,other in plates do
    if name~=mode and other.Visible then
     if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(other) then GuiService.SelectedObject=nil end
     other.Visible=false
    end
   end
   activePanel=target
   activeClose=if mode=="Finish" then finish.close elseif mode=="Coach" then coach.skip else close
   activeButtons=if mode=="Finish" then finish.buttons elseif mode=="Coach" then coach.buttons else buttons
   closeAction=if mode=="Coach" then "SkipIntro" else "Close"
   if target.Visible~=visible then
    if visible then
     lastFocus=GuiService.SelectedObject
     if UserInputService.GamepadEnabled or lastFocus then GuiService.SelectedObject=activeClose end
    elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(target) then
     GuiService.SelectedObject=if lastFocus and lastFocus.Parent and lastFocus.Visible then lastFocus else nil
    end
   end
   local opening=visible and not target.Visible
   target.Visible=visible
   choices=if mode=="Coach" then model.coach.buttons else model.buttons
   if mode=="Practice" then
    local practiceClose,order,map=Practice.ShowModal(practice,practiceScreen,model.buttons[1],visible,pending,opening)
    activeClose,activeButtons,choices=practiceClose,map,order
   elseif mode=="Finish" then
    FinishTicket.Render(finish,model,pending,message)
    if opening then slideIn(finish.plate) end
   elseif mode=="Coach" then
    Coach.Render(coach,model.coach,pending,opening)
    Coach.Layout(coach,gui.AbsoluteSize,Kit.LargeText())
   else
    Kit.SetBig(heading,model.title)
    Kit.SetChip(enrollment,model.enrollment,if model.enrolled then "Good" else "Plain")
    local lines={}
    for _,line in string.split(model.body,"\n") do if line~="" then table.insert(lines,line) end end
    if message and message~="" then table.insert(lines,message) end
    local ids={}
    for _,definition in model.buttons do table.insert(ids,definition.id) end
    local nextSignature=table.concat(ids,",")
    if nextSignature~=signature then
     for _,button in buttons do button:Destroy() end
     table.clear(buttons); signature=nextSignature
    end
    for index,definition in model.buttons do
     local button=buttons[definition.id]
     if not button then
      local id=definition.id
      local main=index==1
      button=Kit.SkyButton(content,id,definition.text,UDim2.fromOffset(200,if main then 60 else 48),UDim2.new(),function() activate(id) end,
       if not main then "Alt" elseif QUIET[id] then "Light" else "Primary",if main then 24 else 17)
      buttons[id]=button
     end
     Kit.SetButtonText(button,definition.text)
     button:SetAttribute("Available",not pending)
     button.Selectable,button.Active=not pending,not pending
    end
    place(lines)
    if opening then
     slideIn(panel)
     for index,definition in model.buttons do Kit.Punch(buttons[definition.id],.85,.38,.22+index*.06) end
    end
   end
   if visible and UserInputService.GamepadEnabled and not GuiService.SelectedObject then GuiService.SelectedObject=activeClose end
  end,
  Notice=function(message: string) note.Text=message; notePlate.Visible=message~="" end,
  -- Event end summary (nil hides it) and the finale's Exit celebration pill.
  EventEnd=function(info: any?)
   enable()
   EventEnd.Set(eventEnd,info,player.UserId)
  end,
  Finale=function(active: boolean) EventEnd.SetFinale(eventEnd,active) end,
  -- Running practice HUD; nil hides it.
  Practice=function(screen: any?)
   enable()
   Practice.SetHud(practice,screen)
   practiceRunning=screen~=nil and screen.mode=="Running"
  end,
  Launcher=function(visible: boolean)
   if visible and not launcher.Visible then Kit.Punch(launcher,.01,.42) end
   launcher.Visible=visible
   -- During a practice run the top right holds Retry, so the launcher waits bottom right.
   launcher.Position=if launcherSlot then UDim2.fromOffset(launcherSlot.X-gui.AbsolutePosition.X,launcherSlot.Y-gui.AbsolutePosition.Y)
    elseif practiceRunning then UDim2.new(1,-16,1,-112) else UDim2.new(1,-16,.14,0)
  end,
  -- The racing HUD reserves a slot (screen pixels) so the launcher never covers the live place.
  LauncherSlot=function(slot: Vector2?) launcherSlot=slot end,
  IsTicketVisible=function(): boolean return finish.plate.Visible end,
  Destroy=function() gui:Destroy() end,
 }
end
return View
