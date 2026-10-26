--!strict
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.ShipwreckConfig)
local Geometry=require(game.ReplicatedStorage.Shared.ShipwreckHazards)
local Layout=require(script.Parent.Layout)
local Crumble=require(script.Parent.Crumble)
local FallingHazards=require(script.Parent.FallingHazards)
local WaveHazards=require(script.Parent.WaveHazards)
local Runtime={}
local BODY_PART_NAMES={
    ["HumanoidRootPart"]=true,["Head"]=true,["Torso"]=true,["UpperTorso"]=true,["LowerTorso"]=true,
    ["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,
    ["LeftUpperArm"]=true,["LeftLowerArm"]=true,["LeftHand"]=true,
    ["RightUpperArm"]=true,["RightLowerArm"]=true,["RightHand"]=true,
    ["LeftUpperLeg"]=true,["LeftLowerLeg"]=true,["LeftFoot"]=true,
    ["RightUpperLeg"]=true,["RightLowerLeg"]=true,["RightFoot"]=true,
}
type Racer={player: Player,character: Model,bodyParts: {BasePart}}
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
local function burst(parent,name,color,size,lifetime,speed,spread,direction)
    local emitter=Instance.new("ParticleEmitter")
    emitter.Name=name
    emitter.Texture="rbxasset://textures/particles/smoke_main.dds"
    emitter.Color=ColorSequence.new(color)
    emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size),NumberSequenceKeypoint.new(1,size*2)})
    emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.18),NumberSequenceKeypoint.new(1,1)})
    emitter.Lifetime=NumberRange.new(lifetime)
    emitter.Speed=NumberRange.new(speed*.6,speed)
    emitter.SpreadAngle=Vector2.new(spread,spread)
    emitter.EmissionDirection=direction
    emitter.Rate=0
    emitter.Enabled=false
    emitter.Parent=parent
    return emitter
