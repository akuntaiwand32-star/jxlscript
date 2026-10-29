-- NimeroHub | BERIMAKAN HEWAN v3 (Delta / Luau) - tema Merah Kehitaman
-- Auto Perfect       : baca angka "+N", klik pas mencapai Target + auto "Klik untuk melanjutkan"
-- Auto Farm          : jaga karakter di FarmPos (koordinat tetap)
-- Auto Click x2      : klik tombol x2 saat latihan + tap otomatis layar Tap Bonus kalau muncul

-- Kunci game: hanya jalan di "[🎃] Throw Food For Animals"
local ALLOWED_PLACE_ID = 120219252362013
if game.PlaceId ~= ALLOWED_PLACE_ID then
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "BERIMAKAN HEWAN",
			Text = "Script ini hanya untuk game Throw Food For Animals.",
			Duration = 6,
		})
	end)
	return
end

if _G.AP_CLEAN then pcall(_G.AP_CLEAN) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local lp = Players.LocalPlayer
while not lp do task.wait() lp = Players.LocalPlayer end
local pg = lp:WaitForChild("PlayerGui")
local origIcon = UIS.MouseIconEnabled

local alive = true
local lastErr = ""
local gui -- diisi di bagian UI

local CFG = {
	Enabled = false,
	AutoFarm = false,
	FarmKick = false, -- true = abaikan jeda dan langsung ke FarmPos
	AutoX2 = false,
	Target = 20,
	Lead = 0.02,
	Cooldown = 0.45,
	ClickMode = 1, -- 1 Semua, 2 Mouse, 3 Touch, 4 Tool
	FarmPos = Vector3.new(0.00, 5.60, -45.00),
	FarmRadius = 4,
	ZoneMin = 0.00, ZoneMax = 0.14,
}

local conns = {}
local function bind(c) conns[#conns + 1] = c return c end

-- Loop aman: error di satu fitur tidak mematikan fitur lain
local function loop(tag, interval, fn)
	task.spawn(function()
		while alive do
			local ok, err = pcall(fn)
			if not ok then lastErr = tag .. ": " .. tostring(err) end
			task.wait(interval)
		end
	end)
end

local function tw(o, t, p, style)
	pcall(function()
		TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
	end)
end

------------------------------------------------------------
-- Util teks & visibilitas
------------------------------------------------------------
local function clean(s) return (s:gsub("<[^>]+>", "")) end
local function norm(raw) return (raw:lower():gsub("[^%a]", "")) end

local function ours(o)
	return gui ~= nil and o:IsDescendantOf(gui)
end

local function visible(o)
	local g = o
	while g and g ~= game do
		if g:IsA("GuiObject") then
			if not g.Visible then return false end
		elseif g:IsA("LayerCollector") then
			return g.Enabled
		end
		g = g.Parent
	end
	return true
end

-- Indeks semua teks UI (di-cache 0.3 dtk supaya tidak lag)
local idx, idxT = {}, 0
local function texts()
	local now = os.clock()
	if now - idxT > 0.3 then
		idxT = now
		local out = {}
		for _, o in ipairs(pg:GetDescendants()) do
			if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and not ours(o) then
				out[#out + 1] = o
			end
		end
		idx = out
	end
	return idx
end

-- match(teksKecil, teksNormal) -> boolean
local function findText(match)
	for _, o in ipairs(texts()) do
		if o.Parent then
			local raw = clean(o.Text)
			if raw ~= "" and match(raw:lower(), norm(raw)) and visible(o) and o.TextTransparency < 0.9 then
				return o
			end
		end
	end
	return nil
end

local function clickableFor(o)
	local c = o:IsA("GuiButton") and o or o:FindFirstAncestorWhichIsA("GuiButton")
	if c then return c end
	local anc = o.Parent
	for _ = 1, 3 do
		if anc and anc:IsA("GuiObject") then
			local b = anc:FindFirstChildWhichIsA("GuiButton", true)
			if b and visible(b) then return b end
			anc = anc.Parent
		end
	end
	return (o.Parent and o.Parent:IsA("GuiObject")) and o.Parent or o
end

local function centerOf(g)
	local sg = g:FindFirstAncestorWhichIsA("ScreenGui")
	local inset = Vector2.zero
	if not (sg and sg.IgnoreGuiInset) then
		local ok, v = pcall(function() return GuiService:GetGuiInset() end)
		if ok and v then inset = v end
	end
	return g.AbsolutePosition + g.AbsoluteSize / 2 + inset
end

------------------------------------------------------------
-- Klik
------------------------------------------------------------
local lastClickT = 0

-- HP: hanya kirim sentuhan (jangan kirim event mouse, karena itu membuat
-- Roblox pindah ke kontrol keyboard -> joystick hilang & UI toko ter-reset).
local MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- Lacak sentuhan ASLI pemain supaya klik otomatis tidak memotong geseran/joystick
local userTouches, injectUntil, injectPos = {}, 0, Vector2.new(-9999, -9999)
local lastUserTouchT = 0 -- waktu terakhir sentuhan ASLI pemain (mulai / geser / lepas)
local ourHitTest = function() return false end -- diisi setelah UI dibuat

-- sentuhan buatan (hasil klik otomatis) dikenali dari posisi + waktu yang sangat dekat
local function isInjected(i)
	if os.clock() > injectUntil then return false end
	local d = Vector2.new(i.Position.X, i.Position.Y) - injectPos
	return d.Magnitude < 140
end

bind(UIS.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch and not isInjected(i)
	and not ourHitTest(i.Position) then
		userTouches[i] = os.clock()
		lastUserTouchT = os.clock()
	end
end))
bind(UIS.InputChanged:Connect(function(i)
	-- jari pemain bergeser (putar kamera / joystick)
	if i.UserInputType == Enum.UserInputType.Touch and not isInjected(i)
	and not ourHitTest(i.Position) then
		lastUserTouchT = os.clock()
	end
end))
bind(UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		if userTouches[i] then lastUserTouchT = os.clock() end
		userTouches[i] = nil
	end
end))
local function userBusy()
	local now = os.clock()
	for i, t in pairs(userTouches) do
		if now - t > 30 or i.UserInputState == Enum.UserInputState.End then
			userTouches[i] = nil
		else
			return true
		end
	end
	return false
end

local function click(pos, force)
	if not force and userBusy() then return false end -- pemain sedang menyentuh layar (force = tetap klik)
	task.spawn(function()
		lastClickT = os.clock()
		local m = CFG.ClickMode
		local cam = workspace.CurrentCamera
		local c = pos or (cam and cam.ViewportSize / 2) or Vector2.new(300, 300)
		if (m == 1 or m == 4) and not pos then
			local char = lp.Character
			local tool = char and char:FindFirstChildOfClass("Tool")
			if tool then pcall(function() tool:Activate() end) end
		end
		injectUntil, injectPos = os.clock() + 0.12, Vector2.new(c.X, c.Y)
		-- mode 1 (Semua) = otomatis: HP -> sentuh saja, PC -> mouse saja
		local useMouse = (m == 2) or (m == 1 and not MOBILE)
		local useTouch = (m == 3) or (m == 1 and MOBILE)
		if useMouse then pcall(function() UIS.MouseIconEnabled = false end) end
		if VIM then
			if useMouse then
				pcall(function() VIM:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0) end)
			end
			if useTouch then
				pcall(function() VIM:SendTouchEvent(7, 0, c.X, c.Y) end)
			end
			RunService.Heartbeat:Wait()
			if useMouse then
				pcall(function() VIM:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0) end)
			end
			if useTouch then
				pcall(function() VIM:SendTouchEvent(7, 2, c.X, c.Y) end)
			end
		end
		if useMouse then
			task.delay(0.4, function()
				if os.clock() - lastClickT > 0.35 then
					pcall(function() UIS.MouseIconEnabled = origIcon end)
				end
			end)
		end
	end)
	return true
end

-- Picu tombol langsung (firesignal / getconnections), tanpa klik layar
local function fireButton(b)
	if not (b and b:IsA("GuiButton")) then return false end
	if firesignal then
		pcall(function() firesignal(b.MouseButton1Click) end)
		pcall(function() firesignal(b.Activated) end)
		return true
	elseif getconnections then
		pcall(function()
			for _, sig in ipairs({ b.MouseButton1Click, b.Activated }) do
				for _, cn in ipairs(getconnections(sig)) do
					pcall(function() cn:Fire() end)
				end
			end
		end)
		return true
	end
	return false
end

local function pressBtn(b, alsoVirtual)
	fireButton(b)
	if alsoVirtual then click(centerOf(b), true) end
end

------------------------------------------------------------
-- Deteksi Auto Perfect
------------------------------------------------------------
local bar, indicator
local scanning, scanMsg = false, ""

