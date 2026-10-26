--!strict
local Parts = require(script.Parent.Parts)
local Mechanisms = require(script.Parent.Mechanisms)
local Landmarks = require(script.Parent.Landmarks)
local Kit = {}
function Kit.PressExamples(parent: Instance, template: MeshPart)
 local examples=Parts.Model(parent,"PressExamples")
 for i,state in {"Released","Held"} do
  local x=12+i*4
  local depth=if state=="Held" then Parts.PressDepth else 0
  local key=Parts.Key(examples,template,CFrame.new(x,-.425-depth,30),"Creamy",1,if i==1 then "A" else "S")
  key.Name=state.."Cap"
  key:SetAttribute("Pressable",false)
  key:SetAttribute("ExampleState",state)
  Parts.Block(examples,state.."Socket",Vector3.new(2.54,.1,2.54),CFrame.new(x,-.825,30),Parts.Charcoal,false)
 end
end
function Kit.Build(parent: Instance, template: MeshPart): Model
 local kit=Parts.Model(parent,"KeyboardCircuit_EditableKit_K01")
 kit:SetAttribute("Revision","KC_KIT_C08_01")
 kit:SetAttribute("Phase1Only",true)
 kit:SetAttribute("RuntimeStatus","Inactive construction kit; remaining hazard controllers belong to Phase 2")
 local surfaces=Parts.Model(kit,"Surfaces")
 for i,family in {"Creamy","Thocky","Clacky","Clicky"} do
  Parts.Bank(surfaces,family.."Bank",template,CFrame.new((i-1)*18,0,0),10,6,family)
 end
 Kit.PressExamples(surfaces,template)
 Parts.SpecialKey(surfaces,"Spacebar",CFrame.new(0,0,20),Vector3.new(14,1.25,3.5),"Creamy","SPACE")
 Parts.SpecialKey(surfaces,"Shift",CFrame.new(20,0,20),Vector3.new(10,1.25,4),"Clicky","Shift")
 Parts.SpecialKey(surfaces,"Ctrl",CFrame.new(38,0,20),Vector3.new(5,1.25,5),"Thocky","Ctrl")
 local enter=Parts.Model(surfaces,"EnterL")
 local stem=Parts.SpecialKey(enter,"Stem",CFrame.new(58,0,20),Vector3.new(5,1.25,12),"Creamy","ENTER")
 local returnKey=Parts.SpecialKey(enter,"Return",CFrame.new(53,0,24),Vector3.new(5,1.25,4),"Creamy","↵")
 Parts.JoinSpecialKeys(stem,returnKey)
 local bracket=Parts.Model(surfaces,"Bracket")
 for _,p in {Vector3.new(72,0,17),Vector3.new(77.2,0,20),Vector3.new(72,0,23)} do Parts.Bank(bracket,"BracketArm",template,CFrame.new(p),4,2,"Clacky") end
 local arrow=Parts.Model(surfaces,"Arrow")
 Parts.Bank(arrow,"Shaft",template,CFrame.new(86.1,0,20),6,2,"Clicky","→")
 for i,rows in {6,4,2} do Parts.Bank(arrow,"HeadBand"..i,template,CFrame.new(90.65+(i-1)*2.6,0,20),2,rows,"Clicky","→") end
 local hardware=Parts.Model(kit,"Hardware")
 Parts.Support(hardware,CFrame.new(0,0,42),8)
 Parts.Support(hardware,CFrame.new(12,0,42),14,Parts.Palette.Clacky[2])
 local switch=Parts.Model(hardware,"SwitchAssembly")
 Parts.Block(switch,"Housing",Vector3.new(3,1.5,3),CFrame.new(26,-.75,42),Parts.Palette.Creamy[1],false)
 Parts.Block(switch,"Stem",Vector3.new(1,3,1),CFrame.new(26,1,42),Parts.Palette.Creamy[3],false)
 local warning=Parts.Model(hardware,"WarningStrip")
 Parts.Warning(warning,CFrame.new(38,0,42),Vector3.new(6,.2,3))
 Parts.CheckpointFlag(hardware,CFrame.new(48,0,42),"CP")
 local refuge=Parts.Bank(hardware,"CtrlRefuge",template,CFrame.new(65,0,42),10,6,"Thocky","Ctrl")
 local roof=Parts.Block(refuge,"Roof",Vector3.new(14,1,10),CFrame.new(65,14.5,42),Parts.Charcoal)
 roof:SetAttribute("Role","SolidBlocker")
 for _,x in {-6.4,6.4} do
  local post=Parts.Block(refuge,"GuardPost",Vector3.new(.8,15,.8),CFrame.new(65+x,6.7,46),Parts.Charcoal)
  post:SetAttribute("Role","SolidBlocker")
 end
 local mechanisms=Parts.Model(kit,"Mechanisms")
 Mechanisms.Foundry(mechanisms,template,CFrame.new(20,0,78))
 Mechanisms.Lift(mechanisms,template,CFrame.new(60,0,78))
 Mechanisms.Shuttle(mechanisms,template,CFrame.new(88,0,78))
 local seesaw=Parts.Model(mechanisms,"H02_SeesawVisual")
 Parts.SpecialKey(seesaw,"Spacebar",CFrame.new(5,0,110)*CFrame.Angles(0,0,.12),Vector3.new(18,1.25,4),"Creamy","SPACE")
 Parts.Cylinder(seesaw,"Pivot",CFrame.new(5,-3,110)*CFrame.Angles(0,math.pi/2,0),5,4,Parts.Charcoal)
 local fallaway=Parts.Bank(mechanisms,"H03_FallawayRowVisual",template,CFrame.new(32,0,110),10,4,"Creamy")
 Parts.Warning(fallaway,CFrame.new(32,.04,112),Vector3.new(8,.12,.35))
 local sweep=Parts.KillBody(mechanisms,"H07_SweepVisual",CFrame.new(58,1,110),Vector3.new(16,2.5,3))
 Parts.Cylinder(sweep,"Pivot",CFrame.new(51,-1,110)*CFrame.Angles(0,0,math.pi/2),4,4,Parts.Charcoal)
 local domino=Parts.Model(mechanisms,"H08_DominoVisual")
 for i=1,3 do Parts.KillBody(domino,"Domino"..i,CFrame.new(76+i*4,3,110)*CFrame.Angles(0,0,(i-2)*.35),Vector3.new(3,6,3)) end
 local windows=Parts.Model(mechanisms,"H01_ShiftWindowVisual")
 Parts.SpecialKey(windows,"ShiftBar",CFrame.new(105,0,110),Vector3.new(14,1.25,4),"Clicky","Shift")
 for _,x in {96,114} do Parts.Block(windows,"StopHousing",Vector3.new(2,5,6),CFrame.new(x,-1,110),Parts.Charcoal,false) end
 local world=Parts.Model(kit,"Landmarks")
 Landmarks.USB(world,CFrame.new(0,0,150))
 Landmarks.Rack(world,CFrame.new(30,0,150),template)
 Landmarks.Magazine(world,CFrame.new(60,0,150),template)
 Landmarks.SplitShell(world,CFrame.new(90,0,150),template)
 Landmarks.Dial(world,CFrame.new(120,0,150))
 return kit
end
return Kit

