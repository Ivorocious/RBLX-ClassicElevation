--!nonstrict
local archive=game.ServerStorage.EggRushChickenR05_20261026
local course=archive.Candidate_ChickenR05_C01
local rig=course.Obstacles.Mechanisms.GuardianPeck
local source=archive.BuildSources_C01
local controller=require(source.ChickenPeck).Bind(rig,course,require(source.GuardianPeck).Sample)
local courseFrame=course:GetPivot()
local nodes={rig.Body,rig.Head,rig.Feet.Left,rig.Feet.Right,rig.NeckLower,rig.NeckUpper}
local function frames()
 local result={}
 for _,p in nodes do table.insert(result,{courseFrame:ToObjectSpace(p:GetPivot()):GetComponents()}) end
 return result
end
local data={candidate=course:GetAttribute("CandidateId"),groups={"Body","Head","FootLeft","FootRight","NeckLower","NeckUpper"},home=frames(),frames={},impacts={}}
local refs=rig.Targets:GetChildren();table.sort(refs,function(a,b)return a.Name<b.Name end)
local function markers()
 local result={};for _,ref in refs do local c=ref.Value.Color;table.insert(result,{c.R,c.G,c.B})end;return result
end
for index=0,207 do
 local time=index*17.25/207
 controller.Advance(0,time,function()end,false)
 table.insert(data.frames,{time=time,pose=frames(),markers=markers(),state=rig:GetAttribute("ERState"),target=rig:GetAttribute("ERPeckTarget")})
 if index%10==0 then task.wait() end
end
for target=1,3 do controller.Advance(0,(target-1)*5.75+4.7,function()end,false);table.insert(data.impacts,{target=target,pose=frames(),markers=markers()})end
controller.Stop()
local raw=game.HttpService:JSONEncode(data)
local folder=Instance.new("Folder");folder.Name="PoseSnapshot_C01";assert(not archive:FindFirstChild(folder.Name));folder.Parent=archive
local chunks={}
for offset=1,#raw,40000 do local p=Instance.new("StringValue");p.Name=string.format("Chunk_%03d",#chunks+1);p.Value=raw:sub(offset,offset+39999);p.Parent=folder;table.insert(chunks,p.Name) end
return game.HttpService:JSONEncode({folder=folder.Name,bytes=#raw,chunks=chunks,frames=#data.frames,candidate=data.candidate})
