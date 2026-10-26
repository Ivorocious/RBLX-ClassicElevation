local SS=game.ServerStorage
local H=game:GetService("HttpService")
local rec=SS.MoonlitP3ReworkRecovery.FinalSurfaces20261020
assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
local rows=H:JSONDecode([==[[{"asset":"MC_AR_GalleryBody46","material":"Stone","name":"MC_AR_GalleryBody46__Stone","old":"rbxassetid://74777192495639","new":"rbxassetid://110675077090500","before":72,"after":85},{"asset":"MC_AR_GalleryBody46","material":"StoneLight","name":"MC_AR_GalleryBody46__StoneLight","old":"rbxassetid://118738378150073","new":"rbxassetid://130321844193232","before":324,"after":332},{"asset":"MC_ER_LanternBracket","material":"Stone","name":"MC_ER_LanternBracket__Stone","old":"rbxassetid://106822859589956","new":"rbxassetid://103505608210895","before":24,"after":32},{"asset":"MC_GuideIron","material":"Iron","name":"MC_GuideIron__Iron","old":"rbxassetid://95347984279384","new":"rbxassetid://94053570210534","before":132,"after":160},{"asset":"MC_P3_SlateGable","material":"StoneLight","name":"MC_P3_SlateGable__StoneLight","old":"rbxassetid://125835125733789","new":"rbxassetid://74254182455173","before":144,"after":156},{"asset":"MC_WeightIron","material":"Iron","name":"MC_WeightIron__Iron","old":"rbxassetid://91450645007176","new":"rbxassetid://74196985263519","before":48,"after":72},{"asset":"MC_WindowTracery","material":"Lead","name":"MC_WindowTracery__Lead","old":"rbxassetid://118114614682002","new":"rbxassetid://135492025140978","before":1312,"after":1340}]]==])
assert(not SS.CourseAssetKits:FindFirstChild("MoonlitCitadel_Surface_SR02Library"))
local lib=Instance.new("Folder");lib.Name="MoonlitCitadel_Surface_SR02Library"
for _,row in rows do
 local source=assert(SS.AssetImports.MoonlitCitadel_Surface_SR02Import:FindFirstChild(row.name,true))
 assert(source:IsA("MeshPart") and source.MeshId==row.new)
 local part=source:Clone()
 part.CFrame=CFrame.identity;part.Size=source.MeshSize
 part.Anchored,part.CanCollide,part.CanQuery,part.CanTouch=true,false,false,false
 part:SetAttribute("SourceAsset",row.asset);part:SetAttribute("SourceMaterial",row.material);part:SetAttribute("SourceTriangles",row.after)
 part:SetAttribute("OriginalMeshId",row.old)
 part.Parent=lib
end
lib:SetAttribute("ImportVerified",true);lib:SetAttribute("AxisVerified",true)
lib:SetAttribute("AssetId",99796608028640)
lib:SetAttribute("PayloadSHA256","b6382dbc2c0f631c548475e51fa2263c0afffadd006b2f75a6c4cbfb2112e419")
lib:SetAttribute("NativeSelfOverlaps",0);lib:SetAttribute("Triangles",2177);lib.Parent=SS.CourseAssetKits
local folder=Instance.new("Folder");folder.Name="FreshBuild57";folder.Parent=rec
local ok,result=xpcall(function() return require(rec.FinalCandidate57.RouteBuilder).Build(folder) end,debug.traceback)
assert(ok,result)
local course=result
local p,m=0,0
for _,v in course:GetDescendants() do if v:IsA("BasePart") then p+=1 end;if v:IsA("MeshPart") then m+=1 end end
local world=course.Decoration.Phase3World
return {pass=true,fixture=course:GetFullName(),parts=p,meshes=m,source=course:GetAttribute("SourceRevision"),build=course:GetAttribute("BuildRevision"),candidate=course:GetAttribute("CandidateId"),world=world:GetAttributes(),library=lib:GetFullName()}
