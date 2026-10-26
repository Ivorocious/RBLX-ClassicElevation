assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
local fingerprint=(function()
__FINGERPRINT__
end)()
local root=workspace.SGV2_Phase3_F04
assert(fingerprint(root).hash=="75cbafea","Candidate changed")
local work=game.ServerStorage.SGV2_Work
assert(not work:FindFirstChild("Phase3_F04_ExportBuffer"),"Export buffer already exists")
local serializer=game:GetService("SerializationService")
local bytes=serializer:SerializeInstancesAsync({root})
local restored=serializer:DeserializeInstancesAsync(bytes)
local before,after=fingerprint(root),fingerprint(restored[1])
assert(before.hash==after.hash and before.parts==after.parts,"Native round trip differs")
local scripts,hulls=0,0
for _,p in restored[1]:GetDescendants() do
    if p:IsA("LuaSourceContainer") then scripts+=1 end
    if p:IsA("MeshPart") and p:GetAttribute("CorrectionIndex") then
        assert(p.CollisionFidelity==Enum.CollisionFidelity.Hull,"Restored contact changed")
        hulls+=1
    end
end
assert(scripts==0 and hulls==9)
for _,p in restored do p:Destroy() end
local encoding=game:GetService("EncodingService")
local compressed=encoding:CompressBuffer(bytes,Enum.CompressionAlgorithm.Zstd,3)
local encoded=buffer.tostring(encoding:Base64Encode(compressed))
local folder=Instance.new("Folder")
folder.Name="Phase3_F04_ExportBuffer"
folder.Parent=work
for i=1,math.ceil(#encoded/45000) do
    local chunk=Instance.new("StringValue")
    chunk.Name=string.format("Chunk_%02d",i)
    chunk.Value=encoded:sub((i-1)*45000+1,i*45000)
    chunk.Parent=folder
end
folder:SetAttribute("Bytes",buffer.len(bytes))
folder:SetAttribute("CandidateId",root.Name)
folder:SetAttribute("Compression","Zstd")
return game:GetService("HttpService"):JSONEncode({bytes=buffer.len(bytes),compressedBytes=buffer.len(compressed),
    base64Length=#encoded,chunks=#folder:GetChildren(),fingerprint=before,roundTrip=after,
    restoredHullMeshes=hulls,scripts=scripts,buffer=folder:GetFullName()})
