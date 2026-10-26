
local Test={}
function Test.Run(template)
    local player=assert(game.Players:GetPlayers()[1]) local character=assert(player.Character)
    local root,humanoid=character.HumanoidRootPart,character.Humanoid
    local saved,anchored=character:GetPivot(),root.Anchored
    local fixture=template:Clone() fixture.Name="__C12LandingFixture"
    fixture:PivotTo(CFrame.new(8000,100,0)) fixture.Parent=workspace
    local current=fixture local recoveries=0
    local source=game.ServerScriptService.Services.CourseHazardService:Clone() source.Parent=game.ServerStorage
    local service=require(source)
    service.Init({Services={RaceService={IsRaceActive=function() return true end},
        PlayerRaceService={IsOfficialRacer=function(p) return p==player end,GetPlayerStatus=function() return "Racing" end},
        CourseService={GetActiveCourse=function() return current end},
        RespawnService={RecoverPlayer=function() recoveries+=1 return true end}}})
    local records={}
    local ok,failure=xpcall(function()
        service.Start()
        local cp=fixture.Checkpoints.Checkpoint_003
        root.Anchored=false root:SetNetworkOwner(nil)
        character:PivotTo(cp.CFrame+Vector3.new(0,5,0)) root.AssemblyLinearVelocity=Vector3.zero
        task.wait(6.7)
        assert(recoveries==0,"Spinner touched the respawning avatar")
        assert((Vector3.new(root.Position.X,cp.Position.Y,root.Position.Z)-cp.Position).Magnitude<1.5,"Avatar slid off CP3")
        assert(math.abs(root.Position.Y-(cp.Position.Y+humanoid.HipHeight+root.Size.Y/2))<1,"Avatar is not supported")
        table.insert(records,{name="SupportedRespawnSurvivesFullSpinnerCycle",passed=true,seconds=6.7})
        local target=fixture:GetPivot():PointToWorldSpace(Vector3.new(-215,44.6,-8))
        local tile
        for _,p in fixture:GetDescendants() do if p:IsA("BasePart") and p:GetAttribute("HazardType")=="Crumble" and (p.Position-target).Magnitude<.05 then tile=p break end end
        assert(tile,"First crumble tile missing")
        local touched=false local connection=tile.Touched:Connect(function(p) if p:IsDescendantOf(character) then touched=true end end)
        humanoid:MoveTo(target+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2,0)) humanoid.Jump=true
        local deadline=os.clock()+2
        repeat task.wait(.025) until touched or os.clock()>deadline
        connection:Disconnect()
        assert(touched and recoveries==0,"Normal jump from new CP3 to first crumble tile failed")
        table.insert(records,{name="ActualAvatarJumpsToFirstCrumbleTile",passed=true})
    end,debug.traceback)
    current=nil service.BindActiveCourse()
    humanoid:Move(Vector3.zero) character:PivotTo(saved) root.Anchored=anchored root.AssemblyLinearVelocity=Vector3.zero
    if not anchored then root:SetNetworkOwnershipAuto() end
    fixture:Destroy() source:Destroy()
    return {passed=ok,records=records,failure=if ok then nil else failure,limitation="One real avatar; focused landing and first jump only"}
end
return Test
