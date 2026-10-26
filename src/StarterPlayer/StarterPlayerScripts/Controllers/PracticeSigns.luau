--!strict
-- Practice area pad labels, restyled on this client only: Normal pads in sky blue, Harder line pads
-- in pink. During a run only that line's labels show, with the next pad in yellow and finished
-- pads in mint. The server's labels and pads are not changed.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PracticeConfig = require(ReplicatedStorage.Config.PracticeConfig)
local Kit = require(script.Parent.UiKit)

local Signs = {}
local LANE_FILL = {Normal = Kit.SkyDeep, Hard = Kit.Pink}
local styled: {[BillboardGui]: {label: TextLabel, lane: string?, index: number?}} = {}

-- Pad index along a lane: Checkpoint<N> is N, Start is 0 (start and finish of every lap).
local function padIndex(name: string): number?
	if name == "Start" then return 0 end
	local number = string.match(name, "^Checkpoint(%d+)$")
	return if number then tonumber(number) else nil
end

local function style(board: BillboardGui): any
	local entry = styled[board]
	if entry then return entry end
	local label = board:FindFirstChildWhichIsA("TextLabel")
	if not label then return nil end
	local pad = board.Parent
	local lane = pad and pad.Parent
	local laneName = if lane and (lane.Name == "Normal" or lane.Name == "Hard") then lane.Name else nil
	label.FontFace, label.TextColor3, label.TextScaled = Kit.Display, Kit.White, true
	label.BackgroundColor3 = if laneName then LANE_FILL[laneName] else Kit.Navy
	label.BackgroundTransparency = .05
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(.5, 0), label
	local edge = Kit.Stroke(label, Kit.Navy, 3, true)
	edge.Name = "Edge"
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingBottom, padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 10), UDim.new(0, 10)
	padding.Parent = label
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize, limit.Parent = 20, label
	if laneName and label.Text ~= "" then
		label.Text = string.gsub(label.Text, "^Hard", "Harder line")
	end
	entry = {label = label, lane = laneName, index = if laneName and pad then padIndex(pad.Name) else nil}
	styled[board] = entry
	board.Destroying:Connect(function() styled[board] = nil end)
	return entry
end

-- screen: RaceFlowPresentation.PracticeScreen result (or nil outside the practice area).
function Signs.Update(screen: any?)
	local area = workspace:FindFirstChild(PracticeConfig.CircuitName)
	if not area then return end
	local running = screen ~= nil and screen.mode == "Running"
	for _, board in area:GetDescendants() do
		if board:IsA("BillboardGui") then
			local entry = style(board)
			if entry and entry.lane then
				local mine = running and entry.lane == screen.line
				board.Enabled = not running or mine
				local fill = LANE_FILL[entry.lane]
				local text = Kit.Navy
				if mine and entry.index ~= nil and typeof(screen.nextIndex) == "number" then
					local nextIndex = screen.nextIndex
					local isNext = entry.index == nextIndex
					local done = if nextIndex == 0 then entry.index ~= 0 else entry.index ~= 0 and entry.index < nextIndex
					fill = if isNext then Kit.Sun elseif done then Kit.Mint else fill
					text = if isNext or done then Kit.Navy else Kit.White
					board.AlwaysOnTop = isNext
				else
					text = Kit.White
					board.AlwaysOnTop = false
				end
				entry.label.BackgroundColor3, entry.label.TextColor3 = fill, text
			end
		end
	end
end

return Signs
