-- The opening vote in motion: cards drift, a pick pops in, a change of mind, the LOCKED IN! stamp
-- and the timer's urgent last seconds. Loops.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({}, function(holder, _values)
	local View = StoryKit.Load("GalleryVotingView")
	local function noop() end
	local catalog = StoryKit.Catalog()
	local ui: any = nil
	local layer: Frame? = nil
	local function show(picks: {string}, confirmed: boolean, left: number)
		View.Render(ui, {catalog = catalog, picks = picks, timeLeft = left, duration = 15, phase = "Voting", pending = false, confirmed = confirmed, message = ""})
	end
	local stop = StoryKit.Sequence(holder, {
		{name = "Vote opens", seconds = 2, run = function()
			if layer then layer:Destroy() end
			local frame = Instance.new("Frame")
			frame.Name, frame.Size, frame.BackgroundTransparency = "Vote", UDim2.fromScale(1, 1), 1
			frame.Parent = holder
			layer = frame
			ui = View.Create(frame, {Hide = noop, Select = noop, Confirm = noop, Search = noop, Remove = noop})
			show({}, false, 12)
			return nil
		end},
		{name = "Pick a course", seconds = 1.8, run = function() show({catalog[1].id}, false, 11); return nil end},
		{name = "Change your mind", seconds = 1.8, run = function() show({catalog[3].id}, false, 10); return nil end},
		{name = "Locked in", seconds = 2.4, run = function() show({catalog[3].id}, true, 9); return nil end},
		{name = "Last seconds", seconds = 5.4, run = function()
			local running = true
			task.spawn(function()
				for left = 5, 1, -1 do
					if not running then return end
					show({catalog[3].id}, true, left)
					task.wait(1)
				end
			end)
			return function() running = false end
		end},
	}, {fresh = false})
	return function() stop(); if layer then layer:Destroy() end end
end)
