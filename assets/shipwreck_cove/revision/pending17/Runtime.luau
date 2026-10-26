--!strict
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.ShipwreckConfig)
local Geometry=require(game.ReplicatedStorage.Shared.ShipwreckHazards)
local Layout=require(script.Parent.Layout)
local Runtime={}
local function vec(v)return Vector3.new(v[1],v[2],v[3])end
local function sweepOffset(d,t)
    local period=d.period or Config.ObstacleSweepPeriod
    local distance=math.sin((t-(d.phase or 0))*2*math.pi/period)*(d.amplitude or Config.ObstacleSweepAmplitude)
    if d.axis=="Z" or d.axis=="z" then return Vector3.new(0,0,distance) end
    return Vector3.new(distance,0,0)
end
local function sound(parent,name,id,volume)
    local s=Instance.new("Sound");s.Name=name;s.SoundId=id;s.Volume=volume
    s.RollOffMinDistance=8;s.RollOffMaxDistance=90;s.Parent=parent;return s
end
function Runtime.Create(course,recover,eligible)
    local origin=course.Bounds.CourseOrigin.CFrame
    local h1=course.Decoration.H01;local h2=course.Decoration.H02
    local tideBounds=course.Obstacles.ShipwreckHazards.SurgeBounds
    local shots={};local sounds={};local original={};local hazards={}
    local function remember(p)original[p]={p.CFrame,p.Transparency}end
    local overlap=OverlapParams.new()
    overlap.FilterType=Enum.RaycastFilterType.Include
    overlap.MaxParts=0
    for _,d in Layout.shots do
        local ball,cue,impact=h1[d.name],h1[d.cue],h1[d.impact]
        remember(ball);remember(cue);remember(impact)
        local fuse=sound(cue,"Fuse",Config.Audio.Fuse,.42)
        local blast=sound(cue,"Blast",Config.Audio.Blast,.65)
        table.insert(sounds,fuse);table.insert(sounds,blast)
        table.insert(shots,{ball=ball,cue=cue,impact=impact,start=origin:PointToWorldSpace(vec(d.start)),
            finish=origin:PointToWorldSpace(vec(d.finish)),offset=d.phase,phase="",fuse=fuse,blast=blast})
    end
    local obstacleVisuals=course.Decoration:FindFirstChild("Obstacles")
    for _,d in Layout.hazards or {} do
        local candidate=obstacleVisuals and obstacleVisuals:FindFirstChild(d.name)
        local visual: BasePart?=if candidate and candidate:IsA("BasePart") then candidate else nil
        if visual then remember(visual) end
        table.insert(hazards,{data=d,visual=visual,cf=origin*CFrame.new(vec(d.p)),size=vec(d.size)})
    end
    local water,foam=h2.SurgeWater,h2.SurgeFoam
    remember(water);remember(foam)
    local waterSize=water.Size
    local waterTop=water.Position.Y+waterSize.Y/2
    local waterBed=origin.Position.Y-4
    local waveCandidate=h2:FindFirstChild("SurgeWave")
    local wave: BasePart?=if waveCandidate and waveCandidate:IsA("BasePart") then waveCandidate else nil
    if wave then remember(wave) end
    local warning=sound(foam,"TideWarning",Config.Audio.TideWarning,.45)
    local rush=sound(foam,"TideSurge",Config.Audio.TideSurge,.5)
    table.insert(sounds,warning);table.insert(sounds,rush)
    local lastTide=""
    local previousTime=0
    local nextVisualTime=0
    local function bodies()
        local racers={}
        local characters={}
        for _,p in Players:GetPlayers() do
            local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
            if eligible(p) and c and h and h.Health>0 and (c:GetAttribute("RecoveryUntil")or 0)<=workspace:GetServerTimeNow() then
                table.insert(racers,{player=p,character=c})
                table.insert(characters,c)
            end
        end
        overlap.FilterDescendantsInstances=characters
        return racers
    end
    local controller={}
    function controller.Step(t,dt,active)
        -- A stalled server cannot reconstruct player movement; do not punish stale contact.
        local racers=nil
        local recovered={}
        local function getRacers()
            if not racers then racers=if active and dt<=.5 then bodies() else {} end
            return racers
        end
        local function contact(cf,size,reason)
            if not active or dt>.5 then return end
            local byCharacter={}
            for _,r in getRacers() do byCharacter[r.character]=r.player end
            for _,body in workspace:GetPartBoundsInBox(cf,size,overlap) do
                local character=body:FindFirstAncestorOfClass("Model")
                local player=character and byCharacter[character]
                if player and not recovered[player] then
                    recovered[player]=true
                    recover(player,reason,false)
                end
            end
        end
        local updateVisuals=t>=nextVisualTime
        if updateVisuals then nextVisualTime=t+1/30 end
        for _,s in shots do
            local cycle=(t-s.offset)%Config.CannonCycle
            local travel=(s.finish-s.start).Magnitude/Config.CannonSpeed
            local phase=if cycle<Config.CannonWarning then "Warning" elseif cycle<Config.CannonWarning+travel then "Shot" else "Clear"
            if phase~=s.phase and active then
                if phase=="Warning" then s.fuse:Play() elseif phase=="Shot" then s.blast:Play() end
            end
            s.phase=phase;s.cue.Transparency=if phase=="Warning" then 0 else 1
            s.ball.Transparency=if phase=="Shot" then 0 else 1
            s.impact.Transparency=if cycle>=Config.CannonWarning+travel and cycle<Config.CannonWarning+travel+.4 then 0 else 1
            s.ball:SetAttribute("Phase",phase)
            if phase=="Shot" then
                local age=cycle-Config.CannonWarning
                local now=s.start:Lerp(s.finish,age/travel)
                if updateVisuals then s.ball.CFrame=CFrame.new(now) end
            end
            if active and dt<=.5 then
                for _,interval in Geometry.ShotIntervals(previousTime,t,s.offset,Config.CannonCycle,Config.CannonWarning,travel) do
                local previous=s.start:Lerp(s.finish,interval[1])
                local now=s.start:Lerp(s.finish,interval[2])
                for _,r in getRacers() do
                    if not recovered[r.player] then
                    for _,body in r.character:GetChildren() do
                        if body:IsA("BasePart") and Geometry.SweptSphere(previous,now,Config.CannonRadius,body.CFrame,body.Size) then
                            recovered[r.player]=true;recover(r.player,"H01 Cannon",false);break
                        end
                    end
                    end
                end
                end
            end
        end
        for _,hazard in hazards do
            local d=hazard.data
            local offset=if d.kind=="sweep" then sweepOffset(d,t) else Vector3.zero
            if updateVisuals and hazard.visual then
                hazard.visual.CFrame=original[hazard.visual][1]+origin:VectorToWorldSpace(offset)
            end
            if d.kind=="static" then
                contact(hazard.cf,hazard.size,d.name)
            elseif d.kind=="sweep" then
                local before=sweepOffset(d,math.max(0,previousTime))
                local middle=sweepOffset(d,(math.max(0,previousTime)+t)/2)
                local minimum=Vector3.new(math.min(before.X,middle.X,offset.X),0,math.min(before.Z,middle.Z,offset.Z))
                local maximum=Vector3.new(math.max(before.X,middle.X,offset.X),0,math.max(before.Z,middle.Z,offset.Z))
                contact(hazard.cf+origin:VectorToWorldSpace((minimum+maximum)/2),
                    hazard.size+maximum-minimum,d.name)
            end
        end
        local phase,amount=Geometry.TidePhase(t,Config)
        if phase~=lastTide and active then
            if phase=="Warning" then warning:Play() elseif phase=="Surge" then rush:Play() end
        end
        lastTide=phase;tideBounds:SetAttribute("Phase",phase)
        local surgeProgress=math.clamp((t%Config.TideCycle-Config.TideDry-Config.TideWarning)
            /Config.TideActive,0,1)
        local rise=if phase=="Warning" then amount*Config.TideWarningRise
            elseif phase=="Surge" then Config.TideWarningRise
                +(Config.TideRise-Config.TideWarningRise)*math.min(1,surgeProgress*3)
            else amount*Config.TideRise
        local travel=if phase=="Surge" then surgeProgress elseif phase=="Drain" then amount else 0
        if updateVisuals then
            -- Keep the rising pool connected to its bed rather than lifting a thin sheet.
            local top=waterTop+rise
            water.Size=Vector3.new(waterSize.X,math.max(.3,top-waterBed),waterSize.Z)
            water.CFrame=original[water][1]+Vector3.new(0,(top+waterBed)/2-original[water][1].Position.Y,0)
            foam.CFrame=original[foam][1]+Vector3.new(0,rise,-Config.TideSweepDistance*travel)
            if wave then
                wave.CFrame=original[wave][1]+Vector3.new(0,rise,-Config.TideSweepDistance*travel)
                wave.Transparency=if phase=="Surge" or phase=="Drain" then original[wave][2] else 1
            end
        end
        if phase=="Surge" or phase=="Drain" then
            local bottom=tideBounds.Position.Y-tideBounds.Size.Y/2
            local top=math.min(waterTop+rise,
                tideBounds.Position.Y+tideBounds.Size.Y/2)
            local front=if phase=="Surge" then tideBounds.Size.Z/2-tideBounds.Size.Z*surgeProgress
                else -tideBounds.Size.Z/2
            local depth=tideBounds.Size.Z/2-front
            if top>bottom and depth>0 then
                contact(tideBounds.CFrame*CFrame.new(0,(bottom+top)/2-tideBounds.Position.Y,
                    (front+tideBounds.Size.Z/2)/2),Vector3.new(tideBounds.Size.X,top-bottom,depth),
                    "H02 Tide surge")
            end
        end
        previousTime=t
    end
    function controller.Reset()
        previousTime=0;nextVisualTime=0;lastTide=""
        for _,s in shots do s.phase="" end
    end
    function controller.Stop()
        for p,state in original do if p.Parent then p.CFrame=state[1];p.Transparency=state[2] end end
        if water.Parent then water.Size=waterSize end
        for _,s in sounds do s:Destroy() end
    end
    return controller
end
return Runtime