local function scanBody()
	bar, indicator = nil, nil
	local all = pg:GetDescendants()
	local bars = {}
	for _, o in ipairs(all) do
		if o:IsA("GuiObject") and not ours(o) then
			local s = o.AbsoluteSize
			if s.Y > 100 and s.X > 8 and s.Y > s.X * 2.2 and visible(o) then
				bars[#bars + 1] = o
				if #bars >= 6 then break end
			end
		end
	end
	local cands = {}
	for _, b in ipairs(bars) do
		local bp, bs = b.AbsolutePosition, b.AbsoluteSize
		for _, c in ipairs(all) do
			if c ~= b and c:IsA("GuiObject") and not ours(c) and visible(c) then
				local cs, cp = c.AbsoluteSize, c.AbsolutePosition
				local cx = cp.X + cs.X / 2
				if cs.X >= bs.X * 0.5 and cs.X <= bs.X * 2.5
					and cs.Y > 2 and cs.Y < bs.Y * 0.2
					and cp.Y >= bp.Y - bs.Y * 0.2 and cp.Y <= bp.Y + bs.Y * 1.2
					and cx >= bp.X - bs.X * 0.5 and cx <= bp.X + bs.X * 1.5 then
					cands[#cands + 1] = { b = b, c = c, min = math.huge, max = -math.huge }
					if #cands >= 80 then break end
				end
			end
		end
	end
	for _ = 1, 10 do
		for _, k in ipairs(cands) do
			if k.c.Parent then
				local y = k.c.AbsolutePosition.Y
				if y < k.min then k.min = y end
				if y > k.max then k.max = y end
			end
		end
		task.wait(0.08)
	end
	local best, bestRange = nil, 0
	for _, k in ipairs(cands) do
		local r = k.max - k.min
		if r > bestRange and r > k.b.AbsoluteSize.Y * 0.05 then best, bestRange = k, r end
	end
	if best then
		bar, indicator = best.b, best.c
		scanMsg = "bar ditemukan"
		return true
	end
	scanMsg = string.format("tdk ketemu (%d/%d)", #bars, #cands)
	return false
end

local function scan()
	if scanning then return false end
	scanning = true
	local ok, res = pcall(scanBody)
	scanning = false
	if not ok then
		lastErr = "scan: " .. tostring(res)
		scanMsg = "error"
		return false
	end
	return res
end

local function ratio()
	if not (bar and indicator and bar.Parent and indicator.Parent) then return nil end
	local cy = indicator.AbsolutePosition.Y + indicator.AbsoluteSize.Y / 2
	return math.clamp((cy - bar.AbsolutePosition.Y) / bar.AbsoluteSize.Y, 0, 1)
end

local valueLabel, lastFind = nil, 0
local function readValue()
	if valueLabel and not (valueLabel.Parent and visible(valueLabel)) then valueLabel = nil end
	if not valueLabel then
		local now = os.clock()
		if now - lastFind < 0.4 then return nil end
		lastFind = now
		for _, o in ipairs(texts()) do
			if o.Parent and clean(o.Text):match("^%s*%+%s*%d+%s*$") and visible(o) then
				valueLabel = o
				break
			end
		end
	end
	if not valueLabel then return nil end
	return tonumber(clean(valueLabel.Text):match("%d+"))
end

------------------------------------------------------------
-- UI (tema Merah Kehitaman)
------------------------------------------------------------
local BG = Color3.fromRGB(10, 4, 6)
local ROW = Color3.fromRGB(28, 9, 13)
local ROW_DOWN = Color3.fromRGB(66, 14, 22)
local ACCENT = Color3.fromRGB(176, 16, 36)
local ON = Color3.fromRGB(232, 38, 54)
local OFFC = Color3.fromRGB(58, 32, 36)
local TXT = Color3.fromRGB(246, 232, 232)
local SUB = Color3.fromRGB(176, 128, 134)

local parent = pg
pcall(function()
	if gethui then
		local h = gethui()
		if h then parent = h end
	end
end)
local old = parent:FindFirstChild("NimeroHubUI")
if old then old:Destroy() end

gui = Instance.new("ScreenGui")
gui.Name = "NimeroHubUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
gui.Parent = parent

_G.AP_CLEAN = function()
	alive = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() gui:Destroy() end)
	pcall(function() UIS.MouseIconEnabled = origIcon end)
end

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
	return c
end

local function stroke(o, color, th, tr)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = th or 1
	s.Transparency = tr or 0.6
	s.Parent = o
	return s
end

local function label(parentObj, text, size, color, font, xa)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamMedium
	l.TextXAlignment = xa or Enum.TextXAlignment.Left
	l.Parent = parentObj
	return l
end

-- Bara merah (partikel halus)
local EMBER_COLORS = { Color3.fromRGB(235, 40, 52), Color3.fromRGB(170, 12, 28), Color3.fromRGB(255, 96, 104) }
local function spawnEmbers(host, count, zi, big)
	local rng = Random.new()
	for _ = 1, count do
		local e = Instance.new("Frame")
		e.AnchorPoint = Vector2.new(0.5, 0.5)
		e.BorderSizePixel = 0
		e.BackgroundTransparency = 1
		e.ZIndex = zi
		e.Position = UDim2.fromScale(0.5, 1.1)
		e.Parent = host
		corner(e, 4)
		task.spawn(function()
			task.wait(rng:NextNumber(0, 3))
			while alive and host.Parent and gui.Parent do
				if host.Visible == false then
					task.wait(0.5)
				else
					local s = big and rng:NextInteger(3, 7) or rng:NextInteger(2, 3)
					local x = rng:NextNumber(0.04, 0.96)
					local dur = rng:NextNumber(2.4, 4.6)
					e.Size = UDim2.fromOffset(s, s)
					e.BackgroundColor3 = EMBER_COLORS[rng:NextInteger(1, #EMBER_COLORS)]
					e.Position = UDim2.fromScale(x, 1.05)
					e.BackgroundTransparency = 0.2
					tw(e, dur, {
						Position = UDim2.fromScale(x + rng:NextNumber(-0.08, 0.08), rng:NextNumber(0.05, 0.5)),
						BackgroundTransparency = 1,
					}, Enum.EasingStyle.Sine)
					task.wait(dur)
				end
			end
		end)
	end
end

-- Gelembung
local BUB = 56
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.fromOffset(BUB, BUB)
bubble.Position = UDim2.fromOffset(40, 140)
bubble.BackgroundColor3 = Color3.fromRGB(20, 5, 9)
bubble.Text = "NH"
bubble.TextColor3 = Color3.fromRGB(240, 60, 72)
bubble.Font = Enum.Font.GothamBlack
bubble.TextSize = 19
bubble.AutoButtonColor = false
bubble.ZIndex = 20 -- selalu di atas panel, tidak pernah tertimpa
bubble.Parent = gui
corner(bubble, BUB / 2)
local bstroke = stroke(bubble, ON, 2.5, 0.3)
local bring = Instance.new("Frame")
bring.Size = UDim2.new(1, -10, 1, -10)
bring.Position = UDim2.fromOffset(5, 5)
bring.BackgroundTransparency = 1
bring.Parent = bubble
corner(bring, BUB)
stroke(bring, ACCENT, 1, 0.5)
local bscale = Instance.new("UIScale")
bscale.Parent = bubble

-- Panel
local PW, PH = 248, 304
local panelOpen = false
local setPanel

local panel = Instance.new("CanvasGroup")
panel.Size = UDim2.fromOffset(PW, PH)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = BG
panel.BackgroundTransparency = 1
panel.GroupTransparency = 1
panel.Visible = false
panel.Parent = gui
corner(panel, 18)
local pedge = Instance.new("Frame")
pedge.Name = "Edge"
pedge.Size = UDim2.new(1, -2, 1, -2)
pedge.Position = UDim2.fromOffset(1, 1)
pedge.BackgroundTransparency = 1
pedge.BorderSizePixel = 0
pedge.ZIndex = 50
pedge.Parent = panel
corner(pedge, 17)
local pstroke = stroke(pedge, ACCENT, 1.5, 0.5)
local pscale = Instance.new("UIScale")
pscale.Scale = 0.85
pscale.Parent = panel

-- latar: hitam -> merah gelap
local bgFrame = Instance.new("Frame")
bgFrame.Size = UDim2.fromScale(1, 1)
bgFrame.BackgroundColor3 = Color3.new(1, 1, 1)
bgFrame.BorderSizePixel = 0
bgFrame.Parent = panel
corner(bgFrame, 18)
local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 6, 11)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(12, 4, 7)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 3, 4)),
})
bgGrad.Rotation = 90
bgGrad.Parent = bgFrame

-- cahaya merah lembut di dasar (ikut terpotong sudut panel)
local glow = Instance.new("Frame")
glow.Size = UDim2.new(1, 0, 0, 110)
glow.Position = UDim2.new(0, 0, 1, -110)
glow.BackgroundColor3 = ACCENT
glow.BorderSizePixel = 0
glow.Parent = panel
corner(glow, 18)
local glowGrad = Instance.new("UIGradient")
glowGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(1, 0.6),
})
glowGrad.Rotation = 90
glowGrad.Parent = glow

spawnEmbers(panel, 8, 1, false)

-- header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = Color3.new(1, 1, 1)
header.BorderSizePixel = 0
header.Active = true
header.Parent = panel
local hGrad = Instance.new("UIGradient")
hGrad.Color = ColorSequence.new(Color3.fromRGB(128, 10, 24), Color3.fromRGB(20, 4, 8))
hGrad.Parent = header
corner(header, 18)
local hfill = Instance.new("Frame") -- menutup sudut bawah header supaya tetap rata
hfill.Size = UDim2.new(1, 0, 0, 24)
hfill.Position = UDim2.new(0, 0, 1, -24)
hfill.BackgroundColor3 = Color3.new(1, 1, 1)
hfill.BorderSizePixel = 0
hfill.ZIndex = 0
hfill.Parent = header
local hfGrad = Instance.new("UIGradient")
hfGrad.Color = ColorSequence.new(Color3.fromRGB(128, 10, 24), Color3.fromRGB(20, 4, 8))
hfGrad.Parent = hfill

local hline = Instance.new("Frame")
hline.Size = UDim2.new(1, 0, 0, 2)
hline.Position = UDim2.new(0, 0, 1, -2)
hline.BackgroundColor3 = ON
hline.BorderSizePixel = 0
hline.Parent = header
local hlGrad = Instance.new("UIGradient")
hlGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(1, 1),
})
hlGrad.Parent = hline

