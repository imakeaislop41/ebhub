-- EB Hub (standalone)
-- Dynamic script hub with per-game tab support.
-- Universal features (Fly, Noclip, WalkSpeed, etc.) always available.
-- Game-specific tabs/features injected via GAME_CONFIGS at the bottom.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local OWNERS = { ebolacuh = true }
local FRIENDS = { phoenixlcshifterv151 = true }

------------------------------------------------------------------
-- Game Detection
------------------------------------------------------------------
local detectedGame = nil
local gameSupported = false

do
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if ok and info and info.Name then
		detectedGame = info.Name
	end
end

local C = {
	bg = Color3.fromRGB(12, 12, 12),
	side = Color3.fromRGB(0, 0, 0),
	card = Color3.fromRGB(22, 22, 22),
	card2 = Color3.fromRGB(32, 32, 32),
	stroke = Color3.fromRGB(45, 45, 45),
	track = Color3.fromRGB(50, 50, 50),
	text = Color3.fromRGB(235, 235, 235),
	sub = Color3.fromRGB(140, 140, 140),
	accent = Color3.fromRGB(125, 220, 90),
}

-- remove an older copy if the script is run again
local existing = playerGui:FindFirstChild("EBHub")
if existing then
	existing:Destroy()
end

-- disconnect old connections from previous execution
if _G._EBHub_Connections then
	for _, conn in _G._EBHub_Connections do
		pcall(function() conn:Disconnect() end)
	end
end
_G._EBHub_Connections = {}

local function ebConnect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(_G._EBHub_Connections, conn)
	return conn
end

------------------------------------------------------------------
-- Builder helpers
------------------------------------------------------------------
local function new(class, props, children)
	local i = Instance.new(class)
	if i:IsA("GuiObject") then
		i.BorderSizePixel = 0
	end
	if i:IsA("TextLabel") or i:IsA("TextButton") or i:IsA("TextBox") then
		i.Font = Enum.Font.Gotham
		i.TextColor3 = C.text
		i.BackgroundTransparency = 1
		i.TextSize = 13
	end
	for k, v in props do
		if k ~= "Parent" then
			i[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = i
	end
	i.Parent = props.Parent
	return i
end

local function corner(r)
	return new("UICorner", { CornerRadius = r and UDim.new(0, r) or UDim.new(1, 0) })
end

local function stroke(col)
	return new("UIStroke", { Color = col or C.stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

------------------------------------------------------------------
-- Build: ScreenGui + main window
------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "EBHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 5,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local main = new("Frame", {
	Parent = gui,
	Name = "Main",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(575, 326),
	BackgroundColor3 = C.bg,
	ClipsDescendants = true,
}, { corner(10), stroke() })
local mainScale = new("UIScale", { Parent = main, Scale = 1 })

-- Sidebar
local sidebar = new("Frame", { Parent = main, Name = "Sidebar", BackgroundColor3 = C.side, Size = UDim2.new(0, 128, 1, 0) }, { corner(10) })
new("Frame", { Parent = sidebar, Name = "Cover", BackgroundColor3 = C.side, Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0, 10, 1, 0) })
new("Frame", { Parent = sidebar, Name = "Edge", BackgroundColor3 = C.stroke, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0) })
local sideTitle = new("TextLabel", { Parent = sidebar, Name = "Title", Text = "EB", Font = Enum.Font.Garamond, TextSize = 36, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 40) })
new("TextLabel", { Parent = sidebar, Name = "Subtitle", Text = "H U B  ·  v1.0", TextSize = 10, TextColor3 = C.sub, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 14) })

local tabs = new("Frame", { Parent = sidebar, Name = "Tabs", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 0, 180) }, {
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
})
local indicator = new("Frame", { Parent = sidebar, Name = "Indicator", BackgroundColor3 = C.accent, Position = UDim2.fromOffset(8, 76 + 7), Size = UDim2.fromOffset(3, 16) }, { corner() })

local profile = new("Frame", { Parent = sidebar, Name = "Profile", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -52), Size = UDim2.new(1, 0, 0, 52) }, {
	new("Frame", { Name = "Line", BackgroundColor3 = C.stroke, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 0, 1) }),
	new("ImageLabel", { Name = "Avatar", BackgroundColor3 = C.card2, Image = "", Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(28, 28) }, { corner() }),
	new("TextLabel", { Name = "PlayerName", Text = "Player", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(46, 12), Size = UDim2.new(1, -52, 0, 14) }),
	new("TextLabel", { Name = "Rank", Text = "Member", TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(46, 27), Size = UDim2.new(1, -52, 0, 12) }),
})

-- Topbar
local topbar = new("Frame", { Parent = main, Name = "Topbar", BackgroundTransparency = 1, Position = UDim2.fromOffset(128, 0), Size = UDim2.new(1, -128, 0, 44) })
local pageTitle = new("TextLabel", { Parent = topbar, Name = "PageTitle", Text = "Home", Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -100, 1, 0) })
local function topButton(name, text, x)
	return new("TextButton", {
		Parent = topbar, Name = name, Text = text, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.sub, AutoButtonColor = false,
		BackgroundTransparency = 0, BackgroundColor3 = C.card, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(26, 26),
	}, { corner(6) })
end
local minimizeButton = topButton("Minimize", "–", -66)
local closeButton = topButton("Close", "×", -36)
new("Frame", { Parent = main, Name = "Divider", BackgroundColor3 = C.stroke, Position = UDim2.fromOffset(128, 44), Size = UDim2.new(1, -128, 0, 1) })

local pages = new("Frame", { Parent = main, Name = "Pages", BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromOffset(128, 45), Size = UDim2.new(1, -128, 1, -45) })

------------------------------------------------------------------
-- State
------------------------------------------------------------------
local FULL_SIZE = main.Size
local MIN_SIZE = UDim2.new(FULL_SIZE.X.Scale, FULL_SIZE.X.Offset, 0, 44)

local toggleKey = Enum.KeyCode.RightShift
local notificationsOn = true
local userScale = 1
local baseScale = 1
local isOpen = false
local isMinimized = false
local loaded = false
local startTime = os.clock()

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function isClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

------------------------------------------------------------------
-- Notifications
------------------------------------------------------------------
local notifs = new("Frame", { Parent = gui, Name = "Notifications", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(250, 400) }, {
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom }),
})
local template = new("Frame", { Parent = notifs, Name = "Template", Visible = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50) }, {
	new("Frame", { Name = "Inner", BackgroundColor3 = C.bg, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, {
		corner(8), stroke(),
		new("Frame", { Name = "Accent", BackgroundColor3 = C.accent, Size = UDim2.new(0, 3, 1, 0) }),
		new("TextLabel", { Name = "Title", Text = "Title", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -24, 0, 16) }),
		new("TextLabel", { Name = "Body", Text = "Body", TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(14, 26), Size = UDim2.new(1, -24, 0, 14) }),
		new("Frame", { Name = "Timer", BackgroundColor3 = C.accent, BackgroundTransparency = 0.5, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2) }),
	}),
})

local notifOrder = 0

local function notify(title, body, duration, force)
	if not notificationsOn and not force then
		return
	end
	duration = duration or 3
	notifOrder += 1
	local n = template:Clone()
	n.Name = "Notification"
	n.LayoutOrder = notifOrder
	n.Visible = true
	local inner = n:FindFirstChild("Inner")
	if not inner then n:Destroy() return end
	inner.Title.Text = title
	inner.Body.Text = body or ""
	inner.Position = UDim2.new(1.2, 0, 0, 0)
	n.Parent = notifs

	tween(inner, 0.45, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
	tween(inner.Timer, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay(duration, function()
		tween(inner, 0.35, { Position = UDim2.new(1.2, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Wait()
		tween(n, 0.2, { Size = UDim2.new(1, 0, 0, 0) }).Completed:Wait()
		n:Destroy()
	end)
end

------------------------------------------------------------------
-- Open / close / minimize
------------------------------------------------------------------
local function applyScale(animated)
	local target = baseScale * userScale
	if animated then
		tween(mainScale, 0.25, { Scale = target })
	else
		mainScale.Scale = target
	end
end

local function setOpen(open)
	if not loaded or open == isOpen then
		return
	end
	isOpen = open
	if open then
		main.Visible = true
		mainScale.Scale = baseScale * userScale * 0.85
		tween(mainScale, 0.4, { Scale = baseScale * userScale }, Enum.EasingStyle.Back)
	else
		tween(mainScale, 0.2, { Scale = baseScale * userScale * 0.85 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Once(function()
			if not isOpen then
				main.Visible = false
			end
		end)
	end
end

local function setMinimized(minimized)
	isMinimized = minimized
	tween(main, 0.35, { Size = minimized and MIN_SIZE or FULL_SIZE })
	minimizeButton.Text = minimized and "+" or "–"
end

------------------------------------------------------------------
-- Open button
------------------------------------------------------------------
local openButton = new("TextButton", {
	Parent = gui, Name = "OpenButton", Text = "EB", Font = Enum.Font.Garamond, TextSize = 20, AutoButtonColor = false, BackgroundTransparency = 0,
	BackgroundColor3 = C.side, Visible = false, Position = UDim2.fromOffset(14, 70), Size = UDim2.fromOffset(42, 42),
}, { corner(), stroke() })

minimizeButton.MouseButton1Click:Connect(function()
	setMinimized(not isMinimized)
end)
closeButton.MouseButton1Click:Connect(function()
	setOpen(false)
	notify("Hub hidden", "Press " .. toggleKey.Name .. " or tap EB to reopen")
end)
openButton.MouseButton1Click:Connect(function()
	setOpen(not isOpen)
end)

for _, b in { minimizeButton, closeButton } do
	b.MouseEnter:Connect(function()
		tween(b, 0.15, { BackgroundColor3 = b == closeButton and Color3.fromRGB(170, 50, 50) or C.card2, TextColor3 = C.text })
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.15, { BackgroundColor3 = C.card, TextColor3 = C.sub })
	end)
end

------------------------------------------------------------------
-- Dragging
------------------------------------------------------------------
local dragging, dragStart, startPos

local function beginDrag(input)
	if isClick(input) then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end
topbar.InputBegan:Connect(beginDrag)
sideTitle.InputBegan:Connect(beginDrag)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		tween(main, 0.08, {
			Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y),
		}, Enum.EasingStyle.Linear)
	end
end)

------------------------------------------------------------------
-- Tab System (dynamic)
------------------------------------------------------------------
local currentTab = nil
local tabOrder = {} -- ordered list of tab names
local tabPages = {} -- [name] = ScrollingFrame
local tabButtons = {} -- [name] = TextButton

-- Computes the indicator Y position for a given tab button
local function getIndicatorY(tabBtn)
	-- Walk the layout to find the visual index
	local idx = 0
	for _, child in tabs:GetChildren() do
		if child:IsA("TextButton") then
			if child.LayoutOrder < tabBtn.LayoutOrder then
				idx += 1
			elseif child == tabBtn then
				break
			end
		end
	end
	return tabs.Position.Y.Offset + idx * 34 + 7
end

local function selectTab(name)
	if currentTab == name then
		return
	end
	currentTab = name
	for tabName, tabBtn in tabButtons do
		local selected = tabName == name
		tween(tabBtn, 0.25, {
			BackgroundTransparency = selected and 0 or 1,
			TextColor3 = selected and C.text or C.sub,
		})
		if selected then
			tween(indicator, 0.35, { Position = UDim2.fromOffset(8, getIndicatorY(tabBtn)) }, Enum.EasingStyle.Back)
		end
	end
	for tabName, pg in tabPages do
		if tabName == name then
			pg.Visible = true
			pg.CanvasPosition = Vector2.zero
			pg.Position = UDim2.fromOffset(0, 14)
			tween(pg, 0.35, { Position = UDim2.fromOffset(0, 0) })
		else
			pg.Visible = false
		end
	end
	pageTitle.Text = name
	pageTitle.TextTransparency = 1
	tween(pageTitle, 0.3, { TextTransparency = 0 })
end

local function wireTabButton(tabBtn, name)
	tabBtn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
	tabBtn.MouseEnter:Connect(function()
		if currentTab ~= name then
			tween(tabBtn, 0.15, { TextColor3 = C.text, BackgroundTransparency = 0.6 })
		end
	end)
	tabBtn.MouseLeave:Connect(function()
		if currentTab ~= name then
			tween(tabBtn, 0.15, { TextColor3 = C.sub, BackgroundTransparency = 1 })
		end
	end)
end

------------------------------------------------------------------
-- Element builders — each page tracks its own order counter
------------------------------------------------------------------
local pageOrders = {} -- [pageName] = current order

local function nextPageOrder(pageName)
	pageOrders[pageName] = (pageOrders[pageName] or 0) + 1
	return pageOrders[pageName]
end

local function makePage(name)
	pageOrders[name] = 0
	return new("ScrollingFrame", {
		Parent = pages, Name = name, Visible = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.stroke, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }),
	})
end

local function section(p, text)
	new("TextLabel", {
		Parent = p, Name = "Section", LayoutOrder = nextPageOrder(p.Name), Text = string.upper(text), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.sub,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom, Size = UDim2.new(1, 0, 0, 20),
	}, { new("UIPadding", { PaddingLeft = UDim.new(0, 2) }) })
end

local function toggle(p, name, key, default)
	local f = new("Frame", { Parent = p, Name = name, LayoutOrder = nextPageOrder(p.Name), BackgroundColor3 = C.card, Size = UDim2.new(1, 0, 0, 38) }, {
		corner(6),
		new("TextLabel", { Name = "Title", Text = name, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -110, 1, 0) }),
		new("Frame", { Name = "Switch", BackgroundColor3 = C.track, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(34, 18) }, {
			corner(),
			new("Frame", { Name = "Knob", BackgroundColor3 = C.text, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(14, 14) }, { corner() }),
		}),
	})
	if key then
		new("TextLabel", {
			Parent = f, Name = "Key", Text = key, Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = C.sub, BackgroundTransparency = 0, BackgroundColor3 = C.card2,
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0), Size = UDim2.fromOffset(24, 18),
		}, { corner(4) })
		f:SetAttribute("Key", key)
	end
	f:SetAttribute("Type", "Toggle")
	f:SetAttribute("Enabled", default or false)
	return f
