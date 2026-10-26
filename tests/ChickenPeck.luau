local fs,luau,rbx=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox")
local env={};for key,value in rbx do env[key]=value end
local CF=table.clone(rbx.CFrame)
function CF.lookAt(origin,target,up)
 local forward=(target-origin).Unit;local right=forward:Cross(up or rbx.Vector3.yAxis).Unit
 return rbx.CFrame.fromMatrix(origin,right,right:Cross(forward),-forward)
end
env.CFrame=CF
local motion=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/ChickenMotion.luau"),{environment=env})()
local sample=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/GuardianPeck.luau"),{environment=env})().Sample
local bindingEnv=table.clone(env)
bindingEnv.script={Parent={ChickenMotion={}}}
bindingEnv.require=function()return motion end
local binding=luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/ChickenPeck.luau"),{environment=bindingEnv})()
local V,Color=rbx.Vector3.new,rbx.Color3.fromRGB
local root=CF.new(91,18,40)*CF.Angles(0,-math.pi/2,0)
local points={V(135,28.32,40),V(121.5,29.32,26),V(87,23.32,85)}
local initial=motion.Pose(root,points[1],{state="Rest",alpha=0},{previousTarget=points[3]})
local course={}
local function group(frame)
 local self={frame=frame,Parent=true,parts={}}
 function self:GetPivot()return self.frame end
 function self:PivotTo(at)
  local delta=at*self.frame:Inverse();self.frame=at
  for _,part in self.parts do part.CFrame=delta*part.CFrame end
 end
 return self
end
local body,head,feet=group(initial.body),group(initial.head),group(root)
feet.Left,feet.Right=group(initial.footLeft),group(initial.footRight)
local function part(frame,headPart,lethal)
 local self={CFrame=frame,Parent=true,Anchored=true,CanCollide=false,CanQuery=true,Transparency=0}
 function self:IsA(name)return name=="BasePart"end
 function self:IsDescendantOf(object)return headPart and object==head end
 function self:GetAttribute(name)return if name=="ERLethal"then lethal else nil end
 return self
end
local beak=part(initial.head*CF.new(0,-2,-8.5),true,true)
head.parts={beak}
local shell=part(initial.body,false,false);body.parts={shell}
local lower,upper=part(initial.lower,false,false),part(initial.upper,false,false)
local parts={shell,beak,lower,upper}
local attributes={RestSeconds=2.2,WarningSeconds=1.8,StrikeSeconds=.55,ImpactSeconds=.3,RecoverSeconds=.9,ERState="Authored",ERPeckTarget=0,ERStrike=false}
local refs,plates={},{}
for index,point in points do
 local sound={Looped=false,TimePosition=index,IsPlaying=false,Parent=true,plays=0}
 function sound:Stop()self.IsPlaying=false end
 function sound:Play()self.IsPlaying=true;self.plays+=1 end
 local plate={Position=point-V(0,.32,0),Size=V(6,.14,6),Color=Color(30+index,40,50),Parent=true,Transparency=0,sound=sound}
 function plate:IsA(name)return name=="BasePart"end
 function plate:IsDescendantOf(object)return object==course end
 function plate:GetAttribute()return nil end
 function plate:FindFirstChild(name)return if name=="WarningSound"then sound else nil end
 table.insert(plates,plate);table.insert(refs,{Name=tostring(index),Value=plate})
end
local model={Body=body,Head=head,Feet=feet,NeckLower=lower,NeckUpper=upper,Parent=true,Targets={}}
function model:GetPivot()return root end
function model:GetDescendants()return parts end
function model:GetAttribute(name)return attributes[name]end
function model:SetAttribute(name,value)attributes[name]=value end
function model.Targets:GetChildren()return refs end
local frames={};for _,p in parts do frames[p]=p.CFrame end
local colors={};for _,p in plates do colors[p]=p.Color end
local controller=binding.Bind(model,course,sample)
local checks,contacts=0,0
local function check(ok,message)checks+=1;assert(ok,message)end
local function contact(p,tag)check(p==beak and tag=="EggRush:ChickenPeck","Only the visible beak reaches the contact callback");contacts+=1 end
local function advance(time,dt,bodies)
 controller.Advance(time-dt,dt,contact,bodies)
end
advance(.001,.001,false)
check((head.frame.Position-initial.head.Position).Magnitude<.0001,"First advance preserves the assembly's previous-target attention")
advance(2.3,.1,false)
check(contacts==0 and attributes.ERState=="Warning"and attributes.ERStrike==false,"Warning is nonlethal")
check(plates[1].sound.IsPlaying,"Current target warning sound plays")
controller.Hold();check(not plates[1].sound.IsPlaying,"Hold silences warning")
controller.Resume();check(plates[1].sound.IsPlaying,"Resume restores active warning")
advance(4.2,.1,true)
check(contacts>1 and attributes.ERStrike==true,"Active strike samples visible beak across the elapsed step")
local afterStrike=contacts
advance(5.5,.1,false)
check(contacts==afterStrike and attributes.ERStrike==false,"Recovery applies no damage")
local settings={rest=2.2,warning=1.8,strike=.55,impact=.3,recover=.9}
local duration=5.75
for targetIndex=2,3 do
 local time=(targetIndex-1)*duration+.7
 advance(time,.01,false)
 local s=sample(settings,time,3)
 local expected=motion.Pose(root,points[targetIndex],s,{previousTarget=points[targetIndex-1]})
 check((head.frame.Position-expected.head.Position).Magnitude<.0001,"Runtime passes the previous target to continuous Rest motion")
 check((feet.Left.frame.Position-expected.footLeft.Position).Magnitude<.0001,"Runtime preserves the target-to-target foot stance")
end
advance(3*duration+.8,.01,false)
local expected=motion.Pose(root,points[1],sample(settings,3*duration+.8,3),{previousTarget=points[3]})
check((head.frame.Position-expected.head.Position).Magnitude<.0001,"Last-to-first transition stays continuous")
controller.Stop()
for p,frame in frames do check(p.CFrame==frame,"Stop restores the exact authored part frame")end
check(body.frame==initial.body and head.frame==initial.head and feet.Left.frame==initial.footLeft and feet.Right.frame==initial.footRight,"Stop restores authored model pivots")
for p,color in colors do
 check(p.Color==color and not p.sound.IsPlaying and p.sound.Looped==false,"Stop restores plate and sound state")
end
check(attributes.ERState=="Authored"and attributes.ERPeckTarget==0 and attributes.ERStrike==false,"Stop restores authored state attributes")
print(string.format("ChickenPeck: %d context, continuity, beak-only contact, warning and exact-restoration checks pass; mocked binding, not native play proof",checks))