local ptitle = label(header, "NimeroHub", 16, Color3.new(1, 1, 1), Enum.Font.Michroma)
ptitle.Size = UDim2.new(1, -100, 0, 22)
ptitle.Position = UDim2.fromOffset(14, 5)
local tgrad = Instance.new("UIGradient")
tgrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 128)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 236, 236)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 128)),
})
tgrad.Parent = ptitle
local psub = label(header, "BERIMAKAN HEWAN", 10, SUB, Enum.Font.GothamBold)
psub.Size = UDim2.new(1, -100, 0, 14)
psub.Position = UDim2.fromOffset(15, 26)

local SUB_BASE = "BERIMAKAN HEWAN"
local subUntil = 0
local function setSub(text, secs)
	psub.Text = text
	subUntil = os.clock() + (secs or 4)
end
loop("sub", 0.5, function()
	if psub.Text ~= SUB_BASE and os.clock() > subUntil then psub.Text = SUB_BASE end
end)

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(9, 9)
dot.Position = UDim2.new(1, -68, 0.5, -4)
dot.BackgroundColor3 = OFFC
dot.Parent = header
corner(dot, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -40, 0.5, -14)
closeBtn.BackgroundColor3 = ROW_DOWN
closeBtn.Text = "✕"
closeBtn.TextColor3 = TXT
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
corner(closeBtn, 9)
stroke(closeBtn, ON, 1, 0.6)
closeBtn.MouseButton1Click:Connect(function()
	if setPanel then setPanel(false) end
end)

local FONT_TITLE = Enum.Font.Michroma -- judul: futuristik
local FONT_ROW = Enum.Font.Oswald       -- nama fitur: tegas & ramping
local FONT_TAG = Enum.Font.GothamBlack  -- label kecil ON/OFF

local function pressable(row)
	row.MouseButton1Down:Connect(function() tw(row, 0.08, { BackgroundColor3 = ROW_DOWN }) end)
	local function up() tw(row, 0.18, { BackgroundColor3 = ROW }) end
	row.MouseButton1Up:Connect(up)
	row.MouseLeave:Connect(up)
end

------------------------------------------------------------
-- Efek suara (bawaan Roblox, tanpa unduhan) & notifikasi
------------------------------------------------------------
local SoundService = game:GetService("SoundService")
local function sfx(id, vol, speed)
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = id
		snd.Volume = vol or 0.5
		snd.PlaybackSpeed = speed or 1
		snd.Parent = SoundService
		snd.Ended:Connect(function() snd:Destroy() end)
		snd:Play()
		task.delay(3, function() if snd.Parent then snd:Destroy() end end)
	end)
end
local function sfxToggle(on)
	if on then
		sfx("rbxasset://sounds/switch.wav", 0.6, 1.35)
		task.delay(0.07, function() sfx("rbxasset://sounds/button.wav", 0.35, 1.6) end)
	else
		sfx("rbxasset://sounds/switch.wav", 0.5, 0.8)
	end
end

-- Notifikasi kotak (muncul dari atas, menumpuk maks 3, hilang sendiri)
local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Position = UDim2.new(0.5, 0, 0, 46)
toastHolder.Size = UDim2.fromOffset(250, 200)
toastHolder.BackgroundTransparency = 1
toastHolder.ZIndex = 100
toastHolder.Parent = gui
local tl = Instance.new("UIListLayout")
tl.Padding = UDim.new(0, 8)
tl.SortOrder = Enum.SortOrder.LayoutOrder
tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
tl.Parent = toastHolder

local toastN, toastLive = 0, {}
local function dismissToast(t)
	if not t or t.gone then return end
	t.gone = true
	tw(t.card, 0.25, { GroupTransparency = 1 })
	tw(t.slide, 0.25, { Position = UDim2.fromOffset(0, -18) }, Enum.EasingStyle.Quad)
	task.delay(0.28, function() pcall(function() t.wrap:Destroy() end) end)
end

