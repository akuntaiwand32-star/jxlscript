-- NIMEROHUB | SERVER HOP ALL GAME
-- UI ungu-hijau terang, font besar, tiap fitur dalam kotak sendiri, efek gelembung di dalam menu.
-- Mau tambah fitur? Lihat contoh di bagian "Isi menu" paling bawah.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LP = Players.LocalPlayer

local CONFIG = {
	Title = "NIMEROHUB",
	Version = "V4",
	Letter = "N",
}

-- ============ Parent + bersihkan versi lama ============
local env = (getgenv and getgenv()) or _G
if env.NimeroHub_Cleanup then pcall(env.NimeroHub_Cleanup) end

local parent
pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not parent then parent = LP:WaitForChild("PlayerGui") end
pcall(function()
	local old = parent:FindFirstChild("NimeroHub")
	if old then old:Destroy() end
end)

-- ============ Warna ============
local Theme = {accent = Color3.fromRGB(150, 92, 255), accent2 = Color3.fromRGB(48, 226, 170)}
local C = {
	bg = Color3.fromRGB(14, 10, 26),
	top = Color3.fromRGB(24, 17, 44),
	panel = Color3.fromRGB(34, 25, 60),
	panel2 = Color3.fromRGB(50, 38, 88),
	off = Color3.fromRGB(72, 60, 112),
	stroke = Color3.fromRGB(125, 105, 195),
	text = Color3.fromRGB(246, 242, 255),
	sub = Color3.fromRGB(180, 172, 216),
	danger = Color3.fromRGB(255, 95, 120),
}

-- ============ Helper ============
local conns = {}
local function conn(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end
local function new(class, props, par)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if par then o.Parent = par end
	return o
end
local function round(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function stroke(o, col, th, tr)
	return new("UIStroke", {Color = col or C.stroke, Thickness = th or 1, Transparency = tr or 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end
local function pad(o, l, t, r, b)
	return new("UIPadding", {PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0)}, o)
end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function grad(o, rot)
	return new("UIGradient", {Rotation = rot or 0, Color = ColorSequence.new(Theme.accent, Theme.accent2)}, o)
end
local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

-- ============ GUI dasar ============
local gui = new("ScreenGui", {
	Name = "NimeroHub", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, parent)
env.NimeroHub_Cleanup = function() pcall(function() gui:Destroy() end) end
gui.Destroying:Connect(function()
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end)

-- ============ Jendela utama ============
local WIN_W, WIN_H, HEAD = 440, 300, 48
local UI_SCALE = 0.85   -- ukuran keseluruhan UI (1 = besar, 0.7 = kecil). Ubah sesuai selera

local root = new("Frame", {
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	Position = UDim2.new(0.5, -WIN_W * UI_SCALE / 2, 0.5, -WIN_H * UI_SCALE / 2),
	BackgroundTransparency = 1,
}, gui)
local scale = new("UIScale", {Scale = UI_SCALE}, root)

local shadow = new("ImageLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 6),
	Size = UDim2.new(1, 56, 1, 56), BackgroundTransparency = 1,
	Image = "rbxassetid://6014261993", ImageColor3 = Color3.fromRGB(60, 20, 120), ImageTransparency = 0.35,
	ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0,
}, root)

local main = new("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, ZIndex = 1}, root)
round(main, 16)

-- cahaya warna di latar
local glow = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 1}, main)
round(glow, 16)
new("UIGradient", {
	Rotation = 125,
	Color = ColorSequence.new(Theme.accent, Theme.accent2),
	Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.78), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.82)}),
}, glow)

-- border gradien berputar
local border = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5}, root)
round(border, 16)
local borderStroke = new("UIStroke", {Thickness = 2, Transparency = 0.05, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, border)
local borderGrad = grad(borderStroke, 0)
conn(RunService.Heartbeat, function(dt) borderGrad.Rotation = (borderGrad.Rotation + dt * 45) % 360 end)

-- ============ Header ============
local top = new("Frame", {Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = C.top, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 3}, main)
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = C.stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0}, top)

local logo = new("Frame", {Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0, 12, 0.5, -16), BackgroundColor3 = Color3.new(1, 1, 1)}, top)
round(logo, 10)
grad(logo, 45)
new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = CONFIG.Letter, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 19, TextStrokeTransparency = 0.6}, logo)

