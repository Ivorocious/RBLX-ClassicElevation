--!nonstrict
return function(port)
 assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177 and not game.RunService:IsRunning())
 local H,E,S=game.HttpService,game.EncodingService,game.SerializationService
 local before=H.HttpEnabled
 local function hash(bytes)local b=E:ComputeBufferHash(bytes,Enum.HashAlgorithm.Sha256);local p={};for i=0,buffer.len(b)-1 do p[#p+1]=string.format("%02x",buffer.readu8(b,i))end;return table.concat(p)end
 local ok,text=pcall(function()H.HttpEnabled=true;return H:GetAsync("http://127.0.0.1:"..port.."/enclosure_er01_manifest.json")end)
 H.HttpEnabled=before;assert(ok,text)
 assert(hash(buffer.fromstring(text))=="408808da502372c0bc911febbe269d5aa47eec45d46fefe474fedab30067f7d6")
 local manifest=H:JSONDecode(text);local destination=game.ServerStorage.CourseAssetKits
 assert(not destination:FindFirstChild("MoonlitCitadel_Enclosure_ER01Library"),"Preserve existing imported kit")
 local loaded=game.InsertService:LoadAsset(83390081804897)
 local expected,found={},{};for _,row in manifest.export_parts do expected[row.name]=row end
 local count,maxError=0,0
 for _,p in loaded:GetDescendants() do
  assert(not p:IsA("LuaSourceContainer"),"Imported scripts forbidden")
  if p:IsA("BasePart") then
   assert(p:IsA("MeshPart") and expected[p.Name],"Unexpected import part "..p.Name)
   local error=(p.Size-Vector3.new(table.unpack(expected[p.Name].roblox_size))).Magnitude
   assert(error<.008,"Imported size mismatch "..p.Name..":"..error);maxError=math.max(maxError,error)
   assert(not found[p.Name]);found[p.Name]=p;count+=1
  end
 end
 assert(count==manifest.part_count)
 local library=Instance.new("Model");library.Name="MoonlitCitadel_Enclosure_ER01Library"
 for index,row in manifest.export_parts do
  local unit=library:FindFirstChild(row.asset)
  if not unit then unit=Instance.new("Model");unit.Name,unit.Parent=row.asset,library;unit.WorldPivot=CFrame.identity end
  local p=found[row.name]:Clone();p.Size=Vector3.new(table.unpack(row.roblox_size));p.CFrame=CFrame.new(Vector3.new(table.unpack(row.roblox_center)))*CFrame.Angles(0,math.pi,0)
  p.PivotOffset=CFrame.identity;p.Color=Color3.fromRGB(table.unpack(row.rgb));p.Material=Enum.Material.SmoothPlastic
  p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch,p.Transparency=true,false,false,false,0
  p.RenderFidelity=Enum.RenderFidelity.Precise
  p:SetAttribute("Role","Decoration");p:SetAttribute("SourceAsset",row.asset);p:SetAttribute("SourceMaterial",row.material);p:SetAttribute("SourceTriangles",row.triangles)
  p.Parent=unit;if index%24==0 then task.wait()end
 end
 library.WorldPivot=CFrame.identity;library:SetAttribute("AxisNormalization","Raw FBX depth mapped by180-degree local yaw")
 library:SetAttribute("ImportVerified",true);library:SetAttribute("EnclosureImportVerified",true);library:SetAttribute("AxisVerified",false)
 library:SetAttribute("AssetId","83390081804897");library:SetAttribute("SourceSHA256","8910e3e6ef3a7d8287376fc1b21e3262820c6ae165ae99211fb703e7c762eb04")
 library:SetAttribute("ManifestSHA256","408808da502372c0bc911febbe269d5aa47eec45d46fefe474fedab30067f7d6");library:SetAttribute("LibraryTriangles",manifest.export_triangles)
 loaded.Name,loaded.Parent="MoonlitCitadel_Enclosure_ER01Import",game.ServerStorage.AssetImports;library.Parent=destination
 local bytes=S:SerializeInstancesAsync({library})
 local sent,response=pcall(function()H.HttpEnabled=true;return H:RequestAsync({Url="http://127.0.0.1:"..port.."/enclosure_er01_library_before_axes.rbxm",Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=buffer.tostring(bytes)})end)
 H.HttpEnabled=before;assert(sent,response);assert(response.Success,response.Body)
 local receipt=H:JSONDecode(response.Body);assert(receipt.sha256==hash(bytes))
 return H:JSONEncode({ok=true,library=library:GetFullName(),count=count,maxSizeError=maxError,triangles=manifest.export_triangles,httpRestored=H.HttpEnabled==before,receipt=receipt})
end