end

local function slider(p, name, min, max, default, suffix)
	local r = (default - min) / (max - min)
	local f = new("Frame", { Parent = p, Name = name, LayoutOrder = nextPageOrder(p.Name), BackgroundColor3 = C.card, Size = UDim2.new(1, 0, 0, 52) }, {
		corner(6),
		new("TextLabel", { Name = "Title", Text = name, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -90, 0, 16) }),
		new("TextLabel", {
			Name = "Value", Text = tostring(default) .. (suffix or ""), Font = Enum.Font.GothamBold, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(70, 16),
		}),
		new("Frame", { Name = "Bar", BackgroundColor3 = C.track, Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 6) }, {
			corner(),
			new("Frame", { Name = "Fill", BackgroundColor3 = C.accent, Size = UDim2.fromScale(r, 1) }, { corner() }),
			new("Frame", { Name = "Knob", BackgroundColor3 = C.text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(r, 0.5), Size = UDim2.fromOffset(12, 12) }, { corner() }),
		}),
	})
	f:SetAttribute("Type", "Slider")
	f:SetAttribute("Min", min)
	f:SetAttribute("Max", max)
	f:SetAttribute("Value", default)
	f:SetAttribute("Suffix", suffix or "")
	return f
end

local function button(p, name)
	local b = new("TextButton", {
		Parent = p, Name = name, LayoutOrder = nextPageOrder(p.Name), Text = "", AutoButtonColor = false, BackgroundTransparency = 0, BackgroundColor3 = C.card,
		ClipsDescendants = true, Size = UDim2.new(1, 0, 0, 36),
	}, {
		corner(6),
		new("TextLabel", { Name = "Title", Text = name, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0) }),
		new("TextLabel", { Name = "Arrow", Text = "›", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.sub, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 16, 1, 0) }),
	})
	b:SetAttribute("Type", "Button")
	return b
end

local function paragraph(p, name, text)
	return new("Frame", { Parent = p, Name = name, LayoutOrder = nextPageOrder(p.Name), BackgroundColor3 = C.card, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) }, {
		corner(6),
		new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		new("TextLabel", {
			Name = "Body", Text = text, TextSize = 12, TextColor3 = C.sub, TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LineHeight = 1.2,
		}),
	})
end

------------------------------------------------------------------
-- Callback registries (game configs add entries here)
------------------------------------------------------------------
local onToggle = {}
local onSlider = {}
local onButton = {}
local keyToggles = {} -- [KeyCode] = callback

------------------------------------------------------------------
-- Control setup functions
------------------------------------------------------------------
local function hover(obj)
	obj.MouseEnter:Connect(function()
		tween(obj, 0.15, { BackgroundColor3 = C.card2 })
	end)
	obj.MouseLeave:Connect(function()
		tween(obj, 0.15, { BackgroundColor3 = C.card })
	end)
end

local function ripple(btn, x, y)
	local scale = math.max(mainScale.Scale, 0.01)
	local circle = new("Frame", {
		Parent = btn, Name = "Ripple", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85,
		Position = UDim2.fromOffset((x - btn.AbsolutePosition.X) / scale, (y - btn.AbsolutePosition.Y) / scale), Size = UDim2.fromOffset(0, 0),
	}, { corner() })
	local size = btn.AbsoluteSize.X / scale * 2
	tween(circle, 0.5, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }).Completed:Once(function()
		circle:Destroy()
	end)
end

local function setupToggle(frame)
	local switch = frame.Switch
	local knob = switch.Knob

	local function render(animated)
		local on = frame:GetAttribute("Enabled")
		local pos = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		local col = on and C.accent or C.track
		if animated then
			tween(knob, 0.25, { Position = pos }, Enum.EasingStyle.Back)
			tween(switch, 0.25, { BackgroundColor3 = col })
			knob.Size = UDim2.fromOffset(18, 14)
			tween(knob, 0.25, { Size = UDim2.fromOffset(14, 14) })
		else
			knob.Position = pos
			switch.BackgroundColor3 = col
		end
	end

	local function set(on)
		frame:SetAttribute("Enabled", on)
		render(true)
		if onToggle[frame.Name] then
			onToggle[frame.Name](on)
			if frame.Name == "Notifications" then
				notify("Notifications", on and "Enabled" or "Disabled", 2, true)
				return
			end
		end
		notify(frame.Name, on and "Enabled" or "Disabled", 2)
	end

	frame.InputBegan:Connect(function(input)
		if isClick(input) then
			set(not frame:GetAttribute("Enabled"))
		end
	end)
	hover(frame)
	render(false)

	local key = frame:GetAttribute("Key")
	if key and Enum.KeyCode[key] then
		keyToggles[Enum.KeyCode[key]] = function()
			set(not frame:GetAttribute("Enabled"))
		end
	end
end

local function setupSlider(frame)
	local bar = frame.Bar
	local fill = bar.Fill
	local knob = bar.Knob
	local valueLabel = frame.Value
	local min, max = frame:GetAttribute("Min"), frame:GetAttribute("Max")
	local suffix = frame:GetAttribute("Suffix") or ""
	local sliding = false

	local function update(x)
		local ratio = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local value = math.floor(min + (max - min) * ratio + 0.5)
		ratio = (value - min) / (max - min)
		tween(fill, 0.1, { Size = UDim2.fromScale(ratio, 1) })
		tween(knob, 0.1, { Position = UDim2.fromScale(ratio, 0.5) })
		if frame:GetAttribute("Value") ~= value then
			frame:SetAttribute("Value", value)
			valueLabel.Text = tostring(value) .. suffix
			if onSlider[frame.Name] then
				onSlider[frame.Name](value)
			end
		end
	end

	frame.InputBegan:Connect(function(input)
		if isClick(input) then
			sliding = true
			tween(knob, 0.15, { Size = UDim2.fromOffset(16, 16) })
			update(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if sliding and isClick(input) then
			sliding = false
			tween(knob, 0.15, { Size = UDim2.fromOffset(12, 12) })
		end
	end)
	hover(frame)
end

local function setupButton(btn)
	btn.MouseButton1Down:Connect(function(x, y)
		ripple(btn, x, y)
	end)
	btn.MouseButton1Click:Connect(function()
		local arrow = btn:FindFirstChild("Arrow")
		if arrow then
			arrow.Position = UDim2.new(1, -6, 0, 0)
			tween(arrow, 0.3, { Position = UDim2.new(1, -12, 0, 0) }, Enum.EasingStyle.Back)
		end
		if onButton[btn.Name] then
			onButton[btn.Name]()
		else
			notify(btn.Name, "Done!", 2)
		end
	end)
	hover(btn)
end

local listeningForKey = false

local function setupKeybind(frame)
	local keyButton = frame.Key
	keyButton.MouseButton1Click:Connect(function()
		if listeningForKey then
			return
		end
		listeningForKey = true
		keyButton.Text = "..."
		tween(keyButton, 0.2, { TextColor3 = C.accent })
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				conn:Disconnect()
				if input.KeyCode ~= Enum.KeyCode.Escape then
					toggleKey = input.KeyCode
				end
				keyButton.Text = toggleKey.Name
				tween(keyButton, 0.2, { TextColor3 = C.text })
				notify("Keybind updated", "Toggle UI: " .. toggleKey.Name, 2)
				task.defer(function()
					listeningForKey = false
				end)
			end
		end)
	end)
	hover(frame)
end

-- Wires up all elements inside a page (call after adding elements)
local function setupPage(pg)
	for _, el in pg:GetChildren() do
		local kind = el:GetAttribute("Type")
		if kind == "Toggle" then
			setupToggle(el)
		elseif kind == "Slider" then
			setupSlider(el)
		elseif kind == "Button" then
			setupButton(el)
		elseif kind == "Keybind" then
			setupKeybind(el)
		end
	end
end

------------------------------------------------------------------
-- Hub API — addTab / removeTab
-- Game configs use this to inject their own pages.
--
-- layoutOrder controls position in the sidebar:
--   Home=1, Player=2, Visuals=3, World=4, Settings=100
--   Game tabs should use 5-99 to land between World and Settings.
------------------------------------------------------------------
local SETTINGS_ORDER = 100

local function addTab(name, layoutOrder)
	-- Create the sidebar button
	local tabBtn = new("TextButton", {
		Parent = tabs, Name = name, LayoutOrder = layoutOrder, Text = name,
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.sub,
		Font = Enum.Font.GothamMedium, AutoButtonColor = false,
		BackgroundTransparency = 1, BackgroundColor3 = C.card2,
		Size = UDim2.new(1, 0, 0, 30),
	}, { corner(6), new("UIPadding", { PaddingLeft = UDim.new(0, 14) }) })

	wireTabButton(tabBtn, name)

	-- Create the page
	local pg = makePage(name)

	-- Track
	tabButtons[name] = tabBtn
	tabPages[name] = pg
	table.insert(tabOrder, name)

	return pg
end

local function removeTab(name)
	if name == "Home" or name == "Settings" then return end -- protected

	if tabButtons[name] then
		tabButtons[name]:Destroy()
		tabButtons[name] = nil
	end
	if tabPages[name] then
		tabPages[name]:Destroy()
		tabPages[name] = nil
	end
	for i, n in tabOrder do
		if n == name then
			table.remove(tabOrder, i)
			break
		end
	end

	-- If we were on this tab, go home
	if currentTab == name then
		selectTab("Home")
	end
