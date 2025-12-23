-- modules/hud/ui_pages.lua
-- UI Pages System - All tab pages for the HUD

local UIPagesModule = {}

-- Dependencies (injected by main HUD)
local Settings, Data, Constants
local LightingModule, AnimationsModule, FlightModule, CameraModule, PlayerModule
local UIBuilder, notify, toAssetIdString
local UserInputService, TeleportService, HttpService, GuiService, LocalPlayer
local pagesHolder, tabsBar

-- State references (will be injected)
local flightToggleKey
local flySpeed, minFlySpeed, maxFlySpeed
local playerSpeed
local MICUP_PLACE_IDS, DISCORD_LINK

-- Internal UI state
local pages, tabButtons, activePageName = {}, {}, ""

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------
function UIPagesModule.init(deps)
	-- Inject module dependencies
	Settings = deps.Settings
	Data = deps.Data
	Constants = deps.Constants
	LightingModule = deps.LightingModule
	AnimationsModule = deps.AnimationsModule
	FlightModule = deps.FlightModule
	CameraModule = deps.CameraModule
	PlayerModule = deps.PlayerModule
	UIBuilder = deps.UIBuilder
	notify = deps.notify
	toAssetIdString = deps.toAssetIdString

	-- Inject services
	UserInputService = deps.UserInputService
	TeleportService = deps.TeleportService
	HttpService = deps.HttpService
	GuiService = deps.GuiService
	LocalPlayer = deps.LocalPlayer

	-- Inject UI containers
	pagesHolder = deps.pagesHolder
	tabsBar = deps.tabsBar

	-- Inject state references
	flightToggleKey = deps.flightToggleKey
	MICUP_PLACE_IDS = deps.MICUP_PLACE_IDS
	DISCORD_LINK = deps.DISCORD_LINK
end

-- Getters for dynamic state (since these change)
function UIPagesModule.getFlySpeed() return flySpeed end
function UIPagesModule.setFlySpeed(speed) flySpeed = speed end
function UIPagesModule.getMinFlySpeed() return minFlySpeed end
function UIPagesModule.setMinFlySpeed(speed) minFlySpeed = speed end
function UIPagesModule.getMaxFlySpeed() return maxFlySpeed end
function UIPagesModule.setMaxFlySpeed(speed) maxFlySpeed = speed end
function UIPagesModule.getPlayerSpeed() return playerSpeed end
function UIPagesModule.setPlayerSpeed(speed) playerSpeed = speed end

--------------------------------------------------------------------
-- HELPER: CREATE PAGE
--------------------------------------------------------------------
local function makePage(name)
	local p = Instance.new("Frame")
	p.Name = name
	p.BackgroundTransparency = 1
	p.Size = UDim2.new(1, 0, 1, 0)
	p.Visible = false
	p.Parent = pagesHolder

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 4
	scroll.Parent = p

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scroll

	pages[name] = {Page = p, Scroll = scroll}
	return p, scroll
end

--------------------------------------------------------------------
-- TAB SWITCHING
--------------------------------------------------------------------
local function switchPage(pageName)
	if not pages or not pages[pageName] then return end
	if pageName == activePageName then return end

	local newPg = pages[pageName]
	local oldPg = pages[activePageName]
	if not newPg then return end

	for n, btn in pairs(tabButtons) do
		UIBuilder.setTabButtonActive(btn, n == pageName)
	end

	local newFrame = newPg.Page
	local oldFrame = oldPg and oldPg.Page or nil

	newFrame.Visible = true
	newFrame.Position = UDim2.new(0, 26, 0, 0)
	UIBuilder.tween(newFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})

	if oldFrame then
		local twn = UIBuilder.tween(oldFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0, -26, 0, 0)})
		twn.Completed:Connect(function()
			oldFrame.Visible = false
			oldFrame.Position = UDim2.new(0, 0, 0, 0)
		end)
	end

	activePageName = pageName
end

local function addTabButton(pageName, order, w)
	local b = UIBuilder.makeButton(tabsBar, pageName)
	b.LayoutOrder = order or 1
	b.Size = UDim2.new(0, w or 120, 0, 38)
	tabButtons[pageName] = b
	b.MouseButton1Click:Connect(function() switchPage(pageName) end)
end

