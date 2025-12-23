-- utils/ui.lua
-- UI helper functions for creating styled components

local UIUtils = {}

local Constants = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/constants.lua"))()
local THEME = Constants.THEME

--------------------------------------------------------------------
-- UI COMPONENT BUILDERS
--------------------------------------------------------------------

function UIUtils.makeCorner(parent, r)
	local c = parent:FindFirstChildOfClass("UICorner")
	if not c then
		c = Instance.new("UICorner")
		c.Parent = parent
	end
	c.CornerRadius = UDim.new(0, r or 10)
	return c
end

function UIUtils.makeStroke(parent, thickness, color, transparency)
	local s = parent:FindFirstChildOfClass("UIStroke")
	if not s then
		s = Instance.new("UIStroke")
		s.Parent = parent
	end
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color or THEME.Red
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0.10
	return s
end

function UIUtils.makeGlass(parent)
	parent.BackgroundColor3 = THEME.Panel
	parent.BackgroundTransparency = THEME.PanelTrans

	local g = parent:FindFirstChildOfClass("UIGradient")
	if not g then
		g = Instance.new("UIGradient")
		g.Parent = parent
	end

	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.GlassTop),
		ColorSequenceKeypoint.new(0.4, THEME.GlassMid),
		ColorSequenceKeypoint.new(1, THEME.GlassBot),
	})
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.20),
	})
	return g
end

function UIUtils.themeButton(btn)
	btn.BackgroundColor3 = THEME.Button
	btn.BackgroundTransparency = 0.20
	btn.TextColor3 = THEME.Text
	btn.Font = Enum.Font.GothamBold

	UIUtils.makeCorner(btn, 10)

	local st = btn:FindFirstChildOfClass("UIStroke")
	if not st then
		st = Instance.new("UIStroke")
		st.Parent = btn
	end
	st.Color = THEME.Red
	st.Thickness = 0.5
	st.Transparency = 0.25
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	btn.AutoButtonColor = false

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = THEME.ButtonHover
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = THEME.Button
	end)
end

function UIUtils.makeButton(parent, txt)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = THEME.Button
	b.BackgroundTransparency = 0.2
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Text = txt or "Button"
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = THEME.Text
	b.Parent = parent
	UIUtils.makeCorner(b, 10)

	local st = Instance.new("UIStroke")
	st.Color = THEME.Red
	st.Thickness = 1
	st.Transparency = 0.25
	st.Parent = b

	return b
end

--------------------------------------------------------------------
-- NOTIFICATION SYSTEM
--------------------------------------------------------------------

function UIUtils.notify(gui, titleText, bodyText, seconds)
	if not gui then return end
	local dur = seconds or 2.2

	local box = Instance.new("Frame")
	box.Name = "SOS_Notify"
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 18)
	box.Size = UDim2.new(0, 420, 0, 70)
	box.BorderSizePixel = 0
	box.Parent = gui
	UIUtils.makeCorner(box, 14)
	UIUtils.makeGlass(box)
	UIUtils.makeStroke(box, 2, THEME.Red, 0.12)
	box.ZIndex = 2000

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 14, 0, 8)
	title.Size = UDim2.new(1, -28, 0, 22)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = THEME.Text
	title.Text = titleText or "Notice"
	title.ZIndex = 2001
	title.Parent = box

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 14, 0, 30)
	body.Size = UDim2.new(1, -28, 0, 34)
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.TextColor3 = Color3.fromRGB(225, 225, 225)
	body.Text = bodyText or ""
	body.ZIndex = 2001
	body.Parent = box

	task.delay(dur, function()
		if box and box.Parent then
			box:Destroy()
		end
	end)
end

--------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------

function UIUtils.tween(obj, info, props)
	local TweenService = game:GetService("TweenService")
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

function UIUtils.clamp01(x)
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

function UIUtils.safeDestroy(inst)
	if inst and inst.Parent then
		inst:Destroy()
	end
end

return UIUtils