local title = new("TextLabel", {
	Size = UDim2.new(0, 190, 0, 22), Position = UDim2.new(0, 53, 0, 6), BackgroundTransparency = 1,
	Text = CONFIG.Title, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 19,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top)
grad(title, 0)
local subtitle = new("TextLabel", {
	Size = UDim2.new(0, 200, 0, 14), Position = UDim2.new(0, 53, 0, 28), BackgroundTransparency = 1,
	Text = CONFIG.Version .. "  |  -- FPS", TextColor3 = C.sub, Font = Enum.Font.GothamMedium, TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
}, top)

local function headerBtn(text, xOff)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, xOff, 0.5, -16),
		BackgroundColor3 = C.panel2, Text = text, TextColor3 = C.text,
		Font = Enum.Font.GothamBold, TextSize = 17, AutoButtonColor = false,
	}, top)
	round(b, 10)
	return b
end
local closeBtn = headerBtn("X", -44)
local minBtn = headerBtn("-", -82)
for _, b in ipairs({closeBtn, minBtn}) do
	local danger = (b == closeBtn)
	b.MouseEnter:Connect(function() tween(b, 0.12, {BackgroundColor3 = danger and C.danger or C.off}) end)
	b.MouseLeave:Connect(function() tween(b, 0.12, {BackgroundColor3 = C.panel2}) end)
end

do -- FPS
	local acc, frames = 0, 0
	conn(RunService.RenderStepped, function(dt)
		acc += dt; frames += 1
		if acc >= 0.5 then
			subtitle.Text = (CONFIG.Version .. "  |  %d FPS"):format(math.floor(frames / acc + 0.5))
			acc, frames = 0, 0
		end
	end)
end

-- ============ Gelembung peluncur (on/off menu) ============
local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 400)
local bubble = new("TextButton", {
	Size = UDim2.fromOffset(48, 48), Position = UDim2.fromOffset(10, math.floor(vp.Y * 0.4)),
	BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false, ZIndex = 10,
}, gui)
round(bubble, 24)
local bubbleGrad = grad(bubble, 45)
new("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = CONFIG.Letter, TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBlack, TextSize = 21, TextStrokeTransparency = 0.6,
}, bubble)
local ring = new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 1.5, Transparency = 0.55}, bubble)
TweenService:Create(ring, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.95, Thickness = 6}):Play()

-- ============ Buka / tutup / minimize ============
local body
local isOpen = true
local minimized = false

local function setOpen(v)
	if v == isOpen then return end
	isOpen = v
	if v then
		root.Visible = true
		scale.Scale = 0.88 * UI_SCALE
		main.GroupTransparency = 1
		tween(scale, 0.32, {Scale = UI_SCALE}, Enum.EasingStyle.Back)
		tween(main, 0.25, {GroupTransparency = 0})
		tween(shadow, 0.25, {ImageTransparency = 0.35})
		tween(borderStroke, 0.25, {Transparency = 0.05})
	else
		tween(scale, 0.2, {Scale = 0.9 * UI_SCALE})
		tween(main, 0.2, {GroupTransparency = 1})
		tween(shadow, 0.2, {ImageTransparency = 1})
		tween(borderStroke, 0.2, {Transparency = 1})
		task.delay(0.22, function() if not isOpen then root.Visible = false end end)
	end
	bubbleGrad.Enabled = v
	tween(bubble, 0.2, {BackgroundColor3 = v and Color3.new(1, 1, 1) or C.off})
end
local function toggleMenu() setOpen(not isOpen) end
closeBtn.MouseButton1Click:Connect(toggleMenu)

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	minBtn.Text = minimized and "+" or "-"
	if minimized then
		task.delay(0.3, function() if minimized then body.Visible = false end end)
	else
		body.Visible = true
	end
	tween(root, 0.28, {Size = UDim2.fromOffset(WIN_W, minimized and HEAD or WIN_H)})
end)

conn(UIS.InputBegan, function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end)

