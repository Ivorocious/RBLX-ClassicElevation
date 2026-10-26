--!strict
-- Shop preview (brief "Shop"): Get Keys and Finish styles tabs. Amounts, prices and styles are not
-- decided yet, so every card is "Coming soon" and its button only answers that; there are no
-- MarketplaceService calls or developer products here.
local RunService = game:GetService("RunService")
local Kit = require(script.Parent.UiKit)

local View = {}
-- Tier names only: amounts and prices wait for the owner's Keys decision.
local PACKS = {"Starter", "Bundle", "Big bundle", "Mega bundle"}
local STYLES = {
	{name = "Confetti pop", fx = "Confetti"}, {name = "Lightning", fx = "Bolt"},
	{name = "Coin rain", fx = "Coins"}, {name = "Fireworks", fx = "Fireworks"},
}
local CONFETTI = {Kit.Sun, Kit.Pink, Kit.Mint, Kit.White}

local function card(parent: Instance, index: number): Frame
	local plate = Kit.SkyPlate(parent, "Card" .. index, UDim2.fromOffset(210, 380), UDim2.new(), {fill = "White", class = "L", shadow = false, highlight = false})
	plate.LayoutOrder = index
	Kit.SetSkyOpacity(plate, .78)
	return plate
end

local function keyArt(parent: Instance, count: number)
	local art = Kit.Frame(parent, "Art", UDim2.fromOffset(190, 150), UDim2.new(.5, 0, 0, 40))
	art.AnchorPoint = Vector2.new(.5, 0)
	local spread, size = if count >= 3 then 26 else 34, if count >= 3 then 80 else 96
	for index = 1, count do
		local offset = index - (count + 1) / 2
		local key = Kit.Icon(art, "Key" .. index, Kit.Images.SkyKey, size)
		key.AnchorPoint, key.Position, key.Rotation = Vector2.new(.5, .5), UDim2.new(.5, offset * spread, 0, 60 + math.abs(offset) * 14), offset * 12
	end
end

local function preview(parent: Instance, fx: string): Frame
	local box = Kit.Frame(parent, "Preview", UDim2.fromOffset(170, 150), UDim2.new(.5, 0, 0, 40), Kit.Navy, .35)
	box.AnchorPoint, box.ClipsDescendants = Vector2.new(.5, 0), true
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius, boxCorner.Parent = UDim.new(0, 10), box
	box:SetAttribute("Fx", fx)
	-- A fixed seed scatters pieces the same way every time without lining them up.
	local scatter = Random.new(17)
	if fx == "Confetti" then
		for index = 1, 16 do
			local piece = Kit.Frame(box, "Piece", UDim2.fromOffset(8, 12), UDim2.new(scatter:NextNumber(.04, .92), 0, 0, -16), CONFETTI[(index % 4) + 1], 0)
			piece:SetAttribute("Delay", scatter:NextNumber(0, 1.6))
		end
	elseif fx == "Coins" then
		for _ = 1, 8 do
			local coin = Kit.Icon(box, "Coin", Kit.Images.StarCoin, 24)
			coin.Position = UDim2.new(scatter:NextNumber(.02, .82), 0, 0, -26)
			coin:SetAttribute("Delay", scatter:NextNumber(0, 1.6))
		end
	elseif fx == "Bolt" then
		local flash = Kit.Frame(box, "Flash", UDim2.fromScale(1, 1), UDim2.new(), Kit.Sun, 1)
		flash.Name = "Flash"
		for _, start in {Vector2.new(50, 10), Vector2.new(112, 22)} do
			local point = start
			for segment = 1, 3 do
				local angle = if segment % 2 == 1 then 24 else -24
				local length = 44
				local step = Vector2.new(length * math.sin(math.rad(angle)), length * math.cos(math.rad(angle)))
				local bolt = Kit.Frame(box, "Bolt", UDim2.fromOffset(7, length + 4), UDim2.fromOffset(point.X + step.X / 2, point.Y + step.Y / 2), Kit.Sun, 0)
				bolt.AnchorPoint, bolt.Rotation = Vector2.new(.5, .5), -angle
				point += step
			end
		end
	else
		for index, spot in {Vector2.new(.5, .45), Vector2.new(.28, .32), Vector2.new(.72, .58)} do
			local burst = Kit.Frame(box, "Burst", UDim2.fromOffset(10, 10), UDim2.fromScale(spot.X, spot.Y), CONFETTI[index], 1)
			burst.AnchorPoint = Vector2.new(.5, .5)
			local burstCorner = Instance.new("UICorner")
			burstCorner.CornerRadius, burstCorner.Parent = UDim.new(1, 0), burst
			local ring = Instance.new("UIStroke")
			ring.Thickness, ring.Color, ring.Parent = 4, CONFETTI[index], burst
			burst:SetAttribute("Delay", index * .4)
		end
	end
	return box
