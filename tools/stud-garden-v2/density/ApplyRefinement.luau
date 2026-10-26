return function(root, build, Kit)
    assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
    assert(root:GetAttribute("CandidateId")=="SGV2_Density_D01")
    local garden=assert(root:FindFirstChild("GardenUnderstory"))
    local scratch=Instance.new("Model")
    scratch.Name="DensityRefinementScratch"
    scratch.WorldPivot=root:GetPivot()
    scratch:SetAttribute("CandidateId","SGV2_StudStyle_S05")
    scratch:SetAttribute("CourseOrigin",root:GetPivot().Position)
    local ok,result=xpcall(function()
        local ledger=build(scratch,Kit)
        local plan={}
        for _,scene in scratch.GardenUnderstory:GetChildren() do
            local target=assert(garden:FindFirstChild(scene.Name))
            local buckets={}
            for _,p in target:GetChildren() do
                assert(p:IsA("BasePart"))
                local key=p.ClassName..":"..p.Name
                buckets[key]=buckets[key] or {}
                table.insert(buckets[key],p)
            end
            local used={}
            for _,p in scene:GetChildren() do
                assert(p:IsA("BasePart") and p.Anchored)
                local key=p.ClassName..":"..p.Name
                used[key]=(used[key] or 0)+1
                local old=buckets[key] and buckets[key][used[key]]
                assert(old or (p.Name=="LeafJoinedSideVein" and not p.CanCollide))
                table.insert(plan,{source=p,target=old,parent=target})
            end
            for key,items in buckets do assert(used[key]==#items,"Existing scenery would be omitted: "..key) end
        end
        local updated,added=0,0
        for _,item in plan do
            local p,old=item.source,item.target
            if old then
                assert(old.CanCollide==p.CanCollide and old.CanQuery==p.CanQuery and old.CanTouch==p.CanTouch)
                for _,key in {"CFrame","Size","Color","TopSurface","BottomSurface","LeftSurface","RightSurface","FrontSurface","BackSurface"} do old[key]=p[key] end
                updated+=1
            else
                p.Parent=item.parent
                added+=1
            end
        end
        garden:SetAttribute("ArtRevision","D02")
        root:SetAttribute("CandidateId","SGV2_Density_D02")
        return {updated=updated,added=added,ledger=ledger}
    end,debug.traceback)
    scratch:Destroy()
    assert(ok,result)
    return result
end