local function toast(title, on)
	-- notifikasi lama untuk fitur yang sama diganti
	local old = toastLive[title]
	if old then dismissToast(old) end
	local live = 0
	for _, t in pairs(toastLive) do if not t.gone then live += 1 end end
	if live >= 3 then
		for k, t in pairs(toastLive) do
			if not t.gone then dismissToast(t) toastLive[k] = nil break end
		end
	end

	toastN += 1
	local col = on and ON or Color3.fromRGB(128, 96, 100)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.fromOffset(250, 46)
	wrap.BackgroundTransparency = 1
	wrap.LayoutOrder = toastN
	wrap.Parent = toastHolder

	local slide = Instance.new("Frame") -- dipakai untuk gerak masuk/keluar
	slide.Size = UDim2.fromScale(1, 1)
	slide.Position = UDim2.fromOffset(0, -26)
	slide.BackgroundTransparency = 1
	slide.Parent = wrap

	local card = Instance.new("CanvasGroup")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundTransparency = 1
	card.GroupTransparency = 1
	card.Parent = slide
	corner(card, 12)
	local cbg = Instance.new("Frame") -- latar terpisah (gradient di CanvasGroup menggelapkan isinya)
	cbg.Size = UDim2.fromScale(1, 1)
	cbg.BackgroundColor3 = Color3.new(1, 1, 1)
	cbg.BorderSizePixel = 0
	cbg.ZIndex = 0
	cbg.Parent = card
	corner(cbg, 12)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(44, 10, 16), Color3.fromRGB(12, 4, 7))
	g.Rotation = 0
	g.Parent = cbg

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 4, 1, -16)
	bar.Position = UDim2.fromOffset(7, 8)
	bar.BackgroundColor3 = col
	bar.BorderSizePixel = 0
	bar.Parent = card
	corner(bar, 2)

	local ic = Instance.new("Frame")
	ic.Size = UDim2.fromOffset(26, 26)
	ic.Position = UDim2.new(0, 22, 0.5, -13)
	ic.BackgroundColor3 = col
	ic.Parent = card
	corner(ic, 13)
	local icl = label(ic, on and "✓" or "✕", 15, Color3.new(1, 1, 1), Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	icl.Size = UDim2.fromScale(1, 1)

	local t1 = label(card, title, 17, TXT, FONT_ROW)
	t1.Size = UDim2.new(1, -68, 0, 20)
	t1.Position = UDim2.fromOffset(58, 5)
	t1.TextTruncate = Enum.TextTruncate.AtEnd
	local t2 = label(card, on and "AKTIF" or "NONAKTIF", 9, col, FONT_TAG)
	t2.Size = UDim2.new(1, -68, 0, 12)
	t2.Position = UDim2.fromOffset(58, 26)

	local life = Instance.new("Frame") -- garis waktu di dasar kotak
	life.AnchorPoint = Vector2.new(0, 0)
	life.Size = UDim2.new(1, -28, 0, 2)
	life.Position = UDim2.new(0, 14, 1, -5)
	life.BackgroundColor3 = col
	life.BorderSizePixel = 0
	life.Parent = card

	local edge = Instance.new("Frame")
	edge.Size = UDim2.new(1, -2, 1, -2)
	edge.Position = UDim2.fromOffset(1, 1)
	edge.BackgroundTransparency = 1
	edge.ZIndex = 5
	edge.Parent = card
	corner(edge, 11)
	stroke(edge, col, 1.2, 0.45)

	local t = { wrap = wrap, slide = slide, card = card, gone = false }
	toastLive[title] = t

	tw(card, 0.25, { GroupTransparency = 0 })
	tw(slide, 0.38, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	ic.Size = UDim2.fromOffset(12, 12)
	ic.Position = UDim2.new(0, 22, 0.5, -6)
	tw(ic, 0.45, { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0, 22, 0.5, -13) }, Enum.EasingStyle.Back)
	tw(life, 2.4, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	task.delay(2.4, function() dismissToast(t) end)
end

local function makeSwitch(text, y, get, set)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -24, 0, 34)
	row.Position = UDim2.new(0, 12, 0, y)
	row.BackgroundColor3 = ROW
	row.Text = ""
	row.AutoButtonColor = false
	row.Parent = panel
	corner(row, 10)
	local rstroke = stroke(row, ACCENT, 1, 0.6)
	pressable(row)

	-- sorot merah lembut dari kiri saat aktif
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = ON
	fill.BackgroundTransparency = 1
	fill.BorderSizePixel = 0
	fill.Parent = row
	corner(fill, 10)
	local fg = Instance.new("UIGradient")
	fg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	fg.Parent = fill

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.fromOffset(3, 16)
	accentBar.Position = UDim2.new(0, 5, 0.5, -8)
	accentBar.BackgroundColor3 = OFFC
	accentBar.BorderSizePixel = 0
	accentBar.Parent = row
	corner(accentBar, 2)

	local lb = label(row, text, 17, TXT, FONT_ROW)
	lb.Size = UDim2.new(1, -108, 1, 0)
	lb.Position = UDim2.fromOffset(16, 0)
	local tag = label(row, "OFF", 8, SUB, FONT_TAG, Enum.TextXAlignment.Right)
	tag.Size = UDim2.fromOffset(30, 34)
	tag.Position = UDim2.new(1, -86, 0, 0)

	local track = Instance.new("Frame")
	track.Size = UDim2.fromOffset(40, 22)
	track.Position = UDim2.new(1, -52, 0.5, -11)
	track.BackgroundColor3 = OFFC
	track.Parent = row
	corner(track, 11)
	local tstroke = stroke(track, ON, 1.5, 1)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = UDim2.new(0, 3, 0.5, -8)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.Parent = track
	corner(knob, 8)

	local first = true
	local function render()
		local on = get()
		local d = first and 0 or 0.22
		tw(track, d, { BackgroundColor3 = on and ON or OFFC })
		tw(tstroke, d, { Transparency = on and 0.35 or 1 })
		tw(fill, d + 0.1, { BackgroundTransparency = on and 0 or 1 })
		tw(accentBar, d, { BackgroundColor3 = on and ON or OFFC, Size = UDim2.fromOffset(3, on and 22 or 16), Position = UDim2.new(0, 5, 0.5, on and -11 or -8) })
		tw(rstroke, d, { Color = on and ON or ACCENT, Transparency = on and 0.3 or 0.6 })
		tw(lb, d, { TextColor3 = on and Color3.new(1, 1, 1) or TXT })
		tw(tag, d, { TextColor3 = on and ON or SUB })
		tag.Text = on and "ON" or "OFF"
		if first then
			knob.Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
		else
			-- knob melar lalu mengecil (efek cair)
			knob.Size = UDim2.fromOffset(22, 16)
			tw(knob, 0.3, { Size = UDim2.fromOffset(16, 16), Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, Enum.EasingStyle.Back)
		end
		first = false
	end
	row.MouseButton1Click:Connect(function()
		set(not get())
		render()
		local on = get()
		sfxToggle(on)
		toast(text, on)
		-- kedip singkat pada baris
		row.BackgroundColor3 = on and ROW_DOWN or ROW
		tw(row, 0.35, { BackgroundColor3 = ROW })
	end)
	render()
	return render, row
end

------------------------------------------------------------
-- HUD atas tengah: FPS | jumlah pemain | jam
------------------------------------------------------------
do
	local hud = Instance.new("CanvasGroup")
	hud.Name = "InfoHUD"
	hud.AnchorPoint = Vector2.new(0.5, 0)
	hud.Position = UDim2.new(0.5, 0, 0, 8)
	hud.Size = UDim2.fromOffset(264, 28)
	hud.BackgroundTransparency = 1
	hud.GroupTransparency = 1
	hud.ZIndex = 90
	hud.Parent = gui
	corner(hud, 14)
	-- latar di frame terpisah: UIGradient di CanvasGroup akan menggelapkan SEMUA isinya (teks jadi tak terlihat)
	local hbg = Instance.new("Frame")
	hbg.Size = UDim2.fromScale(1, 1)
	hbg.BackgroundColor3 = Color3.new(1, 1, 1)
	hbg.BorderSizePixel = 0
	hbg.ZIndex = 0
	hbg.Parent = hud
	corner(hbg, 14)
	local hg = Instance.new("UIGradient")
	hg.Color = ColorSequence.new(Color3.fromRGB(40, 9, 15), Color3.fromRGB(12, 4, 7))
	hg.Parent = hbg

	local hedge = Instance.new("Frame")
	hedge.Size = UDim2.new(1, -2, 1, -2)
	hedge.Position = UDim2.fromOffset(1, 1)
	hedge.BackgroundTransparency = 1
	hedge.ZIndex = 95
	hedge.Parent = hud
	corner(hedge, 13)
	stroke(hedge, ON, 1.2, 0.5)

	-- tiga kolom sama lebar + pemisah tipis
	local function cell(i, ico)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1 / 3, 0, 1, 0)
		f.Position = UDim2.new((i - 1) / 3, 0, 0, 0)
		f.BackgroundTransparency = 1
		f.Parent = hud
		local ic = label(f, ico, 9, SUB, FONT_TAG, Enum.TextXAlignment.Left)
		ic.Size = UDim2.fromOffset(26, 28)
		ic.Position = UDim2.fromOffset(10, 0)
		local val = label(f, "-", 12, TXT, FONT_ROW, Enum.TextXAlignment.Right)
		val.Size = UDim2.new(1, -40, 1, 0)
		val.Position = UDim2.fromOffset(30, 0)
		if i > 1 then
			local sep = Instance.new("Frame")
			sep.Size = UDim2.fromOffset(1, 14)
			sep.Position = UDim2.new(0, 0, 0.5, -7)
			sep.BackgroundColor3 = ON
			sep.BackgroundTransparency = 0.6
			sep.BorderSizePixel = 0
			sep.Parent = f
		end
		return val
	end
	local fpsV = cell(1, "FPS")
	local plrV = cell(2, "PLR")
	local clkV = cell(3, "JAM")

	tw(hud, 0.5, { GroupTransparency = 0 })

	-- FPS: hitung frame tiap 0.5 detik, dihaluskan
	local frames, tAcc, fps = 0, 0, 60
	bind(RunService.RenderStepped:Connect(function(dt)
		frames += 1
		tAcc += dt
		if tAcc >= 0.5 then
			local cur = frames / tAcc
			fps = fps * 0.5 + cur * 0.5
			frames, tAcc = 0, 0
			local f = math.floor(fps + 0.5)
			fpsV.Text = tostring(f)
			local col = f >= 50 and Color3.fromRGB(110, 235, 140)
				or (f >= 30 and Color3.fromRGB(255, 200, 80) or ON)
			tw(fpsV, 0.3, { TextColor3 = col })
		end
	end))

	loop("hud", 0.5, function()
		local n = #Players:GetPlayers()
		plrV.Text = n .. "/" .. tostring(Players.MaxPlayers)
		clkV.Text = os.date("%H:%M:%S")
	end)
end

local function refreshBubble()
	local active = CFG.Enabled or CFG.AutoFarm or CFG.AutoX2
	tw(bubble, 0.25, {
		BackgroundColor3 = active and ACCENT or Color3.fromRGB(20, 5, 9),
		TextColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(240, 60, 72),
	})
	tw(dot, 0.25, { BackgroundColor3 = active and ON or OFFC })
end

makeSwitch("Auto Perfect", 58, function() return CFG.Enabled end, function(v)
	CFG.Enabled = v
	refreshBubble()
end)
makeSwitch("Auto Farm", 98, function() return CFG.AutoFarm end, function(v)
	CFG.AutoFarm = v
	CFG.FarmKick = v
	refreshBubble()
end)
makeSwitch("Auto Click x2", 138, function() return CFG.AutoX2 end, function(v)
	CFG.AutoX2 = v
	refreshBubble()
end)
-- label status disimpan tersembunyi (dipakai logika fitur di bawah)
local statusHost = Instance.new("Frame")
statusHost.Visible = false
statusHost.Size = UDim2.fromOffset(10, 10)
statusHost.BackgroundTransparency = 1
statusHost.Parent = panel
local status = label(statusHost, "Status: siap", 11, SUB)
local status2 = label(statusHost, "", 11, SUB)
local farmMsg = ""

-- kartu profil: avatar pemain + watermark TikTok
local card = Instance.new("Frame")
card.Size = UDim2.new(1, -24, 0, 108)
card.Position = UDim2.new(0, 12, 0, 184)
card.BackgroundColor3 = Color3.fromRGB(5, 2, 3)
card.BackgroundTransparency = 0.15
card.Parent = panel
corner(card, 10)
stroke(card, ACCENT, 1, 0.65)

local AV = 52
local avRing = Instance.new("Frame")
avRing.AnchorPoint = Vector2.new(0.5, 0)
avRing.Position = UDim2.new(0.5, 0, 0, 8)
avRing.Size = UDim2.fromOffset(AV, AV)
avRing.BackgroundColor3 = Color3.fromRGB(14, 4, 7)
avRing.Parent = card
corner(avRing, AV)
local ringStroke = stroke(avRing, Color3.new(1, 1, 1), 2.5, 0)
local ringGrad = Instance.new("UIGradient")
ringGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(254, 44, 85)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(37, 244, 238)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(254, 44, 85)),
})
ringGrad.Parent = ringStroke

local av = Instance.new("ImageLabel")
av.AnchorPoint = Vector2.new(0.5, 0.5)
av.Position = UDim2.fromScale(0.5, 0.5)
av.Size = UDim2.new(1, -8, 1, -8)
av.BackgroundColor3 = Color3.fromRGB(30, 8, 12)
av.BorderSizePixel = 0
av.Image = ""
av.Parent = avRing
corner(av, AV)
task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and img then av.Image = img end
end)

-- watermark TikTok: lapisan cyan + merah (gaya glitch TikTok) + teks utama
local WM = "@aanantamng"
local function wmLayer(color, dx, z, tr)
	local l = label(card, WM, 15, color, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Position = UDim2.new(0.5, dx, 0, 66)
	l.Size = UDim2.new(1, -10, 0, 20)
	l.ZIndex = z
	l.TextTransparency = tr or 0
	return l
end
local wmCyan = wmLayer(Color3.fromRGB(37, 244, 238), -1.5, 2, 0.1)
local wmRed = wmLayer(Color3.fromRGB(254, 44, 85), 1.5, 3, 0.1)
local wmMain = wmLayer(Color3.new(1, 1, 1), 0, 4, 0)
local wmGrad = Instance.new("UIGradient")
wmGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 172)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
})
wmGrad.Parent = wmMain

