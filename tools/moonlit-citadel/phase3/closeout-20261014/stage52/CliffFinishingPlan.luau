--!nonstrict
local Finishing={}
local v=Vector3.new
local Metadata={
 ["MC_P3_Rework_RockCluster"]={parts=1,triangles=156,low=v(-4.650166512,0,-3.186931372),high=v(4.198452473,2.799999952,2.051786661),library="P3"},
 ["MC_EC_SlopePine"]={parts=2,triangles=348,low=v(-7.300000191,-2,-6.942712784),high=v(7.300000191,34,6.942712784),library="ER01"},
 ["MC_EC_SlopeBroadleaf"]={parts=2,triangles=228,low=v(-8.77435112,-2,-9.504844666),high=v(8.77435112,30,9.504844666),library="ER01"},
 ["MC_P3_Rural_HeatherFern"]={parts=2,triangles=360,low=v(-9,-0.25,-4.5),high=v(9,2.799999952,6),library="TL01"},
}
local Units={
 {district="CliffFinishing",name="WestCliffLowerFold",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-325,83,-88,0,1,0,0,0,1,1,0,0),scale=v(4.5,6.4,3),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="WestCliffUpperFold",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-325.5,137,-67,0,1,0,0,0,1,1,0,0),scale=v(3.3,5.6,2.8),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="WestCliffMiddleFold",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-324.25,121,14,0,1,0,0,0,1,1,0,0),scale=v(4,6.4,3),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="WestCliffArrivalFold",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-321.25,91,73,0,1,0,0,0,1,1,0,0),scale=v(4.6,6.8,2.9),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="WestCliffSouthShoulder",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-337.75,165,114,0,1,0,0,0,1,1,0,0),scale=v(3.1,5,2.5),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="NorthCliffWestFold",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-174,145,-275.75,1,0,0,0,0,-1,0,1,0),scale=v(3.8,6,3.4),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="NorthCliffCentralFold",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-102,186,-272.75,1,0,0,0,0,-1,0,1,0),scale=v(3.2,5.3,2.8),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="NorthCliffGalleryFold",asset="MC_P3_Rework_RockCluster",localCF=CFrame.new(-52,153,-262.75,1,0,0,0,0,-1,0,1,0),scale=v(3.6,6.5,2.7),library="P3",materialRole="EmbeddedCliffRock"},
 {district="CliffFinishing",name="WestCliffLowPine",asset="MC_EC_SlopePine",localCF=CFrame.new(-331.25,93.887660076,-112,0.91308894,0,0.407760453,0,1,0,-0.407760453,0,0.91308894),scale=v(0.8,0.8,0.8),library="ER01",materialRole="CliffTreeGroup"},
 {district="CliffFinishing",name="WestCliffLowBroadleaf",asset="MC_EC_SlopeBroadleaf",localCF=CFrame.new(-319.5,69.457764905,-95,0.453596121,0,0.89120736,0,1,0,-0.89120736,0,0.453596121),scale=v(0.84,0.84,0.84),library="ER01",materialRole="CliffTreeGroup"},
 {district="CliffFinishing",name="WestCliffMiddleBroadleaf",asset="MC_EC_SlopeBroadleaf",localCF=CFrame.new(-322.5,110.352824866,-5,-0.666276021,0,0.745705212,0,1,0,-0.745705212,0,-0.666276021),scale=v(0.91,0.91,0.91),library="ER01",materialRole="CliffTreeGroup"},
 {district="CliffFinishing",name="WestCliffArrivalPine",asset="MC_EC_SlopePine",localCF=CFrame.new(-321.5,97.185934942,94,-0.942222341,0,0.33498815,0,1,0,-0.33498815,0,-0.942222341),scale=v(0.78,0.78,0.78),library="ER01",materialRole="CliffTreeGroup"},
 {district="CliffFinishing",name="NorthCliffLowBroadleaf",asset="MC_EC_SlopeBroadleaf",localCF=CFrame.new(-153,110.894733135,-269,0.696706709,0,0.717356091,0,1,0,-0.717356091,0,0.696706709),scale=v(0.86,0.86,0.86),library="ER01",materialRole="CliffTreeGroup"},
 {district="CliffFinishing",name="NorthCliffLowPine",asset="MC_EC_SlopePine",localCF=CFrame.new(-68,123.168961785,-259.75,-0.128844494,0,0.99166481,0,1,0,-0.99166481,0,-0.128844494),scale=v(0.79,0.79,0.79),library="ER01",materialRole="CliffTreeGroup"},
 {district="CliffFinishing",name="WestCliffHerbs1",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-333,112.278730887,-111,0.118965226,0.990240177,0.07260625,-0.947955257,0.135027896,-0.288354464,-0.295344045,-0.034523323,0.954767006),scale=v(1.1,1.1,1.1),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="WestCliffHerbs2",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-320.5,75.38147227,-88,0.230039296,0.97236706,0.039802299,-0.152418154,0.076392683,-0.985359257,-0.961171488,0.220604757,0.165779711),scale=v(1,1,1),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="WestCliffHerbs3",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-342,185.653964772,-77,-0.547821661,0.704377203,0.451380309,0.291825445,0.666547468,-0.685968208,-0.78404677,-0.244063984,-0.570704332),scale=v(1.1,1.1,1.1),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="WestCliffHerbs4",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-322.25,129.006867371,-20,0.06998525,0.997266593,0.023694026,-0.97756637,0.073294281,-0.197463772,-0.19866066,-0.009342932,0.980023802),scale=v(0.95,0.95,0.95),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="WestCliffHerbs5",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-344.75,205.890052533,27,-0.09138426,0.641812051,0.761397536,0.243392911,0.755802629,-0.607883441,-0.965613177,0.129767784,-0.225280968),scale=v(1,1,1),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="WestCliffHerbs6",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-322,112.969920081,89,-0.046412936,0.996799825,0.065084165,0.736017986,0.078175669,-0.672432962,-0.675369057,0.016693528,-0.737290962),scale=v(1.1,1.1,1.1),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="NorthCliffHerbs1",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-185,267.736108483,-307.25,0.993945805,-0.006108701,0.109701503,0.096608596,0.524145842,-0.846131146,-0.052330824,0.851606611,0.521562714),scale=v(1.05,1.05,1.05),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="NorthCliffHerbs2",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-144,109.39643362,-259.5,-0.893411026,-0.364363653,0.262784829,0.253529779,0.073960742,0.964495962,-0.370863032,0.928315107,0.026299694),scale=v(0.95,0.95,0.95),library="TL01",materialRole="CliffUnderstory"},
 {district="CliffFinishing",name="NorthCliffHerbs3",asset="MC_P3_Rural_HeatherFern",localCF=CFrame.new(-66,158.303129991,-260.75,-0.968379899,-0.123799722,-0.216596398,-0.224438078,0.053193568,0.973035453,-0.108939984,0.990880453,-0.079296954),scale=v(1,1,1),library="TL01",materialRole="CliffUnderstory"},
}
function Finishing.Get()
 local plan,rows={},{}
 local counts={units=0,meshParts=0,triangles=0,proposalRows=rows,artCanCollide=false,artCanQuery=false,artCanTouch=false}
 for _,unit in Units do
  local meta=assert(Metadata[unit.asset])
  table.insert(plan,table.clone(unit))
  counts.units+=1;counts.meshParts+=meta.parts;counts.triangles+=meta.triangles
  local cf=unit.localCF*CFrame.new((meta.low+meta.high)/2*unit.scale)
  local size=(meta.high-meta.low)*unit.scale
  table.insert(rows,{path="CliffFinishing/"..unit.name,frame={cf:GetComponents()},size={size.X,size.Y,size.Z},anchored=true,collide=false,query=false,touch=false,transparency=0})
 end
 return plan,counts
end
Finishing.AssetGeometry=Metadata
return Finishing