end

function View.Create(parent: Instance, close: () -> ()): any
	local shop: any = {tab = "Keys", buttons = {}}
	local root = Kit.Frame(parent, "Shop", UDim2.fromScale(1, 1), UDim2.new())
	root.Visible, root.ZIndex = false, 21
	-- Layout scale on the holder, open/close pop on the panel: one UIScale per object.
	local holder = Kit.Frame(root, "Holder", UDim2.fromOffset(1000, 530), UDim2.fromScale(.5, .55))
	holder.AnchorPoint = Vector2.new(.5, .5)
	local panelScale = Instance.new("UIScale")
	panelScale.Name, panelScale.Parent = "LayoutScale", holder
	local panel = Kit.SkyPlate(holder, "Panel", UDim2.fromScale(1, 1), UDim2.new(), {class = "L", stripes = true})
	shop.root, shop.panel, shop.scale = root, panel, panelScale
	local content = Kit.Content(panel)
	local title = Kit.SkyBig(content, "Title", "SHOP", 44, true)
	title.Position = UDim2.fromOffset(84, 24)
	local tabs = Kit.Frame(content, "Tabs", UDim2.fromOffset(330, 46), UDim2.fromOffset(240, 26))
	local function setTab(name: string)
		shop.tab = name
		Kit.SetSkyButtonKind(shop.buttons.TabKeys, if name == "Keys" then "Primary" else "Light")
		Kit.SetSkyButtonKind(shop.buttons.TabStyles, if name == "Styles" then "Primary" else "Light")
		shop.keys.Visible, shop.styles.Visible = name == "Keys", name == "Styles"
		local grid = if name == "Keys" then shop.keys else shop.styles
		for index, item in grid:GetChildren() do
			if item:IsA("GuiObject") then Kit.Punch(item, .85, .4, .06 * index) end
		end
		Kit.Play("Pop")
	end
	shop.buttons.TabKeys = Kit.SkyButton(tabs, "TabKeys", "Get Keys", UDim2.fromOffset(150, 44), UDim2.new(), function() setTab("Keys") end, "Primary", 17)
	shop.buttons.TabStyles = Kit.SkyButton(tabs, "TabStyles", "Finish styles", UDim2.fromOffset(170, 44), UDim2.fromOffset(160, 0), function() setTab("Styles") end, "Light", 17)
	shop.buttons.Close = Kit.SkyButton(content, "Close", "×", UDim2.fromOffset(52, 52), UDim2.new(1, -96, 0, 22), close, "Light", 30)
	local answer = Kit.Chip(content, "Answer", "The shop opens soon!", 16, "Good")
	answer.AnchorPoint, answer.Position, answer.Visible = Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -16), false
	local function comingSoon()
		answer.Visible = true
		Kit.Punch(answer, .6, .35)
		Kit.Play("Pop")
		local token = os.clock()
		shop.answerToken = token
		task.delay(1.8, function() if shop.answerToken == token then answer.Visible = false end end)
	end
	local function grid(name: string): Frame
		local frame = Kit.Frame(content, name, UDim2.new(1, -150, 0, 390), UDim2.fromOffset(84, 96))
		local list = Instance.new("UIListLayout")
		list.FillDirection, list.HorizontalAlignment, list.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, UDim.new(0, 14)
		list.SortOrder, list.Parent = Enum.SortOrder.LayoutOrder, frame
		return frame
	end
	shop.keys, shop.styles = grid("Keys"), grid("Styles")
	for index = 1, 4 do
		local plate = card(shop.keys, index)
		local inner = Kit.Content(plate)
		keyArt(inner, index)
		local name = Kit.SkyBig(inner, "Name", string.upper(PACKS[index]), 30)
		name.Position, name.Size = UDim2.fromOffset(7, 214), UDim2.new(1, -14, 0, 34)
		local chip = Kit.Chip(inner, "Pack", "Key pack", 14)
		chip.AnchorPoint, chip.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 262)
		Kit.SkyButton(inner, "Buy", "Coming soon", UDim2.fromOffset(160, 50), UDim2.new(.5, -80, 0, 306), comingSoon, "Light", 18)
	end
	for index, style in STYLES do
		local plate = card(shop.styles, index)
		local inner = Kit.Content(plate)
		preview(inner, style.fx)
		local name = Kit.SkyBig(inner, "Name", string.upper(style.name), 22)
		name.Position, name.Size = UDim2.fromOffset(8, 206), UDim2.new(1, -16, 0, 24)
		local price = Kit.Chip(inner, "Price", "Unlock with Keys", 14)
		price.AnchorPoint, price.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 248)
		Kit.SkyButton(inner, "Buy", "Coming soon", UDim2.fromOffset(160, 50), UDim2.new(.5, -80, 0, 306), comingSoon, "Light", 18)
	end
	shop.styles.Visible = false
	-- Small looping previews for the Finish styles cards while the tab is open.
	local started = os.clock()
	local loop = RunService.Heartbeat:Connect(function()
		if not root.Visible or not Kit.Motion() then return end
		local t = os.clock() - started
		if shop.keys.Visible then
			-- Key bundles bob gently, out of step with each other.
			for index, card in shop.keys:GetChildren() do
				local art = card:IsA("GuiObject") and card:FindFirstChild("Art", true)
				if art and art:IsA("GuiObject") then art.Position = UDim2.new(.5, 0, 0, 40 + math.sin(t * 2.2 + index) * 5) end
			end
			return
		end
		if not shop.styles.Visible then return end
		for _, box in shop.styles:GetDescendants() do
			if box.Name == "Preview" and box:IsA("Frame") then
				local fx = box:GetAttribute("Fx")
				for _, item in box:GetChildren() do
					if item:IsA("GuiObject") then
						local delay = (item:GetAttribute("Delay") or 0) :: number
						if fx == "Confetti" or fx == "Coins" then
							local k = ((t + delay) % 1.6) / 1.6
							item.Position = UDim2.new(item.Position.X.Scale, item.Position.X.Offset, k * 1.15, -26)
							item.Rotation = k * 300
						elseif fx == "Bolt" then
							local on = (t % 1.4) < .12
							if item.Name == "Flash" then item.BackgroundTransparency = if on then .6 else 1
							else item.BackgroundTransparency = if on then 0 else .7 end
						else
							local k = ((t + delay) % 1.2) / 1.2
							item.Size = UDim2.fromOffset(10 + k * 70, 10 + k * 70)
							local ring = item:FindFirstChildOfClass("UIStroke")
							if ring then ring.Transparency = k end
						end
					end
				end
			end
		end
	end)
	root.Destroying:Connect(function() loop:Disconnect() end)
	shop.SetTab = setTab
	return shop
end

function View.Open(shop: any)
	shop.root.Visible = true
	shop.SetTab(shop.tab)
	if Kit.Motion() then
		local pop = Kit.Scaler(shop.panel)
		pop.Scale = .82
		Kit.Tween(pop, .48, {Scale = 1}, "Pop")
	end
	Kit.Play("Whoosh")
end

function View.Close(shop: any)
	shop.root.Visible = false
end

function View.Layout(shop: any, size: Vector2)
	shop.scale.Scale = math.clamp(math.min(size.X / 1180, size.Y / 700), .45, 1.2)
end

return View
