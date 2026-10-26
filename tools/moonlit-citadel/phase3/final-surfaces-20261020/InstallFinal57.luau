local SS,H=game.ServerStorage,game:GetService("HttpService")
local rec=SS.MoonlitP3ReworkRecovery.FinalSurfaces20261020
assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
local candidate=rec.FinalCandidate57
local F,V=require(candidate.SurfaceFinishingPlan),require(candidate.SurfaceMeshVariants)
local W,L,E=require(candidate.WorldPlan),require(candidate.Layout),require(candidate.EnvironmentPlan)
local plan,counts=W.Get(L);local outer,oc=E.Get(L,counts.plantingMounts,counts.assemblies)
for _,r in outer do table.insert(plan,r) end
assert(#plan==315 and counts.triangles+oc.triangles==272145)
local pose={};for _,p in H:JSONDecode([==[["Decoration/Phase3World/CrownArrival/CrownBaseUnifiedShell/MC_ER_CrownBaseShell__StoneLight","Decoration/Phase3World/CrownArrival/CrownEmblemLowerPier/MC_AR_MasonryMass__Stone","Decoration/Phase3World/CrownArrival/CrownSouthScreenFoot1/MC_AR_MasonryMass__StoneLight","Decoration/Phase3World/CrownArrival/CrownWestScreenFoot1/MC_AR_MasonryMass__StoneDark","Decoration/Phase3World/CrownArrival/CrownWestScreenFoot1/MC_AR_MasonryMass__StoneLight","Decoration/Phase3World/DT_West/WestArrivalNorthJambNiche/MC_DT_FacadeNiche__StoneLight","Decoration/Phase3World/DT_West/WestHighJambNiche/MC_DT_FacadeNiche__Stone","Decoration/Phase3World/DT_West/WestHighJambNiche/MC_DT_FacadeNiche__StoneDark","Decoration/Phase3World/DT_West/WestHighJambNiche/MC_DT_FacadeNiche__StoneLight","Decoration/Phase3World/FortressRamparts/WestSteppedCurtain2/MC_ER_Rampart__Stone","Decoration/Phase3World/FortressRamparts/WestSteppedCurtain2/MC_ER_Rampart__StoneDark","Decoration/Phase3World/FortressRamparts/WestSteppedCurtain2/MC_ER_Rampart__StoneLight","Decoration/Phase3World/GalleryKeepJunction/JunctionEastSeatedRoof/MC_AR_GalleryRoof46__SlateBand","Decoration/Phase3World/GalleryKeepJunction/JunctionWestSeatedRoof/MC_AR_GalleryRoof46__SlateBand","Decoration/Phase3World/GrandKeep/NorthGrandButtress-1/MC_TL_SteppedButtress__Stone","Decoration/Phase3World/GrandKeep/NorthGrandButtress1/MC_TL_SteppedButtress__Stone","Decoration/Phase3World/GrandKeep/SouthGrandButtress-1/MC_TL_SteppedButtress__Stone","Decoration/Phase3World/GrandKeep/SouthGrandButtress1/MC_TL_SteppedButtress__Stone","Decoration/Phase3World/GrandKeep/UpperKeepWarmLancet1MC_WindowFrame/MC_WindowFrame__Stone","Decoration/Phase3World/GrandKeep/UpperKeepWarmLancet2MC_WindowFrame/MC_WindowFrame__Stone","Decoration/Phase3World/LanternPendulums/Gallery1EnclosedBody/MC_AR_GalleryBody46__StoneDark","Decoration/Phase3World/LanternPendulums/Gallery1PlanterShelf-1/MC_AR_MasonryMass__StoneLight","Decoration/Phase3World/LanternPendulums/Gallery2EnclosedBody/MC_AR_GalleryBody46__StoneDark","Decoration/Phase3World/LanternPendulums/Gallery2PlanterShelf-1/MC_AR_MasonryMass__StoneLight","Decoration/Phase3World/LanternPendulums/Gallery3EnclosedBody/MC_AR_GalleryBody46__StoneDark","Decoration/Phase3World/LanternPendulums/GalleryInteriorQuietLancet1MC_WindowFrame/MC_WindowFrame__Stone","Decoration/Phase3World/LanternPendulums/GalleryInteriorQuietLancet2MC_WindowFrame/MC_WindowFrame__Stone","Decoration/Phase3World/LanternPendulums/GalleryInteriorQuietLancet3MC_WindowFrame/MC_WindowFrame__Stone","Decoration/Phase3World/RaisedFortressCourts/NorthEastRaisedCourt/MC_ER_RaisedCourt__Slate","Decoration/Phase3World/RaisedFortressCourts/NorthWestRaisedCourt/MC_ER_RaisedCourt__Stone","Decoration/Phase3World/SteppedFortressWings/EastUpperDeepWing/MC_ER_SteppedWing__Stone","Obstacles/ArchCatchReturn/Ramp_2/StoneSkin/MC_FloorStone__Floor","Obstacles/ArchCatchReturn/Ramp_2/StoneSkin/MC_FloorStone__StoneDark","Obstacles/GalleryExpertApproach/BetweenBandRail2/StoneSkin/MC_FloorStone__Floor","Obstacles/GalleryExpertApproach/BetweenBandRail2/StoneSkin/MC_FloorStone__StoneDark","Obstacles/GalleryExpertApproach/BetweenBandRail3/StoneSkin/MC_FloorStone__Floor","Obstacles/GalleryExpertApproach/BetweenBandRail3/StoneSkin/MC_FloorStone__StoneDark","Obstacles/GalleryExpertApproach/EntryRail/StoneSkin/MC_FloorStone__Floor","Obstacles/GalleryExpertApproach/EntryRail/StoneSkin/MC_FloorStone__StoneDark","Obstacles/GalleryExpertShortcut/LiftNeedle1/StoneSkin/MC_FloorStone__Floor","Obstacles/GalleryExpertShortcut/LiftNeedle1/StoneSkin/MC_FloorStone__StoneDark","Obstacles/LiftCatchReturn/Ramp_2/StoneSkin/MC_FloorStone__Floor","Obstacles/LiftCatchReturn/Ramp_2/StoneSkin/MC_FloorStone__StoneDark","Obstacles/LiftCatchReturn/Ramp_3/StoneSkin/MC_FloorStone__Floor","Obstacles/LiftCatchReturn/Ramp_3/StoneSkin/MC_FloorStone__StoneDark","Obstacles/MovingCars/Lower_Bay1/MC_CarIronBrass/MC_CarIronBrass__Brass","Obstacles/MovingCars/Lower_Bay2/MC_CarIronBrass/MC_CarIronBrass__Brass","Obstacles/MovingCars/Upper_Bay1/MC_CarIronBrass/MC_CarIronBrass__Brass","Obstacles/MovingCars/Upper_Bay2/MC_CarIronBrass/MC_CarIronBrass__Brass","Obstacles/RouteHazards/ArchExpert_FinalRiseRail_Red35/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_FinalRiseRail_Red35/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_FirstNeedle_Red26/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_FirstNeedle_Red26/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_HighNeedle_Red28/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_HighNeedle_Red28/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_HighNeedle_Red29/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_HighNeedle_Red29/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_InnerTakeoff_Red23/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_InnerTakeoff_Red23/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_MergeTurn_Red34/IronBrassMount-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_MergeTurn_Red34/IronBrassMount1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_OffsetCorbel_Red30/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_OffsetCorbel_Red31/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_ReturnBeam_Red33/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_ReturnBeam_Red33/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_ReturnTurn_Red32/IronBrassMount-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_ReturnTurn_Red32/IronBrassMount1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_RiseCorbel_Red24/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_RiseCorbel_Red24/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_RiseCorbel_Red25/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_RiseCorbel_Red25/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_WrapTurn_Red27/IronBrassMount-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchExpert_WrapTurn_Red27/IronBrassMount1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_1_1_Red6/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_1_1_Red6/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_2_1_Red7/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_2_3_Red8/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_2_3_Red8/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_2_4_Red9/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_3_1_Red10/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/ArchNormal_Causeway_3_1_Red10/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_1_1_Red18/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_1_1_Red18/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_1_2_Red19/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_2_2_Red20/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_2_2_Red20/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_2_3_Red21/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_2_5_Red22/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/CrownApproach_Causeway_2_5_Red22/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertApproach_EntryRail_Red36/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertApproach_EntryRail_Red36/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle1_Red40/IronBrassPost-1/MC_GuideIron__Brass","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle1_Red40/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle1_Red40/IronBrassPost1/MC_GuideIron__Brass","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle1_Red40/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle2_Red41/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle2_Red41/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle3_Red42/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/GalleryExpertShortcut_LiftNeedle3_Red42/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/Gallery_ExpertAfter1_Red37/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/Gallery_ExpertAfter1_Red37/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/Gallery_ExpertAfter2_Red38/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/Gallery_ExpertAfter3_Red39/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/Gallery_ExpertAfter3_Red39/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/MachineryApproach_Causeway_1_1_Red11/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/MachineryApproach_Causeway_1_1_Red11/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/MachineryApproach_Causeway_1_2_Red12/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/MachineryApproach_Causeway_2_2_Red13/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/MachineryApproach_Causeway_2_2_Red13/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/MachineryApproach_Causeway_2_3_Red14/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/SharedArches_Causeway_2_2_Red2/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/SharedArches_Causeway_4_1_Red4/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/SharedArches_Causeway_4_3_Red5/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/SharedArches_Causeway_4_3_Red5/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep1_Red43/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep1_Red43/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep1_Red44/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep1_Red44/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep2_Red45/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep2_Red45/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep2_Red46/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep2_Red46/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep3_Red47/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep3_Red48/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep5_Red49/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep5_Red49/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep5_Red50/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperBrace_BraceStep5_Red50/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperNormalApproach_Causeway_2_1_Red15/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperNormalApproach_Causeway_2_1_Red15/IronBrassPost1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperNormalApproach_Causeway_2_2_Red16/IronBrassMount/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperNormalApproach_Causeway_3_1_Red17/IronBrassPost-1/MC_GuideIron__Iron","Obstacles/RouteHazards/UpperNormalApproach_Causeway_3_1_Red17/IronBrassPost1/MC_GuideIron__Iron","Obstacles/UpperBrace/BraceStep1/BraceSkin/MC_ExpertCorbel__StoneDark","Obstacles/UpperBrace/BraceStep2/BraceSkin/MC_ExpertCorbel__StoneDark","Obstacles/UpperBrace/BraceStep3/BraceSkin/MC_ExpertCorbel__StoneDark","Obstacles/UpperBrace/BraceStep4/BraceSkin/MC_ExpertCorbel__StoneDark","Obstacles/UpperBrace/BraceStep5/BraceSkin/MC_ExpertCorbel__StoneDark"]]==]) do pose[p]=true end
local variants={};for _,r in H:JSONDecode([==[[{"asset":"MC_AR_GalleryBody46","material":"Stone","name":"MC_AR_GalleryBody46__Stone","old":"rbxassetid://74777192495639","new":"rbxassetid://110675077090500","before":72,"after":85},{"asset":"MC_AR_GalleryBody46","material":"StoneLight","name":"MC_AR_GalleryBody46__StoneLight","old":"rbxassetid://118738378150073","new":"rbxassetid://130321844193232","before":324,"after":332},{"asset":"MC_ER_LanternBracket","material":"Stone","name":"MC_ER_LanternBracket__Stone","old":"rbxassetid://106822859589956","new":"rbxassetid://103505608210895","before":24,"after":32},{"asset":"MC_GuideIron","material":"Iron","name":"MC_GuideIron__Iron","old":"rbxassetid://95347984279384","new":"rbxassetid://94053570210534","before":132,"after":160},{"asset":"MC_P3_SlateGable","material":"StoneLight","name":"MC_P3_SlateGable__StoneLight","old":"rbxassetid://125835125733789","new":"rbxassetid://74254182455173","before":144,"after":156},{"asset":"MC_WeightIron","material":"Iron","name":"MC_WeightIron__Iron","old":"rbxassetid://91450645007176","new":"rbxassetid://74196985263519","before":48,"after":72},{"asset":"MC_WindowTracery","material":"Lead","name":"MC_WindowTracery__Lead","old":"rbxassetid://118114614682002","new":"rbxassetid://135492025140978","before":1312,"after":1340}]]==]) do variants[r.old]=r end
local function parts(root,canonical)
 local out={}
 for _,p in root:GetDescendants() do if p:IsA("BasePart") then
  local names={};local n=p;while n~=root do table.insert(names,1,n.Name);n=n.Parent end
  local path=table.concat(names,"/")
  if canonical then path=path:gsub("^Decoration/Wayfinding/Arrows/","Decoration/Wayfinding/") end
  assert(not out[path],"Ambiguous part");out[path]=p
 end end
 return out
end
local function equal(a,b)
 if typeof(a)~=typeof(b) then return false end
 if type(a)~="table" then return a==b end
 for k,v in a do if not equal(v,b[k]) then return false end end
 for k in b do if a[k]==nil then return false end end
 return true
end
local function metadata(p,q)
 for _,key in {"VisualTopOffset","ArrowTarget"} do
  local a,b=p:GetAttribute(key),q:GetAttribute(key)
  local changed=if typeof(a)=="number" and typeof(b)=="number" then math.abs(a-b)>.0005
   elseif typeof(a)=="Vector3" and typeof(b)=="Vector3" then (a-b).Magnitude>.0005 else false
  if changed then p:SetAttribute(key,b) end
 end
end
local fresh=parts(rec.FreshBuild57.Course_MoonlitCitadel,true)
local current={workspace.Course_MoonlitCitadel,SS.CourseLibrary.Course_MoonlitCitadel}
local originals={rec.BeforeModels56.Editable,rec.BeforeModels56.Stored}
local propNames={"Anchored","CanCollide","CanTouch","CanQuery","CastShadow","Transparency","Reflectance","Color","Material","MaterialVariant"}
for i,model in current do
 assert(model:GetAttribute("SourceRevision")==56 and model:GetAttribute("BuildRevision")==50)
 local a,b=parts(model),parts(originals[i])
 for path,p in a do
  local q=assert(b[path]);assert(p.CFrame==q.CFrame and p.Size==q.Size,path.." changed since capture")
  if p:IsA("MeshPart") then assert(p.MeshId==q.MeshId) end
  assert(equal(p:GetAttributes(),q:GetAttributes()),path.." attributes changed since capture")
  for _,key in propNames do assert(p[key]==q[key],path..":"..key) end
 end
end
local reports={}
local ok,err=xpcall(function()
 for i,model in current do
  local route=F.ApplyRoute(model);local worldCount=0
  for _,data in plan do
   local unit=assert(model.Decoration.Phase3World[data.district][data.name])
   worldCount+=F.ApplyWorldUnit(model,unit,data)
  end
  assert(route==107 and worldCount==31)
  local replaced=V.Apply(model,139)
  local now,old=parts(model),parts(originals[i])
  local poses,meshChanges,partCount,changedParts,top,arrowTargets=0,0,0,0,0,0
  local collider,walkable,hazards,arrows=0,0,0,0
  for path,p in now do
   local canonical=path:gsub("^Decoration/Wayfinding/Arrows/","Decoration/Wayfinding/")
   metadata(p,assert(fresh[canonical]))
   local q=assert(old[path]);partCount+=1
   local changed=false
   if p.CFrame~=q.CFrame or p.Size~=q.Size then assert(pose[path],path.." unexpected pose");poses+=1;changed=true end
   for _,key in propNames do assert(p[key]==q[key],path.." unexpected "..key) end
   if p:IsA("MeshPart") then
    if p.MeshId~=q.MeshId then assert(variants[q.MeshId] and p.MeshId==variants[q.MeshId].new);meshChanges+=1;changed=true end
    for _,key in {"TextureID","DoubleSided","RenderFidelity"} do assert(p[key]==q[key],path.." changed "..key) end
   end
   local aa,bb=p:GetAttributes(),q:GetAttributes();local keys={}
   for k in aa do keys[k]=true end;for k in bb do keys[k]=true end
   for key in keys do
    if equal(aa[key],bb[key]) then continue end
    local allowed=false
    if key=="SourceTriangles" and q:IsA("MeshPart") and variants[q.MeshId] then allowed=aa[key]==variants[q.MeshId].after end
    if key=="VisualTopOffset" then allowed=aa[key]==fresh[canonical]:GetAttribute(key);top+=1 end
    if key=="ArrowTarget" then allowed=aa[key]==fresh[canonical]:GetAttribute(key);arrowTargets+=1 end
    assert(allowed,path.." unexpected attribute "..key)
   end
   if changed then changedParts+=1 end
   if p.CanCollide then collider+=1 end
   if p:GetAttribute("MCWalkable") then walkable+=1 end
   if p:GetAttribute("MoonlitHazard") then hazards+=1 end
   if p:GetAttribute("SourceAsset")=="MC_P3_Rework_SolidArrow" then
    arrows+=1;assert(p.CFrame==q.CFrame and p.Size==q.Size and p.MeshId==q.MeshId,"Arrow geometry changed")
   end
  end
  assert(partCount==1775 and poses==138 and meshChanges==139 and collider==147 and walkable==135 and hazards==55 and arrows==19)
  assert(top==6 and arrowTargets==4)
  model:SetAttribute("SourceRevision",57);model:SetAttribute("BuildRevision",51)
  model:SetAttribute("CandidateId","MC_P3_FINAL_SURFACES_20261020")
  model:SetAttribute("SourcePacketHash","8c4f03338de361a397e10f7209ddd86015005857cbd50c361a7f005366d1f974")
  local world=model.Decoration.Phase3World
  for _,key in {"PlacedTriangles","DetailTriangles","ArtRepairCandidate","DetailCandidate"} do world:SetAttribute(key,rec.FreshBuild57.Course_MoonlitCitadel.Decoration.Phase3World:GetAttribute(key)) end
  table.insert(reports,{model=model:GetFullName(),parts=partCount,poseAdjustments=poses,meshReplacements=meshChanges,changedVisualParts=changedParts,
   colliders=collider,walkables=walkable,hazards=hazards,arrows=arrows,arrowGeometryExact=true,visualTopMetadata=top,arrowTargetHeightMetadata=arrowTargets,
   allOtherPartGeometryFlagsAppearanceExact=true,originalFloorAndVeilExact=true,finishGeometryExact=true})
  task.wait()
 end
end,debug.traceback)
if not ok then
 for i,model in current do
  local a,b=parts(model),parts(originals[i])
  for path,p in a do
   local q=b[path]
   if p:IsA("MeshPart") and p.MeshId~=q.MeshId then p:ApplyMesh(q) end
   p.CFrame,p.Size=q.CFrame,q.Size
   for _,key in propNames do p[key]=q[key] end
   for key in p:GetAttributes() do if q:GetAttribute(key)==nil then p:SetAttribute(key,nil) end end
   for key,value in q:GetAttributes() do p:SetAttribute(key,value) end
  end
  for key in model:GetAttributes() do if originals[i]:GetAttribute(key)==nil then model:SetAttribute(key,nil) end end
  for key,value in originals[i]:GetAttributes() do model:SetAttribute(key,value) end
  local world=model.Decoration.Phase3World
  local originalWorld=originals[i].Decoration.Phase3World
  for key in world:GetAttributes() do if originalWorld:GetAttribute(key)==nil then world:SetAttribute(key,nil) end end
  for key,value in originalWorld:GetAttributes() do world:SetAttribute(key,value) end
 end
 error("Installation rolled back: "..tostring(err))
end
local report={pass=true,source=57,build=51,packetSHA256="8c4f03338de361a397e10f7209ddd86015005857cbd50c361a7f005366d1f974",models=reports,
 freshFullBuilderPass=true,freshParts=1775,worldUnits=315,worldMeshes=869,worldTriangles=272145,visibleTriangles=367069,
 meshAssetId=99796608028640,nativeSourceRecords=37,poseManifestSHA256=F.ManifestSHA256,
 nativeMeshesVerified=true,cleanupRoots=113,published=false,wholePlaceSave=false,
 proofLimit="Finite geometry and native full-build proof; rendering and player testing are separate."}
local value=Instance.new("StringValue");value.Name="NativeInstallProof57";value.Value=H:JSONEncode(report);value.Parent=rec
return report
