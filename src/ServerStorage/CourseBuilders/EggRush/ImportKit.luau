--!nonstrict
local ImportKit = {}
local PALETTE = {
 Shell="FFF0CA",ShellShade="E8D4A8",Mint="68CDB0",Coral="F67D60",Lilac="B688D8",
 Honey="B97B43",Straw="D89C53",Iron="646A78",IronLight="949BA9",Ink="343744",
 Amber="FFC04B",GlassBlue="8CC7DA",Rock="868993",RockShade="707580",Green="63C448",GreenShade="4BA83B",Window="4C9EC4",Leaf="579147",
}
function ImportKit.Normalize(importRoot,kit)
 assert(importRoot:IsDescendantOf(game.ServerStorage),"Inspect imports in ServerStorage")
 local created={}
 for _,p in ipairs(importRoot:GetDescendants()) do
  assert(not p:IsA("LuaSourceContainer"),"Owned art must not contain scripts")
  if not p:IsA("BasePart") then continue end
  local asset,role=p.Name:match("^ER_(.-)__(.+)$")
  assert(asset and PALETTE[role],"Unknown owned asset/material: "..p.Name)
  local model=created[asset]
  if not model then
   assert(not kit:FindFirstChild(asset),"Keep the existing inspected kit unit: "..asset)
   model=Instance.new("Model");model.Name=asset;model.WorldPivot=CFrame.identity
   model:SetAttribute("ERAsset",asset);model:SetAttribute("SourceImport",importRoot.Name)
   model.Parent=kit;created[asset]=model
  end
  local origin=p:GetPivot()*CFrame.Angles(-math.pi/2,0,0)*CFrame.Angles(0,math.pi,0)
  local copy=p:Clone();copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false
  copy.CFrame=origin:ToObjectSpace(p.CFrame);copy.Color=Color3.fromHex(PALETTE[role]);copy.Material=Enum.Material.SmoothPlastic
  copy:SetAttribute("ERMaterial",role);copy.Parent=model
 end
 for _,model in created do model.WorldPivot=CFrame.identity end
 return created
end
function ImportKit.PrepareVisibleContacts(kit,names)
 assert(game:GetService("RunService"):IsStudio(),"Prepare owned art in Studio")
 local receipts={}
 for _,name in ipairs(names)do
  local model=assert(kit:FindFirstChild(name))
  for _,p in ipairs(model:GetDescendants())do
   if not p:IsA("MeshPart")then continue end
   local size,texture=p.Size,p.TextureID
   local mesh=game:GetService("AssetService"):CreateMeshPartAsync(Content.fromUri(p.MeshId),{CollisionFidelity=Enum.CollisionFidelity.PreciseConvexDecomposition})
   p:ApplyMesh(mesh);p.Size=size;p.TextureID=texture;mesh:Destroy()
   table.insert(receipts,{asset=name,part=p.Name,fidelity=tostring(p.CollisionFidelity)})
  end
 end
 return receipts
end
return ImportKit