local wmTag = label(card, "T I K T O K", 9, SUB, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
wmTag.AnchorPoint = Vector2.new(0.5, 0)
wmTag.Position = UDim2.new(0.5, 0, 0, 88)
wmTag.Size = UDim2.new(1, -14, 0, 12)
wmTag.TextTruncate = Enum.TextTruncate.AtEnd

-- animasi: cincin avatar berputar, teks berkilau, glitch sesekali
task.spawn(function()
	while alive and gui.Parent do
		ringGrad.Rotation = 0
		tw(ringGrad, 2.4, { Rotation = 360 }, Enum.EasingStyle.Linear)
		task.wait(2.4)
	end
end)
task.spawn(function()
	while alive and gui.Parent do
		wmGrad.Offset = Vector2.new(-1, 0)
		tw(wmGrad, 1.8, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine)
		task.wait(2.2)
	end
end)
task.spawn(function()
	local rng = Random.new()
	while alive and gui.Parent do
		task.wait(rng:NextNumber(2, 3.5))
		for _ = 1, 6 do
			wmCyan.Position = UDim2.new(0.5, rng:NextInteger(-5, 1), 0, 66 + rng:NextInteger(-1, 1))
			wmRed.Position = UDim2.new(0.5, rng:NextInteger(-1, 5), 0, 66 + rng:NextInteger(-1, 1))
			task.wait(0.04)
		end
		wmCyan.Position = UDim2.new(0.5, -1.5, 0, 66)
		wmRed.Position = UDim2.new(0.5, 1.5, 0, 66)
	end
end)

-- Posisi panel & buka/tutup
-- skala agar panel selalu muat di layar (HP landscape tingginya pendek)
local function panelFit()
	local vs = workspace.CurrentCamera.ViewportSize
	return math.clamp((vs.Y - 12) / PH, 0.6, 1)
end

-- bx/by (opsional) = posisi tujuan gelembung; dipakai saat gelembung sedang digeser
local function placePanel(animate, bx, by)
	local vs = workspace.CurrentCamera.ViewportSize
	local fit = panelFit()
	local pw, ph = PW * fit, PH * fit
	local bp = (bx and by) and Vector2.new(bx, by) or bubble.AbsolutePosition
	local gap = 32 -- jarak panel ke gelembung
	local m = 6

	local rightX = bp.X + BUB + gap
	local leftX = bp.X - pw - gap
	local function fitsX(px) return px >= m and px + pw <= vs.X - m end

	local first, second = rightX, leftX
	if (bp.X + BUB / 2) >= vs.X / 2 then first, second = leftX, rightX end

	local x, y
	local sideOk = true
	if fitsX(first) then
		x = first
	elseif fitsX(second) then
		x = second
	else
		sideOk = false
		x = math.clamp(bp.X + BUB / 2 - pw / 2, m, math.max(m, vs.X - pw - m))
	end

	if sideOk then
		y = math.clamp(bp.Y + BUB / 2 - ph / 2, m, math.max(m, vs.Y - ph - m))
	else
		-- tidak muat di samping: taruh di bawah / atas gelembung
		local below = bp.Y + BUB + gap
		local above = bp.Y - ph - gap
		if below + ph <= vs.Y - m then
			y = below
		elseif above >= m then
			y = above
		else
			y = math.clamp(below, m, math.max(m, vs.Y - ph - m))
		end
	end

	local target = UDim2.fromOffset(x + pw / 2, y + ph / 2)
	if animate and panel.Visible then
		tw(panel, 0.22, { Position = target }, Enum.EasingStyle.Quad)
	else
		panel.Position = target
	end
end

local GAP_MIN = 28
local function ensureGap(animate)
	if not panelOpen or not panel.Visible then return end
	local bp, bs = bubble.AbsolutePosition, bubble.AbsoluteSize
	local pp, ps = panel.AbsolutePosition, panel.AbsoluteSize
	local overlapY = pp.Y < bp.Y + bs.Y + GAP_MIN and pp.Y + ps.Y > bp.Y - GAP_MIN
	if not overlapY then return end
	local vs = workspace.CurrentCamera.ViewportSize
	local panelRight = (pp.X + ps.X / 2) >= (bp.X + bs.X / 2)
	local dx = 0
	if panelRight then
		dx = math.max(0, (bp.X + bs.X + GAP_MIN) - pp.X)
	else
		dx = -math.max(0, (pp.X + ps.X) - (bp.X - GAP_MIN))
	end
	if dx == 0 then return end
	local newLeft = math.clamp(pp.X + dx, 6, math.max(6, vs.X - ps.X - 6))
	dx = newLeft - pp.X
	if math.abs(dx) < 0.5 then return end
	local cur = panel.Position
	local target = UDim2.fromOffset(cur.X.Offset + dx, cur.Y.Offset)
	if animate then
		tw(panel, 0.2, { Position = target }, Enum.EasingStyle.Quad)
	else
		panel.Position = target
	end
end

setPanel = function(open)
	panelOpen = open
	sfx("rbxasset://sounds/button.wav", 0.3, open and 1.4 or 1)
	if open then
		placePanel()
		panel.Visible = true
		tw(panel, 0.22, { GroupTransparency = 0 })
		tw(pscale, 0.28, { Scale = panelFit() }, Enum.EasingStyle.Back)
		task.delay(0.4, function() ensureGap(true) end)
	else
		tw(panel, 0.16, { GroupTransparency = 1 })
		tw(pscale, 0.16, { Scale = 0.85 * panelFit() })
		task.delay(0.17, function()
			if not panelOpen then panel.Visible = false end
		end)
	end
end

-- layar berputar / ukuran berubah: tata ulang panel supaya tidak menimpa gelembung
do
	local cam = workspace.CurrentCamera
	if cam then
		bind(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if panelOpen then
				tw(pscale, 0.2, { Scale = panelFit() })
				placePanel(true)
			end
		end))
	end
end

-- sentuhan di atas gelembung/panel = sentuhan UI, bukan pemain menggerakkan karakter
ourHitTest = function(pos)
	local ins = Vector2.zero
	pcall(function() ins = GuiService:GetGuiInset() end)
	local q1 = Vector2.new(pos.X, pos.Y)
	local q2 = Vector2.new(pos.X + ins.X, pos.Y + ins.Y)
	local function inside(g, q)
		if not (g and g.Parent and g.Visible) then return false end
		local a, sz, pad = g.AbsolutePosition, g.AbsoluteSize, 12
		return q.X >= a.X - pad and q.X <= a.X + sz.X + pad and q.Y >= a.Y - pad and q.Y <= a.Y + sz.Y + pad
	end
	return inside(bubble, q1) or inside(bubble, q2) or inside(panel, q1) or inside(panel, q2)
end

-- Drag gelembung (bebas di mana saja), tap = buka/tutup
do
	local dragging, moved, startIn, startPos = false, false, nil, nil
	bubble.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, moved = true, false
			startIn = i.Position
			startPos = bubble.Position
			tw(bscale, 0.1, { Scale = 0.9 })
		end
	end)
	bind(UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startIn
			if d.Magnitude > 8 then moved = true end
			if moved then
				local nx, ny = startPos.X.Offset + d.X, startPos.Y.Offset + d.Y
				bubble.Position = UDim2.fromOffset(nx, ny)
				if panelOpen then placePanel(false, nx, ny) end
			end
		end
	end))
	bind(UIS.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false
			tw(bscale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
			if moved then
				-- tetap di tempat dilepas (hanya dijaga agar tidak keluar layar)
				local vs = workspace.CurrentCamera.ViewportSize
				local p = bubble.AbsolutePosition
				local tx = math.clamp(p.X, 4, math.max(4, vs.X - BUB - 4))
				local ty = math.clamp(p.Y, 4, math.max(4, vs.Y - BUB - 4))
				if tx ~= p.X or ty ~= p.Y then
					tw(bubble, 0.15, { Position = UDim2.fromOffset(tx, ty) })
				end
				if panelOpen then
					placePanel(true, tx, ty)
					task.delay(0.45, function() ensureGap(true) end)
				end
			else
				setPanel(not panelOpen)
			end
		end
	end))
end

-- Panel mengikuti gelembung (tidak digeser manual, supaya tidak menimpa gelembung)

