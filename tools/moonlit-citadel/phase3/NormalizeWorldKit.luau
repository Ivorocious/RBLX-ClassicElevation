--!nonstrict
return function(port, manifestHash)
 assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
 assert(game.PlaceId==85558151074819 and game.GameId==10191126818 and game.CreatorId==86069177)
 local H=game.HttpService
 local beforeHttp=H.HttpEnabled
 local report={}
 local ok,why=xpcall(function()
  H.HttpEnabled=true
  local response=H:RequestAsync({Url="http://127.0.0.1:"..port.."/MC_P3_world_manifest.json",Method="GET"})
  assert(response.Success,response.StatusCode)
  local bytes=game.EncodingService:ComputeBufferHash(buffer.fromstring(response.Body),Enum.HashAlgorithm.Sha256)
  local pieces={};for i=0,buffer.len(bytes)-1 do pieces[#pieces+1]=string.format("%02x",buffer.readu8(bytes,i)) end
  assert(table.concat(pieces)==manifestHash,"Manifest hash mismatch")
  local manifest=H:JSONDecode(response.Body)
  local imported=assert(game.ServerStorage.AssetImports:FindFirstChild("MoonlitCitadel_P3World_C01Import"))
  local destination=game.ServerStorage.CourseAssetKits
  assert(not destination:FindFirstChild("MoonlitCitadel_P3World_C01Library"),"Preserve the existing P3 library")
  local expected,count,maxError={},0,0
  for _,row in manifest.export_parts do expected[row.name]=row end
  for _,p in imported:GetDescendants() do
   assert(not p:IsA("LuaSourceContainer"),"Unexpected imported script")
   if not p:IsA("BasePart") then continue end
   assert(p:IsA("MeshPart") and expected[p.Name],"Unexpected mesh "..p.Name)
   local size=Vector3.new(table.unpack(expected[p.Name].roblox_size))
   local difference=(p.Size-size).Magnitude
   assert(difference<.003,"Scale mismatch "..p.Name..":"..difference)
   maxError=math.max(maxError,difference);count+=1
  end
  assert(count==30 and count==#manifest.export_parts,"Incomplete import")
  local library=Instance.new("Model");library.Name="MoonlitCitadel_P3World_C01Library"
  for _,row in manifest.export_parts do
   local unit=library:FindFirstChild(row.asset)
   if not unit then unit=Instance.new("Model");unit.Name,unit.Parent=row.asset,library;unit.WorldPivot=CFrame.identity;unit:SetAttribute("MCEditUnit",row.asset) end
   local p=assert(imported:FindFirstChild(row.name,true)):Clone()
   p.CFrame,p.Size=CFrame.new(Vector3.new(table.unpack(row.roblox_center))),Vector3.new(table.unpack(row.roblox_size))
   p.Color=Color3.fromRGB(table.unpack(row.rgb))
   p.Material=if row.material:find("Stone",1,true) or row.material=="Floor" then Enum.Material.Limestone elseif row.material:find("Slate",1,true) then Enum.Material.Slate elseif row.material=="Iron" or row.material=="Brass" then Enum.Material.Metal else Enum.Material.SmoothPlastic
   p.Transparency,p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=0,true,false,false,false
   p.CastShadow=not row.material:find("Leaf",1,true) and row.material~="Brass"
   p:SetAttribute("Role","Decoration");p:SetAttribute("SourceMaterial",row.material);p:SetAttribute("SourceAsset",row.asset);p:SetAttribute("SourceTriangles",row.triangles)
   p.Parent=unit
  end
  library.WorldPivot=CFrame.identity
  library:SetAttribute("CandidateId","MC_P3_WORLD_KIT_C01");library:SetAttribute("OpenCloudAssetId","73456811793403")
  library:SetAttribute("SourceFile","assets/moonlit_citadel/phase3/candidate01/MC_P3_WORLD_KIT.fbx")
  library:SetAttribute("SourceSHA256","9ec7e9add8665ecc3c6ac5aed585c14402086924072f834f75b5089c29e4ff31")
  library:SetAttribute("ImportVerified",true);library:SetAttribute("LibraryTriangles",manifest.export_triangles)
  library.Parent=destination
  report={parts=count,units=#library:GetChildren(),maxSizeError=maxError,assetId="73456811793403",triangles=manifest.export_triangles,path=library:GetFullName()}
 end,debug.traceback)
 H.HttpEnabled=beforeHttp
 report.ok,report.failure,report.httpRestored=ok,why,H.HttpEnabled==beforeHttp
 return H:JSONEncode(report)
end
