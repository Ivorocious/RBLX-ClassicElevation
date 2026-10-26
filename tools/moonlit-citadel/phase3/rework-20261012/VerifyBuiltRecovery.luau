local fs, roblox, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde')
local base='docs/artifacts/moonlit-citadel/phase3/rework-20261012/'
local rows={}
for _, name in {'rw10_owner_models.rbxm','rw10_built_r01.rbxm','rw10_built_r02.rbxm','rw10_built_r03.rbxm','rw10_built_r04.rbxm'} do
 if fs.isFile(base..name) then
  local bytes=fs.readFile(base..name)
  local receipt=serde.decode('json',fs.readFile(base..name..'.receipt.json'))
  assert(#bytes==receipt.bytes and serde.hash('sha256',bytes)==receipt.sha256,name)
  local roots=roblox.deserializeModel(bytes)
  local models={}
  for _,model in roots do
   local count={name=model.Name,source=model:GetAttribute('SourceRevision'),build=model:GetAttribute('BuildRevision'),parts=0,meshes=0,colliders=0,instances=#model:GetDescendants()}
   for _,part in model:GetDescendants() do if part:IsA('BasePart') then count.parts+=1;if part:IsA('MeshPart')then count.meshes+=1 end;if part.CanCollide then count.colliders+=1 end end end
   table.insert(models,count)
  end
  table.insert(rows,{name=name,sha256=receipt.sha256,bytes=#bytes,models=models})
 end
end
fs.writeFile(base..'rw10_native_recovery_verification.json',serde.encode('json',rows))
print(serde.encode('json',rows))