-- ============ Drag ============
local function drag(handle, target, onTap, onEnd)
	local dragging, startIn, startPos, moved = false, nil, nil, 0
	conn(handle.InputBegan, function(i)
		if isPress(i) then
			dragging, startIn, startPos, moved = true, i.Position, target.Position, 0
			local c
			c = i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
					if moved < 6 then
						if onTap then onTap() end
					elseif onEnd then
						onEnd()
					end
				end
			end)
		end
	end)
	conn(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startIn
			moved = math.max(moved, d.Magnitude)
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end
drag(top, root)
drag(bubble, bubble, toggleMenu, function()
	local v = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 400)
	local p = bubble.AbsolutePosition
	local x = (p.X + 24 < v.X / 2) and 8 or (v.X - 56)
	local y = math.clamp(p.Y, 8, v.Y - 56)
	tween(bubble, 0.3, {Position = UDim2.fromOffset(x, y)}, Enum.EasingStyle.Back)
end)

-- ============ Efek gelembung di dalam menu ============
do
	local fx = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, ClipsDescendants = true}, main)
	local list = {}
	for i = 1, 18 do
		local sz = math.random(12, 42)
		local b = new("Frame", {Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.84, BorderSizePixel = 0}, fx)
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, b)
		new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.55}, b)
		grad(b, math.random(0, 360))
		-- kilau kecil di sudut gelembung
		local hl = new("Frame", {Size = UDim2.fromScale(0.22, 0.22), Position = UDim2.fromScale(0.2, 0.16), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.45, BorderSizePixel = 0}, b)
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, hl)
		list[i] = {f = b, x = math.random(0, WIN_W), y = math.random(0, WIN_H), sp = math.random(14, 40), amp = math.random(6, 18), fr = math.random(8, 18) / 10, ph = math.random() * 6.28, sz = sz}
	end
	local t = 0
	conn(RunService.Heartbeat, function(dt)
		if not isOpen or minimized then return end
		t += dt
		for _, p in ipairs(list) do
			p.y -= p.sp * dt
			if p.y < -p.sz then
				p.y = WIN_H + p.sz
				p.x = math.random(0, WIN_W)
			end
			p.f.Position = UDim2.fromOffset(p.x + math.sin(t * p.fr + p.ph) * p.amp, p.y)
		end
	end)
end

-- ============ Notifikasi ============
local toasts = new("Frame", {Size = UDim2.new(0, 260, 1, -20), Position = UDim2.new(1, -270, 0, 10), BackgroundTransparency = 1, ZIndex = 20}, gui)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, toasts)