end
function Runtime.Create(course,recover,eligible)
    local origin=course.Bounds.CourseOrigin.CFrame
    local h1=course.Decoration.H01
    local crumble=Crumble.Create(course,Layout.crumble or {},eligible)
    local falling=FallingHazards.Create(course,Layout.falling or {})
    local waves=WaveHazards.Create(course,Layout.surges or {})
    local shots={};local sounds={};local effects={};local original={};local hazards={}
    local function remember(p)original[p]={p.CFrame,p.Transparency}end
    for _,d in Layout.shots do
        local ball,cue,impact=h1[d.name],h1[d.cue],h1[d.impact]
        remember(ball);remember(cue);remember(impact)
        local fuse=sound(cue,"Fuse",Config.Audio.Fuse,.42)
        local blast=sound(cue,"Blast",Config.Audio.Blast,.65)
        table.insert(sounds,fuse);table.insert(sounds,blast)
        local fire=burst(cue,"MuzzleFire",Color3.fromRGB(255,174,62),1.2,.25,8,28,Enum.NormalId.Top)
        local smoke=burst(cue,"MuzzleSmoke",Color3.fromRGB(99,93,83),1.1,.9,5,38,Enum.NormalId.Top)
        local splash=burst(impact,"WaterSplash",Color3.fromRGB(210,239,240),.75,.55,10,65,Enum.NormalId.Top)
        table.insert(effects,fire);table.insert(effects,smoke);table.insert(effects,splash)
        table.insert(shots,{ball=ball,cue=cue,impact=impact,start=origin:PointToWorldSpace(vec(d.start)),
            finish=origin:PointToWorldSpace(vec(d.finish)),arc=origin:VectorToWorldSpace(Vector3.yAxis)
                *(d.arcHeight or Config.CannonArcHeight),offset=d.phase,phase="",fuse=fuse,blast=blast,
            fire=fire,smoke=smoke,splash=splash})
    end
    local obstacleVisuals=course.Decoration:FindFirstChild("Obstacles")
    for _,d in Layout.hazards or {} do
        local found=false
        for _,visual in if obstacleVisuals then obstacleVisuals:GetChildren() else {} do
            if not visual:IsA('BasePart') or visual.Name~=d.name then continue end
            found=true
            remember(visual)
            table.insert(hazards,{data=d,visual=visual,cf=visual.CFrame,size=visual.Size})
        end
        if not found then
            warn("Disabled Shipwreck hazard "..d.name..": its visible part is missing")
        end
    end
    local previousTime=0
    local nextVisualTime=0
    local function shotPosition(shot,progress)
        return shot.start:Lerp(shot.finish,progress)+shot.arc*(4*progress*(1-progress))
    end
    local function bodies(): {Racer}
        local racers: {Racer}={}
        for _,p in Players:GetPlayers() do
            local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
            if eligible(p) and c and h and h.Health>0 and (c:GetAttribute("RecoveryUntil")or 0)<=workspace:GetServerTimeNow() then
                local bodyParts: {BasePart}={}
                for _,child in c:GetChildren() do
                    if child:IsA("BasePart") and BODY_PART_NAMES[child.Name] then
                        table.insert(bodyParts,child)
                    end
                end
                table.insert(racers,{player=p,character=c,bodyParts=bodyParts})
            end
        end
        return racers
    end
    local controller={}
    function controller.Step(t,dt,active)
        -- A stalled server cannot reconstruct player movement; do not punish stale contact.
        local racers: {Racer}?=nil
        local recovered: {[Player]: boolean}={}
        local function getRacers()
            if not racers then racers=if active and dt<=.5 then bodies() else {} end
            return racers
        end
        local function contact(cf,size,reason,startCf)
            if not active or dt>.5 then return end
            for _,r in getRacers() do
                if recovered[r.player] then continue end
                for _,body in r.bodyParts do
                    if body.Parent==r.character then
                        local hit=if startCf then Geometry.SweptBoxesIntersect(startCf,cf,size,body.CFrame,body.Size)
                            else Geometry.BoxesIntersect(cf,size,body.CFrame,body.Size)
                        if hit then
                            recovered[r.player]=true
                            recover(r.player,reason,false)
                            break
                        end
                    end
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
                if phase=="Warning" then
                    s.fuse:Play()
                elseif phase=="Shot" then
                    s.blast:Play();s.fire:Emit(Config.CannonFireParticles);s.smoke:Emit(Config.CannonSmokeParticles)
                elseif phase=="Clear" and s.phase=="Shot" then
                    s.splash:Emit(Config.CannonSplashParticles)
                end
            end
            s.phase=phase;s.cue.Transparency=if phase=="Warning" then 0 else 1
            s.ball.Transparency=if phase=="Shot" then 0 else 1
            s.impact.Transparency=if cycle>=Config.CannonWarning+travel and cycle<Config.CannonWarning+travel+.4 then 0 else 1
            s.ball:SetAttribute("Phase",phase)
            if phase=="Shot" then
                local age=cycle-Config.CannonWarning
                local now=shotPosition(s,age/travel)
                if updateVisuals then s.ball.CFrame=CFrame.new(now) end
            end
            if active and dt<=.5 then
                for _,interval in Geometry.ShotIntervals(previousTime,t,s.offset,Config.CannonCycle,Config.CannonWarning,travel) do
                local segments=math.max(1,math.ceil((interval[2]-interval[1])/Config.CannonArcCollisionStep))
                for segment=1,segments do
                    local previous=shotPosition(s,interval[1]+(interval[2]-interval[1])*(segment-1)/segments)
                    local now=shotPosition(s,interval[1]+(interval[2]-interval[1])*segment/segments)
                    for _,r in getRacers() do
                        if not recovered[r.player] then
                            for _,body in r.bodyParts do
                                if body.Parent==r.character and Geometry.SweptSphere(previous,now,Config.CannonRadius,body.CFrame,body.Size) then
                                    recovered[r.player]=true;recover(r.player,"H01 Cannon",false);break
                                end
                            end
                        end
                    end
                end
                end
            end
        end
        for _,hazard in hazards do
            if not hazard.visual.Parent then continue end
            local d=hazard.data
            local offset=if d.kind=="sweep" then sweepOffset(d,t) else Vector3.zero
            if d.kind=="sweep" or updateVisuals then
                hazard.visual.CFrame=hazard.cf+origin:VectorToWorldSpace(offset)
            end
			if d.kind=="static" then
				contact(hazard.visual.CFrame,hazard.visual.Size,d.name)
            elseif d.kind=="sweep" then
                local previousT=math.min(t,math.max(0,previousTime))
                local steps=math.max(1,math.ceil((t-previousT)*30))
                for step=1,steps do
                    local startT=previousT+(t-previousT)*(step-1)/steps
                    local endT=previousT+(t-previousT)*step/steps
                    local startCf=hazard.cf+origin:VectorToWorldSpace(sweepOffset(d,startT))
                    local endCf=hazard.cf+origin:VectorToWorldSpace(sweepOffset(d,endT))
                    contact(endCf,hazard.size,d.name,startCf)
                end
            end
        end
        falling.Step(t,dt,active,updateVisuals,getRacers(),function(player,reason)
            if not recovered[player] then
                recovered[player]=true
                recover(player,reason,false)
            end
        end)
        waves.Step(t,dt,active,updateVisuals,contact)
        previousTime=t
        crumble.Step(t,active)
    end
    function controller.Reset()
        previousTime=0;nextVisualTime=0
        for _,s in shots do s.phase="" end
        crumble.Reset()
        falling.Reset()
        waves.Reset()
    end
    function controller.Stop()
        crumble.Stop()
        falling.Stop()
        waves.Stop()
        for p,state in original do if p.Parent then p.CFrame=state[1];p.Transparency=state[2] end end
        for _,effect in effects do effect:Destroy() end
        for _,s in sounds do s:Destroy() end
    end
    return controller
end
return Runtime
