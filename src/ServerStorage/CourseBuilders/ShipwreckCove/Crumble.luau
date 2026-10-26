--!strict
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.ShipwreckConfig)
local Crumble={}

function Crumble.Create(course,stoneNames,eligible)
    local visuals=course.Decoration
    local colliders=course.Obstacles.WalkingSurfaces
    local stones={}
    local expertByCollider={}
    for _,name in stoneNames do
        local visual=visuals:FindFirstChild(name,true)
        local collider=colliders:FindFirstChild(name)
        if not visual or not visual:IsA("BasePart") or not collider or not collider:IsA("BasePart") then
            warn("Disabled Shipwreck crumble stone "..name..": its visible part or walking surface is missing")
            continue
        end
        local markers={}
        local routeMarkers=course:FindFirstChild('RouteMarkers')
        for _,prefix in {'ExpertLanding_','CliffLanding_','RouteArrow_'} do
            local marker=routeMarkers and routeMarkers:FindFirstChild(prefix..name)
            if marker and marker:IsA('BasePart') then
                table.insert(markers,{part=marker,cframe=marker.CFrame})
            end
        end
        table.insert(stones,{visual=visual,collider=collider,markers=markers,visualCFrame=visual.CFrame,
            colliderCFrame=collider.CFrame,visualTransparency=visual.Transparency,
            collide=collider.CanCollide,query=collider.CanQuery,state="Ready",since=0,
            warning=if name:match('^Spar%d+$') then Config.ExpertSparWarning else Config.CrumbleWarning})
        if name:match('^Rib%d+$') or name:match('^Spar%d+$') then
            expertByCollider[collider]=stones[#stones]
        end
    end

    local overlap=OverlapParams.new()
    overlap.FilterType=Enum.RaycastFilterType.Include
    overlap.MaxParts=0
    local landingRay=RaycastParams.new()
    landingRay.FilterType=Enum.RaycastFilterType.Include
    landingRay.FilterDescendantsInstances={colliders}
    landingRay.RespectCanCollide=true
    local nextCheck=0
    local function restore(stone)
        if stone.visual.Parent then
            stone.visual.CFrame=stone.visualCFrame
            stone.visual.Transparency=stone.visualTransparency
        end
        if stone.collider.Parent then
            stone.collider.CFrame=stone.colliderCFrame
            stone.collider.CanCollide=stone.collide
            stone.collider.CanQuery=stone.query
        end
        for _,marker in stone.markers do
            if marker.part.Parent then marker.part.CFrame=marker.cframe end
        end
        stone.state="Ready"
    end
    local function dropStone(stone,drop)
        local offset=Vector3.new(0,-drop,0)
        stone.visual.CFrame=stone.visualCFrame+offset
        stone.collider.CFrame=stone.colliderCFrame+offset
        for _,marker in stone.markers do
            if marker.part.Parent then marker.part.CFrame=marker.cframe+offset end
        end
    end
    local controller={}
    function controller.Step(t,active)
        for _,stone in stones do
            if not stone.visual.Parent or not stone.collider.Parent then continue end
            local elapsed=t-stone.since
            if stone.state=="Armed" then
                if elapsed>=stone.warning then
                    stone.state="Falling";stone.since=t
                    stone.collider.CanCollide=false;stone.collider.CanQuery=false
                else
                    -- Only the visible stone shakes; its walking surface stays stable until the drop.
                    local shake=math.sin(elapsed*90)*.12*(elapsed/stone.warning)
                    stone.visual.CFrame=stone.visualCFrame*CFrame.new(shake,0,-shake*.5)
                end
            elseif stone.state=="Falling" then
                if elapsed>=Config.CrumbleFall then
                    stone.state="Waiting";stone.since=t
                    dropStone(stone,Config.CrumbleDrop)
                else
                    local drop=Config.CrumbleDrop*(elapsed/Config.CrumbleFall)^2
                    dropStone(stone,drop)
                end
            elseif stone.state=="Waiting" and elapsed>=Config.CrumbleReset then
                restore(stone)
            end
        end
        if not active then return end
        local checkRegular=t>=nextCheck
        if checkRegular then nextCheck=t+Config.CrumbleCheck end

        local nearby={}
        for _,player in Players:GetPlayers() do
            local character=player.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local root=character and character:FindFirstChild("HumanoidRootPart")
            if eligible(player) and character and humanoid and humanoid.Health>0
                and root and root:IsA("BasePart") and humanoid.FloorMaterial~=Enum.Material.Air
                and (character:GetAttribute("RecoveryUntil") or 0)<=workspace:GetServerTimeNow() then
                table.insert(nearby,{character=character,root=root})
                -- Narrow expert caps can be crossed between the regular overlap checks.
                local hit=workspace:Raycast(root.Position,
                    Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.65),0),landingRay)
                local stone=hit and expertByCollider[hit.Instance]
                if stone and stone.state=='Ready' then
                    stone.state='Armed';stone.since=t
                end
            end
        end
        if #nearby==0 or not checkRegular then return end
        for _,stone in stones do
            if not stone.visual.Parent or not stone.collider.Parent then continue end
            if stone.state~="Ready" then continue end
            local collider=stone.collider
            local top=stone.colliderCFrame*CFrame.new(0,collider.Size.Y/2+.2,0)
            local candidates={}
            local characterByPart={}
            for _,racer in nearby do
                local localPosition=stone.colliderCFrame:PointToObjectSpace(racer.root.Position)
                if math.abs(localPosition.X)<=collider.Size.X/2+2
                    and math.abs(localPosition.Z)<=collider.Size.Z/2+2
                    and localPosition.Y>=collider.Size.Y/2+.5
                    and localPosition.Y<=collider.Size.Y/2+5 then
                    table.insert(candidates,racer.character)
                    characterByPart[racer.character]=true
                end
            end
            if #candidates==0 then continue end
            overlap.FilterDescendantsInstances=candidates
            local topSize=Vector3.new(math.max(.5,collider.Size.X-.2),.8,
                math.max(.5,collider.Size.Z-.2))
            for _,part in workspace:GetPartBoundsInBox(top,topSize,overlap) do
                local character=part:FindFirstAncestorOfClass("Model")
                if character and characterByPart[character] then
                    stone.state="Armed";stone.since=t
                    break
                end
            end
        end
    end
    function controller.Reset()
        nextCheck=0
        for _,stone in stones do restore(stone) end
    end
    function controller.Stop()
        controller.Reset()
    end
    return controller
end

return Crumble