end

------------------------------------------------------------------
-- Build: core tabs (always present)
------------------------------------------------------------------

-- HOME (order 1)
local homePage = addTab("Home", 1)
local welcome = new("Frame", { Parent = homePage, Name = "Welcome", LayoutOrder = nextPageOrder("Home"), BackgroundColor3 = C.card, Size = UDim2.new(1, 0, 0, 70) }, {
	corner(8),
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 170)) }),
	new("ImageLabel", { Name = "Avatar", BackgroundColor3 = C.card2, Image = "", Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(48, 48) }, {
		corner(), new("UIStroke", { Color = C.accent, Thickness = 1.5 }),
	}),
	new("TextLabel", { Name = "Greeting", Text = "Welcome back,", TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(72, 16), Size = UDim2.new(1, -160, 0, 14) }),
	new("TextLabel", { Name = "PlayerName", Text = "Player", Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(72, 32), Size = UDim2.new(1, -160, 0, 22) }),
	new("TextLabel", {
		Name = "Badge", Text = "MEMBER", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = C.bg, BackgroundTransparency = 0, BackgroundColor3 = C.accent,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(64, 20),
	}, { corner() }),
})
local stats = new("Frame", { Parent = homePage, Name = "Stats", LayoutOrder = nextPageOrder("Home"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54) }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
for i, s in { { "Players", "0" }, { "Ping", "0 ms" }, { "Session", "00:00" } } do
	new("Frame", { Parent = stats, Name = s[1], LayoutOrder = i, BackgroundColor3 = C.card, Size = UDim2.new(1 / 3, -4, 1, 0) }, {
		corner(6),
		new("TextLabel", { Name = "Label", Text = string.upper(s[1]), Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 9), Size = UDim2.new(1, -20, 0, 12) }),
		new("TextLabel", { Name = "Value", Text = s[2], Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -20, 0, 20) }),
	})
end

local gameInfoText
if detectedGame then
	gameInfoText = '<font color="#7ddc5a">Detected:</font> ' .. detectedGame
else
	gameInfoText = '<font color="#ff6b6b">Could not detect game</font>'
end
section(homePage, "Game")
paragraph(homePage, "GameInfo", gameInfoText)
section(homePage, "Changelog")
paragraph(homePage, "Changelog", '<font color="#7ddc5a">v1.0</font>  ·  Initial release\n' ..
	"• New loader & animated interface\n" ..
	"• Player, Visuals and World tabs\n" ..
	"• Keybinds for toggles\n" ..
	'• Press <b>RightShift</b> to hide / show the hub')

-- NOTE: Player, Visuals, World tabs removed.
-- Universal features (Fly, Noclip, etc.) are still wired and work via keybinds.
-- Game-specific tabs are injected by GAME_CONFIGS below.

-- SETTINGS (order 100 — always last)
local st = addTab("Settings", SETTINGS_ORDER)
section(st, "Interface")
local kb = new("Frame", { Parent = st, Name = "Toggle UI", LayoutOrder = nextPageOrder("Settings"), BackgroundColor3 = C.card, Size = UDim2.new(1, 0, 0, 38) }, {
	corner(6),
	new("TextLabel", { Name = "Title", Text = "Toggle UI Keybind", TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -120, 1, 0) }),
	new("TextButton", {
		Name = "Key", Text = "RightShift", Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.text, AutoButtonColor = false, BackgroundTransparency = 0,
		BackgroundColor3 = C.card2, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(84, 22),
	}, { corner(4), stroke() }),
})
kb:SetAttribute("Type", "Keybind")
toggle(st, "Notifications", nil, true)
slider(st, "UI Scale", 80, 120, 100, "%")
section(st, "About")
paragraph(st, "About", '<b>EB Hub</b> v1.0\nMade by <font color="#7ddc5a">ebolacuh</font>')

------------------------------------------------------------------
-- Character helpers
------------------------------------------------------------------
local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

------------------------------------------------------------------
-- Feature State
------------------------------------------------------------------
local featureState = {
	flyEnabled = false,
	flySpeed = 50,
	noclipEnabled = false,
	infiniteJumpEnabled = false,
	walkSpeed = 16,
	jumpPower = 50,
	antiAfkEnabled = false,
	clickTpEnabled = false,
	fullbrightEnabled = false,
	noFogEnabled = false,
	fov = 70,
	lowGravEnabled = false,
}

local originalLighting = {
	Ambient = Lighting.Ambient,
	Brightness = Lighting.Brightness,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	GlobalShadows = Lighting.GlobalShadows,
}
local originalGravity = workspace.Gravity

------------------------------------------------------------------
-- FLY
------------------------------------------------------------------
local flyBody, flyGyro, flyConn = nil, nil, nil

local function startFly()
	local root = getRootPart()
	local hum = getHumanoid()
	if not root or not hum then return end
	hum.PlatformStand = true

	flyBody = Instance.new("BodyVelocity")
	flyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyBody.Velocity = Vector3.zero
	flyBody.Parent = root

	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	flyGyro.P = 9000
	flyGyro.Parent = root

	flyConn = RunService.RenderStepped:Connect(function()
		if not featureState.flyEnabled then return end
		local cam = workspace.CurrentCamera
		if not cam or not root.Parent then return end
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			dir -= Vector3.new(0, 1, 0)
		end
		if dir.Magnitude > 0 then dir = dir.Unit end
		flyBody.Velocity = dir * featureState.flySpeed
		flyGyro.CFrame = cam.CFrame
	end)
end

local function stopFly()
	local hum = getHumanoid()
	if hum then hum.PlatformStand = false end
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if flyBody then flyBody:Destroy(); flyBody = nil end
	if flyGyro then flyGyro:Destroy(); flyGyro = nil end
end

------------------------------------------------------------------
-- NOCLIP
------------------------------------------------------------------
local noclipConn = nil

local function startNoclip()
	noclipConn = RunService.Stepped:Connect(function()
		if not featureState.noclipEnabled then return end
		local char = player.Character
		if not char then return end
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end)
end

local function stopNoclip()
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end

------------------------------------------------------------------
-- INFINITE JUMP
------------------------------------------------------------------
local infJumpConn = nil

