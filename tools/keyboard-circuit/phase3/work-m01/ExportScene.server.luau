--!strict
assert(game.PlaceId==85558151074819)
local c=workspace.KeyboardCircuit_P3_M01_01
local parts,labels={},{}
for _, item in c:GetDescendants() do
	if item:IsA("BasePart") then
		table.insert(parts,{name=item.Name,path=item:GetFullName():sub(#c:GetFullName()+2),class=item.ClassName,cf={item.CFrame:GetComponents()},size={item.Size.X,item.Size.Y,item.Size.Z},color={item.Color.R,item.Color.G,item.Color.B},material=item.Material.Name,transparency=item.Transparency,shape=if item:IsA("Part") then item.Shape.Name else "Block",artwork=item:IsDescendantOf(c.MapEnvironment)})
	elseif item:IsA("TextLabel") and item.Parent:IsA("SurfaceGui") and item.Parent.Enabled and item.Visible and item.Text~="" then
		local part=item.Parent.Parent
		table.insert(labels,{partPath=part:GetFullName():sub(#c:GetFullName()+2),text=item.Text,face=item.Parent.Face.Name,color={item.TextColor3.R,item.TextColor3.G,item.TextColor3.B},position={item.Position.X.Scale,item.Position.Y.Scale,item.Position.X.Offset,item.Position.Y.Offset},size={item.Size.X.Scale,item.Size.Y.Scale,item.Size.X.Offset,item.Size.Y.Offset},canvas={item.Parent.CanvasSize.X,item.Parent.CanvasSize.Y}})
	end
end
local origin=c:GetAttribute("Origin")
local data={candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),origin={origin.X,origin.Y,origin.Z},parts=parts,labels=labels,limits="Exact native snapshot geometry and label strings, reconstructed offline using the existing K02 source mesh. Render lighting, text rasterization, transparency and camera are offline approximations. No Studio camera changed."}
local encoding=game:GetService("EncodingService")
shared.KCP3M01SceneExport01=buffer.tostring(encoding:Base64Encode(encoding:CompressBuffer(buffer.fromstring(game.HttpService:JSONEncode(data)),Enum.CompressionAlgorithm.Zstd,3)))
return game.HttpService:JSONEncode({parts=#parts,labels=#labels,base64Chars=#shared.KCP3M01SceneExport01,limits=data.limits})
