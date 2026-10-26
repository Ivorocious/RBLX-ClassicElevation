local SS,H=game.ServerStorage,game:GetService("HttpService")
local rec=SS.MoonlitP3ReworkRecovery.FinalSurfaces20261020
assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
local archive=SS.DeveloperArchives.MoonlitCitadel.Cleanup20261020
assert(#archive.RestoreLinks:GetChildren()==113)
local addedParts,addedInstances=0,0
for i,name in {"MoonlitCitadel_Surface_SR01Import","MoonlitCitadel_Surface_SR02Import"} do
 local root=assert(SS.AssetImports:FindFirstChild(name))
 for _,v in game:GetDescendants() do
  if v:IsA("ObjectValue") and v.Value and (v.Value==root or v.Value:IsDescendantOf(root)) then
   assert(v:IsDescendantOf(root),"Raw repair import is still referenced")
  end
 end
 local parts,instances=0,1
 for _,v in root:GetDescendants() do
  instances+=1;if v:IsA("BasePart") then parts+=1 end
  assert(not v:IsA("LuaSourceContainer"),"Unexpected raw import code")
 end
 local link=Instance.new("Folder");link.Name=string.format("%03d",113+i)
 link:SetAttribute("OriginalPath",root:GetFullName());link:SetAttribute("Parts",parts);link:SetAttribute("Instances",instances)
 local parent=Instance.new("ObjectValue");parent.Name="OriginalParent";parent.Value=root.Parent;parent.Parent=link
 local value=Instance.new("ObjectValue");value.Name="ArchivedRoot";value.Value=root;value.Parent=link
 link.Parent=archive.RestoreLinks;root.Parent=archive.RawImports
 addedParts+=parts;addedInstances+=instances;task.wait()
end
archive:SetAttribute("RootCount",115)
archive:SetAttribute("PartCount",archive:GetAttribute("PartCount")+addedParts)
archive:SetAttribute("InstanceCount",archive:GetAttribute("InstanceCount")+addedInstances)
local totalParts,totalInstances=0,0
for _,link in archive.RestoreLinks:GetChildren() do
 local root=assert(link.ArchivedRoot.Value);assert(link.OriginalParent.Value and root.Parent.Parent==archive)
 local p,n=if root:IsA("BasePart") then 1 else 0,1
 for _,v in root:GetDescendants() do n+=1;if v:IsA("BasePart") then p+=1 end end
 assert(p==link:GetAttribute("Parts") and n==link:GetAttribute("Instances"))
 totalParts+=p;totalInstances+=n;task.wait()
end
assert(totalParts==archive:GetAttribute("PartCount") and totalInstances==archive:GetAttribute("InstanceCount"))
local activeKits={"MoonlitCitadel_BL02Library","MoonlitCitadel_P3Rework_RW01Library","MoonlitCitadel_P3ArtRepair_AR01Library","MoonlitCitadel_TowerLandscape_TL01Library","MoonlitCitadel_Enclosure_ER01Library","MoonlitCitadel_Detail_DT02Library","MoonlitCitadel_Surface_SR02Library"}
for _,name in activeKits do assert(SS.CourseAssetKits:FindFirstChild(name),name) end
assert(SS.MoonlitP3ReworkRecovery.DetailPass20261014.CaptureSnapshot53)
assert(workspace.Course_MoonlitCitadel:GetAttribute("SourceRevision")==57 and SS.CourseLibrary.Course_MoonlitCitadel:GetAttribute("SourceRevision")==57)
if rec:FindFirstChild("FreshBuild57") then rec.FreshBuild57:Destroy() end
local report={pass=true,source=57,roots=115,parts=totalParts,instances=totalInstances,
 groups={P3ReworkHistory=93,LegacyRecoveries=4,RetiredLibraries=4,RawImports=14},activeLibraries=7,
 allRestoreLinksAndCountsPass=true,currentModelsPreserved=true,currentRecoveryPreserved=true,captureHelperPreserved=true,
 ownFreshBuildScratchRemoved=true,userInstancesDeleted=0,storedMemoryReductionClaim=false}
local value=Instance.new("StringValue");value.Name="CleanupFinalProof57";value.Value=H:JSONEncode(report);value.Parent=rec
local install=H:JSONDecode(rec.NativeInstallProof57.Value);install.cleanupRoots=115;rec.NativeInstallProof57.Value=H:JSONEncode(install)
return report