local function notify(head, text, dur)
	local holder = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1}, toasts)
	local t = new("Frame", {Size = UDim2.fromScale(1, 1), Position = UDim2.new(1, 30, 0, 0), BackgroundColor3 = C.top}, holder)
	round(t, 12)
	stroke(t, C.stroke, 1, 0.35)
	local bar = new("Frame", {Size = UDim2.new(0, 4, 1, -16), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, t)
	round(bar, 2)
	grad(bar, 90)
	new("TextLabel", {
		Size = UDim2.new(1, -30, 0, 22), Position = UDim2.new(0, 20, 0, 6), BackgroundTransparency = 1,
		Text = head, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, t)
	new("TextLabel", {
		Size = UDim2.new(1, -30, 0, 18), Position = UDim2.new(0, 20, 0, 29), BackgroundTransparency = 1,
		Text = text or "", TextColor3 = C.sub, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, t)
	tween(t, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
	task.delay(dur or 2.4, function()
		if not t.Parent then return end
		tween(t, 0.25, {Position = UDim2.new(1, 30, 0, 0)})
		task.wait(0.28)
		holder:Destroy()
	end)
end

-- ============ Sidebar + halaman ============
body = new("Frame", {Size = UDim2.new(1, 0, 1, -HEAD), Position = UDim2.new(0, 0, 0, HEAD), BackgroundTransparency = 1, ClipsDescendants = true}, main)

-- tab di atas, rata tengah (tidak ada sidebar kiri)
local tabBar = new("ScrollingFrame", {
	Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 8, 0, 6), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
	ScrollingDirection = Enum.ScrollingDirection.X,
}, body)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
}, tabBar)

local content = new("Frame", {Size = UDim2.new(1, -16, 1, -54), Position = UDim2.new(0, 8, 0, 48), BackgroundTransparency = 1, ClipsDescendants = true}, body)

local pages, tabs = {}, {}
local currentTab
local function selectTab(name)
	if currentTab == name then return end
	currentTab = name
	for n, p in pairs(pages) do
		if n == name then
			p.Visible = true
			p.Position = UDim2.new(0, 14, 0, 0)
			tween(p, 0.3, {Position = UDim2.new(0, 0, 0, 0)})
		else
			p.Visible = false
		end
	end
	for n, t in pairs(tabs) do
		local on = (n == name)
		tween(t.btn, 0.2, {BackgroundTransparency = on and 0.1 or 1, TextColor3 = on and C.text or C.sub})
		tween(t.bar, 0.25, {Size = UDim2.new(on and 0.6 or 0, 0, 0, 3), BackgroundTransparency = on and 0 or 1}, Enum.EasingStyle.Back)
	end
end

local function addTab(name)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(130, 34), BackgroundColor3 = C.panel2, BackgroundTransparency = 1, Text = name,
		TextColor3 = C.sub, Font = Enum.Font.GothamBlack, TextSize = 15, AutoButtonColor = false,
	}, tabBar)
	round(b, 10)
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(0, 3, 0, 3), Position = UDim2.new(0.5, 0, 1, -2),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
	}, b)
	round(bar, 2)
	grad(bar, 0)
	local p = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.accent,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
	}, content)
	new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, p)
	pad(p, 0, 2, 6, 8)
	pages[name], tabs[name] = p, {btn = b, bar = bar}
	b.MouseButton1Click:Connect(function() selectTab(name) end)
	b.MouseEnter:Connect(function() if currentTab ~= name then tween(b, 0.12, {BackgroundTransparency = 0.6}) end end)
	b.MouseLeave:Connect(function() if currentTab ~= name then tween(b, 0.12, {BackgroundTransparency = 1}) end end)
	return p
end

-- ============ Komponen ============
-- Kotak pembungkus satu fitur: addGroup(page, "NAMA FITUR") lalu isi dengan addToggle(kotak, ...), dst.
local function addGroup(page, titleText)
	local box = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.top, BackgroundTransparency = 0.2}, page)
	round(box, 14)
	stroke(box, Theme.accent, 1.3, 0.45)
	new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, box)
	pad(box, 10, 10, 10, 12)
	if titleText then
		local h = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = string.upper(titleText),
			TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		}, box)
		grad(h, 0)
	end
	new("Frame", {Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1}, page) -- jarak ke kotak berikutnya
	return box
end

local function addLabel(par, text)
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text,
		TextColor3 = C.sub, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, par)
end

local function card(par, h, clickable)
	local row = new(clickable and "TextButton" or "Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.panel, BackgroundTransparency = 0.12}, par)
	if clickable then row.Text = ""; row.AutoButtonColor = false end
	round(row, 12)
	local s = stroke(row, C.stroke, 1, 0.65)
	row.MouseEnter:Connect(function()
		tween(row, 0.15, {BackgroundColor3 = C.panel2})
		tween(s, 0.15, {Transparency = 0.3})
	end)
	row.MouseLeave:Connect(function()
		tween(row, 0.15, {BackgroundColor3 = C.panel})
		tween(s, 0.15, {Transparency = 0.65})
	end)
	return row
end

local function addToggle(par, text, default, cb)
	local state = default or false
	local row = card(par, 46, true)
	new("TextLabel", {
		Size = UDim2.new(1, -74, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1,
		Text = text, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local pill = new("Frame", {Size = UDim2.fromOffset(48, 26), Position = UDim2.new(1, -60, 0.5, -13), BackgroundColor3 = C.off}, row)
	round(pill, 13)
	local pg = grad(pill, 0)
	local knob = new("Frame", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = Color3.new(1, 1, 1)}, pill)
	round(knob, 10)
	local function render(t)
		pill.BackgroundColor3 = state and Color3.new(1, 1, 1) or C.off
		pg.Enabled = state
		tween(knob, t, {Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)}, Enum.EasingStyle.Back)
	end
	render(0)
	row.MouseButton1Click:Connect(function()
		state = not state
		render(0.22)
		cb(state)
	end)
	return function(v) state = v; render(0.2) end
end

local function addButton(par, text, cb, w)
	-- latar bergradien (Frame) dan teks (TextButton) dipisah supaya teks tidak ikut terwarnai gradien
	-- w (opsional) = lebar skala, mis. 0.5 untuk dua tombol sebaris
	local holder = new("Frame", {Size = w and UDim2.new(w, -4, 0, 46) or UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, par)
	local bg = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1)}, holder)
	round(bg, 12)
	grad(bg, 20)
	local sc = new("UIScale", {}, bg)
	local b = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text,
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 16,
		TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.6,
		AutoButtonColor = false, ZIndex = 2,
	}, holder)
	b.MouseEnter:Connect(function() tween(sc, 0.12, {Scale = 1.015}) end)
	b.MouseLeave:Connect(function() tween(sc, 0.12, {Scale = 1}) end)
	b.MouseButton1Click:Connect(function()
		tween(sc, 0.08, {Scale = 0.96})
		task.delay(0.09, function() tween(sc, 0.2, {Scale = 1}, Enum.EasingStyle.Back) end)
		cb()
	end)
	return b
