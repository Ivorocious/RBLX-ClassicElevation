local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local folder="assets/egg_rush_circuit/phase2/chicken_r04/candidate_a02/"
local manifest=serde.decode("json",fs.readFile(folder.."manifest.json"))
local source="src/ServerStorage/CourseBuilders/EggRush/RestartP2/ChickenKit.luau"
local kit=luau.load(fs.readFile(source),{debugName=source,environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,Enum=roblox.Enum,Instance=roblox.Instance}})()
local V,CF=roblox.Vector3.new,roblox.CFrame.new
local frame=CF(12,6,-31)*roblox.CFrame.Angles(.15,.8,-.25)
local parent=roblox.Instance.new("Folder")
local models,parts,lethals=0,0,0
assert(manifest.build=="ER_CHICKEN_R04_A02")
assert(manifest.templates.Body.partCount==17 and manifest.templates.Head.partCount==15 and manifest.templates.Feet.partCount==10)
assert(manifest.attachments.bodyFront=="+X" and manifest.attachments.headFront=="-Z")
assert(V(table.unpack(manifest.attachments.beakTip))==V(0,-2,-10))
assert(V(table.unpack(manifest.attachments.headNeck))==V(0,-5,3))
assert(manifest.attachments.neckLinkLength==6 and manifest.attachments.neckWidth==9)
for key,template in manifest.templates do
 for _,factorValue in {false,.8,1,V(1.2,.9,.75)} do
  local model=kit.Create(parent,key,frame,if factorValue==false then nil else factorValue)
  local factor=if typeof(factorValue)=="number" then V(factorValue,factorValue,factorValue) elseif typeof(factorValue)=="Vector3" then factorValue else V(1,1,1)
  assert(model.Parent==parent and model.Name==key and #model:GetChildren()==template.partCount)
  for _,data in template.parts do
   local p=assert(model:FindFirstChild(data.name))
   local at=V(table.unpack(data.position))*factor
   local expected=frame*CF(at.X,at.Y,at.Z,table.unpack(data.rotationMatrix))
   assert((p.Size-V(table.unpack(data.size))*factor).Magnitude<.0001)
   local x,y={p.CFrame:GetComponents()},{expected:GetComponents()}
   for i,value in y do assert(math.abs(x[i]-value)<.0001) end
   assert(p.Anchored and not p.CanCollide and not p.CanTouch)
   assert(p.CanQuery==data.lethal and p:GetAttribute("ERLethal")==data.lethal)
   assert(p.Material==roblox.Enum.Material[data.material])
   assert(p.Color==roblox.Color3.fromRGB(table.unpack(data.color)))
   if data.lethal then assert(key=="Head" and p.Name=="Beak" and data.paletteRole=="Hot");lethals+=1 end
   parts+=1
  end
  if key=="Head" then
   local beak=model.Beak
   local actualTip=beak.CFrame:PointToWorldSpace(V(0,0,-beak.Size.Z/2))
   local expectedTip=frame:PointToWorldSpace(V(table.unpack(manifest.attachments.beakTip))*factor)
   assert((actualTip-expectedTip).Magnitude<.0001)
   assert((beak.CFrame.LookVector-frame.LookVector).Magnitude<.0001)
  end
  models+=1
 end
end
local report={build=manifest.build,status="passed",models=models,partsChecked=parts,lethalPiecesChecked=lethals,checks={"Luau compile","manifest transform and scale parity","native primitive sizes/colors/materials","visible red Beak is the only lethal piece","Head front and transformed BeakTip attachment parity","42-part A02 template and short-neck contract"},boundary="Offline source/API check, not native game proof"}
fs.writeFile(folder.."api_check.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",report))
