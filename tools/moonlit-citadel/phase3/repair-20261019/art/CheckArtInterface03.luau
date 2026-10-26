local fs,serde,luau,rbx=require("@lune/fs"),require("@lune/serde"),require("@lune/luau"),require("@lune/roblox")
local own="tools/moonlit-citadel/phase3/repair-20261019/art/proposal03/"
local plan=serde.decode("json",fs.readFile(own.."art-plan.json"))
local baseline=serde.decode("json",fs.readFile(plan.basePlanPath))
local original,byName={},{ }
for _,row in baseline.units do
    local unit=table.clone(row)
    unit.localCF=rbx.CFrame.new(table.unpack(row.localCF));unit.scale=rbx.Vector3.new(table.unpack(row.scale))
    table.insert(original,unit);byName[unit.name]=unit
end
local apply=luau.load(fs.readFile(own.."ArtRepairPlan.luau"),{environment={CFrame=rbx.CFrame,Vector3=rbx.Vector3}})()
local result=apply.Apply(original)
assert(#original==320 and #result==315)
local actual,edits,retired={},{},{}
for _,record in plan.replacements do edits[record.after.name]=record end
for _,record in plan.retired do retired[record.before.name]=true end
local untouched,changed=0,0
for _,unit in result do
    assert(not actual[unit.name] and not retired[unit.name]);actual[unit.name]=unit
    local edit=edits[unit.name]
    if edit then
        changed+=1
        local expected=edit.after
        assert(unit.asset==expected.asset and unit.library==expected.library)
        assert((unit.localCF.Position-rbx.Vector3.new(table.unpack(expected.localCF,1,3))).Magnitude<.00004)
        assert((unit.scale-rbx.Vector3.new(table.unpack(expected.scale))).Magnitude<.000001)
        local old=byName[unit.name]
        assert(old.localCF==rbx.CFrame.new(table.unpack(edit.before.localCF)) and old.scale==rbx.Vector3.new(table.unpack(edit.before.scale)),"Input mutated")
    else
        untouched+=1;assert(unit==byName[unit.name],"Unchanged unit was replaced")
    end
end
assert(changed==56 and untouched==259)
for name in retired do assert(not actual[name] and byName[name]) end
local oldWing,newWing=byName.WestArchMiddleWing.localCF,actual.WestArchMiddleWing.localCF
local attachments={};local maxError=0
for name,unit in actual do
    if unit.supportUnit~="WestArchMiddleWing" and name~="WestMiddleEaveCornice" then continue end
    local before=oldWing:ToObjectSpace(byName[name].localCF)
    local after=newWing:ToObjectSpace(unit.localCF)
    local error=(before.Position-after.Position).Magnitude
    assert(error<.00004,"West support changed beyond float32 rounding")
    maxError=math.max(maxError,error)
    table.insert(attachments,{name=name,relativePositionError=error,positionDelta={unit.localCF.X-byName[name].localCF.X,unit.localCF.Y-byName[name].localCF.Y,unit.localCF.Z-byName[name].localCF.Z}})
end
assert(#attachments==8)
local missing=table.clone(original)
for index,unit in missing do if unit.name=="LanternWallBracket1" then table.remove(missing,index);break end end
assert(not pcall(function() apply.Apply(missing) end),"Missing repaired unit must fail")
local report={pass=true,inputUnits=320,resultUnits=#result,changedUnits=changed,untouchedSameTables=untouched,retiredUnits=5,
    stagedModuleSHA256=serde.hash("sha256",fs.readFile(own.."ArtRepairPlan.luau")),planSHA256=serde.hash("sha256",fs.readFile(own.."art-plan.json")),
    baselinePlanSHA256=serde.hash("sha256",fs.readFile(plan.basePlanPath)),allInputPosesAndScalesPreserved=true,
    westSupportAttachmentCount=#attachments,westMaxRelativePositionRounding=maxError,westAttachments=attachments,
    missingRepairedUnitRejected=true,productionEdited=false,nativeInstalled=false}
fs.writeFile(own.."interface-check.json",serde.encode("json",report,true).."\n")
print(serde.encode("json",report))
