--!strict
local Gate = {}

-- Accept a continuous back-to-front crossing inside the gate, never a large position jump.
function Gate.Crossed(cf: CFrame, size: Vector3, previous: Vector3?, current: Vector3, dt: number): boolean
    if previous == nil or dt <= 0 or dt > 1 then return false end
    -- Tolerate a short frame hitch, but cap travel even when elapsed time is large.
    if (current-previous).Magnitude > math.min(24, math.max(2, dt*40)) then return false end
    local a,b=cf:PointToObjectSpace(previous),cf:PointToObjectSpace(current)
    if a.Z <= 0 or b.Z > 0 then return false end
    local alpha=a.Z/(a.Z-b.Z)
    local at=a:Lerp(b,alpha)
    return math.abs(at.X)<=size.X/2 and math.abs(at.Y)<=size.Y/2
end

return Gate