end

local function addSlider(par, text, min, max, def, cb)
	local row = card(par, 64, false)
	new("TextLabel", {
		Size = UDim2.new(1, -90, 0, 24), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1,
		Text = text, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local badge = new("TextLabel", {
		Size = UDim2.fromOffset(54, 22), Position = UDim2.new(1, -66, 0, 7), BackgroundColor3 = C.off,
		Text = tostring(def), TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 13,
	}, row)
	round(badge, 8)
	local hit = new("Frame", {Size = UDim2.new(1, -28, 0, 26), Position = UDim2.new(0, 14, 0, 32), BackgroundTransparency = 1}, row)
	local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0.5, -4), BackgroundColor3 = C.off}, hit)
	round(bar, 4)
	local a0 = (def - min) / (max - min)
	local fill = new("Frame", {Size = UDim2.new(a0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1)}, bar)
	round(fill, 4)
	grad(fill, 0)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), Position = UDim2.new(a0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3,
	}, bar)
	round(knob, 9)
	stroke(knob, Theme.accent, 2, 0)
	local sliding = false
	local function set(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local v = math.floor(min + (max - min) * a + 0.5)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		badge.Text = tostring(v)
		cb(v)
	end
	conn(hit.InputBegan, function(i)
		if isPress(i) then
			sliding = true
			tween(knob, 0.12, {Size = UDim2.fromOffset(22, 22)})
			set(i.Position.X)
		end
	end)
	conn(UIS.InputChanged, function(i)
		if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			set(i.Position.X)
		end
	end)
	conn(UIS.InputEnded, function(i)
		if isPress(i) and sliding then
			sliding = false
			tween(knob, 0.15, {Size = UDim2.fromOffset(18, 18)})
		end
	end)
end

local function addInput(par, text, default, cb)
	local last = default
	local row = card(par, 46, false)
	new("TextLabel", {
		Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1,
		Text = text, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local box = new("TextBox", {
		Size = UDim2.fromOffset(86, 30), Position = UDim2.new(1, -98, 0.5, -15), BackgroundColor3 = C.off,
		Text = tostring(default), TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, ClearTextOnFocus = false,
	}, row)
	round(box, 9)
	local bs = stroke(box, Theme.accent2, 1.5, 1)
	box.Focused:Connect(function() tween(bs, 0.15, {Transparency = 0}) end)
	box.FocusLost:Connect(function()
		tween(bs, 0.15, {Transparency = 1})
		local n = tonumber(box.Text)
		if n and n > 0 then last = n; cb(n) end
		box.Text = tostring(last)
	end)
end

-- ============ SERVER HOP (logika) ============
local function httpGet(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if ok and type(res) == "string" and #res > 0 then return res end
	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if req then
		local ok2, r = pcall(req, {Url = url, Method = "GET"})
		if ok2 and r and r.Body and (r.StatusCode == nil or r.StatusCode == 200) then return r.Body end
	end
	return nil
end

local SERVER_COUNT = 10   -- jumlah pilihan server yang ditampilkan
local MAX_PAGES = 3       -- halaman per urutan (1 halaman = sampai 100 server)

local function fetchServers()
	local out, seen, anyBody, errMsg = {}, {}, false, nil
	for _, order in ipairs({"Asc", "Desc"}) do
		local cursor = nil
		for _ = 1, MAX_PAGES do
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&excludeFullGames=true&limit=100"):format(game.PlaceId, order)
			if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
			local bodyTxt = httpGet(url)
			if not bodyTxt then break end
			anyBody = true
			local ok, data = pcall(function() return HttpService:JSONDecode(bodyTxt) end)
			if not ok or type(data) ~= "table" then break end
			if data.errors then
				errMsg = "Dibatasi Roblox, coba lagi sebentar"
				break
			end
			for _, sv in ipairs(data.data or {}) do
				if sv.id ~= game.JobId and not seen[sv.id] and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then
					seen[sv.id] = true
					table.insert(out, sv)
				end
			end
			cursor = data.nextPageCursor
			if not cursor then break end
			task.wait(0.4)
		end
	end
	if #out == 0 then
		if not anyBody then return nil, "Gagal memuat (executor tidak mendukung HttpGet?)" end
		return nil, errMsg or "Tidak ada server lain yang tersedia"
	end
	return out
end

local function pickN(list, mode)
	local l = table.clone(list)
	if mode == "Sepi" then
		table.sort(l, function(a, b) if a.playing ~= b.playing then return a.playing < b.playing end return a.id < b.id end)
	elseif mode == "Ramai" then
		table.sort(l, function(a, b) if a.playing ~= b.playing then return a.playing > b.playing end return a.id < b.id end)
	elseif mode == "Ping" then
		table.sort(l, function(a, b)
			local pa, pb = a.ping or 9999, b.ping or 9999
			if pa ~= pb then return pa < pb end
			return a.id < b.id
		end)
	else
		for i = #l, 2, -1 do
			local j = math.random(i)
			l[i], l[j] = l[j], l[i]
		end
	end
	local r = {}
	for i = 1, math.min(SERVER_COUNT, #l) do r[i] = l[i] end
	return r
end

local hopping = false
local function joinServer(id)
	if hopping then return end
	hopping = true
	notify("Server Hop", "Pindah server...", 2)
	local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LP) end)
	if not ok then
		hopping = false
		notify("Gagal pindah", tostring(err), 3)
	end
	task.delay(10, function() hopping = false end)
end
conn(TeleportService.TeleportInitFailed, function(_, _, msg)
	hopping = false
	notify("Gagal pindah", tostring(msg), 3)
end)

-- ============ Isi menu ============
-- Cara menambah fitur baru (tiap fitur = satu kotak):
--   local tab = addTab("NAMA TAB")               -- tab baru di sidebar (bisa digulir)
--   local kotak = addGroup(tab, "Nama fitur")    -- kotak fitur
--   addToggle(kotak, "Nyalakan", false, function(on) ... end)
--   addButton(kotak, "Tombol", function() ... end)
--   addSlider(kotak, "Slider", 0, 100, 50, function(v) ... end)
--   addInput(kotak, "Angka", 10, function(n) ... end)
--   notify("Judul", "Pesan")

local serverTab = addTab("SERVER")

local srvMode = "Sepi"
local srvCache = nil
local srvRows = {}
local srvLoading = false
local lastFetch = 0
local showServers, refreshServers

-- SATU kotak berisi semuanya: urutan, tombol, dan daftar server
local gMain = addGroup(serverTab, "Server Hop")

-- urutan server (rata tengah)
do
	local row = card(gMain, 48, false)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center}, row)
	local chips = {}
	local function paint()
		for name, b in pairs(chips) do
			local on = (name == srvMode)
			b.BackgroundColor3 = on and Theme.accent or C.off
			b.TextColor3 = on and Color3.new(1, 1, 1) or C.sub
		end
	end
	for _, name in ipairs({"Sepi", "Ramai", "Ping", "Acak"}) do
		local b = new("TextButton", {
			Size = UDim2.new(0.225, 0, 0, 32), BackgroundColor3 = C.off, Text = name, TextColor3 = C.sub,
			Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false,
		}, row)
		round(b, 9)
		chips[name] = b
		b.MouseButton1Click:Connect(function()
			srvMode = name
			paint()
			if showServers then showServers() end
		end)
	end
	paint()
end

-- dua tombol sebaris
do
	local row = new("Frame", {Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1}, gMain)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center}, row)
	addButton(row, "Refresh", function() refreshServers() end, 0.5)
	addButton(row, "Server acak", function()
		if srvCache and #srvCache > 0 then
			joinServer(srvCache[math.random(#srvCache)].id)
		else
			refreshServers(function(list) joinServer(list[math.random(#list)].id) end)
		end
	end, 0.5)
end

local srvStatus = addLabel(gMain, "Memuat server otomatis...")
srvStatus.Size = UDim2.new(1, 0, 0, 34)
srvStatus.TextSize = 13
srvStatus.TextXAlignment = Enum.TextXAlignment.Center

local srvHolder = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, gMain)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, srvHolder)

showServers = function()
	for _, r in ipairs(srvRows) do r:Destroy() end
	srvRows = {}
	if not srvCache then return end
	local items = pickN(srvCache, srvMode)
	srvStatus.Text = ("%d server ditemukan, tampil %d (urut: %s)"):format(#srvCache, #items, srvMode)
	for i, sv in ipairs(items) do
		local r = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.panel, BackgroundTransparency = 0.12, LayoutOrder = i}, srvHolder)
		round(r, 12)
		stroke(r, C.stroke, 1, 0.6)
		new("TextLabel", {
			Size = UDim2.new(1, -96, 0, 22), Position = UDim2.new(0, 14, 0, 7), BackgroundTransparency = 1,
			Text = "Server " .. i .. "  -  " .. sv.playing .. "/" .. sv.maxPlayers .. " pemain",
			TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		}, r)
		new("TextLabel", {
			Size = UDim2.new(1, -96, 0, 18), Position = UDim2.new(0, 14, 0, 30), BackgroundTransparency = 1,
			Text = "Ping " .. (sv.ping and (tostring(math.floor(sv.ping)) .. " ms") or "-") .. (sv.fps and ("   FPS " .. math.floor(sv.fps)) or ""),
			TextColor3 = C.sub, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		}, r)
		local jb = new("TextButton", {
			Size = UDim2.fromOffset(72, 34), Position = UDim2.new(1, -84, 0.5, -17), BackgroundColor3 = Theme.accent,
			Text = "Join", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 15, AutoButtonColor = false,
		}, r)
		round(jb, 10)
		jb.MouseButton1Click:Connect(function() joinServer(sv.id) end)
		table.insert(srvRows, r)
	end
end

refreshServers = function(after, silent)
	if srvLoading then return end
	if os.clock() - lastFetch < 3 then
		if not silent then notify("Tunggu sebentar", "Jangan terlalu cepat refresh", 1.5) end
		return
	end
	srvLoading = true
	lastFetch = os.clock()
	if not silent or not srvCache then srvStatus.Text = "Memuat server..." end
	task.spawn(function()
		local list, err = fetchServers()
		srvLoading = false
		if not gui.Parent then return end
		if not list then
			if silent and srvCache then return end
			srvCache = nil
			showServers()
			srvStatus.Text = err or "Gagal memuat"
			return
		end
		srvCache = list
		showServers()
		if after then after(list) end
	end)
end

-- baca server otomatis, lalu segarkan tiap 30 detik selama tab SERVER terbuka
task.spawn(function()
	task.wait(0.8)
	refreshServers(nil, true)
	while gui.Parent do
		task.wait(30)
		if isOpen and not minimized and currentTab == "SERVER" and not hopping then
			refreshServers(nil, true)
		end
	end
end)

-- ============ Mulai ============
selectTab("SERVER")
main.GroupTransparency = 1
scale.Scale = 0.88 * UI_SCALE
tween(main, 0.4, {GroupTransparency = 0})
tween(scale, 0.45, {Scale = UI_SCALE}, Enum.EasingStyle.Back)
task.delay(0.5, function() notify(CONFIG.Title, "Siap dipakai") end)