--------------------------------------------------------------------
-- BUILD ALL PAGES
--------------------------------------------------------------------
function UIPagesModule.buildAllPages()
	-- Reset state
	pages, tabButtons, activePageName = {}, {}, ""

	-- Create all pages
	local infoPage, infoScroll = makePage("Info")
	local controlsPage, controlsScroll = makePage("Controls")
	local flyPage, flyScroll = makePage("Fly")
	local animPage, animScroll = makePage("Anim Packs")
	local playerPage, playerScroll = makePage("Player")
	local cameraPage, cameraScroll = makePage("Camera")
	local lightingPage, lightingScroll = makePage("Lighting")
	local serverPage, serverScroll = makePage("Server")
	local clientPage, clientScroll = makePage("Client")
	local micupPage, micupScroll = nil, nil
	do
		local placeIdStr = tostring(game.PlaceId)
		if MICUP_PLACE_IDS[placeIdStr] then
			micupPage, micupScroll = makePage("Mic up")
		end
	end

	-- Shorthand references
	local makeText = UIBuilder.makeText
	local makeButton = UIBuilder.makeButton
	local makeInput = UIBuilder.makeInput
	local makeCorner = UIBuilder.makeCorner
	local tween = UIBuilder.tween
	local setTabButtonActive = UIBuilder.setTabButtonActive
	local clamp01 = UIBuilder.clamp01

	-- INFO TAB
	do
		local header = makeText(infoScroll, "The Sins Of Scripting HUD", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local msg = makeText(infoScroll, "Welcome.\n\nDiscord:\nPress to copy, or it will open if copy isn't supported.\n", 14, false)
		msg.Size = UDim2.new(1, 0, 0, 90)

		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 44)
		row.Parent = infoScroll

		local rowLay = Instance.new("UIListLayout")
		rowLay.FillDirection = Enum.FillDirection.Horizontal
		rowLay.Padding = UDim.new(0, 10)
		rowLay.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLay.Parent = row

		local discordBtn = makeButton(row, "(SOS Server)")
		discordBtn.Size = UDim2.new(0, 180, 0, 36)

		local linkBox = makeInput(row, "Press to copy")
		linkBox.Size = UDim2.new(1, -200, 0, 36)
		linkBox.Text = DISCORD_LINK

		discordBtn.MouseButton1Click:Connect(function()
			local copied = false
			pcall(function()
				if typeof(setclipboard) == "function" then
					setclipboard(DISCORD_LINK)
					copied = true
				end
			end)

			if copied then
				notify("SOS Server", "Copied to clipboard.", 2)
			else
				pcall(function() linkBox:CaptureFocus() end)
				pcall(function() GuiService:OpenBrowserWindow(DISCORD_LINK) end)
				notify("SOS Server", "Press to copy (use the box).", 3)
			end
		end)
	end

	-- CONTROLS TAB
	do
		local header = makeText(controlsScroll, "Controls", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local info = makeText(controlsScroll, "PC:\n- Fly Toggle: " .. flightToggleKey.Name .. "\n- Move: WASD + Q/E\n\nMobile:\n- Use the Fly button (bottom-right)\n- Use the top arrow to open/close the menu", 14, false)
		info.Size = UDim2.new(1, 0, 0, 120)
	end

	-- FLY TAB
	do
		local header = makeText(flyScroll, "Flight Emotes", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local keyLegend = makeText(flyScroll, "A = Apply    R = Reset", 13, true)
		keyLegend.Size = UDim2.new(1, 0, 0, 18)
		keyLegend.TextColor3 = Color3.fromRGB(220, 220, 220)

		local warning = makeText(flyScroll, "Animation IDs for flight must be a Published Marketplace/Catalog EMOTE assetid from the Creator Store.\n(If you paste random IDs, it can fail.)\n(copy and paste id in the link of the creator store version or the chosen Emote (Wont Work With Normal Marketplace ID))", 13, false)
		warning.TextColor3 = Color3.fromRGB(220, 220, 220)
		warning.Size = UDim2.new(1, 0, 0, 92)

		local function makeIdRow(labelText, getFn, setFn, resetFn)
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 44)
			row.Parent = flyScroll

			local l = makeText(row, labelText, 14, true)
			l.Size = UDim2.new(0, 120, 1, 0)

			local box = makeInput(row, "rbxassetid://... or number")
			box.Size = UDim2.new(1, -240, 0, 36)
			box.Position = UDim2.new(0, 130, 0, 4)
			box.Text = getFn()

			local applyBtn = makeButton(row, "A")
			applyBtn.Size = UDim2.new(0, 70, 0, 36)
			applyBtn.AnchorPoint = Vector2.new(1, 0)
			applyBtn.Position = UDim2.new(1, -90, 0, 4)

			local resetBtn = makeButton(row, "R")
			resetBtn.Size = UDim2.new(0, 70, 0, 36)
			resetBtn.AnchorPoint = Vector2.new(1, 0)
			resetBtn.Position = UDim2.new(1, -10, 0, 4)

			applyBtn.MouseButton1Click:Connect(function()
				local parsed = toAssetIdString(box.Text)
				if not parsed then
					notify("Flight Emotes", "Invalid ID. Use rbxassetid://123 or just 123", 3)
					return
				end
				setFn(parsed)
				AnimationsModule.loadFlightTracks()
				if FlightModule.isFlying() then
					AnimationsModule.stopFlightAnims()
					AnimationsModule.playFloat()
				end
				Settings.scheduleSave()
				notify("Flight Emotes", "Applied.", 2)
			end)

			resetBtn.MouseButton1Click:Connect(function()
				resetFn()
				box.Text = getFn()
				AnimationsModule.loadFlightTracks()
				if FlightModule.isFlying() then
					AnimationsModule.stopFlightAnims()
					AnimationsModule.playFloat()
				end
				Settings.scheduleSave()
				notify("Flight Emotes", "Reset to default.", 2)
			end)
		end

		makeIdRow("FLOAT_ID:",
			function() return AnimationsModule.getFloatId() end,
			function(v) AnimationsModule.setFloatId(v) end,
			function() AnimationsModule.resetFloatId() end)

		makeIdRow("FLY_ID:",
			function() return AnimationsModule.getFlyId() end,
			function(v) AnimationsModule.setFlyId(v) end,
			function() AnimationsModule.resetFlyId() end)

		-- Fly Speed Slider
		local speedHeader = makeText(flyScroll, "Fly Speed", 16, true)
		speedHeader.Size = UDim2.new(1, 0, 0, 22)

		local speedRow = Instance.new("Frame")
		speedRow.BackgroundTransparency = 1
		speedRow.Size = UDim2.new(1, 0, 0, 60)
		speedRow.Parent = flyScroll

		local speedLabel = makeText(speedRow, "Speed: " .. tostring(flySpeed), 14, true)
		speedLabel.Size = UDim2.new(1, 0, 0, 18)

		local sliderBg = Instance.new("Frame")
		sliderBg.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
		sliderBg.BackgroundTransparency = 0.15
		sliderBg.BorderSizePixel = 0
		sliderBg.Position = UDim2.new(0, 0, 0, 26)
		sliderBg.Size = UDim2.new(1, 0, 0, 10)
		sliderBg.Parent = speedRow
		makeCorner(sliderBg, 999)

		local sliderFill = Instance.new("Frame")
		sliderFill.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		sliderFill.BorderSizePixel = 0
		sliderFill.Size = UDim2.new(0, 0, 1, 0)
		sliderFill.Parent = sliderBg
		makeCorner(sliderFill, 999)

		local knob = Instance.new("Frame")
		knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
		knob.BorderSizePixel = 0
		knob.Size = UDim2.new(0, 14, 0, 14)
		knob.Parent = sliderBg
		makeCorner(knob, 999)

		local function setSpeedFromAlpha(a)
			a = clamp01(a)
			local s = minFlySpeed + (maxFlySpeed - minFlySpeed) * a
			flySpeed = math.floor(s + 0.5)
			UIPagesModule.setFlySpeed(flySpeed)
			FlightModule.setFlySpeed(flySpeed)
			speedLabel.Text = "Speed: " .. tostring(flySpeed)
			sliderFill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, -7, 0.5, -7)
			Settings.scheduleSave()
		end

		setSpeedFromAlpha((flySpeed - minFlySpeed) / (maxFlySpeed - minFlySpeed))

		local dragging = false
		sliderBg.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		sliderBg.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if not dragging then return end
			if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
			local a = (i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
			setSpeedFromAlpha(a)
		end)
	end

	-- ANIM PACKS TAB
	do
		local header = makeText(animScroll, "Anim Packs", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local help = makeText(animScroll, "Pick a STATE, then pick a pack name to change only that state.", 13, false)
		help.Size = UDim2.new(1, 0, 0, 34)
		help.TextColor3 = Color3.fromRGB(210, 210, 210)

		local animStateBar = Instance.new("ScrollingFrame")
		animStateBar.BackgroundTransparency = 1
		animStateBar.BorderSizePixel = 0
		animStateBar.Size = UDim2.new(1, 0, 0, 44)
		animStateBar.CanvasSize = UDim2.new(0, 0, 0, 0)
		animStateBar.AutomaticCanvasSize = Enum.AutomaticSize.X
		animStateBar.ScrollingDirection = Enum.ScrollingDirection.X
		animStateBar.ScrollBarThickness = 2
		animStateBar.Parent = animScroll

		local stLayout = Instance.new("UIListLayout")
		stLayout.FillDirection = Enum.FillDirection.Horizontal
		stLayout.SortOrder = Enum.SortOrder.LayoutOrder
		stLayout.Padding = UDim.new(0, 12)
		stLayout.Parent = animStateBar

		local animCategoryBar = Instance.new("ScrollingFrame")
		animCategoryBar.BackgroundTransparency = 1
		animCategoryBar.BorderSizePixel = 0
		animCategoryBar.Size = UDim2.new(1, 0, 0, 44)
		animCategoryBar.CanvasSize = UDim2.new(0, 0, 0, 0)
		animCategoryBar.AutomaticCanvasSize = Enum.AutomaticSize.X
		animCategoryBar.ScrollingDirection = Enum.ScrollingDirection.X
		animCategoryBar.ScrollBarThickness = 2
		animCategoryBar.Parent = animScroll

		local catLayout = Instance.new("UIListLayout")
		catLayout.FillDirection = Enum.FillDirection.Horizontal
		catLayout.SortOrder = Enum.SortOrder.LayoutOrder
		catLayout.Padding = UDim.new(0, 12)
		catLayout.Parent = animCategoryBar

		local animListScroll = Instance.new("ScrollingFrame")
		animListScroll.BackgroundTransparency = 1
		animListScroll.BorderSizePixel = 0
		animListScroll.Size = UDim2.new(1, 0, 0, 250)
		animListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		animListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		animListScroll.ScrollBarThickness = 4
		animListScroll.Parent = animScroll

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 6)
		pad.PaddingBottom = UDim.new(0, 6)
		pad.PaddingLeft = UDim.new(0, 2)
		pad.PaddingRight = UDim.new(0, 2)
		pad.Parent = animListScroll

		local animListContainer = Instance.new("Frame")
		animListContainer.BackgroundTransparency = 1
		animListContainer.Size = UDim2.new(1, 0, 0, 0)
		animListContainer.Parent = animListScroll

		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 10)
		listLayout.Parent = animListContainer

		local function animateListPop()
			animListContainer.Position = UDim2.new(0, 26, 0, 0)
			tween(animListContainer, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
		end

		local stateButtons = {}
		local categoryButtons = {}

		local function rebuildPackList()
			for _, ch in ipairs(animListContainer:GetChildren()) do
				if ch:IsA("TextButton") or ch:IsA("TextLabel") or ch:IsA("Frame") then
					ch:Destroy()
				end
			end

			local lastChosenState = AnimationsModule.getLastChosenState()
			local lastChosenCategory = AnimationsModule.getLastChosenCategory()

			if lastChosenCategory == "Custom" then
				local names = Data.listCustomNamesForState(lastChosenState)
				if #names == 0 then
					local t = makeText(animListContainer, "No Custom animations for: " .. lastChosenState, 14, true)
					t.Size = UDim2.new(1, 0, 0, 28)
					animateListPop()
					return
				end

				for _, nm in ipairs(names) do
					local b = makeButton(animListContainer, nm)
					b.Size = UDim2.new(1, 0, 0, 36)
					b.MouseButton1Click:Connect(function()
						local id = Data.getCustomIdForState(nm, lastChosenState)
						if not id then return end
						local assetStr = "rbxassetid://" .. tostring(id)
						local ok = AnimationsModule.applyStateOverrideToAnimate(lastChosenState, assetStr)
						if ok then
							notify("Anim Packs", "Set " .. lastChosenState .. " to " .. nm, 2)
							Settings.scheduleSave()
						else
							notify("Anim Packs", "Failed to apply. (Animate script missing?)", 3)
						end
					end)
				end
				animateListPop()
				return
			end

			local names = Data.listPackNamesForCategory(lastChosenCategory)
			for _, packName in ipairs(names) do
				local b = makeButton(animListContainer, packName)
				b.Size = UDim2.new(1, 0, 0, 36)
				b.MouseButton1Click:Connect(function()
					local id = Data.getPackValueForState(packName, lastChosenState)
					if not id then
						notify("Anim Packs", "That pack has no ID for: " .. lastChosenState, 2)
						return
					end
					local assetStr = "rbxassetid://" .. tostring(id)
					local ok = AnimationsModule.applyStateOverrideToAnimate(lastChosenState, assetStr)
					if ok then
						notify("Anim Packs", "Set " .. lastChosenState .. " to " .. packName, 2)
						Settings.scheduleSave()
					else
						notify("Anim Packs", "Failed to apply. (Animate script missing?)", 3)
					end
				end)
			end
			animateListPop()
		end

		local function setState(stateName)
			AnimationsModule.setLastChosenState(stateName)
			for n, btn in pairs(stateButtons) do
				setTabButtonActive(btn, n == stateName)
			end
			rebuildPackList()
			Settings.scheduleSave()
		end

		local function setCategory(catName)
			AnimationsModule.setLastChosenCategory(catName)
			for n, btn in pairs(categoryButtons) do
				setTabButtonActive(btn, n == catName)
			end
			rebuildPackList()
			Settings.scheduleSave()
		end

		local states = {"Idle", "Walk", "Run", "Jump", "Climb", "Fall", "Swim"}
		for _, sName in ipairs(states) do
			local b = makeButton(animStateBar, sName)
			b.Size = UDim2.new(0, 110, 0, 36)
			stateButtons[sName] = b
			b.MouseButton1Click:Connect(function() setState(sName) end)
		end

		local cats = {"Roblox Anims", "Unreleased", "Custom"}
		for _, cName in ipairs(cats) do
			local b = makeButton(animCategoryBar, cName)
			b.Size = UDim2.new(0, (cName == "Roblox Anims" and 160 or 130), 0, 36)
			categoryButtons[cName] = b
			b.MouseButton1Click:Connect(function() setCategory(cName) end)
		end

		setCategory(AnimationsModule.getLastChosenCategory())
		setState(AnimationsModule.getLastChosenState())
	end

	-- PLAYER TAB
	do
		local header = makeText(playerScroll, "Player", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local info = makeText(playerScroll, "WalkSpeed changer. Reset uses the game's default speed for you.", 13, false)
		info.Size = UDim2.new(1, 0, 0, 34)
		info.TextColor3 = Color3.fromRGB(210, 210, 210)

		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 76)
		row.Parent = playerScroll

		playerSpeed = PlayerModule.getPlayerSpeed()
		local speedLabel = makeText(row, "Speed: " .. tostring(playerSpeed or 16), 14, true)
		speedLabel.Size = UDim2.new(1, 0, 0, 18)

		local sliderBg = Instance.new("Frame")
		sliderBg.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
		sliderBg.BackgroundTransparency = 0.15
		sliderBg.BorderSizePixel = 0
		sliderBg.Position = UDim2.new(0, 0, 0, 26)
		sliderBg.Size = UDim2.new(1, 0, 0, 10)
		sliderBg.Parent = row
		makeCorner(sliderBg, 999)

		local sliderFill = Instance.new("Frame")
		sliderFill.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		sliderFill.BorderSizePixel = 0
		sliderFill.Size = UDim2.new(0, 0, 1, 0)
		sliderFill.Parent = sliderBg
		makeCorner(sliderFill, 999)

		local knob = Instance.new("Frame")
		knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
		knob.BorderSizePixel = 0
		knob.Size = UDim2.new(0, 14, 0, 14)
		knob.Parent = sliderBg
		makeCorner(knob, 999)

		local resetBtn = makeButton(row, "Reset")
		resetBtn.Size = UDim2.new(0, 100, 0, 34)
		resetBtn.AnchorPoint = Vector2.new(1, 0)
		resetBtn.Position = UDim2.new(1, 0, 0, 42)

		local function setSpeedFromAlpha(a)
			a = clamp01(a)
			local s = 2 + (500 - 2) * a
			playerSpeed = math.floor(s + 0.5)
			PlayerModule.setPlayerSpeed(playerSpeed)
			speedLabel.Text = "Speed: " .. tostring(playerSpeed)
			sliderFill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, -7, 0.5, -7)
			PlayerModule.applyPlayerSpeed()
			Settings.scheduleSave()
		end

		local function alphaFromSpeed(s)
			s = math.clamp(s, 2, 500)
			return (s - 2) / (500 - 2)
		end

		setSpeedFromAlpha(alphaFromSpeed(playerSpeed or 16))

		local dragging = false
		sliderBg.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		sliderBg.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if not dragging then return end
			if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
			local a = (i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
			setSpeedFromAlpha(a)
		end)

		resetBtn.MouseButton1Click:Connect(function()
			PlayerModule.resetPlayerSpeedToDefault()
			playerSpeed = PlayerModule.getPlayerSpeed()
			setSpeedFromAlpha(alphaFromSpeed(playerSpeed or 16))
			notify("Player", "Speed reset.", 2)
		end)
	end

	-- CAMERA TAB
	do
		local header = makeText(cameraScroll, "Camera", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local sub = makeText(cameraScroll, "Choose camera subject, offset, max zoom, and FOV. Each has a reset.", 13, false)
		sub.Size = UDim2.new(1, 0, 0, 34)
		sub.TextColor3 = Color3.fromRGB(210, 210, 210)

		local subjectHeader = makeText(cameraScroll, "Attach To", 15, true)
		subjectHeader.Size = UDim2.new(1, 0, 0, 20)

		local subjectBar = Instance.new("ScrollingFrame")
		subjectBar.BackgroundTransparency = 1
		subjectBar.BorderSizePixel = 0
		subjectBar.Size = UDim2.new(1, 0, 0, 44)
		subjectBar.CanvasSize = UDim2.new(0, 0, 0, 0)
		subjectBar.AutomaticCanvasSize = Enum.AutomaticSize.X
		subjectBar.ScrollingDirection = Enum.ScrollingDirection.X
		subjectBar.ScrollBarThickness = 2
		subjectBar.Parent = cameraScroll

		local subjLayout = Instance.new("UIListLayout")
		subjLayout.FillDirection = Enum.FillDirection.Horizontal
		subjLayout.SortOrder = Enum.SortOrder.LayoutOrder
		subjLayout.Padding = UDim.new(0, 10)
		subjLayout.Parent = subjectBar

		local subjButtons = {}
		local modes = {"Humanoid", "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}

		local function setSubjectMode(m)
			CameraModule.setCamSubjectMode(m)
			for k, b in pairs(subjButtons) do
				setTabButtonActive(b, k == m)
			end
			CameraModule.applyCameraSettings()
			Settings.scheduleSave()
		end

		for _, m in ipairs(modes) do
			local b = makeButton(subjectBar, m)
			b.Size = UDim2.new(0, 170, 0, 36)
			subjButtons[m] = b
			b.MouseButton1Click:Connect(function() setSubjectMode(m) end)
		end

		local offHeader = makeText(cameraScroll, "Offset", 15, true)
		offHeader.Size = UDim2.new(1, 0, 0, 20)

		local function makeAxisSlider(axisName, getValFn, setValFn, minV, maxV)
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 66)
			row.Parent = cameraScroll

			local label = makeText(row, axisName .. ": " .. string.format("%.2f", getValFn()), 14, true)
			label.Size = UDim2.new(1, -120, 0, 18)

			local reset = makeButton(row, "Reset")
			reset.Size = UDim2.new(0, 100, 0, 30)
			reset.AnchorPoint = Vector2.new(1, 0)
			reset.Position = UDim2.new(1, 0, 0, 0)

			local sliderBg = Instance.new("Frame")
			sliderBg.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
			sliderBg.BackgroundTransparency = 0.15
			sliderBg.BorderSizePixel = 0
			sliderBg.Position = UDim2.new(0, 0, 0, 26)
			sliderBg.Size = UDim2.new(1, 0, 0, 10)
			sliderBg.Parent = row
			makeCorner(sliderBg, 999)

			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
			fill.BorderSizePixel = 0
			fill.Size = UDim2.new(0, 0, 1, 0)
			fill.Parent = sliderBg
			makeCorner(fill, 999)

			local knob = Instance.new("Frame")
			knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
			knob.BorderSizePixel = 0
			knob.Size = UDim2.new(0, 14, 0, 14)
			knob.Parent = sliderBg
			makeCorner(knob, 999)

			local function setFromAlpha(a)
				a = clamp01(a)
				local v = minV + (maxV - minV) * a
				setValFn(v)
				label.Text = axisName .. ": " .. string.format("%.2f", getValFn())
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, -7, 0.5, -7)
				CameraModule.applyCameraSettings()
				Settings.scheduleSave()
			end

			local function alphaFromValue(v)
				v = math.clamp(v, minV, maxV)
				return (v - minV) / (maxV - minV)
			end

			setFromAlpha(alphaFromValue(getValFn()))

			local dragging = false
			sliderBg.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = true
				end
			end)
			sliderBg.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			UserInputService.InputChanged:Connect(function(i)
				if not dragging then return end
				if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
				local a = (i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
				setFromAlpha(a)
			end)

			reset.MouseButton1Click:Connect(function()
				local camOffset = CameraModule.getCamOffset()
				if axisName == "X" then
					CameraModule.setCamOffset(Vector3.new(0, camOffset.Y, camOffset.Z))
				elseif axisName == "Y" then
					CameraModule.setCamOffset(Vector3.new(camOffset.X, 0, camOffset.Z))
				elseif axisName == "Z" then
					CameraModule.setCamOffset(Vector3.new(camOffset.X, camOffset.Y, 0))
				end
				setFromAlpha(alphaFromValue(getValFn()))
				notify("Camera", "Reset " .. axisName .. ".", 2)
			end)
		end

		makeAxisSlider("X",
			function() return CameraModule.getCamOffset().X end,
			function(v)
				local off = CameraModule.getCamOffset()
				CameraModule.setCamOffset(Vector3.new(v, off.Y, off.Z))
			end,
			-10, 10)

		makeAxisSlider("Y",
			function() return CameraModule.getCamOffset().Y end,
			function(v)
				local off = CameraModule.getCamOffset()
				CameraModule.setCamOffset(Vector3.new(off.X, v, off.Z))
			end,
			-10, 10)

		makeAxisSlider("Z",
			function() return CameraModule.getCamOffset().Z end,
			function(v)
				local off = CameraModule.getCamOffset()
				CameraModule.setCamOffset(Vector3.new(off.X, off.Y, v))
			end,
			-10, 10)

		local resetAll = makeButton(cameraScroll, "Reset Camera (All)")
		resetAll.Size = UDim2.new(0, 220, 0, 36)
		resetAll.MouseButton1Click:Connect(function()
			CameraModule.resetCameraToDefaults()
			notify("Camera", "Camera reset.", 2)
		end)

		setSubjectMode(CameraModule.getCamSubjectMode())
		CameraModule.applyCameraSettings()
	end

	-- LIGHTING TAB
	do
		local header = makeText(lightingScroll, "Lighting", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		LightingModule.readLightingSaveState()
		local LightingState = LightingModule.getLightingState()

		local topRow = Instance.new("Frame")
		topRow.BackgroundTransparency = 1
		topRow.Size = UDim2.new(1, 0, 0, 44)
		topRow.Parent = lightingScroll

		local topLay = Instance.new("UIListLayout")
		topLay.FillDirection = Enum.FillDirection.Horizontal
		topLay.Padding = UDim.new(0, 10)
		topLay.Parent = topRow

		local enableBtn = makeButton(topRow, LightingState.Enabled and "Enabled" or "Disabled")
		enableBtn.Size = UDim2.new(0, 140, 0, 36)

		local resetBtn = makeButton(topRow, "Reset Lighting")
		resetBtn.Size = UDim2.new(0, 160, 0, 36)

		enableBtn.MouseButton1Click:Connect(function()
			LightingState.Enabled = not LightingState.Enabled
			enableBtn.Text = LightingState.Enabled and "Enabled" or "Disabled"
			LightingModule.writeLightingSaveState()
			LightingModule.syncLightingToggles()
		end)

		resetBtn.MouseButton1Click:Connect(function()
			LightingModule.resetLightingToOriginal()
			notify("Lighting", "Reset.", 2)
		end)

		local skyHeader = makeText(lightingScroll, "Sky Presets", 15, true)
		skyHeader.Size = UDim2.new(1, 0, 0, 20)

		local skyBar = Instance.new("ScrollingFrame")
		skyBar.BackgroundTransparency = 1
		skyBar.BorderSizePixel = 0
		skyBar.Size = UDim2.new(1, 0, 0, 44)
		skyBar.CanvasSize = UDim2.new(0, 0, 0, 0)
		skyBar.AutomaticCanvasSize = Enum.AutomaticSize.X
		skyBar.ScrollingDirection = Enum.ScrollingDirection.X
		skyBar.ScrollBarThickness = 2
		skyBar.Parent = lightingScroll

		local skyLayout = Instance.new("UIListLayout")
		skyLayout.FillDirection = Enum.FillDirection.Horizontal
		skyLayout.SortOrder = Enum.SortOrder.LayoutOrder
		skyLayout.Padding = UDim.new(0, 10)
		skyLayout.Parent = skyBar

		local skyButtons = {}

		local function setSkyActive(name)
			for k, b in pairs(skyButtons) do
				setTabButtonActive(b, k == name)
			end
		end

		for name, _ in pairs(Data.SKY_PRESETS) do
			local b = makeButton(skyBar, name)
			b.Size = UDim2.new(0, 190, 0, 36)
			skyButtons[name] = b
			b.MouseButton1Click:Connect(function()
				setSkyActive(name)
				LightingModule.applySkyPreset(name)
				notify("Lighting", "Applied: " .. name, 2)
			end)
		end

		local fxHeader = makeText(lightingScroll, "Effects", 15, true)
		fxHeader.Size = UDim2.new(1, 0, 0, 20)

		local function makeToggle(nameKey, labelText)
			local row = Instance.new("Frame")
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 40)
			row.Parent = lightingScroll

			local btn = makeButton(row, "")
			btn.Size = UDim2.new(0, 220, 0, 36)
			btn.Position = UDim2.new(0, 0, 0, 2)

			local function refresh()
				btn.Text = (LightingState.Toggles[nameKey] and "ON: " or "OFF: ") .. labelText
				setTabButtonActive(btn, LightingState.Toggles[nameKey])
			end

			btn.MouseButton1Click:Connect(function()
				LightingState.Toggles[nameKey] = not LightingState.Toggles[nameKey]
				LightingModule.writeLightingSaveState()
				LightingModule.syncLightingToggles()
				refresh()
			end)

			refresh()
		end

		makeToggle("Sky", "Sky")
		makeToggle("Atmosphere", "Atmosphere")
		makeToggle("ColorCorrection", "Color Correction")
		makeToggle("Bloom", "Bloom")
		makeToggle("DepthOfField", "Depth Of Field")
		makeToggle("MotionBlur", "Motion Blur")
		makeToggle("SunRays", "Sun Rays")

		if LightingState.SelectedSky and Data.SKY_PRESETS[LightingState.SelectedSky] then
			setSkyActive(LightingState.SelectedSky)
			if LightingState.Enabled then
				LightingModule.applySkyPreset(LightingState.SelectedSky)
			end
		end
	end

	-- SERVER TAB
	do
		local header = makeText(serverScroll, "Server", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local controls = makeText(serverScroll, "Controls\n- Rejoin: same server\n- Server Hop: best-effort (highest players).", 14, false)
		controls.Size = UDim2.new(1, 0, 0, 56)

		local row = Instance.new("Frame")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 44)
		row.Parent = serverScroll

		local lay = Instance.new("UIListLayout")
		lay.FillDirection = Enum.FillDirection.Horizontal
		lay.Padding = UDim.new(0, 10)
		lay.Parent = row

		local rejoinBtn = makeButton(row, "Rejoin (Same Server)")
		rejoinBtn.Size = UDim2.new(0, 230, 0, 36)

		local hopBtn = makeButton(row, "Server Hop")
		hopBtn.Size = UDim2.new(0, 140, 0, 36)

		rejoinBtn.MouseButton1Click:Connect(function()
			notify("Server", "Rejoining same server...", 2)
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end)
		end)

		hopBtn.MouseButton1Click:Connect(function()
			notify("Server", "Searching servers...", 2)
			task.spawn(function()
				local placeId = game.PlaceId
				local cursor = ""
				local best = nil

				for _ = 1, 3 do
					local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
					if cursor ~= "" then
						url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
					end

					local ok, res = pcall(function()
						return HttpService:GetAsync(url)
					end)

					if not ok then
						notify("Server Hop", "HTTP failed. (HttpEnabled might be off)", 4)
						pcall(function()
							TeleportService:Teleport(placeId, LocalPlayer)
						end)
						return
					end

					local data = HttpService:JSONDecode(res)
					for _, srv in ipairs(data.data or {}) do
						if srv.id and srv.id ~= game.JobId then
							if not best or (srv.playing or 0) > (best.playing or 0) then
								best = srv
							end
						end
					end

					cursor = data.nextPageCursor or ""
					if cursor == "" then break end
				end

				if best and best.id then
					notify("Server Hop", "Teleporting...", 2)
					pcall(function()
						TeleportService:TeleportToPlaceInstance(placeId, best.id, LocalPlayer)
					end)
				else
					notify("Server Hop", "No server found. Trying normal teleport.", 3)
					pcall(function()
						TeleportService:Teleport(placeId, LocalPlayer)
					end)
				end
			end)
		end)
	end

	-- CLIENT TAB (placeholder)
	do
		local t = makeText(clientScroll, "Controls\n(Coming soon)", 14, true)
		t.Size = UDim2.new(1, 0, 0, 50)
	end

	-- MIC UP TAB
	if micupScroll then
		local header = makeText(micupScroll, "Mic up", 16, true)
		header.Size = UDim2.new(1, 0, 0, 22)

		local msg = makeText(micupScroll, "For those of you who play this game hopefully your not a P£D0 also dont be weird and enjoy this tab\n(Some Stuff Will Be Added Soon)", 14, false)
		msg.Size = UDim2.new(1, 0, 0, 120)

		local coilBtn = makeButton(micupScroll, "Better Speed Coil")
		coilBtn.Size = UDim2.new(0, 220, 0, 40)
		coilBtn.MouseButton1Click:Connect(function()
			if PlayerModule.ownsAnyVipPass() then
				PlayerModule.giveBetterSpeedCoil()
			else
				notify("VIP Required", "You need VIP First.", 3)
			end
		end)
	end

	-- CREATE TAB BUTTONS
	addTabButton("Info", 1)
	addTabButton("Controls", 2, 130)
	addTabButton("Fly", 3)
	addTabButton("Anim Packs", 4, 140)
	addTabButton("Player", 5)
	addTabButton("Camera", 6)
	addTabButton("Lighting", 7)
	addTabButton("Server", 8)
	addTabButton("Client", 9)
	if micupPage then
		addTabButton("Mic up", 10, 120)
	end

	-- Hide all pages initially
	for _, pg in pairs(pages) do
		pg.Page.Visible = false
	end

	-- Switch to Info page
	activePageName = ""
	switchPage("Info")
end

return UIPagesModule
