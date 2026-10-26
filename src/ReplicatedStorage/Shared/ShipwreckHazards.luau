--!strict
local Geometry={}
local function projectionRadius(cf: CFrame,size: Vector3,axis: Vector3): number
    local half=size*.5
    return half.X*math.abs(cf.XVector:Dot(axis))
        +half.Y*math.abs(cf.YVector:Dot(axis))
        +half.Z*math.abs(cf.ZVector:Dot(axis))
end
local function separatingAxes(cfA: CFrame,cfB: CFrame): {Vector3}
    local axes={cfA.XVector,cfA.YVector,cfA.ZVector,cfB.XVector,cfB.YVector,cfB.ZVector}
    for _,axisA in {cfA.XVector,cfA.YVector,cfA.ZVector} do
        for _,axisB in {cfB.XVector,cfB.YVector,cfB.ZVector} do
            table.insert(axes,axisA:Cross(axisB))
        end
    end
    return axes
end
function Geometry.BoxesIntersect(cfA: CFrame,sizeA: Vector3,cfB: CFrame,sizeB: Vector3): boolean
    local separation=cfB.Position-cfA.Position
    local boundingRadius=(sizeA.Magnitude+sizeB.Magnitude)*0.5
    if separation:Dot(separation)>boundingRadius*boundingRadius then return false end
    for _,axis in separatingAxes(cfA,cfB) do
        if axis.Magnitude>1e-6 then
            local radius=projectionRadius(cfA,sizeA,axis)+projectionRadius(cfB,sizeB,axis)
            if math.abs(separation:Dot(axis))>radius then return false end
        end
    end
    return true
end
function Geometry.SweptBoxesIntersect(startCF: CFrame,endCF: CFrame,sizeA: Vector3,
    cfB: CFrame,sizeB: Vector3): boolean
    local separation=startCF.Position-cfB.Position
    local movement=endCF.Position-startCF.Position
    local movementLengthSquared=movement:Dot(movement)
    local closestTime=if movementLengthSquared>1e-8
        then math.clamp((cfB.Position-startCF.Position):Dot(movement)/movementLengthSquared,0,1) else 0
    local closestSeparation=startCF.Position+movement*closestTime-cfB.Position
    local boundingRadius=(sizeA.Magnitude+sizeB.Magnitude)*0.5
    if closestSeparation:Dot(closestSeparation)>boundingRadius*boundingRadius then return false end
    local first,last=0,1
    for _,axis in separatingAxes(startCF,cfB) do
        if axis.Magnitude>1e-6 then
            local radius=projectionRadius(startCF,sizeA,axis)+projectionRadius(cfB,sizeB,axis)
            local position=separation:Dot(axis)
            local velocity=movement:Dot(axis)
            if math.abs(velocity)<1e-6 then
                if math.abs(position)>radius then return false end
            else
                local a=(-radius-position)/velocity
                local b=(radius-position)/velocity
                first=math.max(first,math.min(a,b))
                last=math.min(last,math.max(a,b))
                if first>last then return false end
            end
        end
    end
    return true
end
local function distanceSquaredToBox(point: Vector3,half: Vector3): number
    local x=math.max(0,math.abs(point.X)-half.X)
    local y=math.max(0,math.abs(point.Y)-half.Y)
    local z=math.max(0,math.abs(point.Z)-half.Z)
    return x*x+y*y+z*z
end
function Geometry.ShotIntervals(previous: number, current: number, offset: number, cycle: number, warning: number, travel: number)
    local intervals={}
    for lap=math.floor((previous-offset)/cycle),math.floor((current-offset)/cycle) do
        local start=offset+lap*cycle+warning
        local a,b=math.max(previous,start),math.min(current,start+travel)
        if b>=a then table.insert(intervals,{(a-start)/travel,(b-start)/travel}) end
    end
    return intervals
end
function Geometry.SweptSphere(a: Vector3,b: Vector3,radius: number,cf: CFrame,size: Vector3): boolean
    local p,q=cf:PointToObjectSpace(a),cf:PointToObjectSpace(b)
    local half=size*.5
    local direction=q-p
    local radiusSquared=radius*radius
    local expanded=half+Vector3.one*radius
    local enter,leave=0,1
    for _,axis in {"X","Y","Z"} do
        local delta=direction[axis]
        if math.abs(delta)<1e-6 then
            if math.abs(p[axis])>expanded[axis] then return false end
        else
            local first=(-expanded[axis]-p[axis])/delta
            local last=(expanded[axis]-p[axis])/delta
            enter=math.max(enter,math.min(first,last))
            leave=math.min(leave,math.max(first,last))
            if enter>leave then return false end
        end
    end
    local function distanceAt(t: number): number
        return distanceSquaredToBox(p+direction*t,half)
    end
    if direction:Dot(direction)<1e-8 then
        return distanceSquaredToBox(p,half)<=radiusSquared
    end
    local low,high=0,1
    for _=1,24 do
        local left=low+(high-low)/3
        local right=high-(high-low)/3
        if distanceAt(left)<=distanceAt(right) then high=right else low=left end
    end
    local closest=(low+high)*.5
    local minimum=math.min(distanceAt(0),distanceAt(1),distanceAt(closest))
    return minimum<=radiusSquared
end
function Geometry.TidePhase(t: number,config): (string,number)
    local phase=t%config.TideCycle
    if phase<config.TideDry then return "Dry",0 end
    phase-=config.TideDry
    if phase<config.TideWarning then return "Warning",phase/config.TideWarning end
    phase-=config.TideWarning
    if phase<config.TideActive then return "Surge",1 end
    return "Drain",1-(phase-config.TideActive)/config.TideDrain
end
return Geometry
