
local kit=game.ServerStorage.CourseAssetKits.KeyboardCircuit_EditableKit_K01
local stage=Instance.new("Folder");stage.Name,stage.Parent="KC_AssetShowcase_C05",workspace
local backdrop=Instance.new("Part");backdrop.Name="PlainShowcaseBackdrop";backdrop.Anchored=true;backdrop.Size=Vector3.new(3000,4,3000);backdrop.CFrame=CFrame.new(3250,308,-2150);backdrop.Color=Color3.fromRGB(184,201,207);backdrop.Material=Enum.Material.SmoothPlastic;backdrop.Parent=stage
local result={}
for index,info in {{name="Surfaces",cols=4,dx=24,dz=25},{name="Mechanisms",cols=3,dx=65,dz=55},{name="Landmarks",cols=3,dx=45,dz=50}} do
 local sheet=Instance.new("Model");sheet.Name,sheet.Parent=info.name,stage
 local origin=Vector3.new(2850+(index-1)*400,310,-2150)
 local units={}
 for _,v in kit[info.name]:GetChildren() do table.insert(units,v) end
 if info.name=="Surfaces" then for _,v in kit.Hardware:GetChildren() do table.insert(units,v) end end
 for n,unit in units do
  local clone=unit:Clone();clone.Parent=sheet
  local cf,size
  if clone:IsA("Model") then cf,size=clone:GetBoundingBox() else cf,size=clone.CFrame,clone.Size end
  local target=origin+Vector3.new(((n-1)%info.cols-(info.cols-1)/2)*info.dx,size.Y/2,math.floor((n-1)/info.cols)*info.dz-30)
  local delta=target-cf.Position
  if clone:IsA("Model") then clone:PivotTo(clone:GetPivot()+delta) else clone.CFrame+=delta end
  for _,part in clone:GetDescendants() do if part:IsA("BasePart") then part.Anchored=true end end
 end
 table.insert(result,{sheet=info.name,origin=tostring(origin),assets=#units})
end
return result

