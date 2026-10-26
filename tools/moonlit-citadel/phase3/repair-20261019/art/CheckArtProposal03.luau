local fs,luau=require("@lune/fs"),require("@lune/luau")
local raw=fs.readFile("tools/moonlit-citadel/phase3/repair-20261019/art/CheckArtProposal.luau")
raw=raw:gsub("proposal01/proposed%-actual%-part%-bounds.json","proposal03/proposed-actual-part-bounds.json")
raw=raw:gsub("local result=clearance.CheckParts%(rows,volumes%)",[[
local retained={}
for _,row in rows do
    if string.sub(row.path,1,#"WestArchMiddleWing/")~="WestArchMiddleWing/" then table.insert(retained,row) end
end
rows=retained
local wing
for _,unit in plan.units do if unit.name=="WestArchMiddleWing" then wing=unit end end
assert(wing and math.abs(wing.localCF[1]-(-267.08))<.00001)
local geometry=load("FortressGeometry").MC_ER_SteppedWing
local cf=roblox.CFrame.new(table.unpack(wing.localCF));local scale=roblox.Vector3.new(table.unpack(wing.scale))
for index,box in geometry.occupied do
    local centre=(box.low+box.high)*.5
    local half=(box.high-box.low)*.5
    local pose=cf*roblox.CFrame.new(centre*scale)
    local size=half*2*scale
    table.insert(rows,{path="WestArchMiddleWing/VerifiedOccupied"..index,frame={pose:GetComponents()},size={size.X,size.Y,size.Z},anchored=true,collide=false,query=false,touch=false,transparency=0})
end
local result=clearance.CheckParts(rows,volumes)
]])
raw=raw:gsub('actualProposedPartAABBs=true','actualProposedPartAABBs=true,wingUsesExistingVerifiedOccupiedComponents=true')
return luau.load(raw,{debugName="FinalArtProposalClearance"})()
