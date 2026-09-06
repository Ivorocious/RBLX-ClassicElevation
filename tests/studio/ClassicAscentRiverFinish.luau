--!strict

-- Run in Studio Edit mode after applying the River Finish pass to a workspace candidate.
local RiverFinish = {}

local EXPECTED_ZOOM = 30
local EXPECTED_CHECKPOINTS = 19
local EXPECTED_STREAMS = 20
local LOGS_PER_STREAM = 5
local LOG_TRAVEL = 176
local LOG_ENDPOINT_OFFSET = 88
local LOG_SPEED = 68 / 13
local SAMPLE_PROGRESS = { 0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1 }
local EPSILON = 0.01

local function approximatelyEqual(left: number, right: number): boolean
	return math.abs(left - right) <= EPSILON
end

local function streamKey(start: CFrame, finish: CFrame): string
	local center = start:Lerp(finish, 0.5)
	return string.format("%.3f:%.3f:%.3f", center.Position.X, center.Position.Y, center.Position.Z)
end

local function routeOrBank(part: BasePart, model: Model): boolean
	return part:GetAttribute("RoutePad") == true
		or part.Name == "CompleteRiverBank"
		or part:IsDescendantOf(model.Checkpoints)
end

function RiverFinish.Run(model: Model): string
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	assert(model:IsDescendantOf(workspace), "River finish sweep requires a workspace candidate")
	assert(model:GetAttribute("RiverFinishRevision") == 1, "River Finish revision 1 is required")
	assert(game:GetService("StarterPlayer").CameraMaxZoomDistance == EXPECTED_ZOOM, "Camera max zoom must be 30")
	assert(#model.Checkpoints:GetChildren() == EXPECTED_CHECKPOINTS, "Nineteen checkpoints required")

	local continuation = model.Decoration:FindFirstChild("RiverContinuation")
	assert(continuation ~= nil, "River continuation is required")
	local continuationParts = 0
	for _, object in ipairs(continuation:GetDescendants()) do
		if object:IsA("BasePart") then
			continuationParts += 1
			assert(not object.CanCollide and not object.CanTouch, "River continuation must remain scenery only: " .. object:GetFullName())
		end
	end
	assert(continuationParts > 0, "River continuation has no geometry")

	local streams: { [string]: { BasePart } } = {}
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") and object:GetAttribute("MotionKind") == "MovingLog" then
			local start = object:GetAttribute("MotionStart")
			local finish = object:GetAttribute("MotionEnd")
			assert(typeof(start) == "CFrame" and typeof(finish) == "CFrame", "Moving log endpoints are required")
			assert(object:GetAttribute("InitialProgress") == 0, "Moving logs must begin at progress zero")
			assert(approximatelyEqual(((start :: CFrame).Position - (finish :: CFrame).Position).Magnitude, LOG_TRAVEL), "Moving log travel must be 176 studs")

			local center = (start :: CFrame):Lerp(finish :: CFrame, 0.5)
			local startLocal = center:PointToObjectSpace((start :: CFrame).Position)
			local finishLocal = center:PointToObjectSpace((finish :: CFrame).Position)
			assert(approximatelyEqual(math.abs(startLocal.X), LOG_ENDPOINT_OFFSET) and approximatelyEqual(math.abs(finishLocal.X), LOG_ENDPOINT_OFFSET), "Moving log endpoints must be 88 studs from stream center")
			assert(approximatelyEqual(startLocal.Y, 0) and approximatelyEqual(startLocal.Z, 0) and approximatelyEqual(finishLocal.Y, 0) and approximatelyEqual(finishLocal.Z, 0), "Moving log travel must stay on the stream axis")
			assert(approximatelyEqual(object:GetAttribute("MotionDuration"), LOG_TRAVEL / LOG_SPEED), "Moving log speed must remain 68/13")

			local key = streamKey(start :: CFrame, finish :: CFrame)
			streams[key] = streams[key] or {}
			table.insert(streams[key], object)
		end
	end

	local streamCount = 0
	local sweptStreams = 0
	for key, logs in pairs(streams) do
		streamCount += 1
		assert(#logs == LOGS_PER_STREAM, "Expected five logs in stream " .. key)
		table.sort(logs, function(left, right)
			return (left:GetAttribute("CycleOffset") :: number) < (right:GetAttribute("CycleOffset") :: number)
		end)
		local cadence = ((logs[1]:GetAttribute("MotionDuration") :: number) + (logs[1]:GetAttribute("PauseDuration") :: number)) / LOGS_PER_STREAM
		for index = 2, #logs do
			local previous = logs[index - 1]:GetAttribute("CycleOffset") :: number
			local current = logs[index]:GetAttribute("CycleOffset") :: number
			assert(approximatelyEqual(current - previous, cadence), "River log cadence changed in stream " .. key)
		end

		local log = logs[1]
		local start = log:GetAttribute("MotionStart") :: CFrame
		local finish = log:GetAttribute("MotionEnd") :: CFrame
		local center = start:Lerp(finish, 0.5)
		local boundaryParams = RaycastParams.new()
		boundaryParams.FilterType = Enum.RaycastFilterType.Include
		boundaryParams.FilterDescendantsInstances = { model.Bounds }
		for _, side in ipairs({ -1, 1 }) do
			local hit = workspace:Raycast(center.Position + Vector3.new(0, 5, 0), center.RightVector * side * 70, boundaryParams)
			assert(hit and hit.Instance.CanCollide and hit.Instance:GetAttribute("CourseBoundary"), "Playable boundary must block access to the extended river")
		end
		local exclusions: { Instance } = { log }
		for _, child in ipairs(log:GetDescendants()) do
			table.insert(exclusions, child)
		end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = exclusions
		for _, progress in ipairs(SAMPLE_PROGRESS) do
			for _, hit in ipairs(workspace:GetPartBoundsInBox(start:Lerp(finish, progress), log.Size, params)) do
				assert(not routeOrBank(hit, model), string.format("River log crosses route or bank at %.3f: %s", progress, hit:GetFullName()))
			end
		end
		sweptStreams += 1
	end

	assert(streamCount == EXPECTED_STREAMS, "Expected twenty river streams")
	return string.format("PASS: %d streams, %d logs, %d sampled stream sweeps, %d continuation parts, zoom %d, %d checkpoints", streamCount, streamCount * LOGS_PER_STREAM, sweptStreams, continuationParts, EXPECTED_ZOOM, EXPECTED_CHECKPOINTS)
end

return RiverFinish