local function startInfJump()
	infJumpConn = UserInputService.JumpRequest:Connect(function()
		if not featureState.infiniteJumpEnabled then return end
		local hum = getHumanoid()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
end

local function stopInfJump()
	if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
end

------------------------------------------------------------------
-- ANTI AFK
------------------------------------------------------------------
local antiAfkConn = nil

local function startAntiAfk()
	antiAfkConn = player.Idled:Connect(function()
		local vim = game:GetService("VirtualUser")
		vim:CaptureController()
		vim:ClickButton2(Vector2.zero)
	end)
end

local function stopAntiAfk()
	if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
end

------------------------------------------------------------------
-- CLICK TELEPORT
------------------------------------------------------------------
local clickTpConn = nil

local function startClickTp()
	local mouse = player:GetMouse()
	clickTpConn = mouse.Button1Down:Connect(function()
		if not featureState.clickTpEnabled then return end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			local root = getRootPart()
			if root and mouse.Hit then
				root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
			end
		end
	end)
end

local function stopClickTp()
	if clickTpConn then clickTpConn:Disconnect(); clickTpConn = nil end
end

------------------------------------------------------------------
-- FULLBRIGHT / NO FOG / FOV / LOW GRAV
------------------------------------------------------------------
local function setFullbright(on)
	if on then
		Lighting.Ambient = Color3.fromRGB(200, 200, 200)
		Lighting.Brightness = 2
		Lighting.GlobalShadows = false
		for _, effect in Lighting:GetChildren() do
			if effect:IsA("Atmosphere") then
				effect:SetAttribute("_ebhub_density", effect.Density)
				effect.Density = 0
			end
		end
	else
		Lighting.Ambient = originalLighting.Ambient
		Lighting.Brightness = originalLighting.Brightness
		Lighting.GlobalShadows = originalLighting.GlobalShadows
		for _, effect in Lighting:GetChildren() do
			if effect:IsA("Atmosphere") then
				local saved = effect:GetAttribute("_ebhub_density")
				if saved then effect.Density = saved end
			end
		end
	end
end

local function setNoFog(on)
	if on then
		Lighting.FogEnd = 1e9
		Lighting.FogStart = 1e9
	else
		Lighting.FogEnd = originalLighting.FogEnd
		Lighting.FogStart = originalLighting.FogStart
	end
end

local function setFov(value)
	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = value end
end

local function setLowGrav(on)
	workspace.Gravity = on and 50 or originalGravity
end

------------------------------------------------------------------
-- Wire universal callbacks
------------------------------------------------------------------
onToggle.Notifications = function(on) notificationsOn = on end

onToggle.Fly = function(on)
	featureState.flyEnabled = on
	if on then startFly() else stopFly() end
end

onToggle.Noclip = function(on)
	featureState.noclipEnabled = on
	if on then startNoclip() else stopNoclip() end
end

onToggle["Infinite Jump"] = function(on)
	featureState.infiniteJumpEnabled = on
	if on then startInfJump() else stopInfJump() end
end

onToggle["Anti AFK"] = function(on)
	featureState.antiAfkEnabled = on
	if on then startAntiAfk() else stopAntiAfk() end
end

onToggle["Click Teleport"] = function(on)
	featureState.clickTpEnabled = on
	if on then startClickTp() else stopClickTp() end
end

onToggle.Fullbright = function(on)
	featureState.fullbrightEnabled = on
	setFullbright(on)
end

onToggle["No Fog"] = function(on)
	featureState.noFogEnabled = on
	setNoFog(on)
end

onToggle["Low Gravity"] = function(on)
	featureState.lowGravEnabled = on
	setLowGrav(on)
end

onSlider["UI Scale"] = function(value)
	userScale = value / 100
	applyScale(true)
end

onSlider["Fly Speed"] = function(value)
	featureState.flySpeed = value
end

onSlider.WalkSpeed = function(value)
	featureState.walkSpeed = value
	local hum = getHumanoid()
	if hum then hum.WalkSpeed = value end
end

onSlider.JumpPower = function(value)
	featureState.jumpPower = value
	local hum = getHumanoid()
	if hum then hum.JumpPower = value; hum.UseJumpPower = true end
end

onSlider["Field of View"] = function(value)
	featureState.fov = value
	setFov(value)
end

onButton["Reset Character"] = function()
	local hum = getHumanoid()
	if hum then hum.Health = 0 end
end

onButton["Teleport to Spawn"] = function()
	local root = getRootPart()
	if not root then return end
	local spawn = nil
	for _, desc in workspace:GetDescendants() do
		if desc:IsA("SpawnLocation") then spawn = desc; break end
	end
	if spawn then
		root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
	else
		notify("Teleport", "No spawn found", 2)
	end
end

onButton["Teleport to Random Player"] = function()
	local root = getRootPart()
	if not root then return end
	local others = {}
	for _, p in Players:GetPlayers() do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(others, p)
		end
	end
	if #others == 0 then
		notify("Teleport", "No other players", 2)
		return
	end
	local target = others[math.random(1, #others)]
	root.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
	notify("Teleport", "Teleported to " .. target.DisplayName, 2)
end

onButton.Rejoin = function()
	TeleportService:Teleport(game.PlaceId, player)
end

onButton["Server Hop"] = function()
	notify("Server Hop", "Finding server...", 2)
	task.spawn(function()
		local ok, servers = pcall(function()
			local HttpService = game:GetService("HttpService")
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/0?sortOrder=Asc&limit=10"
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if ok and servers and servers.data then
			for _, server in servers.data do
				if server.playing and server.playing < server.maxPlayers and server.id ~= game.JobId then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
					return
				end
			end
			notify("Server Hop", "No servers found, rejoining...", 2)
			TeleportService:Teleport(game.PlaceId, player)
		else
			notify("Server Hop", "Failed, rejoining instead", 2)
			TeleportService:Teleport(game.PlaceId, player)
		end
	end)
end

------------------------------------------------------------------
-- Wire up all core pages
------------------------------------------------------------------
for _, pg in tabPages do
	setupPage(pg)
end

------------------------------------------------------------------
-- Input handler
------------------------------------------------------------------
ebConnect(UserInputService.InputBegan, function(input, processed)
	if processed or listeningForKey or not loaded then
		return
	end
	if input.KeyCode == toggleKey then
		setOpen(not isOpen)
	elseif isOpen and keyToggles[input.KeyCode] then
		keyToggles[input.KeyCode]()
	end
end)

------------------------------------------------------------------
-- Respawn handler
------------------------------------------------------------------
ebConnect(player.CharacterAdded, function(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	if featureState.walkSpeed ~= 16 then
		hum.WalkSpeed = featureState.walkSpeed
	end
	if featureState.jumpPower ~= 50 then
		hum.UseJumpPower = true
		hum.JumpPower = featureState.jumpPower
	end
	if featureState.flyEnabled then
		stopFly()
		task.wait(0.5)
		startFly()
	end
end)

------------------------------------------------------------------
-- Profile / stats
------------------------------------------------------------------
local isOwner = OWNERS[string.lower(player.Name)] == true
local isFriend = FRIENDS[string.lower(player.Name)] == true

welcome.PlayerName.Text = player.DisplayName
welcome.Badge.Text = isOwner and "OWNER" or isFriend and "FRIEND" or "MEMBER"
if isOwner then
	welcome.Badge.BackgroundColor3 = Color3.fromRGB(255, 190, 50)
elseif isFriend then
	welcome.Badge.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
end
profile.PlayerName.Text = player.DisplayName
profile.Rank.Text = isOwner and "Owner" or isFriend and "Friend" or "Member"

task.spawn(function()
	local ok, image = pcall(function()
		return Players:GetUserThumbnailAsync(math.max(player.UserId, 1), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok then
		welcome.Avatar.Image = image
		profile.Avatar.Image = image
	end
end)

task.spawn(function()
	while gui.Parent do
		stats.Players.Value.Text = tostring(#Players:GetPlayers())
		local okPing, ping = pcall(function() return player:GetNetworkPing() end)
		stats.Ping.Value.Text = okPing and (math.floor(ping * 1000) .. " ms") or "--"
		local t = math.floor(os.clock() - startTime)
		stats.Session.Value.Text = string.format("%02d:%02d", t // 60, t % 60)
		task.wait(1)
	end
end)

------------------------------------------------------------------
-- Responsive scale
------------------------------------------------------------------
local function updateBaseScale()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local vp = camera.ViewportSize
	baseScale = math.clamp(math.min(vp.X / 700, vp.Y / 420), 0.55, 1)
	if loaded then applyScale(false) end
end
updateBaseScale()
if workspace.CurrentCamera then
	ebConnect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateBaseScale)
end

gui.Parent = playerGui

--================================================================
--  GAME CONFIGS
--  Each entry is a PlaceId → setup function.
--  The function receives a table of helpers so it can build
--  tabs, add elements, register callbacks, and toast.
--
--  Available helpers inside the config function:
--    hub.addTab(name, order)   → returns the page (ScrollingFrame)
--    hub.removeTab(name)
--    hub.section(page, text)
--    hub.toggle(page, name, key?, default?)
--    hub.slider(page, name, min, max, default, suffix?)
--    hub.button(page, name)
--    hub.paragraph(page, name, text)
--    hub.onToggle[name] = function(on) ... end
--    hub.onSlider[name] = function(value) ... end
--    hub.onButton[name] = function() ... end
--    hub.notify(title, body, duration?)
--    hub.setupPage(page)   — call AFTER adding all elements
--    hub.player             — LocalPlayer
--    hub.getCharacter()
--    hub.getHumanoid()
--    hub.getRootPart()
--================================================================
local hub = {
	addTab = addTab,
	removeTab = removeTab,
	section = section,
	toggle = toggle,
	slider = slider,
	button = button,
	paragraph = paragraph,
	onToggle = onToggle,
	onSlider = onSlider,
	onButton = onButton,
	notify = notify,
	setupPage = setupPage,
	player = player,
	getCharacter = getCharacter,
	getHumanoid = getHumanoid,
	getRootPart = getRootPart,
}

------------------------------------------------------------------
-- GAME_CONFIGS — add your games here
------------------------------------------------------------------
local GAME_CONFIGS = {

	-- Swing Obby for Brainrots!
	[114640202062357] = function(hub)
		------------------------------------------------------------
		-- Services & Remotes
		------------------------------------------------------------
		local RunService = game:GetService("RunService")
		local KnitServices = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services")
		local GameplayRF = KnitServices:WaitForChild("GameplayService"):WaitForChild("RF")
		local PlotRF     = KnitServices:WaitForChild("PlotService"):WaitForChild("RF")

		local ReturnToPlot     = GameplayRF:WaitForChild("ReturnToPlot")
		local SellRemote       = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellBrainrot")
		local PlacePickUpSwap  = PlotRF:WaitForChild("PlacePickUpSwap")
		local MaxUpgradeRemote = PlotRF:WaitForChild("MaxUpgrade")

		------------------------------------------------------------
		-- Rarity hierarchy
		------------------------------------------------------------
		local RARITY_VALUE = {
			Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
			Legendary = 5, Mythic = 6, Secret = 7, Divine = 8, Ancient = 9,
		}
		local RARITY_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Ancient" }

		------------------------------------------------------------
		-- State
		------------------------------------------------------------
		local farmActive = false
		local autoPlaceActive = true
		local autoUpgradeActive = true
		local farmDelay = 0.35
		local farmZoneMin = 1
		local farmZoneMax = 14
		local minRarity = 1
		local farmStats = { collected = 0, placed = 0, upgraded = 0, cycles = 0 }

		------------------------------------------------------------
		-- Cache our plot once
		------------------------------------------------------------
		local myPlot = nil
		do
			-- Retry a few times in case plot attributes aren't set yet
			for attempt = 1, 10 do
				for _, plot in workspace.Plots:GetChildren() do
					if plot:GetAttribute("OwnerUserID") == hub.player.UserId then
						myPlot = plot
						break
					end
				end
				if myPlot then break end
				task.wait(0.5)
			end
		end

		------------------------------------------------------------
		-- Helpers
		------------------------------------------------------------
		local function getBrainrotTools()
			local tools = {}
			for _, t in hub.player.Backpack:GetChildren() do
				if t:IsA("Tool") and t.Name:find("_Tool") then
					table.insert(tools, t)
				end
			end
			-- Also check character (equipped tool)
			local char = hub.player.Character
			if char then
				for _, t in char:GetChildren() do
					if t:IsA("Tool") and t.Name:find("_Tool") then
						table.insert(tools, t)
					end
				end
			end
			return tools
		end

		local function hasBrainrotTools()
			return #getBrainrotTools() > 0
		end

		local function podHasBrainrot(pod)
			local bmFolder = pod:FindFirstChild("BrainrotModel")
			if not bmFolder then return false end
			return #bmFolder:GetChildren() > 0
		end

		local function getEmptyPods()
			if not myPlot then return {} end
			local pods = myPlot:FindFirstChild("Pods")
			if not pods then return {} end
			local empty = {}
			for _, pod in pods:GetChildren() do
				if not podHasBrainrot(pod) then
					table.insert(empty, pod)
				end
			end
			table.sort(empty, function(a, b)
				return (tonumber(a.Name) or 999) < (tonumber(b.Name) or 999)
			end)
			return empty
		end

		local function getOccupiedPods()
			if not myPlot then return {} end
			local pods = myPlot:FindFirstChild("Pods")
			if not pods then return {} end
			local list = {}
			for _, pod in pods:GetChildren() do
				if podHasBrainrot(pod) then
					table.insert(list, pod)
				end
			end
			return list
		end

		local function getBrainrots()
			local folder = workspace:FindFirstChild("ActiveBrainrots")
			if not folder then return {} end
			local list = {}
			for _, b in folder:GetChildren() do
				if b:IsA("BasePart") and b.Name == "ServerHitbox" then
					local zone = b:GetAttribute("Zone")
					local rarity = b:GetAttribute("Rarity") or "Common"
					local rarityVal = RARITY_VALUE[rarity] or 1
					if zone and zone >= farmZoneMin and zone <= farmZoneMax and rarityVal >= minRarity then
						local pp = b:FindFirstChildWhichIsA("ProximityPrompt", true)
						if pp then
							table.insert(list, {
								part = b, prompt = pp, zone = zone,
								pos = b.Position, income = b:GetAttribute("Income") or 0,
								rarity = rarity, rarityVal = rarityVal,
								name = b:GetAttribute("Name") or "?",
							})
						end
					end
				end
			end
			-- Sort by rarity descending first, then income descending
			table.sort(list, function(a, b)
				if a.rarityVal ~= b.rarityVal then return a.rarityVal > b.rarityVal end
				return a.income > b.income
			end)
			return list
		end

		local function tpTo(position)
			local root = hub.getRootPart()
			if not root then return false end
			root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
			return true
		end

		------------------------------------------------------------
		-- Actions
		------------------------------------------------------------
		local function ensureBatEquipped()
			local hum = hub.getHumanoid()
			if not hum then return end
			-- Unequip anything first
			local char = hub.player.Character
			if char then
				local held = char:FindFirstChildOfClass("Tool")
				if held and held.Name == "Bat" then return end -- already good
				if held then hum:UnequipTools() task.wait(0.05) end
			end
			local bat = hub.player.Backpack:FindFirstChild("Bat")
			if bat then
				hum:EquipTool(bat)
				task.wait(0.15)
			end
		end

		local function collectBrainrot(info)
			if not info.part or not info.part.Parent then return false end
			if not info.prompt or not info.prompt.Parent then return false end
			ensureBatEquipped()
			if not tpTo(info.pos) then return false end
			task.wait(1) -- sit on it, let server fully register position
			local ok = pcall(fireproximityprompt, info.prompt, 1)
			task.wait(1) -- wait for pickup to process
			return ok
		end

		local function returnToPlot()
			pcall(function() ReturnToPlot:InvokeServer() end)
		end

		-- Get the worst brainrot on our pods (lowest rarity, then lowest income)
		local function getWorstPod()
			if not myPlot then return nil, nil end
			local pods = myPlot:FindFirstChild("Pods")
			if not pods then return nil, nil end
			local worst = nil
			local worstVal = 999
			local worstIncome = math.huge
			for _, pod in pods:GetChildren() do
				if podHasBrainrot(pod) then
					local rarity = pod:GetAttribute("Rarity") or "Common"
					local rv = RARITY_VALUE[rarity] or 1
					local income = pod:GetAttribute("CurrentIncome") or 0
					if rv < worstVal or (rv == worstVal and income < worstIncome) then
						worst = pod
						worstVal = rv
						worstIncome = income
					end
				end
			end
			return worst, worstVal
		end

		-- Sell only brainrots worse than the worst pod (don't sell upgrades)
		local function sellTrash()
			local hum = hub.getHumanoid()
			if not hum then print("[EB] sellTrash: no humanoid") return end
			local _, worstPodRarity = getWorstPod()
			if not worstPodRarity then worstPodRarity = 0 end

			local tools = getBrainrotTools()
			print("[EB] sellTrash: " .. #tools .. " tools, worstPodRarity=" .. worstPodRarity)
			local sold = 0
			for _, tool in tools do
				local toolRarity = RARITY_VALUE[tool:GetAttribute("Rarity") or "Common"] or 1
				-- Only sell if strictly worse than worst pod
				if toolRarity < worstPodRarity then
					print("[EB] Selling: " .. tool.Name .. " (rv=" .. toolRarity .. " < " .. worstPodRarity .. ")")
					hum:EquipTool(tool)
					task.wait(0.15)
					pcall(function() SellRemote:FireServer("Single") end)
					task.wait(0.2)
					sold += 1
				end
			end
			print("[EB] Sold " .. sold .. " trash")
			ensureBatEquipped()
		end

		-- Force sell everything (manual button only)
		local function sellForceAll()
			local hum = hub.getHumanoid()
			if not hum then return end
			local tools = getBrainrotTools()
			if #tools == 0 then return end
			hum:EquipTool(tools[1])
			task.wait(0.15)
			pcall(function() SellRemote:FireServer("All") end)
			task.wait(0.3)
			ensureBatEquipped()
		end

		-- Place a brainrot tool: fill empty pods first, then smart-swap worst pod
		local function placeOrSwap()
			local hum = hub.getHumanoid()
			if not hum then return 0 end
			local placed = 0

			-- Sort tools by rarity descending so best get placed first
			local tools = getBrainrotTools()
			table.sort(tools, function(a, b)
				local ra = RARITY_VALUE[a:GetAttribute("Rarity") or "Common"] or 1
				local rb = RARITY_VALUE[b:GetAttribute("Rarity") or "Common"] or 1
				return ra > rb
			end)

			for _, tool in tools do
				if not tool.Parent then continue end -- already sold/placed
				local toolRarity = RARITY_VALUE[tool:GetAttribute("Rarity") or "Common"] or 1

				-- Try empty pod first
				local emptyPods = getEmptyPods()
				if #emptyPods > 0 then
					hum:EquipTool(tool)
					task.wait(0.15)
					pcall(function() PlacePickUpSwap:InvokeServer(emptyPods[1]) end)
					placed += 1
					task.wait(0.2)
				else
					-- All pods full — swap only if strictly better than worst
					local worstPod, worstRarity = getWorstPod()
					if worstPod and toolRarity > worstRarity then
						print("[EB] Swapping pod " .. worstPod.Name .. " (rv=" .. worstRarity .. ") for " .. tool.Name .. " (rv=" .. toolRarity .. ")")
						hum:EquipTool(tool)
						task.wait(0.15)
						pcall(function() PlacePickUpSwap:InvokeServer(worstPod) end)
						placed += 1
						task.wait(0.2)
					end
					-- If same or worse rarity, skip this tool (don't break — try next tool)
				end
			end

			ensureBatEquipped()
			return placed
		end

		local UpgradeRemote = PlotRF:WaitForChild("Upgrade")

		local function upgradeAll()
			local upgraded = 0
			local keepGoing = true
			while keepGoing do
				keepGoing = false
				local pods = getOccupiedPods()
				table.sort(pods, function(a, b)
					return (a:GetAttribute("CurrentLevel") or 0) < (b:GetAttribute("CurrentLevel") or 0)
				end)
				for _, pod in pods do
					local ok, result = pcall(function() return UpgradeRemote:InvokeServer(pod) end)
					if ok and result then
						upgraded += 1
						keepGoing = true
					end
					task.wait()
				end
			end
			return upgraded
		end

		-- Auto collect cash from all pods by touching their TouchParts
		local function collectAllCash()
			if not myPlot then print("[EB] collectCash: no plot") return end
			local pods = myPlot:FindFirstChild("Pods")
			if not pods then print("[EB] collectCash: no pods folder") return end
			local root = hub.getRootPart()
			if not root then print("[EB] collectCash: no rootpart") return end
			local touched = 0
			for _, pod in pods:GetChildren() do
				if podHasBrainrot(pod) then
					local touchPart = pod:FindFirstChild("TouchPart")
					if touchPart then
						local ok, err = pcall(function()
							firetouchinterest(root, touchPart, 0)
							task.wait()
							firetouchinterest(root, touchPart, 1)
						end)
						if ok then touched += 1 end
					end
				end
			end
			print("[EB] collectCash: touched " .. touched .. " pods")
		end

		------------------------------------------------------------
		-- 3D Rendering
		------------------------------------------------------------
		local function setRendering(on)
			pcall(function() RunService:Set3dRenderingEnabled(on) end)
		end

		------------------------------------------------------------
		-- Farm loop
		------------------------------------------------------------
		local function farmLoop()
			while farmActive do
				print("[EB] Cycle start")
				local brainrots = getBrainrots()
				if #brainrots == 0 then
					print("[EB] No brainrots found, waiting...")
					task.wait(1.5)
					continue
				end

				farmStats.cycles += 1
				local grabAmount = hub.player:GetAttribute("GrabAmount") or 1
				print("[EB] Found " .. #brainrots .. " brainrots, grabAmount=" .. grabAmount)

				-- Collect up to GrabAmount brainrots (best income first)
				local grabbed = 0
				for _, info in brainrots do
					if not farmActive then break end
					if grabbed >= grabAmount then break end
					print("[EB] Collecting: " .. (info.name or "?") .. " (" .. (info.rarity or "?") .. ") zone " .. (info.zone or "?"))
					if collectBrainrot(info) then
						grabbed += 1
						farmStats.collected += 1
						print("[EB] Grabbed #" .. grabbed)
					else
						print("[EB] Failed to grab")
					end
					task.wait(farmDelay)
				end

				print("[EB] Grabbed total: " .. grabbed)
				if not farmActive or grabbed == 0 then continue end

				-- Return to plot
				print("[EB] Returning to plot...")
				returnToPlot()
				task.wait(0.5)

				-- Place on empty pods or swap worst pods
				if autoPlaceActive then
					print("[EB] Placing/swapping...")
					local toolsBefore = #getBrainrotTools()
					print("[EB] Tools before place: " .. toolsBefore)
					local placed = placeOrSwap()
					local toolsAfter = #getBrainrotTools()
					print("[EB] Placed: " .. placed .. ", tools after: " .. toolsAfter)
					farmStats.placed += placed
					task.wait(0.15)
				else
					print("[EB] Auto place OFF")
				end

				-- Sell only trash (worse than worst pod)
				if hasBrainrotTools() then
					print("[EB] Selling trash...")
					sellTrash()
					task.wait(0.15)
				end

				-- Collect cash from pods
				print("[EB] Collecting cash...")
				collectAllCash()
				task.wait(0.1)

				-- Upgrade all pods (cheapest first)
				if autoUpgradeActive then
					print("[EB] Upgrading...")
					local upgraded = upgradeAll()
					print("[EB] Upgraded: " .. upgraded)
					farmStats.upgraded += upgraded
				end

				task.wait(0.2)
			end
		end

		------------------------------------------------------------
		-- Build UI
		------------------------------------------------------------
		local farm = hub.addTab("Farm", 5)
		hub.section(farm, "Auto Farm")
		hub.toggle(farm, "Auto Farm", "G")
		hub.toggle(farm, "Auto Place + Swap", nil, true)
		hub.toggle(farm, "Auto Upgrade", nil, true)
		hub.slider(farm, "Farm Delay", 10, 100, 35, "ms")
		hub.slider(farm, "Zone Min", 1, 15, 1)
		hub.slider(farm, "Zone Max", 1, 14, 14)
		hub.slider(farm, "Min Rarity", 1, 9, 1)
		hub.section(farm, "Actions")
		hub.button(farm, "Collect Cash")
		hub.button(farm, "Sell Trash")
		hub.button(farm, "Sell All (Force)")
		hub.button(farm, "Place All")
		hub.button(farm, "Upgrade All")
		hub.button(farm, "Return to Plot")
		hub.button(farm, "Collect Best")
		hub.section(farm, "Performance")
		hub.toggle(farm, "Disable 3D Rendering")
		hub.section(farm, "Info")
		hub.paragraph(farm, "FarmInfo", '<font color="#7ddc5a">Status:</font> Idle')
		hub.setupPage(farm)

		local tp = hub.addTab("Teleports", 6)
		hub.section(tp, "Zones")
		for i = 1, 15 do
			hub.button(tp, "Zone " .. i)
		end
		hub.setupPage(tp)

		------------------------------------------------------------
		-- Stats updater
		------------------------------------------------------------
		task.spawn(function()
			local infoFrame = farm:FindFirstChild("FarmInfo")
			local body = infoFrame and infoFrame:FindFirstChild("Body")
			while farm.Parent do
				if body then
					local status = farmActive and '<font color="#7ddc5a">Farming</font>' or "Idle"
					local emptyCount = #getEmptyPods()
					local occupiedCount = #getOccupiedPods()
					body.Text = '<font color="#7ddc5a">Status:</font> ' .. status ..
						'\n<font color="#7ddc5a">Collected:</font> ' .. farmStats.collected ..
						'  |  <font color="#7ddc5a">Placed:</font> ' .. farmStats.placed ..
						'\n<font color="#7ddc5a">Upgraded:</font> ' .. farmStats.upgraded ..
						'  |  <font color="#7ddc5a">Cycles:</font> ' .. farmStats.cycles ..
						'\n<font color="#7ddc5a">Rarity:</font> ' .. (RARITY_NAMES[minRarity] or "?") .. '+' ..
						'  |  <font color="#7ddc5a">Pods:</font> ' .. occupiedCount .. '/' .. (occupiedCount + emptyCount) ..
						'  |  <font color="#7ddc5a">Grab:</font> ' .. (hub.player:GetAttribute("GrabAmount") or 1)
				end
				task.wait(0.5)
			end
		end)

		------------------------------------------------------------
		-- Callbacks
		------------------------------------------------------------
		local farmRunning = false
		hub.onToggle["Auto Farm"] = function(on)
			farmActive = on
			hub.notify("Auto Farm", on and "Started" or "Stopped", 2)
			if on and not farmRunning then
				farmRunning = true
				task.spawn(function()
					farmLoop()
					farmRunning = false
				end)
			end
		end
		hub.onToggle["Auto Place + Swap"] = function(on) autoPlaceActive = on end
		hub.onToggle["Auto Upgrade"] = function(on) autoUpgradeActive = on end
		hub.onToggle["Disable 3D Rendering"] = function(on)
			setRendering(not on)
			hub.notify("3D Rendering", on and "Disabled" or "Enabled", 2)
		end
		hub.onSlider["Farm Delay"] = function(v) farmDelay = v / 100 end
		hub.onSlider["Zone Min"] = function(v) farmZoneMin = v end
		hub.onSlider["Zone Max"] = function(v) farmZoneMax = v end
		hub.onSlider["Min Rarity"] = function(v)
			minRarity = v
			hub.notify("Min Rarity", RARITY_NAMES[v] .. "+", 2)
		end

		hub.onButton["Collect Cash"] = function()
			collectAllCash()
			hub.notify("Cash", "Collected from all pods", 2)
		end
		hub.onButton["Sell Trash"] = function() sellTrash(); hub.notify("Sell", "Sold trash only", 2) end
		hub.onButton["Sell All (Force)"] = function() sellForceAll(); hub.notify("Sell", "Sold everything!", 2) end
		hub.onButton["Place All"] = function()
			local p = placeOrSwap()
			hub.notify("Place", "Placed " .. p, 2)
		end
		hub.onButton["Upgrade All"] = function()
			local u = upgradeAll()
			hub.notify("Upgrade", "Upgraded " .. u .. " pods", 2)
		end
		hub.onButton["Return to Plot"] = function()
			returnToPlot()
			hub.notify("Teleport", "Returned to plot", 2)
		end
		hub.onButton["Collect Best"] = function()
			local brainrots = getBrainrots()
			if #brainrots == 0 then
				hub.notify("Collect", "Nothing matching filter", 2)
				return
			end
			if collectBrainrot(brainrots[1]) then
				hub.notify("Collected", brainrots[1].name .. " (" .. brainrots[1].rarity .. ")", 2)
			else
				hub.notify("Collect", "Failed", 2)
			end
		end

		for i = 1, 15 do
			hub.onButton["Zone " .. i] = function()
				local folder = workspace:FindFirstChild("ActiveBrainrots")
				if folder then
					for _, b in folder:GetChildren() do
						if b:IsA("BasePart") and b:GetAttribute("Zone") == i then
							tpTo(b.Position)
							hub.notify("Teleport", "Zone " .. i, 2)
							return
						end
					end
				end
				hub.notify("Teleport", "No brainrots in Zone " .. i, 2)
			end
		end

		-- Listen for special spawns (Legendary+) and priority grab them
		local BrainrotSpawned = KnitServices:WaitForChild("BrainrotService"):WaitForChild("RE"):WaitForChild("BrainrotSpawned")
		ebConnect(BrainrotSpawned.OnClientEvent, function()
			if not farmActive then return end
			task.wait(0.5) -- let it appear in workspace
			local folder = workspace:FindFirstChild("ActiveBrainrots")
			if not folder then return end
			for _, b in folder:GetChildren() do
				if b:IsA("BasePart") and b.Name == "ServerHitbox" then
					local rarity = b:GetAttribute("Rarity") or "Common"
					local zone = b:GetAttribute("Zone") or 0
					local rv = RARITY_VALUE[rarity] or 1
					if rv >= 6 and zone <= 14 then
						local pp = b:FindFirstChildWhichIsA("ProximityPrompt", true)
						if pp then
							hub.notify("Priority Grab", rarity .. " in Zone " .. zone .. "!", 3)
							collectBrainrot({
								part = b, prompt = pp, zone = zone,
								pos = b.Position, income = b:GetAttribute("Income") or 0,
								rarity = rarity, rarityVal = rv,
								name = b:GetAttribute("Name") or "?",
							})
							returnToPlot()
							task.wait(0.5)
							if autoPlaceActive then placeOrSwap() end
							if hasBrainrotTools() then sellTrash() end
						end
					end
				end
			end
		end)
	end,

	-- Roblox Talent Show
	[10851599] = function(hub)
		------------------------------------------------------------
		-- Services
		------------------------------------------------------------
		local RunService   = game:GetService("RunService")
		local Remotes      = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
		local ChangeTeam   = Remotes:WaitForChild("ChangeTeam")
		local CollectStar  = Remotes:FindFirstChild("Event") and Remotes.Event:FindFirstChild("CollectStar")
		local ClaimRewards = Remotes:FindFirstChild("Event") and Remotes.Event:FindFirstChild("ClaimRewards")

		------------------------------------------------------------
		-- Teleport Locations
		------------------------------------------------------------
		local TELEPORTS = {
			{ "Auditioners Spawn", Vector3.new(73.59, 100.73, -578.14) },
			{ "Audience Spawn",    Vector3.new(293.08, 99.14, -389.73) },
			{ "Performer Spawn",   Vector3.new(91.90, 106.14, -489.56) },
			{ "Host Spawn",        Vector3.new(119.65, 100.87, -479.43) },
			{ "Judges Spawn",      Vector3.new(163.75, 95.05, -407.85) },
			{ "Stage",             Vector3.new(75.40, 101.89, -407.93) },
			{ "Pianos",            Vector3.new(242.32, 99.11, -874.20) },
			{ "Obstacle Courses",  Vector3.new(372.30, 150.19, -723.54) },
			{ "Morphs",            Vector3.new(-106.13, 108.58, -677.53) },
			{ "Artwork",           Vector3.new(23.67, 115.01, -603.60) },
			{ "Benches",           Vector3.new(-55.54, 101.56, -396.59) },
			{ "Club Tyrann",       Vector3.new(279.43, 110.06, -350.49) },
			{ "Control Room",      Vector3.new(243.64, 133.00, -424.49) },
		}

		------------------------------------------------------------
		-- State
		------------------------------------------------------------
		local antiBarrierActive = false
		local savedPosition     = nil
		local flyAnimTrack      = nil

		------------------------------------------------------------
		-- FLY ANIMATION — replaces T-pose with a swim/fall anim
		------------------------------------------------------------
		local FALL_ANIM_ID = "rbxassetid://180436148" -- standard Roblox fall animation

		local function playFlyAnim()
			pcall(function()
				local hum = hub.getHumanoid()
				if not hum then return end
				local animator = hum:FindFirstChildOfClass("Animator")
				if not animator then return end
				local anim = Instance.new("Animation")
				anim.AnimationId = FALL_ANIM_ID
				flyAnimTrack = animator:LoadAnimation(anim)
				flyAnimTrack.Looped = true
				flyAnimTrack.Priority = Enum.AnimationPriority.Action
				flyAnimTrack:Play()
				anim:Destroy()
			end)
		end

		local function stopFlyAnim()
			if flyAnimTrack then
				pcall(function() flyAnimTrack:Stop() flyAnimTrack:Destroy() end)
				flyAnimTrack = nil
			end
		end

		-- Hook into the universal fly toggle to add/remove animation
		local originalFlyToggle = hub.onToggle.Fly
		hub.onToggle.Fly = function(on)
			if originalFlyToggle then originalFlyToggle(on) end
			if on then
				task.delay(0.1, playFlyAnim)
			else
				stopFlyAnim()
			end
		end

		-- Also re-play on respawn if fly is active
		ebConnect(hub.player.CharacterAdded, function(char)
			char:WaitForChild("Humanoid", 10)
			task.wait(1)
			if featureState.flyEnabled and flyAnimTrack == nil then
				playFlyAnim()
			end
		end)

		------------------------------------------------------------
		-- ANTI STAGE BARRIER
		-- Saves your position. On every respawn (LoadCharacter),
		-- instantly TPs you back. Server may re-respawn but we
		-- keep fighting until it gives up or you move away.
		------------------------------------------------------------
		local barrierTargetCF = nil
		local barrierSaveConn = nil

		local function startAntiBarrier()
			-- Save current position as target
			local root = hub.getRootPart()
			if root then barrierTargetCF = root.CFrame end

			-- Continuously update saved position (so it follows you around)
			barrierSaveConn = RunService.Heartbeat:Connect(function()
				if not antiBarrierActive then return end
				local r = hub.player.Character and hub.player.Character:FindFirstChild("HumanoidRootPart")
				if r then barrierTargetCF = r.CFrame end
			end)
		end

		local function stopAntiBarrier()
			if barrierSaveConn then barrierSaveConn:Disconnect() barrierSaveConn = nil end
			barrierTargetCF = nil
		end

		-- Always-on listener: if anti barrier is active, TP back on respawn
		ebConnect(hub.player.CharacterAdded, function(char)
			if not antiBarrierActive or not barrierTargetCF then return end
			local targetCF = barrierTargetCF
			local root = char:WaitForChild("HumanoidRootPart", 10)
			if not root then return end
			-- Spam TP for 2 seconds to fight the server
			for i = 1, 120 do
				if not antiBarrierActive then break end
				root.CFrame = targetCF
				task.wait()
			end
			hub.notify("Anti Barrier", "Teleported back after respawn", 2)
		end)

		------------------------------------------------------------
		-- BYPASS REP DOORS (client-side CanCollide)
		------------------------------------------------------------
		local doorBypassActive = false
		local doorBypassConn   = nil

		local function startDoorBypass()
			local doors = {
				workspace:FindFirstChild("ClubTyrannDoor"),
				workspace:FindFirstChild("ControlRoomDoor"),
				workspace:FindFirstChild("ThreeWinDoor"),
			}
			doorBypassConn = RunService.Heartbeat:Connect(function()
				for _, door in doors do
					if door and door:IsA("BasePart") then
						door.CanCollide = false
					end
				end
			end)
		end

		local function stopDoorBypass()
			if doorBypassConn then doorBypassConn:Disconnect() doorBypassConn = nil end
		end

		------------------------------------------------------------
		-- REP FARM
		-- Auto-joins performance queue, waits for stage call
		------------------------------------------------------------
		local repFarmActive = false

		------------------------------------------------------------
		-- SWORD MODE
		-- Gets a server-side sword from the arena, then uses
		-- Stepped/RenderStepped CFrame split: server sees you
		-- in arena (keeps sword), you see yourself on stage.
		------------------------------------------------------------
		local swordModeActive = false
		local swordSteppedConn = nil
		local swordRenderConn = nil
		local swordTargetCF = nil -- where you VISUALLY appear (stage)
		local swordCamPart = nil  -- invisible part the camera follows
		local ARENA_CF = CFrame.new(143, 97, -940) -- inside ToolBounds

		local function startSwordMode()
			local root = hub.getRootPart()
			if not root then
				hub.notify("Sword Mode", "No character", 2)
				return false
			end

			-- Save current position as the visual target
			swordTargetCF = root.CFrame

			-- TP to arena to get the sword
			root.CFrame = ARENA_CF
			hub.notify("Sword Mode", "Getting sword from arena...", 2)
			task.wait(1.5)

			local sword = hub.player.Backpack:FindFirstChild("Sword")
				or (hub.player.Character and hub.player.Character:FindFirstChild("Sword"))
			if not sword then
				hub.notify("Sword Mode", "Failed to get sword", 2)
				root.CFrame = swordTargetCF
				return false
			end

			-- Equip sword
			local hum = hub.getHumanoid()
			if hum and sword.Parent == hub.player.Backpack then
				hum:EquipTool(sword)
				task.wait(0.1)
			end

			-- Create invisible camera anchor part
			swordCamPart = Instance.new("Part")
			swordCamPart.Name = "_EBSwordCam"
			swordCamPart.Size = Vector3.new(1, 1, 1)
			swordCamPart.Transparency = 1
			swordCamPart.CanCollide = false
			swordCamPart.Anchored = true
			swordCamPart.CFrame = swordTargetCF
			swordCamPart.Parent = workspace

			-- Set camera to follow our fake anchor
			workspace.CurrentCamera.CameraSubject = swordCamPart

			-- Start the CFrame split:
			-- Stepped (physics, server sees) → arena
			-- RenderStepped (visual, you see) → your target position
			swordSteppedConn = RunService.Stepped:Connect(function()
				if not swordModeActive then return end
				local r = hub.player.Character and hub.player.Character:FindFirstChild("HumanoidRootPart")
				if r then r.CFrame = ARENA_CF end
			end)

			swordRenderConn = RunService.RenderStepped:Connect(function()
				if not swordModeActive then return end
				local r = hub.player.Character and hub.player.Character:FindFirstChild("HumanoidRootPart")
				if r and swordTargetCF then
					r.CFrame = swordTargetCF
				end
				-- Keep camera anchor at visual position
				if swordCamPart and swordTargetCF then
					swordCamPart.CFrame = swordTargetCF
				end
			end)

			hub.notify("Sword Mode", "Sword equipped! Use WASD to move.", 3)
			return true
		end

		local function stopSwordMode()
			if swordSteppedConn then swordSteppedConn:Disconnect() swordSteppedConn = nil end
			if swordRenderConn then swordRenderConn:Disconnect() swordRenderConn = nil end
			-- Restore camera to humanoid
			local hum = hub.getHumanoid()
			if hum then workspace.CurrentCamera.CameraSubject = hum end
			-- Clean up cam part
			if swordCamPart then swordCamPart:Destroy() swordCamPart = nil end
			-- TP to where we visually were
			local root = hub.getRootPart()
			if root and swordTargetCF then root.CFrame = swordTargetCF end
			swordTargetCF = nil
		end

		-- Movement while in sword mode: update swordTargetCF with WASD
		local swordMoveConn = nil
		local swordMoveSpeed = 16

		local function startSwordMovement()
			swordMoveConn = RunService.Heartbeat:Connect(function(dt)
				if not swordModeActive or not swordTargetCF then return end
				local cam = workspace.CurrentCamera
				if not cam then return end
				local dir = Vector3.zero
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
				if dir.Magnitude > 0 then
					dir = dir.Unit
					-- Keep Y level (no flying up/down with camera angle)
					dir = Vector3.new(dir.X, 0, dir.Z).Unit
					local newPos = swordTargetCF.Position + dir * swordMoveSpeed * dt
					swordTargetCF = CFrame.new(newPos) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
				end
			end)
		end

		local function stopSwordMovement()
			if swordMoveConn then swordMoveConn:Disconnect() swordMoveConn = nil end
		end

		------------------------------------------------------------
		-- Build tabs
		------------------------------------------------------------

		-- === PLAYER TAB ===
		local playerPage = hub.addTab("Player", 2)
		hub.section(playerPage, "Movement")
		hub.toggle(playerPage, "Fly", "F")
		hub.slider(playerPage, "Fly Speed", 10, 200, 50)
		hub.toggle(playerPage, "Noclip", "V")
		hub.slider(playerPage, "WalkSpeed", 16, 200, 16)
		hub.slider(playerPage, "JumpPower", 50, 200, 50)
		hub.toggle(playerPage, "Infinite Jump")
		hub.toggle(playerPage, "Low Gravity")
		hub.section(playerPage, "Utility")
		hub.toggle(playerPage, "Anti AFK")
		hub.toggle(playerPage, "Click Teleport")
		hub.toggle(playerPage, "Fullbright")
		hub.toggle(playerPage, "No Fog")
		hub.slider(playerPage, "FOV", 30, 120, 70)
		hub.section(playerPage, "Server")
		hub.button(playerPage, "Teleport to Random Player")
		hub.button(playerPage, "Rejoin")
		hub.button(playerPage, "Server Hop")
		hub.setupPage(playerPage)

		-- === TELEPORT TAB ===
		local tpPage = hub.addTab("Teleports", 3)
		hub.section(tpPage, "Locations")
		for _, loc in TELEPORTS do
			hub.button(tpPage, loc[1])
			hub.onButton[loc[1]] = function()
				local root = hub.getRootPart()
				if not root then return end
				root.CFrame = CFrame.new(loc[2] + Vector3.new(0, 3, 0))
				hub.notify("Teleport", "Teleported to " .. loc[1], 2)
			end
		end
		hub.setupPage(tpPage)

		-- === STAGE TAB ===
		local stagePage = hub.addTab("Stage", 4)
		hub.section(stagePage, "Protection")
		hub.toggle(stagePage, "Anti Stage Barrier")
		hub.paragraph(stagePage, "AntiBarrierInfo", "Saves your position. If the server respawns you for being on stage, auto-TPs you back for 2 seconds straight. Works like spamming the teleport button.")
		hub.section(stagePage, "Sword")
		hub.toggle(stagePage, "Sword Mode")
		hub.paragraph(stagePage, "SwordModeInfo", "Gets a server-side sword from the arena. Your character is visually on stage but the server thinks you're in the arena. WASD to move around. Toggle off to drop sword and return to normal.")
		hub.slider(stagePage, "Sword Move Speed", 8, 50, 16)
		hub.section(stagePage, "Doors")
		hub.toggle(stagePage, "Door Bypass")
		hub.paragraph(stagePage, "DoorBypassInfo", "Bypass rep/win doors (Club Tyrann 50 rep, Control Room 100 rep, 3 Wins door). Client-side only.")
		hub.section(stagePage, "Stats")
		hub.paragraph(stagePage, "PlayerStats", "Loading stats...")
		hub.setupPage(stagePage)

		-- Update stats display
		task.spawn(function()
			task.wait(1)
			local ls = hub.player:FindFirstChild("leaderstats")
			if ls then
				local rep = ls:FindFirstChild("Rep")
				local wins = ls:FindFirstChild("Wins")
				local tickets = ls:FindFirstChild("Tickets")
				local statsFrame = stagePage:FindFirstChild("PlayerStats")
				if statsFrame then
					local body = statsFrame:FindFirstChild("Body")
					if body then
						local function updateStats()
							local r = rep and rep.Value or 0
							local w = wins and wins.Value or 0
							local t = tickets and tickets.Value or 0
							body.Text = '<font color="#7ddc5a">Rep:</font> ' .. r ..
								'   <font color="#ff9955">Wins:</font> ' .. w ..
								'   <font color="#55aaff">Tickets:</font> ' .. t
						end
						updateStats()
						if rep then ebConnect(rep.Changed, updateStats) end
						if wins then ebConnect(wins.Changed, updateStats) end
						if tickets then ebConnect(tickets.Changed, updateStats) end
					end
				end
			end
		end)

		------------------------------------------------------------
		-- Wire callbacks
		------------------------------------------------------------
		hub.onToggle["Anti Stage Barrier"] = function(on)
			antiBarrierActive = on
			hub.notify("Anti Barrier", on and "Position locked — auto-TP on respawn" or "Disabled", 2)
			if on then startAntiBarrier() else stopAntiBarrier() end
		end

		hub.onToggle["Sword Mode"] = function(on)
			swordModeActive = on
			if on then
				task.spawn(function()
					local ok = startSwordMode()
					if ok then
						startSwordMovement()
					else
						swordModeActive = false
					end
				end)
			else
				stopSwordMovement()
				stopSwordMode()
				hub.notify("Sword Mode", "Disabled — sword dropped", 2)
			end
		end

		hub.onSlider["Sword Move Speed"] = function(value)
			swordMoveSpeed = value
		end

		hub.onToggle["Door Bypass"] = function(on)
			doorBypassActive = on
			hub.notify("Door Bypass", on and "All doors passable" or "Doors restored", 2)
			if on then startDoorBypass() else stopDoorBypass() end
		end

		-- WalkSpeed and JumpPower wired to universal system already,
		-- but JumpPower needs its own handler
		hub.onSlider.JumpPower = function(value)
			featureState.jumpPower = value
			local hum = hub.getHumanoid()
			if hum then
				hum.UseJumpPower = true
				hum.JumpPower = value
			end
		end

		hub.onSlider.FOV = function(value)
			featureState.fov = value
			local cam = workspace.CurrentCamera
			if cam then cam.FieldOfView = value end
		end
	end,

	-- Midnight Chasers: Highway Racing (Jacksonville)
	[13822562292] = function(hub)
		------------------------------------------------------------
		-- Services
		------------------------------------------------------------
		local RunService = game:GetService("RunService")
		local UserInputService = game:GetService("UserInputService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		------------------------------------------------------------
		-- Network helper (extract real remote name mapping)
		------------------------------------------------------------
		local Network = require(ReplicatedStorage.Modules.Modules.Network)

		------------------------------------------------------------
		-- Teleport Locations
		------------------------------------------------------------
		local TELEPORTS = {
			{"Dealership",      Vector3.new(4361, 5, 9198)},
			{"Customization",   Vector3.new(4299, 7, 9279)},
			{"Race J1",         Vector3.new(4505, 13, 9281)},
			{"Race J2",         Vector3.new(3750, 13, 8514)},
			{"Race J4",         Vector3.new(-445, 13, -214)},
		}

		------------------------------------------------------------
		-- Car Speed Boost (AssemblyLinearVelocity — max speed target)
		------------------------------------------------------------
		local speedBoostActive = false
		local speedBoostConn = nil
		local targetMaxSpeed = 300   -- studs/s target max
		local boostAccel = 0.15      -- how aggressively we push toward target (0-1 lerp)

		local function getPlayerCar()
			return workspace:FindFirstChild(hub.player.Name .. "'s Car")
		end

		local function startSpeedBoost()
			if speedBoostConn then speedBoostConn:Disconnect() end
			speedBoostConn = RunService.Stepped:Connect(function()
				if not speedBoostActive then return end
				local car = getPlayerCar()
				if not car then return end
				local seat = car:FindFirstChild("DriveSeat")
				if not seat then return end
				local look = seat.CFrame.LookVector
				local vel = seat.AssemblyLinearVelocity
				local forwardSpeed = vel:Dot(look)
				if seat.Throttle == 1 then
					if forwardSpeed < targetMaxSpeed then
						-- Smoothly push toward target, not instant
						local deficit = targetMaxSpeed - forwardSpeed
						local push = math.min(deficit * boostAccel, deficit)
						seat.AssemblyLinearVelocity = vel + look * push
					end
				elseif seat.Throttle == -1 then
					local reverseSpeed = vel:Dot(-look)
					if reverseSpeed < targetMaxSpeed * 0.4 then
						local deficit = (targetMaxSpeed * 0.4) - reverseSpeed
						local push = math.min(deficit * boostAccel, deficit)
						seat.AssemblyLinearVelocity = vel - look * push
					end
				end
			end)
		end

		local function stopSpeedBoost()
			if speedBoostConn then speedBoostConn:Disconnect() speedBoostConn = nil end
		end

		------------------------------------------------------------
		-- Car Noclip
		------------------------------------------------------------
		local carNoclipActive = false
		local carNoclipConn = nil
		local cachedCollisions = {}

		local function startCarNoclip()
			if carNoclipConn then carNoclipConn:Disconnect() end
			carNoclipConn = RunService.Stepped:Connect(function()
				if not carNoclipActive then return end
				local car = getPlayerCar()
				if not car then return end
				for _, part in car:GetDescendants() do
					if part:IsA("BasePart") then
						if cachedCollisions[part] == nil then
							cachedCollisions[part] = part.CanCollide
						end
						part.CanCollide = false
					end
				end
			end)
		end

		local function stopCarNoclip()
			if carNoclipConn then carNoclipConn:Disconnect() carNoclipConn = nil end
			local car = getPlayerCar()
			if car then
				for part, orig in pairs(cachedCollisions) do
					if part.Parent then part.CanCollide = orig end
				end
			end
			cachedCollisions = {}
		end

		------------------------------------------------------------
		-- Car Teleport (teleports the whole car)
		------------------------------------------------------------
		local function teleportCar(pos)
			local car = getPlayerCar()
			if car and car.PrimaryPart then
				car:PivotTo(CFrame.new(pos + Vector3.new(0, 5, 0)))
				hub.notify("Teleport", "Car teleported", 2)
			else
				-- Fallback: TP player on foot
				local root = hub.getRootPart()
				if root then
					root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
					hub.notify("Teleport", "Teleported (on foot)", 2)
				end
			end
		end

		------------------------------------------------------------
		-- Fly animation (same system as Talent Show)
		------------------------------------------------------------
		local FALL_ANIM_ID = "rbxassetid://180436148"
		local flyAnimTrack = nil

		local function playFlyAnim()
			local char = hub.player.Character
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			local anim = Instance.new("Animation")
			anim.AnimationId = FALL_ANIM_ID
			flyAnimTrack = hum:LoadAnimation(anim)
			flyAnimTrack.Priority = Enum.AnimationPriority.Action
			flyAnimTrack.Looped = true
			flyAnimTrack:Play()
		end

		local function stopFlyAnim()
			if flyAnimTrack then
				flyAnimTrack:Stop()
				flyAnimTrack:Destroy()
				flyAnimTrack = nil
			end
		end

		-- Hook into universal fly
		local origFlyStart = hub.onToggle.Fly
		hub.onToggle.Fly = function(on)
			if origFlyStart then origFlyStart(on) end
			if on then playFlyAnim() else stopFlyAnim() end
		end

		------------------------------------------------------------
		-- Build tabs
		------------------------------------------------------------

		-- === PLAYER TAB ===
		local playerPage = hub.addTab("Player", 2)
		hub.section(playerPage, "Movement")
		hub.toggle(playerPage, "Fly", "F")
		hub.slider(playerPage, "Fly Speed", 10, 200, 50)
		hub.toggle(playerPage, "Noclip", "V")
		hub.slider(playerPage, "WalkSpeed", 16, 200, 16)
		hub.slider(playerPage, "JumpPower", 50, 200, 50)
		hub.toggle(playerPage, "Infinite Jump")
		hub.toggle(playerPage, "Low Gravity")
		hub.section(playerPage, "Utility")
		hub.toggle(playerPage, "Anti AFK")
		hub.toggle(playerPage, "Click Teleport")
		hub.toggle(playerPage, "Fullbright")
		hub.toggle(playerPage, "No Fog")
		hub.slider(playerPage, "FOV", 30, 120, 70)
		hub.section(playerPage, "Server")
		hub.button(playerPage, "Teleport to Random Player")
		hub.button(playerPage, "Rejoin")
		hub.button(playerPage, "Server Hop")
		hub.setupPage(playerPage)

		-- === CAR TAB ===
		local carPage = hub.addTab("Car", 3)
		hub.section(carPage, "Speed")
		hub.toggle(carPage, "Speed Boost", "G")
		hub.slider(carPage, "Max Speed", 150, 1500, 300)
		hub.slider(carPage, "Acceleration", 5, 50, 15)
		hub.section(carPage, "Physics")
		hub.toggle(carPage, "Car Noclip", "X")
		hub.toggle(carPage, "No Drag")
		hub.section(carPage, "Utility")
		hub.button(carPage, "Despawn Car")
		hub.button(carPage, "Flip Car")
		hub.setupPage(carPage)

		-- === GARAGE TAB (Quick switch between owned cars) ===
		local garagePage = hub.addTab("Garage", 4)
		hub.section(garagePage, "Owned Vehicles")

		local function refreshGarage()
			local Data = require(ReplicatedStorage.Modules.Shared.Data)
			local pData = Data.Get(hub.player)
			for uuid, vData in pairs(pData.Data.Vehicles) do
				local label = vData.Name
				if not hub.onButton[label] then
					hub.button(garagePage, label)
					hub.onButton[label] = function()
						hub.notify("Garage", "Spawning " .. vData.Name .. "...", 2)
						task.spawn(function()
							pcall(function() Network.FireServer("DespawnCar") end)
							task.wait(1)
							Network.FireServer("SpawnCar", uuid, false)
							hub.notify("Garage", "Spawned " .. vData.Name, 3)
						end)
					end
				end
			end
		end
		refreshGarage()

		hub.setupPage(garagePage)

		-- === TELEPORT TAB ===
		local tpPage = hub.addTab("Teleports", 5)
		hub.section(tpPage, "Locations")
		for _, loc in TELEPORTS do
			hub.button(tpPage, loc[1])
			hub.onButton[loc[1]] = function()
				teleportCar(loc[2])
			end
		end
		hub.setupPage(tpPage)

		------------------------------------------------------------
		-- Wire up car features
		------------------------------------------------------------
		hub.onToggle["Speed Boost"] = function(on)
			speedBoostActive = on
			if on then
				startSpeedBoost()
				hub.notify("Speed Boost", "ON — Max: " .. targetMaxSpeed .. " studs/s", 2)
			else
				stopSpeedBoost()
				hub.notify("Speed Boost", "OFF", 2)
			end
		end

		hub.onSlider["Max Speed"] = function(value)
			targetMaxSpeed = value
			if speedBoostActive then
				hub.notify("Speed Boost", "Max: " .. value .. " studs/s", 1)
			end
		end

		hub.onSlider["Acceleration"] = function(value)
			boostAccel = value / 100 -- slider 5-50 maps to 0.05-0.50
			if speedBoostActive then
				hub.notify("Speed Boost", "Accel: " .. value .. "%", 1)
			end
		end

		hub.onToggle["Car Noclip"] = function(on)
			carNoclipActive = on
			if on then
				startCarNoclip()
				hub.notify("Car Noclip", "ON", 2)
			else
				stopCarNoclip()
				hub.notify("Car Noclip", "OFF", 2)
			end
		end

		-- No Drag: disable aerodynamic drag script
		local noDragActive = false
		local origAeroEnabled = true
		hub.onToggle["No Drag"] = function(on)
			noDragActive = on
			local car = getPlayerCar()
			if not car then hub.notify("No Drag", "Spawn a car first", 2) return end
			local aero = car:FindFirstChild("A-Chassis Tune")
				and car["A-Chassis Tune"]:FindFirstChild("A-Chassis Interface")
				and car["A-Chassis Tune"]["A-Chassis Interface"]:FindFirstChild("Aerodynamics")
			if aero then
				if on then
					origAeroEnabled = aero.Enabled
					aero.Enabled = false
					-- Zero out current drag forces
					local body = car:FindFirstChild("Body")
					if body then
						for _, name in {"Drag", "DownforceF", "DownforceR"} do
							local f = body:FindFirstChild(name)
							if f then
								local t = f:FindFirstChild("T")
								if t and t:IsA("BodyThrust") then t.Force = Vector3.zero end
							end
						end
					end
					hub.notify("No Drag", "ON — drag & downforce removed", 2)
				else
					aero.Enabled = origAeroEnabled
					hub.notify("No Drag", "OFF", 2)
				end
			else
				hub.notify("No Drag", "No aero script found", 2)
			end
		end

		hub.onButton["Despawn Car"] = function()
			Network.FireServer("DespawnCar")
			hub.notify("Car", "Despawned", 2)
		end

		hub.onButton["Flip Car"] = function()
			local car = getPlayerCar()
			if not car or not car.PrimaryPart then
				hub.notify("Car", "No car found", 2)
				return
			end
			local cf = car.PrimaryPart.CFrame
			local pos = cf.Position + Vector3.new(0, 5, 0)
			local look = cf.LookVector
			car:PivotTo(CFrame.lookAt(pos, pos + look))
			hub.notify("Car", "Flipped upright", 2)
		end
	end,

}

-- Midnight Chasers: alias all map PlaceIds to the same config
GAME_CONFIGS[139048751758942] = GAME_CONFIGS[13822562292] -- Boneville Salt Flats

-- Run the config for this game, if one exists
local gameConfig = GAME_CONFIGS[game.PlaceId]
if gameConfig then
	gameSupported = true
	gameConfig(hub)

	-- Update the home page game info to show supported
	local infoFrame = homePage:FindFirstChild("GameInfo")
	if infoFrame then
		local body = infoFrame:FindFirstChild("Body")
		if body and detectedGame then
			body.Text = '<font color="#7ddc5a">Detected:</font> ' .. detectedGame .. '  <font color="#7ddc5a">(supported)</font>'
		end
	end
else
	-- Unsupported game
	local infoFrame = homePage:FindFirstChild("GameInfo")
	if infoFrame then
		local body = infoFrame:FindFirstChild("Body")
		if body then
			body.Text = '<font color="#ff5555">Unsupported:</font> ' .. (detectedGame or ("PlaceId " .. game.PlaceId)) .. '  <font color="#ff5555">(no config)</font>'
		end
	end
	notify("EB Hub", "This game is not supported.", 5, true)
end

------------------------------------------------------------------
-- Loader
------------------------------------------------------------------
local loader = new("CanvasGroup", {
	Parent = gui, Name = "Loader", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(300, 160), BackgroundColor3 = C.bg,
}, {
	corner(10), stroke(),
	new("TextLabel", { Name = "Title", Text = "EB", Font = Enum.Font.Garamond, TextSize = 46, Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 44) }),
	new("TextLabel", { Name = "Subtitle", Text = "H U B", TextSize = 10, TextColor3 = C.sub, Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 14) }),
	new("Frame", { Name = "Spinner", BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 102), Size = UDim2.fromOffset(14, 14) }, {
		corner(),
		new("UIStroke", { Color = C.accent, Thickness = 2 }, {
			new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.9), NumberSequenceKeypoint.new(1, 1) }) }),
		}),
	}),
	new("TextLabel", { Name = "Status", Text = "Initializing...", TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(42, 100), Size = UDim2.new(1, -110, 0, 18) }),
	new("TextLabel", { Name = "Percent", Text = "0%", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 100), Size = UDim2.fromOffset(60, 18) }),
	new("Frame", { Name = "Bar", BackgroundColor3 = C.track, Position = UDim2.fromOffset(20, 128), Size = UDim2.new(1, -40, 0, 4) }, {
		corner(),
		new("Frame", { Name = "Fill", BackgroundColor3 = C.accent, Size = UDim2.fromScale(0, 1) }, { corner() }),
	}),
})
local loaderScale = new("UIScale", { Parent = loader, Scale = 1 })

local function runLoader()
	loader.Visible = true
	loader.GroupTransparency = 1
	loaderScale.Scale = 0.9 * baseScale
	tween(loader, 0.4, { GroupTransparency = 0 })
	tween(loaderScale, 0.5, { Scale = baseScale }, Enum.EasingStyle.Back)

	local spinner = loader.Spinner
	local spinConn = RunService.RenderStepped:Connect(function(dt)
		spinner.Rotation = (spinner.Rotation + dt * 360) % 360
	end)

	local title = loader.Title
	task.spawn(function()
		while loader.Visible do
			tween(title, 0.8, { TextColor3 = C.accent }, Enum.EasingStyle.Sine).Completed:Wait()
			tween(title, 0.8, { TextColor3 = C.text }, Enum.EasingStyle.Sine).Completed:Wait()
		end
	end)

	local status = loader.Status
	local percent = loader.Percent
	local fill = loader.Bar.Fill

	local steps = {
		{ "Initializing...", 0.12 },
		{ "Checking game...", 0.3 },
		{ "Loading modules...", 0.55 },
		{ "Building interface...", 0.82 },
		{ "Finishing up...", 0.95 },
		{ "Ready!", 1 },
	}

	local shown = 0
	for _, step in steps do
		status.Text = step[1]
		status.TextTransparency = 1
		tween(status, 0.2, { TextTransparency = 0 })
		local duration = 0.35 + math.random() * 0.4

		if step[1] == "Checking game..." and detectedGame then
			task.delay(duration * 0.5, function()
				status.Text = "Found: " .. detectedGame
				status.TextColor3 = C.accent
				task.delay(0.4, function()
					status.TextColor3 = C.sub
				end)
			end)
			duration += 0.3
		end

		tween(fill, duration, { Size = UDim2.fromScale(step[2], 1) }, Enum.EasingStyle.Quad)
		local from, to = shown, math.floor(step[2] * 100)
		local t0 = os.clock()
		while os.clock() - t0 < duration do
			local a = (os.clock() - t0) / duration
			percent.Text = math.floor(from + (to - from) * a) .. "%"
			task.wait()
		end
		shown = to
		percent.Text = to .. "%"
	end
	status.TextColor3 = C.accent
	task.wait(0.4)

	tween(loader, 0.35, { GroupTransparency = 1 })
	tween(loaderScale, 0.35, { Scale = 1.08 * baseScale }).Completed:Wait()
	loader.Visible = false
	spinConn:Disconnect()

	loaded = true
	openButton.Visible = true
	openButton.Position = UDim2.fromOffset(-60, 70)
	tween(openButton, 0.5, { Position = UDim2.fromOffset(14, 70) }, Enum.EasingStyle.Back)
	setOpen(true)
	selectTab("Home")
	notify("EB Hub loaded", "Welcome, " .. player.DisplayName .. "!", 4)
	task.wait(0.4)

	if detectedGame then
		if gameSupported then
			notify("Game Detected", detectedGame .. " (supported)", 4)
		else
			notify("Game Detected", detectedGame, 4)
		end
	else
		notify("Unknown Game", "PlaceId: " .. tostring(game.PlaceId), 3)
	end

	task.wait(0.4)
	notify("Tip", "Press " .. toggleKey.Name .. " to hide / show", 4)
end

runLoader()