-- Animasi napas
task.spawn(function()
	while alive and gui.Parent do
		local active = CFG.Enabled or CFG.AutoFarm or CFG.AutoX2
		tw(bstroke, 0.9, { Thickness = active and 4.5 or 3, Transparency = active and 0.1 or 0.3 }, Enum.EasingStyle.Sine)
		tw(pstroke, 0.9, { Thickness = 2, Transparency = 0.2 }, Enum.EasingStyle.Sine)
		tw(glow, 0.9, { BackgroundTransparency = 0.25 }, Enum.EasingStyle.Sine)
		tw(tgrad, 0.9, { Offset = Vector2.new(0.4, 0) }, Enum.EasingStyle.Sine)
		task.wait(0.9)
		tw(bstroke, 0.9, { Thickness = 2, Transparency = 0.5 }, Enum.EasingStyle.Sine)
		tw(pstroke, 0.9, { Thickness = 1.5, Transparency = 0.5 }, Enum.EasingStyle.Sine)
		tw(glow, 0.9, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
		tw(tgrad, 0.9, { Offset = Vector2.new(-0.4, 0) }, Enum.EasingStyle.Sine)
		task.wait(0.9)
	end
end)

------------------------------------------------------------
-- Auto Farm
------------------------------------------------------------
local FARM_PAUSE = 2 -- detik jeda setelah pemain menggerakkan karakter sendiri
local farmPauseUntil = 0
local farmFixes = {} -- waktu koreksi terakhir (deteksi tarik-tarikan dengan server)

loop("farm", 0.2, function()
	if not CFG.AutoFarm then
		farmPauseUntil = 0
		farmFixes = {}
		return
	end
	if CFG.FarmKick then
		CFG.FarmKick = false
		farmPauseUntil = 0
		farmFixes = {}
	end

	local char = lp.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hrp and hum and hum.Health > 0 and char:IsDescendantOf(workspace)) then return end

	local now = os.clock()
	-- pemain menggerakkan karakter sendiri -> jangan ditarik balik sebentar
	if hum.MoveDirection.Magnitude > 0.1 or userBusy() then
		farmPauseUntil = now + FARM_PAUSE
	end
	if now < farmPauseUntil then return end
	if (hrp.Position - CFG.FarmPos).Magnitude <= CFG.FarmRadius then return end

	-- kalau server terus mengembalikan karakter, istirahat 4 detik supaya tidak spam teleport
	for i = #farmFixes, 1, -1 do
		if now - farmFixes[i] > 10 then table.remove(farmFixes, i) end
	end
	if #farmFixes >= 10 then
		farmPauseUntil = now + 4
		farmFixes = {}
		return
	end
	farmFixes[#farmFixes + 1] = now

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	char:PivotTo(CFrame.new(CFG.FarmPos) * (hrp.CFrame - hrp.CFrame.Position))
end)

------------------------------------------------------------
-- Auto Perfect
------------------------------------------------------------
local pv, pt, rate = nil, nil, 0
local armed, lastClick, lastScan = true, 0, 0

local function perfectStep()
	if not CFG.Enabled then return end
	local now = os.clock()
	local v = readValue()

	if valueLabel and v then
		if v ~= pv then
			if pv and pt and now - pt < 0.6 then
				rate = rate * 0.5 + ((v - pv) / (now - pt)) * 0.5
			end
			pv, pt = v, now
		end
		local r = (pt and now - pt < 0.2) and rate or 0
		local predicted = v + math.max(r, 0) * CFG.Lead

		if not armed and (v < CFG.Target - 2 or now - lastClick > 2.5) then armed = true end
		status.Text = string.format("+%d / %d  %s", v, CFG.Target, armed and "siap" or "tunggu")

		if armed and predicted >= CFG.Target and now - lastClick > CFG.Cooldown then
			armed, lastClick = false, now
			click(nil, true)
		end
		return
	end

	-- Cadangan: posisi penunjuk bar
	if not (bar and bar.Parent and visible(bar)) then
		if not scanning and now - lastScan > 2 then
			lastScan = now
			task.spawn(scan)
		end
		status.Text = scanning and "Scan..." or "Menunggu bar"
		return
	end
	local rr = ratio()
	if not rr then return end
	status.Text = string.format("Posisi %.0f%%", rr * 100)
	if not armed and (rr > CFG.ZoneMax + 0.2 or now - lastClick > 2.5) then armed = true end
	if armed and rr >= CFG.ZoneMin and rr <= CFG.ZoneMax and now - lastClick > CFG.Cooldown then
		armed, lastClick = false, now
		click(nil, true)
	end
end

bind(RunService.RenderStepped:Connect(function()
	local ok, err = pcall(perfectStep)
	if not ok then lastErr = "perfect: " .. tostring(err) end
end))

-- Auto "Klik untuk melanjutkan"
local lastCont = 0
loop("lanjut", 0.3, function()
	if not CFG.Enabled then return end
	local l = findText(function(raw)
		return raw:find("melanjutkan", 1, true) ~= nil or raw:find("to continue", 1, true) ~= nil
			or raw:find("tap to continue", 1, true) ~= nil
	end)
	if l and os.clock() - lastCont > 0.8 then
		lastCont = os.clock()
		local b = l:IsA("GuiButton") and l or l:FindFirstAncestorWhichIsA("GuiButton")
		if b then fireButton(b) end
		click(nil, true)
		armed, pv, rate = true, nil, 0
	end
end)

------------------------------------------------------------
-- Auto Click x2
------------------------------------------------------------
local x2Btn = nil
local function findX2()
	if x2Btn and x2Btn.Parent and visible(x2Btn) and x2Btn.AbsoluteSize.X > 0 then return x2Btn end
	x2Btn = nil
	local o = findText(function(raw)
		local t = raw:gsub("%s", "")
		return t == "x2" or t == "2x" or t == "\195\1512" or t == "2\195\151"
	end)
	if o then
		x2Btn = clickableFor(o)
		return x2Btn
	end
	return nil
end

-- Tap Bonus: PlayerGui.TrainingSequence.TapBonusLayer
-- Hanya diklik kalau layernya ADA dan sedang terlihat; kalau tidak ada, tidak melakukan apa-apa.
local function findTapBonus()
	local seq = pg:FindFirstChild("TrainingSequence")
	local layer = seq and seq:FindFirstChild("TapBonusLayer", true)
	if not (layer and layer:IsA("GuiObject")) then return nil end
	if not visible(layer) or layer.AbsoluteSize.X <= 0 or layer.AbsoluteSize.Y <= 0 then return nil end
	return layer
end

loop("x2", 0.12, function()
	if CFG.AutoX2 then
		local bonus = findTapBonus()
		if bonus then
			-- layar bonus muncul -> langsung tap (tombol di dalamnya dipicu, lalu tap di tengah layer)
			local b = bonus:IsA("GuiButton") and bonus or bonus:FindFirstChildWhichIsA("GuiButton", true)
			if b and visible(b) then fireButton(b) end
			click(centerOf(bonus), true)
			status2.Text = "Tap Bonus aktif"
			return
		end

		local b = findX2()
		if b then
			-- x2 tetap jalan walau layar sedang disentuh / digeser (force = true)
			click(centerOf(b), true)
			status2.Text = "Klik x2 aktif"
		else
			status2.Text = "Menunggu tombol x2"
		end
	else
		status2.Text = farmMsg
	end
end)

-- baris info di kartu profil: tampilkan error
task.spawn(function()
	while alive and gui.Parent do
		task.wait(0.4)
		local msg = ""
		if lastErr ~= "" then
			msg = "! " .. lastErr
		end
		if msg ~= "" then
			wmTag.Text = msg
			wmTag.TextColor3 = ON
		else
			wmTag.Text = "T I K T O K"
			wmTag.TextColor3 = SUB
		end
	end
end)

refreshBubble()

------------------------------------------------------------
-- Intro NimeroHub (layar penuh, merah kehitaman) + suara + efek ketukan
------------------------------------------------------------
-- Garis waktu (detik) dipakai bersama oleh suara dan animasi agar selalu sinkron
local TL = {
	knock = { 0.30, 0.62, 0.94 },   -- tok, tok, TOK
	riserA = 1.05, riserB = 2.10,   -- ketegangan naik
	letter = 1.20, gap = 0.07,      -- huruf jatuh (tick per huruf)
	impact = 2.10,                  -- benturan + glitch
	sub = 2.70,
	steps = { 2.90, 3.40, 3.90, 4.40, 4.90 }, -- loading (tick naik nada)
	exit = 5.45,                    -- whoosh pintu terbuka
	total = 6.6,
}

-- Sintesis suara intro sendiri (tanpa aset Roblox) -> file WAV
local SR = 22050
local function synthIntro()
	local N = math.floor(SR * TL.total)
	local buf = table.create(N, 0)
	local rng = Random.new(7)
	local sin, exp, floor, abs, pi = math.sin, math.exp, math.floor, math.abs, math.pi
	local counter = 0
	local function tick() counter += 1 if counter % 9000 == 0 then task.wait() end end
	local function noise() return rng:NextNumber() * 2 - 1 end

	local function add(t0, dur, fn)
		local s = floor(t0 * SR) + 1
		for k = 0, floor(dur * SR) - 1 do
			local idx = s + k
			if idx > N then break end
			buf[idx] = buf[idx] + fn(k / SR)
			tick()
		end
	end
	local function sweepPhase(f0, f1, d, t)
		if t > d then t = d end
		local k = math.log(f1 / f0)
		return 2 * pi * f0 * d / k * (exp(k * t / d) - 1)
	end

	-- ketukan kayu/pintu: dentum rendah + ketukan tajam
	local function knock(t0, vol)
		add(t0, 0.4, function(t)
			local body = sin(2 * pi * (58 * t + 3.667 * (1 - exp(-30 * t)))) * exp(-t * 13)
			local wood = sin(2 * pi * 340 * t) * exp(-t * 38) * 0.4
			local click = noise() * exp(-t * 420) * 0.5
			return (body * 0.95 + wood + click) * vol
		end)
	end

	-- naik: sapuan nada + desis yang makin terbuka
	local function riser(t0, t1)
		local d, lp = t1 - t0, 0
		add(t0, d, function(t)
			local u = t / d
			lp = lp + (0.05 + 0.6 * u) * (noise() - lp)
			local tone = sin(sweepPhase(110, 880, d, t)) * (u * u) * 0.28
			local trem = 0.75 + 0.25 * sin(2 * pi * (6 + 14 * u) * t)
			return (tone + lp * u * 0.5) * trem
		end)
	end

	-- tick huruf
	local function letterTick(t0, f)
		add(t0, 0.07, function(t)
			return sin(2 * pi * f * t) * exp(-t * 110) * 0.34 + noise() * exp(-t * 600) * 0.2
		end)
	end

	-- benturan: dentuman dalam + retakan
	local function impact(t0)
		add(t0, 1.7, function(t)
			local boom = sin(sweepPhase(95, 26, 0.9, t)) * exp(-t * 3.3) * 0.95
			local sub = sin(2 * pi * 55 * t) * exp(-t * 5) * 0.4
			local crack = noise() * exp(-t * 22) * 0.55
			return boom + sub + crack
		end)
	end

	-- glitch: sample & hold + gerbang cepat
	local function glitch(t0, dur)
		local held, cnt = 0, 0
		add(t0, dur, function(t)
			cnt += 1
			if cnt % 5 == 0 then held = noise() end
			local gate = (floor(t * 38) % 2 == 0) and 1 or 0.25
			return held * gate * 0.22 * exp(-t * 5)
		end)
	end

	-- ping loading (nada naik)
	local function ping(t0, f)
		add(t0, 0.35, function(t)
			return sin(2 * pi * f * t) * exp(-t * 15) * 0.28 + sin(2 * pi * 2 * f * t) * exp(-t * 24) * 0.1
		end)
	end

	-- lonceng "siap"
	local function chime(t0)
		add(t0, 1.7, function(t)
			return (sin(2 * pi * 1046.5 * t) * 0.22 + sin(2 * pi * 1568 * t) * 0.16
				+ sin(2 * pi * 2093 * t) * 0.08) * exp(-t * 3.2)
		end)
	end

	-- whoosh pintu terbuka
	local function whoosh(t0, d)
		local lp = 0
		add(t0, d, function(t)
			local u = t / d
			local env = sin(pi * u) ^ 1.5
			lp = lp + (0.04 + 0.5 * sin(pi * u)) * (noise() - lp)
			return lp * env * 0.9 + sin(sweepPhase(70, 260, d, t)) * env * 0.25
		end)
	end

	-- susun sesuai garis waktu
	knock(TL.knock[1], 0.75)
	knock(TL.knock[2], 0.75)
	knock(TL.knock[3], 1.0)
	riser(TL.riserA, TL.riserB)
	for i = 1, 9 do letterTick(TL.letter + (i - 1) * TL.gap, 1500 + i * 120) end
	impact(TL.impact)
	glitch(TL.impact + 0.05, 0.4)
	local notes = { 523.25, 587.33, 659.25, 783.99, 1046.5 }
	for i, t in ipairs(TL.steps) do
		if i < #TL.steps then ping(t, notes[i]) else chime(t) end
	end
	whoosh(TL.exit, 0.9)

	-- normalisasi + soft clip
	local peak = 0
	for i = 1, N do
		local a = abs(buf[i])
		if a > peak then peak = a end
	end
	local g = peak > 0.9 and (0.9 / peak) or 1
	for i = 1, N do
		local x = buf[i] * g
		buf[i] = x / (1 + abs(x) * 0.35)
		tick()
	end
	for i = 0, 440 do buf[N - i] = buf[N - i] * (i / 440) end -- fade ujung
	return buf, N
end

local function toWav(buf, N)
	local floor = math.floor
	local function u32(v) return string.char(v % 256, floor(v / 256) % 256, floor(v / 65536) % 256, floor(v / 16777216) % 256) end
	local function u16(v) return string.char(v % 256, floor(v / 256) % 256) end
	local dataLen = N * 2
	local parts = { "RIFF" .. u32(36 + dataLen) .. "WAVEfmt " .. u32(16) .. u16(1) .. u16(1)
		.. u32(SR) .. u32(SR * 2) .. u16(2) .. u16(16) .. "data" .. u32(dataLen) }
	local chunk, c = {}, 0
	for i = 1, N do
		local v = floor(buf[i] * 32767 + 0.5)
		if v > 32767 then v = 32767 elseif v < -32768 then v = -32768 end
		if v < 0 then v = v + 65536 end
		chunk[c + 1] = v % 256
		chunk[c + 2] = floor(v / 256)
		c += 2
		if c >= 2048 then
			parts[#parts + 1] = string.char(table.unpack(chunk, 1, c))
			c = 0
		end
		if i % 30000 == 0 then task.wait() end
	end
	if c > 0 then parts[#parts + 1] = string.char(table.unpack(chunk, 1, c)) end
	return table.concat(parts)
end

local function loadIntroSound()
	local getAsset = getcustomasset or getsynasset
	if not (writefile and getAsset) then return nil end
	local fname = "NimeroHub_intro_v1.wav"
	local ok = pcall(function()
		if not (isfile and isfile(fname)) then
			local buf, N = synthIntro()
			writefile(fname, toWav(buf, N))
		end
	end)
	if not ok then return nil end
	local okA, asset = pcall(getAsset, fname)
	if okA and asset and asset ~= "" then return asset end
	return nil
end

task.spawn(function()
	bubble.Visible = false
	bscale.Scale = 0

	local root, snd
	local ok, err = pcall(function()
		local rng = Random.new()
		local RED_BRIGHT = Color3.fromRGB(255, 70, 84)
		local BLACK = Color3.fromRGB(4, 1, 2)

		-- wadah utama: menutup seluruh layar
		root = Instance.new("Frame")
		root.Name = "Intro"
		root.Position = UDim2.fromScale(0, 0)
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundTransparency = 1
		root.BorderSizePixel = 0
		root.ClipsDescendants = true
		root.Active = true
		root.ZIndex = 100
		root.Parent = gui

		local function box(parentObj, z, color, tr)
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.BackgroundColor3 = color
			f.BackgroundTransparency = tr or 0
			f.ZIndex = z
			f.Parent = parentObj
			return f
		end

		-- latar dua belahan (membuka seperti pintu di akhir)
		local bgTop = box(root, 100, Color3.new(1, 1, 1))
		bgTop.Size = UDim2.fromScale(1, 0.5)
		local g1 = Instance.new("UIGradient")
		g1.Color = ColorSequence.new(Color3.fromRGB(52, 5, 12), BLACK)
		g1.Rotation = 90
		g1.Parent = bgTop
		local bgBot = box(root, 100, Color3.new(1, 1, 1))
		bgBot.Position = UDim2.fromScale(0, 0.5)
		bgBot.Size = UDim2.fromScale(1, 0.5)
		local g2 = Instance.new("UIGradient")
		g2.Color = ColorSequence.new(BLACK, Color3.fromRGB(44, 4, 10))
		g2.Rotation = 90
		g2.Parent = bgBot

		-- isi (bisa digetarkan & di-fade sekaligus)
		local content = box(root, 101, Color3.new(0, 0, 0), 1)
		content.Size = UDim2.fromScale(1, 1)

		for i = 1, 2 do
			local sl = box(content, 101, Color3.fromRGB(200, 20, 36), 0.82)
			sl.Size = UDim2.new(1, 0, 0, 2)
			sl.Position = UDim2.fromScale(0, -0.03)
			task.spawn(function()
				task.wait((i - 1) * 1.2)
				while alive and root.Parent do
					sl.Position = UDim2.fromScale(0, -0.03)
					tw(sl, 2.4, { Position = UDim2.fromScale(0, 1.03) }, Enum.EasingStyle.Linear)
					task.wait(2.4)
				end
			end)
		end

		spawnEmbers(content, 44, 101, true)

		local barT = box(content, 103, Color3.new(0, 0, 0))
		barT.Size = UDim2.new(1, 0, 0, 0)
		local lnT = box(barT, 104, ON)
		lnT.AnchorPoint = Vector2.new(0, 1)
		lnT.Position = UDim2.fromScale(0, 1)
		lnT.Size = UDim2.new(1, 0, 0, 2)
		local barB = box(content, 103, Color3.new(0, 0, 0))
		barB.AnchorPoint = Vector2.new(0, 1)
		barB.Position = UDim2.fromScale(0, 1)
		barB.Size = UDim2.new(1, 0, 0, 0)
		local lnB = box(barB, 104, ON)
		lnB.Size = UDim2.new(1, 0, 0, 2)

		for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
			local ax, ay = c[1], c[2]
			local m = 20
			local pos = UDim2.new(ax, ax == 0 and m or -m, ay, ay == 0 and m or -m)
			local h = box(content, 102, ON)
			h.AnchorPoint = Vector2.new(ax, ay)
			h.Position = pos
			h.Size = UDim2.fromOffset(0, 3)
			local v = box(content, 102, ON)
			v.AnchorPoint = Vector2.new(ax, ay)
			v.Position = pos
			v.Size = UDim2.fromOffset(3, 0)
			tw(h, 0.6, { Size = UDim2.fromOffset(52, 3) }, Enum.EasingStyle.Quint)
			tw(v, 0.6, { Size = UDim2.fromOffset(3, 52) }, Enum.EasingStyle.Quint)
		end

		-- gelombang kejut dari tengah
		local function ring(finalSize, thick)
			if not root.Parent then return end
			local r = box(content, 102, Color3.new(1, 1, 1), 1)
			r.AnchorPoint = Vector2.new(0.5, 0.5)
			r.Position = UDim2.fromScale(0.5, 0.44)
			r.Size = UDim2.fromOffset(40, 40)
			corner(r, 1000)
			local st = stroke(r, ON, thick or 3, 0.15)
			tw(r, 1.2, { Size = UDim2.fromOffset(finalSize or 900, finalSize or 900) }, Enum.EasingStyle.Quad)
			tw(st, 1.2, { Transparency = 1, Thickness = 1 })
			task.delay(1.3, function() r:Destroy() end)
		end

		-- judul 3 lapis (efek glitch)
		local WORD = "NimeroHub"
		local function makeWord(z, colorFn, strokeColor)
			local row = Instance.new("Frame")
			row.AnchorPoint = Vector2.new(0.5, 0.5)
			row.Position = UDim2.fromScale(0.5, 0.44)
			row.Size = UDim2.fromOffset(480, 70)
			row.BackgroundTransparency = 1
			row.ZIndex = z
			row.Parent = content
			local lay = Instance.new("UIListLayout")
			lay.FillDirection = Enum.FillDirection.Horizontal
			lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
			lay.VerticalAlignment = Enum.VerticalAlignment.Center
			lay.SortOrder = Enum.SortOrder.LayoutOrder
			lay.Parent = row
			local list = {}
			for i = 1, #WORD do
				local l = Instance.new("TextLabel")
				l.AutomaticSize = Enum.AutomaticSize.X
				l.Size = UDim2.fromOffset(0, 64)
				l.BackgroundTransparency = 1
				l.Text = WORD:sub(i, i)
				l.Font = Enum.Font.GothamBlack
				l.TextSize = 54
				l.TextColor3 = colorFn(i)
				l.TextTransparency = 1
				l.ZIndex = z
				l.LayoutOrder = i
				l.Parent = row
				local st
				if strokeColor then st = stroke(l, strokeColor, 2, 1) end
				local sc = Instance.new("UIScale")
				sc.Scale = 2.6
				sc.Parent = l
				list[i] = { l = l, st = st, sc = sc }
			end
			return row, list
		end

		local rowDark, listDark = makeWord(102, function() return Color3.fromRGB(90, 0, 12) end)
		local rowRed, listRed = makeWord(103, function() return Color3.fromRGB(255, 24, 48) end)
		local rowMain, listMain = makeWord(104, function(i)
			return Color3.fromRGB(255, math.max(70, 150 - i * 9), math.max(78, 156 - i * 9))
		end, Color3.fromRGB(60, 0, 8))

		local line = box(content, 104, ON)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5, 0.53)
		line.Size = UDim2.fromOffset(0, 3)
		corner(line, 2)

		local sub = label(content, "B E R I M A K A N    H E W A N", 14, SUB, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
		sub.AnchorPoint = Vector2.new(0.5, 0.5)
		sub.Position = UDim2.fromScale(0.5, 0.6)
		sub.Size = UDim2.fromOffset(460, 22)
		sub.TextTransparency = 1
		sub.ZIndex = 104

		local loadTxt = label(content, "", 12, SUB, Enum.Font.GothamMedium, Enum.TextXAlignment.Left)
		loadTxt.AnchorPoint = Vector2.new(0, 1)
		loadTxt.Position = UDim2.new(0.5, -170, 0.79, 0)
		loadTxt.Size = UDim2.fromOffset(280, 18)
		loadTxt.ZIndex = 104
		local pct = label(content, "0%", 12, Color3.new(1, 1, 1), Enum.Font.GothamBold, Enum.TextXAlignment.Right)
		pct.AnchorPoint = Vector2.new(1, 1)
		pct.Position = UDim2.new(0.5, 170, 0.79, 0)
		pct.Size = UDim2.fromOffset(60, 18)
		pct.ZIndex = 104

		local track = box(content, 104, Color3.fromRGB(46, 10, 16))
		track.AnchorPoint = Vector2.new(0.5, 0)
		track.Position = UDim2.new(0.5, 0, 0.8, 4)
		track.Size = UDim2.fromOffset(340, 6)
		corner(track, 3)
		local trackScale = Instance.new("UIScale")
		trackScale.Parent = track
		local fill = box(track, 105, Color3.new(1, 1, 1))
		fill.Size = UDim2.new(0, 0, 1, 0)
		corner(fill, 3)
		local fg = Instance.new("UIGradient")
		fg.Color = ColorSequence.new(Color3.fromRGB(150, 10, 26), RED_BRIGHT)
		fg.Parent = fill

		local flash = box(root, 120, Color3.fromRGB(255, 40, 56), 1)
		flash.Size = UDim2.fromScale(1, 1)

		local function fadeAll(container, t)
			local info = TweenInfo.new(t, Enum.EasingStyle.Quad)
			for _, d in ipairs(container:GetDescendants()) do
				local props
				if d:IsA("TextLabel") then
					props = { TextTransparency = 1, BackgroundTransparency = 1 }
				elseif d:IsA("Frame") then
					props = { BackgroundTransparency = 1 }
				elseif d:IsA("UIStroke") then
					props = { Transparency = 1 }
				end
				if props then pcall(function() TweenService:Create(d, info, props):Play() end) end
			end
		end

		-- getaran layar (efek ketukan)
		local function shake(mag, dur)
			task.spawn(function()
				local t0 = os.clock()
				while os.clock() - t0 < dur and root.Parent do
					local k = 1 - (os.clock() - t0) / dur
					content.Position = UDim2.fromOffset(rng:NextInteger(-mag, mag) * k, rng:NextInteger(-mag, mag) * k)
					task.wait()
				end
				if root.Parent then content.Position = UDim2.fromOffset(0, 0) end
			end)
		end

		-- ketukan: getar + gelombang + kilat merah tipis
		local function knockFx(big)
			shake(big and 10 or 6, 0.18)
			ring(big and 620 or 420, big and 4 or 3)
			flash.BackgroundTransparency = big and 0.78 or 0.9
			tw(flash, 0.28, { BackgroundTransparency = 1 })
			trackScale.Scale = 1
		end

		-- siapkan suara (sebelum garis waktu mulai agar sinkron)
		local soundId = loadIntroSound()
		if soundId then
			snd = Instance.new("Sound")
			snd.Name = "IntroSound"
			snd.SoundId = soundId
			snd.Volume = 0.9
			snd.Parent = gui
		end

		local T0 = os.clock()
		local function at(t)
			local d = T0 + t - os.clock()
			if d > 0 then task.wait(d) end
		end
		if snd then pcall(function() snd:Play() end) end

		-- 0.00 bar sinematik masuk
		tw(barT, 0.6, { Size = UDim2.new(1, 0, 0.09, 0) }, Enum.EasingStyle.Quint)
		tw(barB, 0.6, { Size = UDim2.new(1, 0, 0.09, 0) }, Enum.EasingStyle.Quint)

		-- ketegangan naik: getar halus makin kuat
		task.spawn(function()
			while root.Parent and os.clock() - T0 < TL.riserB do
				local e = os.clock() - T0
				if e > TL.riserA then
					local m = 1 + (e - TL.riserA) / (TL.riserB - TL.riserA) * 3
					content.Position = UDim2.fromOffset(rng:NextNumber(-m, m), rng:NextNumber(-m, m))
				end
				task.wait()
			end
		end)

		-- tok, tok, TOK
		for i, t in ipairs(TL.knock) do
			at(t)
			knockFx(i == #TL.knock)
		end

		-- huruf jatuh satu per satu (tiap huruf = tick + getar kecil)
		for i = 1, #WORD do
			at(TL.letter + (i - 1) * TL.gap)
			local a, b, c = listMain[i], listRed[i], listDark[i]
			tw(a.l, 0.25, { TextTransparency = 0 })
			tw(a.st, 0.25, { Transparency = 0.2 })
			tw(a.sc, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
			tw(b.l, 0.25, { TextTransparency = 0.5 })
			tw(b.sc, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
			tw(c.l, 0.25, { TextTransparency = 0.45 })
			tw(c.sc, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
			shake(2, 0.06)
		end

		-- benturan + glitch
		at(TL.impact)
		flash.BackgroundTransparency = 0.35
		tw(flash, 0.5, { BackgroundTransparency = 1 })
		shake(14, 0.5)
		ring(900, 5)
		task.delay(0.12, function() ring(640, 3) end)
		task.spawn(function()
			for _ = 1, 12 do
				if not root.Parent then return end
				rowRed.Position = UDim2.new(0.5, rng:NextInteger(-10, 10), 0.44, rng:NextInteger(-4, 4))
				rowDark.Position = UDim2.new(0.5, rng:NextInteger(-10, 10), 0.44, rng:NextInteger(-4, 4))
				rowMain.Position = UDim2.new(0.5, rng:NextInteger(-3, 3), 0.44, rng:NextInteger(-2, 2))
				task.wait(0.035)
			end
			rowMain.Position = UDim2.fromScale(0.5, 0.44)
			tw(rowRed, 0.2, { Position = UDim2.new(0.5, -3, 0.44, 0) })
			tw(rowDark, 0.2, { Position = UDim2.new(0.5, 3, 0.44, 0) })
		end)
		task.delay(0.45, function()
			if root.Parent then tw(line, 0.55, { Size = UDim2.fromOffset(300, 3) }, Enum.EasingStyle.Quint) end
		end)

		at(TL.sub)
		tw(sub, 0.5, { TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.58) })

		-- loading: tiap tahap = ping naik nada
		local texts_ = {
			{ 20, "Memuat modul..." },
			{ 45, "Menyiapkan Auto Perfect..." },
			{ 68, "Menyiapkan Auto Farm..." },
			{ 90, "Menyiapkan Auto Click x2..." },
			{ 100, "Siap digunakan" },
		}
		local cur = 0
		for i, st in ipairs(texts_) do
			at(TL.steps[i])
			loadTxt.Text = st[2]
			tw(fill, 0.4, { Size = UDim2.new(st[1] / 100, 0, 1, 0) })
			trackScale.Scale = 1.07
			tw(trackScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
			local from, t0, target = cur, os.clock(), st[1]
			cur = target
			task.spawn(function()
				while os.clock() - t0 < 0.4 do
					pct.Text = string.format("%d%%", math.floor(from + (target - from) * ((os.clock() - t0) / 0.4)))
					task.wait()
				end
				pct.Text = target .. "%"
			end)
			if i == #texts_ then
				shake(3, 0.12)
				ring(500, 2)
			end
		end

		-- keluar: kilatan + whoosh, latar membuka seperti pintu
		at(TL.exit)
		flash.BackgroundTransparency = 0.3
		tw(flash, 0.45, { BackgroundTransparency = 1 })
		fadeAll(content, 0.4)
		task.wait(0.15)
		tw(bgTop, 0.7, { Position = UDim2.fromScale(0, -0.5) }, Enum.EasingStyle.Quint)
		tw(bgBot, 0.7, { Position = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Quint)
		task.wait(0.8)
	end)
	if not ok then lastErr = "intro: " .. tostring(err) end
	if root then pcall(function() root:Destroy() end) end
	if snd then
		task.delay(1.5, function() pcall(function() snd:Stop() snd:Destroy() end) end)
	end

	bubble.Visible = true
	tw(bscale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
end)
