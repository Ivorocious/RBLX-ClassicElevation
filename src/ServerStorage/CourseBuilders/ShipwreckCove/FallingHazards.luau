--!strict
local Config = require(game.ReplicatedStorage.Config.ShipwreckConfig)
local Geometry = require(game.ReplicatedStorage.Shared.ShipwreckHazards)
local FallingHazards = {}

local MIN_WARNING = 1.3
local NAME_HASH_MODULUS = 65521
local RANDOM_SEED_MODULUS = 2147483646

local function vector(point)
	return Vector3.new(point[1], point[2], point[3])
end

local function stableNameSeed(name)
	local value = 5381
	for index = 1, #name do
		value = (value * 33 + string.byte(name, index)) % NAME_HASH_MODULUS
	end
	return value
end

local function positionAtAge(hazard, target, elapsed, fallTime)
	if hazard.data.kind ~= "stalactite" then
		return hazard.top:Lerp(target, math.clamp(elapsed / fallTime, 0, 1))
	end
	if elapsed <= hazard.impactTime then
		return hazard.top:Lerp(target, math.clamp(elapsed / hazard.impactTime, 0, 1))
	end
	return target + hazard.fallDirection * hazard.fallSpeed * (elapsed - hazard.impactTime)
end

local function cycleParameters(hazard, cycleIndex, maximumDelay)
	if hazard.cachedCycleIndex ~= cycleIndex then
		local spread = math.max(0, hazard.data.spread or 0)
		local delay = 0
		local offset = Vector3.zero
		if hazard.data.kind == "coconut" or spread > 0 then
			local cycleSeed = (hazard.seed + (cycleIndex % RANDOM_SEED_MODULUS) * 48271) % RANDOM_SEED_MODULUS + 1
			local random = Random.new(cycleSeed)
			if hazard.data.kind == "coconut" then
				delay = random:NextNumber(0, maximumDelay)
			end
            local allowed = false
            for _ = 1, 16 do
                if spread > 0 then
                    local radius = math.sqrt(random:NextNumber()) * spread
                    local angle = random:NextNumber() * 2 * math.pi
                    offset = hazard.origin:VectorToWorldSpace(Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
                end
                allowed = true
                for _, zone in hazard.safeZones do
                    if Geometry.SweptBoxesIntersect(CFrame.new(hazard.top) * hazard.originalCFrame.Rotation,
                        CFrame.new(hazard.bottom + offset) * hazard.originalCFrame.Rotation,
                        hazard.visual.Size, zone.CFrame, zone.Size + Vector3.new(4, 200, 4)) then
                        allowed = false
                        break
                    end
                end
                if allowed and hazard.groundRay then
                    local target=hazard.bottom+offset
                    local ground=workspace:Raycast(target+Vector3.new(0,60,0),Vector3.new(0,-120,0),hazard.groundRay)
                    if ground then
                        offset=Vector3.new(offset.X,ground.Position.Y+hazard.visual.Size.Y*.5-hazard.bottom.Y,offset.Z)
                    else
                        allowed=false
                    end
                end
                if allowed then break end
            end
            hazard.cachedAllowed = allowed
		end
		hazard.cachedCycleIndex = cycleIndex
		hazard.cachedDelay = delay
		hazard.cachedOffset = offset
	end
    return hazard.cachedDelay, hazard.cachedOffset, hazard.cachedAllowed ~= false
end

function FallingHazards.Create(course, definitions)
	local origin = course.Bounds.CourseOrigin.CFrame
	local folder = course.Decoration:FindFirstChild("Falling")
    local hazards = {}
    local safeZones = {}
    local groundParts = {course.Obstacles.WalkingSurfaces}
    for _,p in course.Decoration:GetDescendants() do
        if p:IsA('BasePart') and p:GetAttribute('SolidGround') then table.insert(groundParts,p) end
    end
    local groundRay=RaycastParams.new()
    groundRay.FilterType=Enum.RaycastFilterType.Include
    groundRay.FilterDescendantsInstances=groundParts
    groundRay.RespectCanCollide=true
    for _, surface in course.Obstacles.WalkingSurfaces:GetChildren() do
        if surface:IsA('BasePart') and (surface.Name == 'HarborAssembly' or surface.Name:match('^R%d_')) then
            table.insert(safeZones, surface)
        end
    end
	local maximumHazards = Config.MaxFallingHazards or 32

	for index, data in definitions or {} do
		if index > maximumHazards then
			break
		end

		local candidate = folder and folder:FindFirstChild(data.name)
		local visual: BasePart? = if candidate and candidate:IsA("BasePart") then candidate else nil
		if visual then
			local top = origin:PointToWorldSpace(vector(data.top))
			local bottom = origin:PointToWorldSpace(vector(data.bottom))
			local impactTime = if data.kind == "stalactite"
				then (Config.FallingStalactiteImpactTime or 0.35) else math.max(0.1, data.fallTime or 0.5)
			local fallDirection = if (bottom - top).Magnitude > 1e-4
				then (bottom - top).Unit else -origin.UpVector
			local fallSpeed = math.max((bottom - top).Magnitude / impactTime, 1e-4)
			local passDistance = if data.kind == "stalactite"
				then visual.Size.Y + (Config.FallingStalactitePassDepth or 8) else 0
			local passTime = passDistance / fallSpeed
			local originalCanCollide = visual.CanCollide
			local originalCanTouch = visual.CanTouch
			visual.CanCollide = false
			visual.CanTouch = false
			local marker = Instance.new("Part")
			marker.Name = data.name .. "Warning"
			marker.Shape = Enum.PartType.Cylinder
			local markerRadius = math.min(data.radius, math.max(visual.Size.X, visual.Size.Z) * 0.5)
			marker.Size = Vector3.new(0.12, 2 * markerRadius, 2 * markerRadius)
			marker.Anchored = true
			marker.CanCollide = false
			marker.CanTouch = false
			marker.CanQuery = false
			marker.CastShadow = false
			marker.Material = Enum.Material.SmoothPlastic
			marker.Color = Color3.fromRGB(230, 54, 42)
			marker.Transparency = 1
			marker.Parent = folder
			table.insert(hazards, {
				data = data,
				visual = visual,
				top = top,
				bottom = bottom,
				impactTime = impactTime,
				fallDirection = fallDirection,
				fallSpeed = fallSpeed,
				passDistance = passDistance,
				passTime = passTime,
				origin = origin,
                seed = stableNameSeed(data.name),
                safeZones = if data.kind == 'coconut' then safeZones else {},
                groundRay = if data.kind == 'coconut' then groundRay else nil,
				marker = marker,
				originalCFrame = visual.CFrame,
				originalColor = visual.Color,
				originalTransparency = visual.Transparency,
				originalCanCollide = originalCanCollide,
				originalCanTouch = originalCanTouch,
				originalState = visual:GetAttribute("State"),
				originalWarning = visual:GetAttribute("Warning"),
			})
		else
			warn("Disabled Shipwreck falling hazard " .. data.name .. ": its visible part is missing")
		end
	end

	local controller = {}
	local function restore()
		for _, hazard in hazards do
			if hazard.visual.Parent then
				hazard.visual.CFrame = hazard.originalCFrame
				hazard.visual.Color = hazard.originalColor
				hazard.visual.Transparency = hazard.originalTransparency
				hazard.visual:SetAttribute("State", hazard.originalState)
				hazard.visual:SetAttribute("Warning", hazard.originalWarning)
			end
			if hazard.marker.Parent then
				hazard.marker.Transparency = 1
			end
		end
	end

	function controller.Step(t, dt, active, updateVisuals, racers, hit)
		for _, hazard in hazards do
			if not hazard.visual.Parent then
				if hazard.marker.Parent then
					hazard.marker.Transparency = 1
				end
				continue
			end
			local data = hazard.data
			local warning = math.max(MIN_WARNING, data.warning or MIN_WARNING)
			local fallTime = if data.kind == "stalactite"
				then hazard.impactTime else math.max(0.1, data.fallTime or 0.5)
			local hold = math.max(0, data.hold or 0.4)
			if data.kind == "stalactite" then
				hold = 0
			end
			local movementTime = fallTime + hazard.passTime
			local activeTime = warning + movementTime + hold
			local requestedPeriod = data.period or 5
			local maximumDelay = if data.kind == "coconut" then (Config.FallingCoconutMaxDelay or 1.4) else 0
			local period = math.max(activeTime + maximumDelay + 0.5, requestedPeriod)
			maximumDelay = math.min(maximumDelay, period - activeTime - 0.5)

			-- Coconut timing and target drift vary by cycle, while stalactites keep their authored period.
			local cycleIndex = math.floor((t - (data.phase or 0)) / period)
            local delay, targetOffset, allowed = cycleParameters(hazard, cycleIndex, maximumDelay)
            local enabled = active and allowed
			local eventTime = (data.phase or 0) + cycleIndex * period + delay
			local age = t - eventTime
			local previousAge = age - dt
			local target = hazard.bottom + targetOffset
			local falling = age >= warning and age < warning + movementTime
			local holding = data.kind ~= "stalactite" and age >= warning + movementTime and age < activeTime
            local cue = enabled and age >= 0 and age < warning
            local dangerous = enabled and (falling or holding)
			local elapsed = if falling then age - warning else movementTime
			local position = if not active then hazard.top elseif falling then positionAtAge(hazard, target, elapsed, fallTime)
				elseif holding then target else hazard.top
            local state = if not enabled then "Reset" elseif cue then "Warning" elseif falling then "Falling" elseif holding then "Hold" else "Reset"
			hazard.visual:SetAttribute("State", state)
			hazard.visual:SetAttribute("Warning", cue)

			if updateVisuals then
				hazard.visual.CFrame = CFrame.new(position) * hazard.originalCFrame.Rotation
				hazard.visual.Color = hazard.originalColor
                hazard.visual.Transparency = if not enabled or age >= activeTime then 1 else hazard.originalTransparency
				local markerCenter = target - Vector3.new(0, hazard.visual.Size.Y * 0.5 - 0.08, 0)
				hazard.marker.CFrame = CFrame.new(markerCenter) * CFrame.Angles(0, 0, math.pi / 2)
				hazard.marker.Transparency = if cue then 0.28 elseif dangerous then 0.6 else 1
			end

			local sweepStart = math.max(previousAge, warning)
			local sweepEnd = math.min(age, warning + movementTime)
			local crossedFall = sweepEnd >= sweepStart and age >= warning and previousAge <= warning + movementTime
            if enabled and dt <= 0.5 and (crossedFall or holding) then
				local before = if crossedFall then positionAtAge(hazard, target, sweepStart - warning, fallTime) else target
				local finish = if crossedFall then positionAtAge(hazard, target, sweepEnd - warning, fallTime) else target
				local rotation = hazard.originalCFrame.Rotation
				for _, racer in racers do
					local struck = false
					for _, body in racer.bodyParts do
						if body.Parent == racer.character then
							local startCFrame = CFrame.new(before) * rotation
							local endCFrame = CFrame.new(finish) * rotation
							if Geometry.SweptBoxesIntersect(startCFrame, endCFrame, hazard.visual.Size,
								body.CFrame, body.Size) then
								struck = true
							end
							if struck then
								break
							end
						end
					end
					if struck then
						hit(racer.player, data.name)
					end
				end
			end
		end
	end

	function controller.Reset()
		restore()
	end
	function controller.Stop()
		restore()
		for _, hazard in hazards do
			if hazard.visual.Parent then
				hazard.visual.CanCollide = hazard.originalCanCollide
				hazard.visual.CanTouch = hazard.originalCanTouch
			end
			hazard.marker:Destroy()
		end
	end
	return controller
end

return FallingHazards
