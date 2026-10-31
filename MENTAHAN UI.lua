-- NimeroHub v2.1 (+ mode Cyberpunk, Galaxy, Black Hole, Neon Samurai)
-- Tema warna + Kristal melayang/jatuh + Pemilih warna kustom (bebas semua warna)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local ES, ED = Enum.EasingStyle, Enum.EasingDirection
local MAIN_W, MAIN_H = 560, 355

-------------------------------------------------
-- SIMPAN PENGATURAN (file di folder executor, butuh writefile/readfile)
-------------------------------------------------
local SV = {path = "NimeroHub/pengaturan.json", cur = {}, saved = {}, auto = true, notif = {}}
function SV.Can()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end
function SV.Load()
	if not SV.Can() then return end
	pcall(function()
		if isfile(SV.path) then
			local d = HttpService:JSONDecode(readfile(SV.path))
			if type(d) == "table" then
				if d.auto == false then
					SV.auto = false -- simpan otomatis dimatikan: mulai dari bawaan
				else
					SV.saved = d
					for k, v in pairs(d) do SV.cur[k] = v end
				end
			end
		end
	end)
end
function SV.Write()
	if not SV.Can() then return end
	SV.token = (SV.token or 0) + 1
	local my = SV.token
	task.delay(0.6, function()
		if my ~= SV.token then return end
		pcall(function()
			if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("NimeroHub") then
				makefolder("NimeroHub")
			end
			local out = {auto = false}
			if SV.auto then
				out = {}
				for k, v in pairs(SV.cur) do out[k] = v end
				out.auto = true
			end
			writefile(SV.path, HttpService:JSONEncode(out))
		end)
	end)
end
function SV.Set(key, value)
	SV.cur[key] = value
	if SV.auto then SV.Write() end
end
SV.Load()

-------------------------------------------------
-- PARENT + HAPUS UI LAMA
-------------------------------------------------
local ParentGui
do
	local ok, res = pcall(function()
		return (gethui and gethui()) or game:GetService("CoreGui")
	end)
	ParentGui = (ok and res) or LocalPlayer:WaitForChild("PlayerGui")
end

pcall(function()
	local old = ParentGui:FindFirstChild("NimeroHub")
	if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NimeroHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
if not pcall(function() ScreenGui.Parent = ParentGui end) then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function Alive()
	return ScreenGui.Parent ~= nil
end

-------------------------------------------------
-- WARNA TETAP
-------------------------------------------------
local Colors = {
	Text = Color3.fromRGB(250, 245, 248),
	Green = Color3.fromRGB(80, 255, 160),
	Yellow = Color3.fromRGB(255, 210, 80),
	Pink = Color3.fromRGB(255, 110, 170),
	GlitchCyan = Color3.fromRGB(0, 255, 255),
	GlitchRed = Color3.fromRGB(255, 30, 80),
	White = Color3.fromRGB(255, 255, 255),
}

-------------------------------------------------
-- TEMA
-------------------------------------------------
local function C(r, g, b) return Color3.fromRGB(r, g, b) end

-- Bikin satu tema lengkap dari 2 warna (dasar gelap diambil dari hue warna 1)
local function MakeTheme(a, b)
	local h, s = a:ToHSV()
	local sat = math.clamp(s * 0.65, 0.14, 0.6)
	local function D(val) return Color3.fromHSV(h, sat, val) end
	return {
		Accent = a, Accent2 = b,
		Dark = Color3.fromHSV(h, math.clamp(s * 0.7, 0.2, 0.8), 0.32),
		BG0 = D(0.09), BG1 = D(0.045),
		Card0 = D(0.12), Card1 = D(0.075),
		Title0 = D(0.125), Title1 = D(0.078),
		Side0 = D(0.095), Side1 = D(0.06),
		Box = D(0.135), Btn = D(0.19),
		TextDim = Color3.fromHSV(h, math.clamp(s * 0.18, 0.05, 0.2), 0.7),
	}
end

-- Warna kustom disimpan sebagai HSV {hue, saturasi, terang}
local CustomHSV = {
	{0.08, 0.85, 1},
	{0.93, 0.60, 1},
}
do
	local cs = SV.saved.custom
	if type(cs) == "table" then
		for i = 1, 2 do
			local c = cs[i]
			if type(c) == "table" and type(c[1]) == "number" and type(c[2]) == "number" and type(c[3]) == "number" then
				CustomHSV[i] = {math.clamp(c[1], 0, 0.999), math.clamp(c[2], 0, 1), math.clamp(c[3], 0.2, 1)}
			end
		end
	end
end
local function CustomColor(i)
	local c = CustomHSV[i]
	return Color3.fromHSV(c[1], c[2], c[3])
end

local Themes = {
	{
		name = "Merah Pink",
		colors = {
			Accent = C(220, 45, 75), Accent2 = C(255, 85, 120), Dark = C(75, 18, 32),
			BG0 = C(22, 9, 14), BG1 = C(11, 5, 9),
			Card0 = C(30, 13, 20), Card1 = C(19, 9, 14),
			Title0 = C(32, 13, 20), Title1 = C(20, 9, 14),
			Side0 = C(24, 10, 16), Side1 = C(15, 7, 11),
			Box = C(34, 14, 23), Btn = C(48, 19, 30), TextDim = C(170, 140, 155),
		},
	},
	{
		name = "Neon",
		colors = {
			Accent = C(20, 190, 255), Accent2 = C(185, 85, 255), Dark = C(35, 45, 105),
			BG0 = C(14, 10, 28), BG1 = C(7, 5, 16),
			Card0 = C(22, 16, 42), Card1 = C(13, 10, 26),
			Title0 = C(24, 17, 46), Title1 = C(14, 10, 28),
			Side0 = C(18, 13, 36), Side1 = C(10, 8, 22),
			Box = C(26, 19, 50), Btn = C(38, 28, 74), TextDim = C(150, 150, 195),
		},
	},
	{
		name = "Abu Rokok & Biru",
		colors = {
			Accent = C(65, 130, 255), Accent2 = C(138, 150, 170), Dark = C(55, 64, 84),
			BG0 = C(21, 24, 31), BG1 = C(10, 12, 17),
			Card0 = C(29, 33, 43), Card1 = C(17, 20, 28),
			Title0 = C(31, 35, 46), Title1 = C(19, 22, 30),
			Side0 = C(24, 27, 36), Side1 = C(14, 16, 23),
			Box = C(35, 40, 53), Btn = C(47, 54, 71), TextDim = C(150, 158, 172),
		},
	},
	{
		name = "Emerald",
		colors = {
			Accent = C(25, 195, 125), Accent2 = C(70, 225, 205), Dark = C(14, 70, 52),
			BG0 = C(9, 21, 17), BG1 = C(5, 11, 9),
			Card0 = C(13, 31, 25), Card1 = C(8, 19, 15),
			Title0 = C(14, 34, 27), Title1 = C(9, 21, 17),
			Side0 = C(11, 26, 21), Side1 = C(7, 16, 13),
			Box = C(16, 38, 31), Btn = C(22, 54, 44), TextDim = C(140, 175, 163),
		},
	},
	{
		name = "Kustom",
		custom = true,
		colors = MakeTheme(CustomColor(1), CustomColor(2)),
	},
}
local CUSTOM = #Themes

local ThemeIdx = 1
if type(SV.saved.theme) == "number" and Themes[SV.saved.theme] then ThemeIdx = SV.saved.theme end
local Cur = {}
for k, v in pairs(Themes[ThemeIdx].colors) do Cur[k] = v end

local Hooks = {}
local function OnTheme(fn)
	table.insert(Hooks, fn)
	fn(Cur)
end
local function Bind(obj, prop, key)
	OnTheme(function(T) obj[prop] = T[key] end)
end

-------------------------------------------------
-- HELPER
-------------------------------------------------
local function Tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or ES.Quint, dir or ED.Out), props)
	tw:Play()
	return tw
end

local function Loop(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, ES.Sine, ED.InOut, -1, true), props):Play()
end

local function Spin(grad, t)
	TweenService:Create(grad, TweenInfo.new(t, ES.Linear, ED.Out, -1), {Rotation = grad.Rotation + 360}):Play()
end

local function IsPointer(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function Make(class, props)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function Label(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or Colors.Text
	return Make("TextLabel", props)
end

local function Corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r)
	c.Parent = obj
	return c
end

local function Stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Transparency = transparency or 0
	s.Parent = obj
	return s
end

local function Grad(obj, c0, c1, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rot or 0
	g.Parent = obj
	return g
end

local function BGrad(obj, k0, k1, rot)
	local g = Grad(obj, Cur[k0], Cur[k1], rot)
	OnTheme(function(T) g.Color = ColorSequence.new(T[k0], T[k1]) end)
	return g
end

-------------------------------------------------
-- CLICK SOUND
-------------------------------------------------
local ClickSound = Make("Sound", {
	SoundId = "rbxassetid://6895079853",
	Volume = 0.45,
	Parent = ScreenGui,
})
local SoundOn = (SV.saved.suara ~= false)
local SoundRenders = {} -- dipanggil tiap suara diganti (baris Pengaturan & tombol suara)
local function SetSound(v)
	SoundOn = v
	SV.Set("suara", v)
	for _, f in ipairs(SoundRenders) do pcall(f, v) end
end
local BootErr = {} -- catatan error fitur tambahan supaya menu utama tetap jalan

-- Nada berbeda dibuat dari satu suara klik dengan mengubah kecepatan putarnya
-- {kecepatan, volume}; beberapa nada berurutan = bunyi "ting" berlapis
local SFX = {k = {
	click = {{1.00, 0.45}},
	tab   = {{1.25, 0.35}},
	on    = {{1.00, 0.40}, {1.40, 0.45}},
	off   = {{1.00, 0.40}, {0.70, 0.40}},
	pilih = {{1.20, 0.40}, {1.60, 0.45}},
	open  = {{0.85, 0.35}, {1.15, 0.40}, {1.45, 0.40}},
	close = {{1.35, 0.35}, {1.05, 0.35}, {0.80, 0.35}},
	spooky = {{0.60, 0.45}, {0.75, 0.40}, {0.50, 0.45}},
	hack   = {{1.80, 0.30}, {2.10, 0.30}, {1.50, 0.30}, {2.40, 0.35}},
	darah  = {{0.50, 0.50}, {0.40, 0.50}, {0.33, 0.45}},
	cyber  = {{1.60, 0.35}, {0.90, 0.35}, {2.20, 0.30}, {1.20, 0.35}, {2.60, 0.30}},
	galaxy = {{0.90, 0.30}, {1.35, 0.30}, {1.80, 0.30}, {2.30, 0.28}},
	lubang = {{1.00, 0.45}, {0.70, 0.45}, {0.45, 0.45}, {0.30, 0.50}, {0.25, 0.50}},
	katana = {{1.90, 0.35}, {2.60, 0.40}, {0.90, 0.40}},
	ketuk  = {{1.00, 0.50}},
	percikan = {{0.70, 0.45}, {1.30, 0.30}, {0.90, 0.25}},
	gelembung = {{1.60, 0.35}, {2.00, 0.30}, {2.40, 0.30}},
	lonceng = {{1.00, 0.40}, {2.00, 0.30}},
	laser  = {{2.50, 0.30}, {1.20, 0.30}, {0.60, 0.30}},
	petir  = {{0.40, 0.50}, {0.90, 0.40}},
	koin   = {{1.80, 0.40}, {2.40, 0.40}},
	whoosh = {{0.60, 0.35}, {1.40, 0.30}},
	pop    = {{1.50, 0.45}},
	ding   = {{2.00, 0.40}, {2.00, 0.25}},
	tik    = {{1.10, 0.40}, {1.25, 0.30}},
	bip    = {{1.70, 0.35}, {1.70, 0.35}},
	soft   = {{0.80, 0.25}, {0.85, 0.25}},
}}
-- ID suara asli per gaya, contoh: hack = "rbxassetid://123456789"
-- kosong = pakai suara klik bawaan dengan kecepatan berbeda
-- Isi ID suara di sini (copy dari Roblox Toolbox / Creator Store), contoh:
-- ketuk = "rbxassetid://123456789", percikan = "rbxassetid://987654321"
SFX.ids = {}
local SoundStyle
local GenericKind = {click = true, tab = true, pilih = true, open = true, close = true, on = true, off = true}
local function SetStyle(k)
	SoundStyle = (k ~= "click") and k or nil
end
SetStyle(SV.saved.gaya)
function SFX.Play(kind)
	if not SoundOn then return end
	if SoundStyle and GenericKind[kind] then kind = SoundStyle end
	local seq = SFX.k[kind] or SFX.k.click
	task.spawn(function()
		for i, n in ipairs(seq) do
			if not Alive() then return end
			local sd = ClickSound:Clone()
			local id = n[3] or SFX.ids[kind]
			if id then sd.SoundId = id end
			sd.PlaybackSpeed = n[1]
			sd.Volume = n[2]
			sd.TimePosition = 0
			sd.Parent = ScreenGui
			sd:Play()
			game:GetService("Debris"):AddItem(sd, 2)
			if i < #seq then task.wait(0.1) end
		end
	end)
end
local function PlayClick(kind)
	SFX.Play(kind)
end

local function Interactive(btn, normalKey, hoverKey)
	Bind(btn, "BackgroundColor3", normalKey)
	local sc = Instance.new("UIScale")
	sc.Parent = btn
	btn.MouseEnter:Connect(function()
		Tween(btn, 0.18, {BackgroundColor3 = Cur[hoverKey]})
		Tween(sc, 0.18, {Scale = 1.03})
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, 0.28, {BackgroundColor3 = Cur[normalKey]})
		Tween(sc, 0.28, {Scale = 1})
	end)
	btn.MouseButton1Down:Connect(function()
		Tween(sc, 0.08, {Scale = 0.95}, ES.Quad)
	end)
	btn.MouseButton1Up:Connect(function()
		Tween(sc, 0.3, {Scale = 1.03}, ES.Back)
	end)
end

local function Glitcher(a, b, ax, bx, rest, hit, amp, minWait, maxWait)
	task.spawn(function()
		while Alive() do
			task.wait(minWait + math.random() * (maxWait - minWait))
			if not Alive() then break end
			for _ = 1, math.random(2, 4) do
				local d = math.random(2, amp)
				local dy = math.random(-1, 1)
				Tween(a, 0.05, {Position = UDim2.new(0, ax - d, 0, dy), TextTransparency = hit}, ES.Linear)
				Tween(b, 0.05, {Position = UDim2.new(0, bx + d, 0, -dy), TextTransparency = hit}, ES.Linear)
				task.wait(0.055)
			end
			Tween(a, 0.3, {Position = UDim2.new(0, ax, 0, 0), TextTransparency = rest}, ES.Quint, ED.Out)
			Tween(b, 0.3, {Position = UDim2.new(0, bx, 0, 0), TextTransparency = rest}, ES.Quint, ED.Out)
		end
	end)
end

-------------------------------------------------
-- TOMBOL NH MELAYANG
-------------------------------------------------
local NHButton = Make("TextButton", {
	Name = "NHButton",
	Size = UDim2.new(0, 50, 0, 50),
	Position = UDim2.new(0, 14, 0.42, 0),
	BackgroundColor3 = Cur.Accent,
	Text = "NH",
	Font = Enum.Font.GothamBlack,
	TextSize = 16,
	TextColor3 = Colors.White,
	AutoButtonColor = false,
	Parent = ScreenGui,
})
Corner(NHButton, "full")
local NHStroke = Stroke(NHButton, Cur.Accent2, 2, 0)
Bind(NHStroke, "Color", "Accent2")
Loop(NHStroke, 1.2, {Transparency = 0.6})
Interactive(NHButton, "Accent", "Accent2")

-------------------------------------------------
-- ROOT (glow + panel + border)
-------------------------------------------------
local Root = Make("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, MAIN_W, 0, MAIN_H),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = ScreenGui,
})
local RootScale = Instance.new("UIScale")
RootScale.Parent = Root

local Glow = Make("ImageLabel", {
	BackgroundTransparency = 1,
	Image = "rbxassetid://5028857084",
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(24, 24, 276, 276),
	ImageColor3 = Cur.Accent,
	ImageTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(1, 52, 1, 52),
	ZIndex = 0,
	Parent = Root,
})
Bind(Glow, "ImageColor3", "Accent")

local Main = Make("CanvasGroup", {
	Name = "Main",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	GroupTransparency = 1,
	Parent = Root,
})
Corner(Main, 16)

-- Gradient background harus di frame terpisah (bukan di CanvasGroup)
local MainBG = Make("Frame", {
	Name = "BG",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Colors.White,
	BorderSizePixel = 0,
	ZIndex = 0,
	Parent = Main,
})
BGrad(MainBG, "BG0", "BG1", 90)

local Border = Make("Frame", {
	Name = "Border",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Active = false,
	ZIndex = 10,
	Parent = Root,
})
Corner(Border, 16)
local MainStroke = Stroke(Border, Colors.White, 1.5, 1)
local BorderGrad = Instance.new("UIGradient")
BorderGrad.Parent = MainStroke
OnTheme(function(T)
	BorderGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, T.Accent2),
		ColorSequenceKeypoint.new(0.3, T.Dark),
		ColorSequenceKeypoint.new(0.55, T.Dark),
		ColorSequenceKeypoint.new(0.8, T.Accent),
		ColorSequenceKeypoint.new(1, T.Accent2),
	})
end)
Spin(BorderGrad, 6)

-------------------------------------------------
-- KRISTAL MELAYANG / JATUH (ikut warna tema)
-------------------------------------------------
local FX = Make("Frame", {
	Name = "Crystals",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Active = false,
	ClipsDescendants = true,
	ZIndex = 6,
	Parent = Main,
})

local CFX = {
	Style = "Kristal",
	List = {},
	Names = {"Kristal", "Kotak", "Permen", "Bintang", "Hati", "Gelembung", "Salju", "Bunga", "Bulan", "Petir", "Daun", "Labu", "Kelelawar", "Hantu"},
	Spark = (SV.saved.percik ~= false),
}
for _, n in ipairs(CFX.Names) do
	if n == SV.saved.hiasan then CFX.Style = n end
end

function CFX.Grad(obj, list, rot)
	local g = Grad(obj, Cur.Accent2, Cur.Accent, rot)
	table.insert(list, g)
	return g
end

-- Membuat satu hiasan (kristal / kotak / permen) di dalam "parent"
-- Mengembalikan lebar dan tinggi hiasan
function CFX.Build(parent, style, s, shard, list)
	if style == "Helowin" then
		local pick = {"Labu", "Kelelawar", "Hantu"}
		style = pick[math.random(#pick)]
	elseif style == "BloodMoon" then
		local pick = {"BulanDarah", "Tetes", "KelelawarMerah"}
		style = pick[math.random(#pick)]
	elseif style == "Kode" then
		local pick = {"Kode0", "Kode1", "KodeBlok"}
		style = pick[math.random(#pick)]
	elseif style == "Cyber" then
		local pick = {"CyberKotak", "CyberGaris", "CyberPlus"}
		style = pick[math.random(#pick)]
	elseif style == "Galaxy" then
		local pick = {"GalBintang", "Planet", "Meteor"}
		style = pick[math.random(#pick)]
	elseif style == "LubangHitam" then
		local pick = {"BHLubang", "BHCincin", "BHPuing"}
		style = pick[math.random(#pick)]
	elseif style == "Samurai" then
		local pick = {"SamKelopak", "SamBilah", "SamKamon"}
		style = pick[math.random(#pick)]
	end
	if style == "Permen" then
		local h = s
		local w = math.floor(s * 2.4)
		local L = math.max(4, math.floor(h * 0.46))
		-- dua ujung bungkus permen
		for _, fx in ipairs({0.15, 0.85}) do
			local wing = Make("Frame", {
				Size = UDim2.new(0, L, 0, L),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(fx, 0, 0.5, 0),
				Rotation = 45,
				BackgroundColor3 = Colors.White,
				BorderSizePixel = 0,
				ZIndex = 1,
				Parent = parent,
			})
			Corner(wing, 1)
			CFX.Grad(wing, list, 90)
		end
		-- badan permen
		local pill = Make("Frame", {
			Size = UDim2.new(0.5, 0, 1, -2),
			Position = UDim2.new(0.25, 0, 0, 1),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(pill, "full")
		CFX.Grad(pill, list, math.random(0, 180))
		Stroke(pill, Colors.White, 1, 0.55)
		-- garis miring di badan permen
		for _, off in ipairs({-0.18, 0.18}) do
			Make("Frame", {
				Size = UDim2.new(0, math.max(2, math.floor(h * 0.14)), 0, math.max(4, math.floor(h * 0.7))),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.floor(h * off), 0.5, 0),
				Rotation = 20,
				BackgroundColor3 = Colors.White,
				BackgroundTransparency = 0.45,
				BorderSizePixel = 0,
				ZIndex = 3,
				Parent = pill,
			})
		end
		local hi = Make("Frame", {
			Size = UDim2.new(0.22, 0, 0.2, 0),
			Position = UDim2.new(0.12, 0, 0.14, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = pill,
		})
		Corner(hi, "full")
		return w, h
	elseif style == "Kotak" then
		local w = s
		local h = shard and math.max(5, math.floor(s * 0.7)) or s
		local body = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(body, 3)
		CFX.Grad(body, list, math.random(0, 180))
		Stroke(body, Colors.White, 1, 0.45)
		local inner = Make("Frame", {
			Size = UDim2.new(0.5, 0, 0.5, 0),
			Position = UDim2.new(0.25, 0, 0.25, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
			Parent = body,
		})
		Corner(inner, 2)
		return w, h
	elseif style == "Bintang" then
		-- bintang 8 sudut: dua persegi, satu diputar 45 derajat
		local w = s + 4
		local h = w
		local L = math.floor(w * 0.68)
		for _, rot in ipairs({0, 45}) do
			local sq = Make("Frame", {
				Size = UDim2.new(0, L, 0, L),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = rot,
				BackgroundColor3 = Colors.White,
				BorderSizePixel = 0,
				Parent = parent,
			})
			CFX.Grad(sq, list, 45)
		end
		local core = Make("Frame", {
			Size = UDim2.new(0, math.max(2, math.floor(L * 0.32)), 0, math.max(2, math.floor(L * 0.32))),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(core, "full")
		return w, h
	elseif style == "Hati" then
		-- hati: satu persegi diputar + dua lingkaran di sisi atasnya
		local w = s + 3
		local h = w
		local L = math.max(4, math.floor(w * 0.5))
		local d = L * 0.7071
		local off = math.floor(d / 2 + 0.5)
		local sq = Make("Frame", {
			Size = UDim2.new(0, L, 0, L),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.58, 0),
			Rotation = 45,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		CFX.Grad(sq, list, 45)
		for _, sx in ipairs({-1, 1}) do
			local lobe = Make("Frame", {
				Size = UDim2.new(0, L, 0, L),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, sx * off, 0.58, -off),
				BackgroundColor3 = Colors.White,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Corner(lobe, "full")
			CFX.Grad(lobe, list, 90)
		end
		local hi = Make("Frame", {
			Size = UDim2.new(0.16, 0, 0.16, 0),
			Position = UDim2.new(0.2, 0, 0.2, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(hi, "full")
		return w, h
	elseif style == "Gelembung" then
		local w = s + 2
		local h = w
		local body = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.65,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(body, "full")
		CFX.Grad(body, list, math.random(0, 180))
		Stroke(body, Colors.White, 1.2, 0.25)
		local hi = Make("Frame", {
			Size = UDim2.new(0.22, 0, 0.22, 0),
			Position = UDim2.new(0.2, 0, 0.16, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Parent = body,
		})
		Corner(hi, "full")
		return w, h
	elseif style == "Salju" then
		-- kepingan salju: tiga batang bersilang
		local w = s + 4
		local h = w
		local t = math.max(2, math.floor(w * 0.14))
		for _, rot in ipairs({0, 60, 120}) do
			local bar = Make("Frame", {
				Size = UDim2.new(1, 0, 0, t),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = rot,
				BackgroundColor3 = Colors.White,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Corner(bar, "full")
			CFX.Grad(bar, list, 0)
		end
		local dot = Make("Frame", {
			Size = UDim2.new(0, t + 2, 0, t + 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(dot, "full")
		return w, h
	elseif style == "Bunga" then
		-- bunga: empat kelopak + inti kuning
		local w = s + 4
		local h = w
		local pd = math.max(3, math.floor(w * 0.46))
		for _, c in ipairs({{0.5, 0.28}, {0.5, 0.72}, {0.28, 0.5}, {0.72, 0.5}}) do
			local petal = Make("Frame", {
				Size = UDim2.new(0, pd, 0, pd),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(c[1], 0, c[2], 0),
				BackgroundColor3 = Colors.White,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Corner(petal, "full")
			CFX.Grad(petal, list, 45)
			Stroke(petal, Colors.White, 1, 0.65)
		end
		local cs = math.max(2, math.floor(w * 0.3))
		local core = Make("Frame", {
			Size = UDim2.new(0, cs, 0, cs),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.Yellow,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(core, "full")
		return w, h
	elseif style == "Bulan" then
		-- bulan purnama dengan kawah
		local w = s + 3
		local h = w
		local body = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(body, "full")
		CFX.Grad(body, list, math.random(0, 180))
		Stroke(body, Colors.White, 1, 0.5)
		for _, c in ipairs({{0.30, 0.32, 0.26}, {0.62, 0.55, 0.20}, {0.36, 0.68, 0.14}}) do
			local cr = Make("Frame", {
				Size = UDim2.new(c[3], 0, c[3], 0),
				Position = UDim2.new(c[1], 0, c[2], 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.78,
				BorderSizePixel = 0,
				Parent = body,
			})
			Corner(cr, "full")
		end
		return w, h
	elseif style == "Petir" then
		-- petir kuning: dua batang miring + satu batang datar
		local w = s + 4
		local h = w
		local t = math.max(2, math.floor(w * 0.26))
		local len = math.max(4, math.floor(w * 0.5))
		local bolt = Color3.fromRGB(255, 214, 64)
		local function Bar(cx, cy, bw, bh, rot)
			local b = Make("Frame", {
				Size = UDim2.new(0, bw, 0, bh),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(cx, 0, cy, 0),
				Rotation = rot,
				BackgroundColor3 = bolt,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Corner(b, 1)
		end
		Bar(0.56, 0.30, t, len, 25)
		Bar(0.44, 0.70, t, len, 25)
		Bar(0.50, 0.50, math.floor(w * 0.34), t, 0)
		return w, h
	elseif style == "Daun" then
		-- daun hijau dengan tulang daun
		local w = s + 4
		local h = w
		local leaf = Make("Frame", {
			Size = UDim2.new(0, math.max(4, math.floor(w * 0.52)), 0, math.floor(w * 0.84)),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = 35,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(leaf, "full")
		local lg = Instance.new("UIGradient")
		lg.Color = ColorSequence.new(Color3.fromRGB(130, 235, 145), Color3.fromRGB(35, 150, 85))
		lg.Rotation = 90
		lg.Parent = leaf
		Make("Frame", {
			Size = UDim2.new(0, math.max(1, math.floor(w * 0.06)), 0.78, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = leaf,
		})
		return w, h
	elseif style == "Labu" then
		-- labu helowin
		local w = s + 4
		local h = w
		local function Seg(x, wd, c0, c1)
			local sg = Make("Frame", {
				Size = UDim2.new(wd, 0, 0.7, 0),
				Position = UDim2.new(x, 0, 0.24, 0),
				BackgroundColor3 = Colors.White,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Corner(sg, "full")
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new(c0, c1)
			g.Rotation = 90
			g.Parent = sg
		end
		Seg(0.04, 0.5, Color3.fromRGB(255, 140, 35), Color3.fromRGB(205, 80, 10))
		Seg(0.46, 0.5, Color3.fromRGB(255, 140, 35), Color3.fromRGB(205, 80, 10))
		Seg(0.27, 0.46, Color3.fromRGB(255, 172, 58), Color3.fromRGB(225, 100, 15))
		Make("Frame", {
			Size = UDim2.new(0.14, 0, 0.2, 0),
			Position = UDim2.new(0.43, 0, 0.06, 0),
			BackgroundColor3 = Color3.fromRGB(95, 150, 55),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		local face = Color3.fromRGB(70, 25, 0)
		for _, ex in ipairs({0.30, 0.58}) do
			Make("Frame", {
				Size = UDim2.new(0.13, 0, 0.13, 0),
				Position = UDim2.new(ex, 0, 0.42, 0),
				Rotation = 45,
				BackgroundColor3 = face,
				BorderSizePixel = 0,
				ZIndex = 2,
				Parent = parent,
			})
		end
		local mouth = Make("Frame", {
			Size = UDim2.new(0.32, 0, 0.09, 0),
			Position = UDim2.new(0.34, 0, 0.66, 0),
			BackgroundColor3 = face,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(mouth, 1)
		return w, h
	elseif style == "Kelelawar" or style == "KelelawarMerah" then
		-- kelelawar ungu
		local w = s + 6
		local h = math.floor(w * 0.7)
		local bat = (style == "KelelawarMerah") and Color3.fromRGB(205, 40, 55) or Color3.fromRGB(135, 85, 205)
		local function Part(cx, cy, sw, sh, rot, color)
			local pt = Make("Frame", {
				Size = UDim2.new(sw, 0, sh, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(cx, 0, cy, 0),
				Rotation = rot,
				BackgroundColor3 = color or bat,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Corner(pt, "full")
			return pt
		end
		for _, m in ipairs({-1, 1}) do
			Part(0.5 + m * 0.27, 0.36, 0.42, 0.22, -m * 20)
			Part(0.5 + m * 0.22, 0.62, 0.34, 0.2, m * 15)
		end
		Part(0.5, 0.5, 0.2, 0.62, 0)
		Part(0.45, 0.16, 0.09, 0.2, -15)
		Part(0.55, 0.16, 0.09, 0.2, 15)
		local eye = Color3.fromRGB(255, 175, 60)
		Part(0.46, 0.44, 0.07, 0.1, 0, eye).ZIndex = 2
		Part(0.54, 0.44, 0.07, 0.1, 0, eye).ZIndex = 2
		return w, h
	elseif style == "Hantu" then
		-- hantu putih
		local w = s + 4
		local h = w
		local gh = Color3.fromRGB(238, 238, 252)
		local function Blob(x, y, sw, sh, round, color, z)
			local b = Make("Frame", {
				Size = UDim2.new(sw, 0, sh, 0),
				Position = UDim2.new(x, 0, y, 0),
				BackgroundColor3 = color or gh,
				BorderSizePixel = 0,
				ZIndex = z or 1,
				Parent = parent,
			})
			if round then Corner(b, "full") end
			return b
		end
		Blob(0.15, 0.06, 0.7, 0.62, true)
		Blob(0.15, 0.36, 0.7, 0.42, false)
		for i = 0, 2 do
			Blob(0.15 + i * 0.2333, 0.70, 0.2333, 0.26, true)
		end
		local dark = Color3.fromRGB(60, 50, 90)
		Blob(0.30, 0.28, 0.11, 0.16, true, dark, 2)
		Blob(0.59, 0.28, 0.11, 0.16, true, dark, 2)
		Blob(0.45, 0.50, 0.10, 0.12, true, dark, 2)
		return w, h
	elseif style == "Kode0" or style == "Kode1" or style == "KodeBlok" then
		-- hiasan hacker: angka 0, angka 1, atau blok piksel
		local green = Color3.fromRGB(70, 255, 130)
		local w, h = s + 2, s + 4
		if style == "Kode0" then
			local ring = Make("Frame", {
				Size = UDim2.new(0.62, 0, 0.84, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Corner(ring, 2)
			Stroke(ring, green, 1.6, 0.05)
		elseif style == "Kode1" then
			local t = math.max(2, math.floor(w * 0.2))
			Make("Frame", {
				Size = UDim2.new(0, t, 0.8, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.56, 0, 0.48, 0),
				BackgroundColor3 = green,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Make("Frame", {
				Size = UDim2.new(0, math.floor(w * 0.34), 0, math.max(2, math.floor(w * 0.17))),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.34, 0, 0.2, 0),
				Rotation = -35,
				BackgroundColor3 = green,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Make("Frame", {
				Size = UDim2.new(0, math.floor(w * 0.62), 0, math.max(2, math.floor(w * 0.15))),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.88, 0),
				BackgroundColor3 = green,
				BorderSizePixel = 0,
				Parent = parent,
			})
		else
			w, h = s, s
			Make("Frame", {
				Size = UDim2.new(0.55, 0, 0.55, 0),
				Position = UDim2.new(0.1, 0, 0.1, 0),
				BackgroundColor3 = green,
				BackgroundTransparency = 0.15,
				BorderSizePixel = 0,
				Parent = parent,
			})
			Make("Frame", {
				Size = UDim2.new(0.32, 0, 0.32, 0),
				Position = UDim2.new(0.58, 0, 0.58, 0),
				BackgroundColor3 = green,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				Parent = parent,
			})
		end
		return w, h
	elseif style == "Terminal" then
		-- jendela terminal kecil ">_" dengan kursor berkedip
		local green = Color3.fromRGB(70, 255, 130)
		local w, h = s + 8, s + 2
		local box = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = Color3.fromRGB(4, 14, 7),
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(box, 3)
		Stroke(box, green, 1.2, 0.1)
		local t = math.max(2, math.floor(h * 0.12))
		local cl = math.max(3, math.floor(h * 0.3))
		local k = math.floor(cl * 0.3)
		for _, dir in ipairs({1, -1}) do
			Make("Frame", {
				Size = UDim2.new(0, cl, 0, t),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.26, 0, 0.5, -dir * k),
				Rotation = dir * 45,
				BackgroundColor3 = green,
				BorderSizePixel = 0,
				ZIndex = 2,
				Parent = box,
			})
		end
		local cursor = Make("Frame", {
			Size = UDim2.new(0, math.max(3, math.floor(w * 0.24)), 0, t),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0.5, 0, 0.68, 0),
			BackgroundColor3 = green,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = box,
		})
		Loop(cursor, 0.5, {BackgroundTransparency = 1})
		return w, h
	elseif style == "BulanDarah" then
		-- bulan merah darah dengan kawah
		local w = s + 3
		local h = w
		local body = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(body, "full")
		local bg = Instance.new("UIGradient")
		bg.Color = ColorSequence.new(Color3.fromRGB(255, 95, 62), Color3.fromRGB(150, 10, 22))
		bg.Rotation = 60
		bg.Parent = body
		Stroke(body, Color3.fromRGB(255, 70, 50), 1.2, 0.45)
		for _, c in ipairs({{0.30, 0.32, 0.26}, {0.62, 0.55, 0.20}, {0.36, 0.68, 0.14}}) do
			local cr = Make("Frame", {
				Size = UDim2.new(c[3], 0, c[3], 0),
				Position = UDim2.new(c[1], 0, c[2], 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.72,
				BorderSizePixel = 0,
				Parent = body,
			})
			Corner(cr, "full")
		end
		return w, h
	elseif style == "Tetes" then
		-- tetes darah: lingkaran + persegi diputar di atasnya
		local w = s + 3
		local h = s + 4
		local function Red(obj)
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new(Color3.fromRGB(238, 38, 48), Color3.fromRGB(140, 0, 16))
			g.Rotation = 90
			g.Parent = obj
		end
		local L = math.max(3, math.floor(w * 0.44))
		local sq = Make("Frame", {
			Size = UDim2.new(0, L, 0, L),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.36, 0),
			Rotation = 45,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Red(sq)
		local D = math.max(4, math.floor(w * 0.64))
		local ball = Make("Frame", {
			Size = UDim2.new(0, D, 0, D),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.66, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(ball, "full")
		Red(ball)
		local hi = Make("Frame", {
			Size = UDim2.new(0, math.max(2, math.floor(w * 0.16)), 0, math.max(2, math.floor(w * 0.16))),
			Position = UDim2.new(0.36, 0, 0.58, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(hi, "full")
		return w, h
	elseif style == "CyberKotak" then
		-- dua kotak neon saling bergeser (magenta garis + kuning isi)
		local mag = Color3.fromRGB(255, 30, 160)
		local yel = Color3.fromRGB(255, 232, 40)
		local w, h = s + 3, s + 3
		local a = Make("Frame", {
			Size = UDim2.new(0.68, 0, 0.68, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Stroke(a, mag, 1.6, 0.05)
		Make("Frame", {
			Size = UDim2.new(0.68, 0, 0.68, 0),
			Position = UDim2.new(0.32, 0, 0.32, 0),
			BackgroundColor3 = yel,
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		return w, h
	elseif style == "CyberGaris" then
		-- garis glitch: tiga batang datar berbeda panjang dan warna
		local w, h = s + 6, s
		local bh = math.max(2, math.floor(h * 0.24))
		for _, b in ipairs({
			{0.00, 0.00, 0.80, Color3.fromRGB(255, 30, 160)},
			{0.12, 0.38, 0.88, Color3.fromRGB(255, 232, 40)},
			{0.00, 0.76, 0.55, Color3.fromRGB(0, 240, 255)},
		}) do
			Make("Frame", {
				Size = UDim2.new(b[3], 0, 0, bh),
				Position = UDim2.new(b[1], 0, b[2], 0),
				BackgroundColor3 = b[4],
				BorderSizePixel = 0,
				Parent = parent,
			})
		end
		return w, h
	elseif style == "CyberPlus" then
		-- tanda plus kuning dengan bayangan magenta
		local w, h = s + 4, s + 4
		local t = math.max(2, math.floor(w * 0.24))
		for _, L in ipairs({
			{Color3.fromRGB(255, 30, 160), 0.60, 0.60, 1},
			{Color3.fromRGB(255, 232, 40), 0.50, 0.50, 2},
		}) do
			Make("Frame", {
				Size = UDim2.new(0.9, 0, 0, t),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(L[2], 0, L[3], 0),
				BackgroundColor3 = L[1],
				BorderSizePixel = 0,
				ZIndex = L[4],
				Parent = parent,
			})
			Make("Frame", {
				Size = UDim2.new(0, t, 0.9, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(L[2], 0, L[3], 0),
				BackgroundColor3 = L[1],
				BorderSizePixel = 0,
				ZIndex = L[4],
				Parent = parent,
			})
		end
		return w, h
	elseif style == "CyberVisor" then
		-- maskot: kacamata visor dengan garis cahaya berkedip
		local mag = Color3.fromRGB(255, 30, 160)
		local yel = Color3.fromRGB(255, 232, 40)
		local w, h = s + 8, s - 2
		local box = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = Color3.fromRGB(14, 8, 18),
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(box, 3)
		Stroke(box, mag, 1.2, 0.1)
		local bar = Make("Frame", {
			Size = UDim2.new(0.76, 0, 0, math.max(2, math.floor(h * 0.2))),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = yel,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = box,
		})
		Loop(bar, 0.6, {BackgroundTransparency = 0.7})
		return w, h
	elseif style == "GalBintang" then
		-- bintang berkilau 4 arah
		local w = s + 4
		local h = w
		local t = math.max(2, math.floor(w * 0.2))
		local bv = Make("Frame", {
			Size = UDim2.new(0, t, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(bv, "full")
		CFX.Grad(bv, list, 90)
		local bhz = Make("Frame", {
			Size = UDim2.new(1, 0, 0, t),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(bhz, "full")
		CFX.Grad(bhz, list, 0)
		local core = Make("Frame", {
			Size = UDim2.new(0, t + 2, 0, t + 2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(core, "full")
		return w, h
	elseif style == "Planet" then
		-- planet bercincin
		local w, h = s + 8, s + 4
		local d = math.max(4, math.floor(h * 0.78))
		local body = Make("Frame", {
			Size = UDim2.new(0, d, 0, d),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = parent,
		})
		Corner(body, "full")
		CFX.Grad(body, list, 60)
		local ring = Make("Frame", {
			Size = UDim2.new(1, 0, 0.36, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = -20,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(ring, "full")
		Stroke(ring, Color3.fromRGB(200, 185, 255), 1.3, 0.15)
		return w, h
	elseif style == "Meteor" then
		-- meteor: kepala bulat dengan ekor memudar
		local w, h = s + 8, s
		local d = math.max(3, math.floor(h * 0.6))
		local tail = Make("Frame", {
			Size = UDim2.new(1, -math.floor(d / 2), 0, math.max(2, math.floor(d * 0.5))),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -math.floor(d / 2), 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(tail, "full")
		local tg = CFX.Grad(tail, list, 0)
		tg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		local head = Make("Frame", {
			Size = UDim2.new(0, d, 0, d),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(head, "full")
		return w, h
	elseif style == "BHLubang" then
		-- lubang hitam: cakram panas di belakang, lubang hitam, pita cahaya di depan
		local amber = Color3.fromRGB(255, 170, 40)
		local w, h = s + 4, s + 4
		local disc = Make("Frame", {
			Size = UDim2.new(1, 0, 0.34, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = -18,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = parent,
		})
		Corner(disc, "full")
		CFX.Grad(disc, list, 0)
		local d = math.max(4, math.floor(h * 0.62))
		local hole = Make("Frame", {
			Size = UDim2.new(0, d, 0, d),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(hole, "full")
		Stroke(hole, amber, 1.4, 0.1)
		local band = Make("Frame", {
			Size = UDim2.new(0.92, 0, 0, math.max(1, math.floor(h * 0.1))),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.56, 0),
			Rotation = -18,
			BackgroundColor3 = amber,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = parent,
		})
		Corner(band, "full")
		return w, h
	elseif style == "BHCincin" then
		-- cincin cahaya mengelilingi titik hitam
		local w = s + 2
		local h = w
		local ring = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(ring, "full")
		Stroke(ring, Color3.fromRGB(255, 170, 40), 1.8, 0.1)
		local mid = Make("Frame", {
			Size = UDim2.new(0.56, 0, 0.56, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = parent,
		})
		Corner(mid, "full")
		Stroke(mid, Color3.fromRGB(190, 215, 255), 1.1, 0.4)
		local dot = Make("Frame", {
			Size = UDim2.new(0.26, 0, 0.26, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = parent,
		})
		Corner(dot, "full")
		return w, h
	elseif style == "BHPuing" then
		-- puing yang tersedot: serpihan miring dengan titik kecil
		local w = math.max(5, math.floor(s * 0.55))
		local h = s + 4
		local shard = Make("Frame", {
			Size = UDim2.new(1, -2, 0.8, 0),
			Position = UDim2.new(0, 1, 0, 0),
			Rotation = 25,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(shard, 2)
		CFX.Grad(shard, list, 90)
		local sp = Make("Frame", {
			Size = UDim2.new(0, 3, 0, 3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.92, 0),
			BackgroundColor3 = Color3.fromRGB(255, 190, 80),
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(sp, "full")
		return w, h
	elseif style == "SamKelopak" then
		-- kelopak sakura merah muda
		local w, h = s + 3, s + 3
		local petal = Make("Frame", {
			Size = UDim2.new(0.55, 0, 0.95, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = 25,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(petal, "full")
		CFX.Grad(petal, list, 90)
		Make("Frame", {
			Size = UDim2.new(0, 1, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.55, 0),
			BackgroundColor3 = Color3.fromRGB(255, 40, 70),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = petal,
		})
		return w, h
	elseif style == "SamBilah" then
		-- bilah katana miring: mata pedang putih berpinggir merah, pelindung, gagang
		local red = Color3.fromRGB(255, 40, 70)
		local w, h = s + 6, s + 6
		local t = math.max(2, math.floor(w * 0.2))
		local blade = Make("Frame", {
			Size = UDim2.new(0, t, 0.95, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = 40,
			BackgroundColor3 = Color3.fromRGB(235, 240, 245),
			BorderSizePixel = 0,
			Parent = parent,
		})
		Stroke(blade, red, 1, 0.2)
		Make("Frame", {
			Size = UDim2.new(1, 0, 0.26, 0),
			Position = UDim2.new(0, 0, 0.74, 0),
			BackgroundColor3 = red,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = blade,
		})
		Make("Frame", {
			Size = UDim2.new(0, math.max(4, math.floor(w * 0.5)), 0, math.max(2, math.floor(t * 0.9))),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.72, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = blade,
		})
		return w, h
	elseif style == "SamKamon" then
		-- lambang bulat merah dengan cincin putih
		local red = Color3.fromRGB(255, 40, 70)
		local w = s + 2
		local h = w
		local body = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundColor3 = red,
			BorderSizePixel = 0,
			Parent = parent,
		})
		Corner(body, "full")
		Stroke(body, Colors.White, 1.2, 0.2)
		local inner = Make("Frame", {
			Size = UDim2.new(0.34, 0, 0.34, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Parent = body,
		})
		Corner(inner, "full")
		return w, h
	end

	-- Kristal (bawaan)
	local w, h = s, s
	if shard then
		w, h = math.max(4, math.floor(s * 0.45)), s + 6
	end
	local body = Make("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundColor3 = Colors.White,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Corner(body, 2)
	CFX.Grad(body, list, math.random(0, 180))
	Stroke(body, Colors.White, 1, 0.55)

	local hi = Make("Frame", {
		Size = UDim2.new(0.38, 0, 0.38, 0),
		Position = UDim2.new(0.14, 0, 0.12, 0),
		BackgroundColor3 = Colors.White,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = body,
	})
	Corner(hi, 1)
	return w, h
end

function CFX.BaseRot(style, shard)
	if style == "Kristal" then
		return shard and math.random(-25, 25) or 45
	elseif style == "Kotak" then
		return math.random(-20, 20)
	end
	return math.random(-30, 30)
end

function CFX.Skin(e, style)
	for _, ch in ipairs(e.c:GetChildren()) do
		if not ch:IsA("UIScale") then ch:Destroy() end
	end
	table.clear(e.grads)
	local w, h = CFX.Build(e.c, style, e.s, e.shard, e.grads)
	e.c.Size = UDim2.new(0, w, 0, h)
end

local function SpawnCrystal()
	local shard = math.random() < 0.4
	local s = math.random(7, 15)

	-- CanvasGroup supaya seluruh hiasan bisa fade sekaligus
	local c = Make("CanvasGroup", {
		Size = UDim2.new(0, s, 0, s),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Rotation = CFX.BaseRot(CFX.Style, shard),
		ZIndex = 6,
		Parent = FX,
	})
	local e = {c = c, s = s, shard = shard, grads = {}}
	table.insert(CFX.List, e)
	OnTheme(function(T)
		for _, g in ipairs(e.grads) do
			g.Color = ColorSequence.new(T.Accent2, T.Accent)
		end
	end)
	CFX.Skin(e, CFX.Style)

	-- berkilau
	local sc = Instance.new("UIScale")
	sc.Parent = c
	Loop(sc, math.random(10, 22) / 10, {Scale = 1.2})

	local target = math.random(30, 60) / 100
	task.spawn(function()
		task.wait(math.random() * 5)
		while Alive() do
			if not Root.Visible then
				task.wait(0.5)
				continue
			end
			local down = math.random() < 0.7 -- sebagian jatuh, sebagian mengambang naik
			local x0 = math.random(8, MAIN_W - 8)
			local sway = math.random(-45, 45)
			local yA = down and -16 or (MAIN_H + 16)
			local yB = down and (MAIN_H + 16) or -16
			local dur = math.random(70, 130) / 10

			c.Position = UDim2.new(0, x0, 0, yA)
			Tween(c, dur, {
				Position = UDim2.new(0, x0 + sway, 0, yB),
				Rotation = c.Rotation + math.random(-100, 100),
			}, ES.Linear)
			Tween(c, 1, {GroupTransparency = target}, ES.Sine)
			task.wait(dur - 1)
			Tween(c, 1, {GroupTransparency = 1}, ES.Sine)
			task.wait(1)
		end
	end)
end

for _ = 1, 10 do SpawnCrystal() end

-- Ganti bentuk semua hiasan yang berterbangan
function CFX.Apply(name)
	CFX.Style = name
	for _, e in ipairs(CFX.List) do
		pcall(CFX.Skin, e, name)
	end
end

-- Jejak hiasan kecil di belakang tombol NH saat digeser
function CFX.Trail(btn)
	if not CFX.Spark or not Alive() then return end
	local now = os.clock()
	if now - (CFX.lastTrail or 0) < 0.06 then return end
	CFX.lastTrail = now
	local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
	local sz = math.random(5, 8)
	local holder = Make("CanvasGroup", {
		Size = UDim2.new(0, sz, 0, sz),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(pos.X + math.random(-6, 6), pos.Y + math.random(-6, 6)),
		BackgroundTransparency = 1,
		Active = false,
		Rotation = math.random(0, 180),
		ZIndex = 0,
		Parent = ScreenGui,
	})
	local w, h = CFX.Build(holder, CFX.Style, sz, false, {})
	holder.Size = UDim2.new(0, w, 0, h)
	Tween(holder, 0.55, {
		Position = UDim2.fromOffset(pos.X + math.random(-14, 14), pos.Y + math.random(10, 26)),
		Rotation = holder.Rotation + math.random(-100, 100),
		GroupTransparency = 1,
	}, ES.Quad, ED.Out)
	task.delay(0.6, function()
		holder:Destroy()
	end)
end

-- Percikan kecil (bentuk hiasan terpilih) menyebar dari tombol yang ditekan
function CFX.Burst(btn)
	if not CFX.Spark or not Alive() then return end
	local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
	for i = 1, 6 do
		local sz = math.random(6, 9)
		local holder = Make("CanvasGroup", {
			Size = UDim2.new(0, sz, 0, sz),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(pos.X, pos.Y),
			BackgroundTransparency = 1,
			Active = false,
			Rotation = math.random(0, 180),
			ZIndex = 200,
			Parent = ScreenGui,
		})
		local w, h = CFX.Build(holder, CFX.Style, sz, false, {})
		holder.Size = UDim2.new(0, w, 0, h)
		local ang = (i / 6) * math.pi * 2 + (math.random() - 0.5) * 0.6
		local dist = math.random(20, 36)
		local dur = 0.45 + math.random() * 0.15
		Tween(holder, dur, {
			Position = UDim2.fromOffset(pos.X + math.cos(ang) * dist, pos.Y + math.sin(ang) * dist),
			Rotation = holder.Rotation + math.random(-140, 140),
			GroupTransparency = 1,
		}, ES.Quad, ED.Out)
		task.delay(dur + 0.05, function()
			holder:Destroy()
		end)
	end
end


-------------------------------------------------
-- TITLE BAR
-------------------------------------------------
local TitleBar = Make("Frame", {
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Colors.White,
	BorderSizePixel = 0,
	Parent = Main,
})
BGrad(TitleBar, "Title0", "Title1", 90)

local Divider = Make("Frame", {
	Size = UDim2.new(1, -24, 0, 1),
	Position = UDim2.new(0, 12, 1, -1),
	BackgroundColor3 = Cur.Accent,
	BorderSizePixel = 0,
	Parent = TitleBar,
})
Bind(Divider, "BackgroundColor3", "Accent")
do
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = Divider
end

local TitleHolder = Make("Frame", {
	Size = UDim2.new(0, 200, 1, 0),
	Position = UDim2.new(0, 14, 0, 0),
	BackgroundTransparency = 1,
	Parent = TitleBar,
})
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.Padding = UDim.new(0, 7)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = TitleHolder
end

local Title = Label({
	Size = UDim2.new(0, 0, 1, 0),
	AutomaticSize = Enum.AutomaticSize.X,
	Text = "NimeroHub",
	Font = Enum.Font.GothamBlack,
	TextSize = 17,
	TextColor3 = Colors.White,
	LayoutOrder = 1,
	Parent = TitleHolder,
})
do
	local g = Grad(Title, Colors.White, Cur.Accent2, 0)
	OnTheme(function(T) g.Color = ColorSequence.new(Colors.White, T.Accent2) end)
end

local SubTitle = Label({
	Size = UDim2.new(0, 0, 1, 0),
	AutomaticSize = Enum.AutomaticSize.X,
	Text = "• v2.1",
	TextSize = 11,
	LayoutOrder = 2,
	Parent = TitleHolder,
})
Bind(SubTitle, "TextColor3", "Accent2")

local StatusDot = Make("Frame", {
	Size = UDim2.new(0, 7, 0, 7),
	Position = UDim2.new(1, -48, 0.5, -3.5),
	BackgroundColor3 = Colors.Green,
	BorderSizePixel = 0,
	Parent = TitleBar,
})
Corner(StatusDot, "full")
Loop(StatusDot, 1.1, {BackgroundTransparency = 0.6})

local StatusText = Label({
	Size = UDim2.new(0, 26, 0, 14),
	Position = UDim2.new(1, -38, 0.5, -7),
	Text = "ON",
	TextSize = 10,
	TextColor3 = Colors.Green,
	Parent = TitleBar,
})

-------------------------------------------------
-- MENU TEMA (title bar)
-------------------------------------------------
local ThemeHolder = Make("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -62, 0.5, 0),
	Size = UDim2.new(0, 0, 0, 24),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = TitleBar,
})
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.Padding = UDim.new(0, 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = ThemeHolder
end

local ThemeLbl = Label({
	Size = UDim2.new(0, 0, 1, 0),
	AutomaticSize = Enum.AutomaticSize.X,
	Text = "TEMA",
	TextSize = 9,
	LayoutOrder = 0,
	Parent = ThemeHolder,
})
Bind(ThemeLbl, "TextColor3", "TextDim")

local Swatches = {}

local function RefreshSwatches()
	for i, s in ipairs(Swatches) do
		local active = (i == ThemeIdx) and not CFX.ModeCur
		Tween(s.stroke, 0.3, {Transparency = active and 0 or 1})
		Tween(s.scale, 0.35, {Scale = active and 1.12 or 1}, ES.Back)
	end
end

local SetTheme, OpenPicker, ClosePicker, TogglePicker -- didefinisikan di bawah

for i, th in ipairs(Themes) do
	local btn = Make("TextButton", {
		Size = UDim2.new(0, 30, 0, 16),
		BackgroundColor3 = Colors.White,
		Text = th.custom and "+" or "",
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = Colors.White,
		TextStrokeTransparency = 0.5,
		AutoButtonColor = false,
		LayoutOrder = i,
		Parent = ThemeHolder,
	})
	Corner(btn, "full")
	local g = Grad(btn, th.colors.Accent, th.colors.Accent2, 0)
	local st = Stroke(btn, Colors.White, 1.5, 1)
	local sc = Instance.new("UIScale")
	sc.Parent = btn
	Swatches[i] = {btn = btn, stroke = st, scale = sc, grad = g}

	btn.MouseEnter:Connect(function()
		if i ~= ThemeIdx then Tween(sc, 0.2, {Scale = 1.08}) end
	end)
	btn.MouseLeave:Connect(function()
		if i ~= ThemeIdx then Tween(sc, 0.25, {Scale = 1}) end
	end)
	btn.MouseButton1Click:Connect(function()
		PlayClick("pilih")
		if th.custom then
			if ThemeIdx == i and not CFX.ModeCur then
				TogglePicker()
			else
				SetTheme(i)
				OpenPicker()
			end
		else
			SetTheme(i)
		end
	end)
end

-------------------------------------------------
-- SIDEBAR
-------------------------------------------------
local Sidebar = Make("Frame", {
	Size = UDim2.new(0, 118, 1, -52),
	Position = UDim2.new(0, 9, 0, 44),
	BackgroundColor3 = Colors.White,
	BorderSizePixel = 0,
	Parent = Main,
})
Corner(Sidebar, 12)
BGrad(Sidebar, "Side0", "Side1", 90)
do
	local s = Stroke(Sidebar, Cur.Accent, 1, 0.8)
	Bind(s, "Color", "Accent")
end

-------------------------------------------------
-- LOGO NH + GLITCH
-------------------------------------------------
local LogoContainer = Make("Frame", {
	Size = UDim2.new(0, 42, 0, 42),
	Position = UDim2.new(0.5, -21, 0, 10),
	BackgroundTransparency = 1,
	Parent = Sidebar,
})

local LogoCircle = Make("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Colors.White,
	BorderSizePixel = 0,
	ZIndex = 1,
	Parent = LogoContainer,
})
Corner(LogoCircle, "full")
BGrad(LogoCircle, "Accent", "Accent2", 45)
local LogoStroke = Stroke(LogoCircle, Cur.Accent2, 1.5, 0.1)
Bind(LogoStroke, "Color", "Accent2")
Loop(LogoStroke, 1.3, {Transparency = 0.7})

-- efek hacker: cincin pemindai + titik berputar di logo N, dan teks NH berkedip
;(function()
	pcall(function()
		local function Orbit(parent, radius, t)
			local holder = Make("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				ZIndex = 4,
				Active = false,
				Parent = parent,
			})
			local dot = Make("Frame", {
				Size = UDim2.new(0, 4, 0, 4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, radius, 0, 0),
				BackgroundColor3 = Cur.Accent2,
				BorderSizePixel = 0,
				ZIndex = 5,
				Active = false,
				Parent = holder,
			})
			Corner(dot, 2)
			Bind(dot, "BackgroundColor3", "Accent2")
			Spin(holder, t)
		end

		-- cincin tipis berkedip di sekeliling logo N
		local ring = Make("Frame", {
			Size = UDim2.new(1, 6, 1, 6),
			Position = UDim2.new(0, -3, 0, -3),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Active = false,
			Parent = LogoContainer,
		})
		Corner(ring, "full")
		local rs = Stroke(ring, Cur.Accent, 1.2, 0.3)
		Bind(rs, "Color", "Accent")
		Loop(rs, 1.4, {Transparency = 0.7})
		Orbit(LogoContainer, 23, 3.2)

		-- titik berputar di tombol NH
		Orbit(NHButton, 27, 2.6)

		-- teks NH berkedip ke karakter acak sebentar, lalu kembali
		task.spawn(function()
			local frames = {"N#", "#H", "N/", "NH"}
			while Alive() do
				task.wait(math.random(30, 50) / 10)
				for _, f in ipairs(frames) do
					NHButton.Text = f
					task.wait(0.07)
				end
				NHButton.Text = "NH"
			end
		end)
	end)
end)()

local function LogoLayer(color, x, z, transparency)
	return Label({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, x, 0, 0),
		Text = "N",
		Font = Enum.Font.GothamBlack,
		TextSize = 19,
		TextColor3 = color,
		TextTransparency = transparency,
		ZIndex = z,
		Parent = LogoContainer,
	})
end
local LogoG1 = LogoLayer(Colors.GlitchCyan, -2, 2, 0.7)
local LogoG2 = LogoLayer(Colors.GlitchRed, 2, 2, 0.7)
LogoLayer(Colors.White, 0, 3, 0)
Glitcher(LogoG1, LogoG2, -2, 2, 0.7, 0.15, 6, 1.2, 2.8)

-------------------------------------------------
-- TOAST
-------------------------------------------------
local Toast = Make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 30),
	Size = UDim2.new(0, 0, 0, 26),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 50,
	Parent = Main,
})
Bind(Toast, "BackgroundColor3", "Box")
Corner(Toast, "full")
local ToastStroke = Stroke(Toast, Cur.Accent, 1, 1)
Bind(ToastStroke, "Color", "Accent")
do
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 14)
	p.PaddingRight = UDim.new(0, 14)
	p.Parent = Toast
end
local ToastLabel = Label({
	Size = UDim2.new(0, 0, 1, 0),
	AutomaticSize = Enum.AutomaticSize.X,
	Text = "",
	TextSize = 11,
	TextTransparency = 1,
	ZIndex = 51,
	Parent = Toast,
})
local toastToken = 0
local function ShowToast(text)
	pcall(function()
		local okT, tm = pcall(function() return DateTime.now():FormatLocalTime("HH:mm:ss", "en-us") end)
		table.insert(SV.notif, 1, {text = tostring(text), time = okT and tm or "--:--:--"})
		while #SV.notif > 20 do table.remove(SV.notif) end
	end)
	toastToken += 1
	local my = toastToken
	ToastLabel.Text = text
	Tween(Toast, 0.4, {Position = UDim2.new(0.5, 0, 1, -12), BackgroundTransparency = 0.05}, ES.Back)
	Tween(ToastLabel, 0.25, {TextTransparency = 0})
	Tween(ToastStroke, 0.25, {Transparency = 0.3})
	task.delay(1.6, function()
		if my ~= toastToken then return end
		Tween(Toast, 0.3, {Position = UDim2.new(0.5, 0, 1, 30), BackgroundTransparency = 1}, ES.Quad, ED.In)
		Tween(ToastLabel, 0.2, {TextTransparency = 1})
		Tween(ToastStroke, 0.2, {Transparency = 1})
	end)
end

-------------------------------------------------
-- FPS BOOST (tombol di title bar, tekan = nyala, tekan lagi = mati)
-------------------------------------------------
do
	local okB, errB = pcall(function()
	local Lighting = game:GetService("Lighting")
	local Terrain = workspace:FindFirstChildOfClass("Terrain")
	local on = false
	local token = 0
	local conn
	local orig = setmetatable({}, {__mode = "k"})
	local saved = {}

	local FPSBtn = Make("TextButton", {
		Name = "FPSBoost",
		Size = UDim2.new(0, 84, 0, 20),
		Position = UDim2.new(0, 146, 0.5, -10),
		BackgroundColor3 = Cur.Btn,
		Text = "FPS BOOST",
		Font = Enum.Font.GothamBlack,
		TextSize = 10,
		TextColor3 = Colors.Text,
		AutoButtonColor = false,
		Parent = TitleBar,
	})
	Corner(FPSBtn, "full")
	local FPSStroke = Stroke(FPSBtn, Cur.Accent, 1, 0.4)
	Bind(FPSStroke, "Color", "Accent")
	local FPSScale = Instance.new("UIScale")
	FPSScale.Parent = FPSBtn
	FPSBtn.MouseButton1Down:Connect(function() Tween(FPSScale, 0.08, {Scale = 0.94}, ES.Quad) end)
	FPSBtn.MouseButton1Up:Connect(function() Tween(FPSScale, 0.25, {Scale = 1}, ES.Back) end)

	local function Paint(animate)
		local bg = on and Cur.Accent or Cur.Btn
		if animate then
			Tween(FPSBtn, 0.25, {BackgroundColor3 = bg})
		else
			FPSBtn.BackgroundColor3 = bg
		end
		FPSBtn.TextColor3 = on and Colors.White or Colors.Text
	end
	OnTheme(function() Paint(false) end)

	local function InCharacter(inst)
		local m = inst:FindFirstAncestorOfClass("Model")
		while m do
			if m:FindFirstChildOfClass("Humanoid") then return true end
			m = m:FindFirstAncestorOfClass("Model")
		end
		return false
	end

	local function BoostInst(d)
		if orig[d] then return end
		if d:IsA("BasePart") then
			if d:IsA("Terrain") or InCharacter(d) then return end
			if d.Material ~= Enum.Material.SmoothPlastic or d.Reflectance ~= 0 then
				orig[d] = {Material = d.Material, Reflectance = d.Reflectance}
				d.Material = Enum.Material.SmoothPlastic
				d.Reflectance = 0
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire")
			or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("PostEffect") then
			if d.Enabled then
				orig[d] = {Enabled = true}
				d.Enabled = false
			end
		end
	end

	local function Start()
		token += 1
		local my = token
		pcall(function()
			saved.shadows = Lighting.GlobalShadows
			Lighting.GlobalShadows = false
		end)
		pcall(function()
			saved.quality = settings().Rendering.QualityLevel
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end)
		if Terrain then
			pcall(function()
				saved.wave = {Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance}
				Terrain.WaterWaveSize = 0
				Terrain.WaterWaveSpeed = 0
				Terrain.WaterReflectance = 0
			end)
		end
		for _, d in ipairs(Lighting:GetDescendants()) do pcall(BoostInst, d) end
		conn = workspace.DescendantAdded:Connect(function(d) pcall(BoostInst, d) end)
		task.spawn(function()
			local n = 0
			for _, d in ipairs(workspace:GetDescendants()) do
				if my ~= token or not on then return end
				pcall(BoostInst, d)
				n += 1
				if n % 300 == 0 then task.wait() end
			end
		end)
	end

	local function Stop()
		token += 1
		local my = token
		if conn then conn:Disconnect() conn = nil end
		pcall(function()
			if saved.shadows ~= nil then Lighting.GlobalShadows = saved.shadows end
		end)
		pcall(function()
			if saved.quality then settings().Rendering.QualityLevel = saved.quality end
		end)
		if Terrain and saved.wave then
			pcall(function()
				Terrain.WaterWaveSize = saved.wave[1]
				Terrain.WaterWaveSpeed = saved.wave[2]
				Terrain.WaterReflectance = saved.wave[3]
			end)
		end
		table.clear(saved)
		task.spawn(function()
			local n = 0
			for d, o in pairs(orig) do
				if my ~= token then return end
				pcall(function()
					for k, v in pairs(o) do d[k] = v end
				end)
				orig[d] = nil
				n += 1
				if n % 300 == 0 then task.wait() end
			end
		end)
	end

	FPSBtn.MouseButton1Click:Connect(function()
		on = not on
		PlayClick(on and "on" or "off")
		Paint(true)
		if on then Start() else Stop() end
		ShowToast(on and "FPS Boost: ON" or "FPS Boost: OFF")
	end)

	ScreenGui.Destroying:Connect(function()
		if on then
			on = false
			pcall(Stop)
		end
	end)
	end)
	if not okB then table.insert(BootErr, "FPS Boost: " .. tostring(errB)) end
end

-------------------------------------------------
-- GANTI TEMA (transisi halus)
-------------------------------------------------
local themeToken = 0
SetTheme = function(idx)
	if idx ~= CUSTOM then ClosePicker() end
	local wasMode = CFX.ModeCur ~= nil
	if wasMode then CFX.ExitMode(true) end
	if idx == ThemeIdx and not wasMode then return end
	ThemeIdx = idx
	SV.Set("theme", idx)
	themeToken += 1
	local my = themeToken

	local from = {}
	for k, v in pairs(Cur) do from[k] = v end
	local to = Themes[idx].colors

	RefreshSwatches()
	ShowToast("Tema: " .. Themes[idx].name)

	task.spawn(function()
		local t0 = os.clock()
		local dur = 0.55
		while my == themeToken and Alive() do
			local a = math.clamp((os.clock() - t0) / dur, 0, 1)
			local e = 1 - (1 - a) ^ 3
			for k, v in pairs(to) do
				Cur[k] = from[k]:Lerp(v, e)
			end
			for _, fn in ipairs(Hooks) do fn(Cur) end
			if a >= 1 then break end
			RunService.Heartbeat:Wait()
		end
	end)
end

task.defer(RefreshSwatches)

-- Putar warna UI ke satu set warna tema
function CFX.TweenTo(to)
	themeToken += 1
	local my = themeToken
	local from = {}
	for k, v in pairs(Cur) do from[k] = v end
	task.spawn(function()
		local t0 = os.clock()
		local dur = 0.55
		while my == themeToken and Alive() do
			local a = math.clamp((os.clock() - t0) / dur, 0, 1)
			local e = 1 - (1 - a) ^ 3
			for k, v in pairs(to) do
				Cur[k] = from[k]:Lerp(v, e)
			end
			for _, fn in ipairs(Hooks) do fn(Cur) end
			if a >= 1 then break end
			RunService.Heartbeat:Wait()
		end
	end)
end

-- MODE SPESIAL: tiap mode punya warna, hiasan, maskot sidebar, font (opsional), dan suara
CFX.Modes = {
	Helowin = {
		name = "Helowin", style = "Helowin", mascot = "Labu", preview = "Labu", sfx = "spooky",
		colors = {
			Accent = C(255, 122, 24), Accent2 = C(165, 75, 235), Dark = C(84, 36, 10),
			BG0 = C(19, 11, 17), BG1 = C(9, 5, 9),
			Card0 = C(29, 16, 25), Card1 = C(18, 10, 16),
			Title0 = C(32, 17, 26), Title1 = C(19, 10, 15),
			Side0 = C(24, 13, 21), Side1 = C(14, 8, 13),
			Box = C(35, 19, 29), Btn = C(52, 28, 38), TextDim = C(190, 155, 135),
		},
	},
	Hacker = {
		name = "Hacker", style = "Kode", mascot = "Terminal", preview = "Kode", font = "Code", sfx = "hack",
		colors = {
			Accent = C(0, 235, 90), Accent2 = C(150, 255, 60), Dark = C(0, 70, 25),
			BG0 = C(5, 12, 7), BG1 = C(1, 5, 2),
			Card0 = C(9, 21, 12), Card1 = C(4, 12, 6),
			Title0 = C(10, 24, 14), Title1 = C(5, 13, 7),
			Side0 = C(7, 17, 10), Side1 = C(3, 9, 5),
			Box = C(11, 27, 16), Btn = C(16, 40, 24), TextDim = C(110, 200, 135),
		},
	},
	BloodMoon = {
		name = "Blood Moon", style = "BloodMoon", mascot = "BulanDarah", preview = "BulanDarah", sfx = "darah",
		colors = {
			Accent = C(196, 18, 32), Accent2 = C(255, 92, 42), Dark = C(84, 10, 16),
			BG0 = C(21, 6, 8), BG1 = C(9, 3, 4),
			Card0 = C(31, 9, 12), Card1 = C(19, 6, 8),
			Title0 = C(35, 10, 13), Title1 = C(21, 6, 8),
			Side0 = C(26, 8, 10), Side1 = C(15, 5, 6),
			Box = C(39, 11, 15), Btn = C(58, 16, 22), TextDim = C(195, 142, 138),
		},
	},
	Cyberpunk = {
		name = "Cyberpunk", style = "Cyber", mascot = "CyberVisor", preview = "Cyber", font = "Jura", sfx = "cyber",
		colors = {
			Accent = C(255, 20, 150), Accent2 = C(255, 225, 40), Dark = C(92, 10, 64),
			BG0 = C(17, 13, 8), BG1 = C(7, 5, 3),
			Card0 = C(28, 22, 11), Card1 = C(17, 13, 7),
			Title0 = C(30, 24, 11), Title1 = C(18, 14, 7),
			Side0 = C(22, 17, 9), Side1 = C(13, 10, 5),
			Box = C(35, 27, 12), Btn = C(54, 41, 15), TextDim = C(205, 190, 120),
		},
	},
	Galaxy = {
		name = "Galaxy", style = "Galaxy", mascot = "Planet", preview = "Galaxy", sfx = "galaxy",
		colors = {
			Accent = C(140, 80, 255), Accent2 = C(60, 140, 255), Dark = C(30, 24, 96),
			BG0 = C(8, 10, 30), BG1 = C(3, 5, 17),
			Card0 = C(14, 18, 46), Card1 = C(8, 11, 29),
			Title0 = C(15, 19, 50), Title1 = C(9, 12, 31),
			Side0 = C(11, 14, 38), Side1 = C(6, 8, 24),
			Box = C(18, 23, 58), Btn = C(28, 34, 86), TextDim = C(150, 165, 225),
		},
	},
	BlackHole = {
		name = "Black Hole", style = "LubangHitam", mascot = "BHLubang", preview = "LubangHitam", sfx = "lubang",
		colors = {
			Accent = C(230, 130, 20), Accent2 = C(150, 185, 255), Dark = C(84, 44, 6),
			BG0 = C(8, 7, 8), BG1 = C(2, 2, 3),
			Card0 = C(17, 14, 15), Card1 = C(9, 7, 8),
			Title0 = C(19, 15, 16), Title1 = C(10, 8, 9),
			Side0 = C(13, 10, 11), Side1 = C(6, 5, 6),
			Box = C(23, 19, 21), Btn = C(38, 31, 34), TextDim = C(190, 165, 150),
		},
	},
	Samurai = {
		name = "Neon Samurai", style = "Samurai", mascot = "SamKamon", preview = "Samurai", sfx = "katana",
		colors = {
			Accent = C(255, 40, 70), Accent2 = C(240, 240, 240), Dark = C(96, 12, 26),
			BG0 = C(10, 8, 10), BG1 = C(4, 3, 5),
			Card0 = C(20, 14, 17), Card1 = C(11, 8, 10),
			Title0 = C(22, 15, 18), Title1 = C(12, 8, 10),
			Side0 = C(16, 11, 14), Side1 = C(8, 6, 8),
			Box = C(27, 18, 22), Btn = C(42, 26, 32), TextDim = C(192, 172, 177),
		},
	},
}
CFX.ModeOrder = {"Helowin", "Hacker", "BloodMoon", "Cyberpunk", "Galaxy", "BlackHole", "Samurai"}

function CFX.EnterMode(key, silent)
	local m = CFX.Modes[key]
	if not m then return end
	SV.hackOn = (key == "Hacker")
	if SV.hackOn and SV.decrypt then SV.decrypt() end
	if SV.applyNames then SV.applyNames(SV.hackOn) end
	CFX.ModeCur = key
	RefreshSwatches()
	CFX.TweenTo(m.colors)
	CFX.Apply(m.style)
	if CFX.SetMascot then CFX.SetMascot(m.mascot) end
	if CFX.SetFont then CFX.SetFont(m.font) end
	SV.Set("mode", key)
	if not silent then
		PlayClick(m.sfx or "pilih")
		ShowToast("Mode: " .. m.name)
	end
end

function CFX.ExitMode(silent)
	SV.hackOn = false
	if SV.applyNames then SV.applyNames(false) end
	if not CFX.ModeCur then return end
	CFX.ModeCur = nil
	RefreshSwatches()
	local back = "Kristal"
	for _, n in ipairs(CFX.Names) do
		if n == SV.cur.hiasan then back = n end
	end
	CFX.Apply(back)
	if CFX.SetMascot then CFX.SetMascot(nil) end
	if CFX.SetFont then CFX.SetFont(nil) end
	SV.Set("mode", "Normal")
	if not silent then
		CFX.TweenTo(Themes[ThemeIdx].colors)
		ShowToast("Mode: Normal")
	end
end

-- Terapkan warna kustom langsung (dipanggil saat slider digeser)
local function ApplyCustom()
	local a, b = CustomColor(1), CustomColor(2)
	Themes[CUSTOM].colors = MakeTheme(a, b)
	Swatches[CUSTOM].grad.Color = ColorSequence.new(a, b)
	if ThemeIdx == CUSTOM and not CFX.ModeCur then
		themeToken += 1 -- hentikan transisi yang masih jalan
		for k, v in pairs(Themes[CUSTOM].colors) do Cur[k] = v end
		for _, fn in ipairs(Hooks) do fn(Cur) end
	end
	SV.Set("custom", {
		{CustomHSV[1][1], CustomHSV[1][2], CustomHSV[1][3]},
		{CustomHSV[2][1], CustomHSV[2][2], CustomHSV[2][3]},
	})
end
Swatches[CUSTOM].grad.Color = ColorSequence.new(CustomColor(1), CustomColor(2))

-------------------------------------------------
-- PEMILIH WARNA KUSTOM (semua warna: hue / pekat / terang)
-------------------------------------------------
local EditSlot = 1
local pickerOpen = false
local pickerToken = 0
local activeSlider = nil
local Chips, Sliders = {}, {}

local Picker = Make("CanvasGroup", {
	Name = "Picker",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 34),
	Size = UDim2.new(0, 232, 0, 160),
	BackgroundTransparency = 1,
	GroupTransparency = 1,
	Visible = false,
	ZIndex = 40,
	Parent = Main,
})
Corner(Picker, 12)

local PBG = Make("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Colors.White,
	BorderSizePixel = 0,
	Active = true, -- supaya sentuhan tidak tembus ke tombol di bawahnya
	Parent = Picker,
})
BGrad(PBG, "Card0", "Card1", 90)

local PBorder = Make("Frame", {
	Size = UDim2.new(1, -2, 1, -2),
	Position = UDim2.new(0, 1, 0, 1),
	BackgroundTransparency = 1,
	Parent = Picker,
})
Corner(PBorder, 11)
do
	local s = Stroke(PBorder, Cur.Accent, 1.2, 0.2)
	Bind(s, "Color", "Accent")
end

Label({
	Size = UDim2.new(1, -40, 0, 16),
	Position = UDim2.new(0, 10, 0, 8),
	Text = "WARNA KUSTOM",
	Font = Enum.Font.GothamBlack,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = Picker,
})

local PClose = Make("TextButton", {
	Size = UDim2.new(0, 22, 0, 18),
	Position = UDim2.new(1, -30, 0, 7),
	BackgroundColor3 = Cur.Btn,
	Text = "X",
	Font = Enum.Font.GothamBlack,
	TextSize = 10,
	TextColor3 = Colors.Text,
	AutoButtonColor = false,
	Parent = Picker,
})
Corner(PClose, 6)
Interactive(PClose, "Btn", "Accent")

local function RefreshPicker(animate)
	local c = CustomHSV[EditSlot]
	local h, s, v = c[1], c[2], c[3]
	Sliders[2].grad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
	Sliders[3].grad.Color = ColorSequence.new(Color3.fromHSV(h, s, 0.2), Color3.fromHSV(h, s, 1))

	local ts = {h, s, (v - 0.2) / 0.8}
	for n, sl in ipairs(Sliders) do
		local pos = UDim2.new(ts[n], 0, 0.5, 0)
		if animate then
			Tween(sl.knob, 0.3, {Position = pos})
		else
			sl.knob.Position = pos
		end
	end
	for i, ch in ipairs(Chips) do
		ch.btn.BackgroundColor3 = CustomColor(i)
		local tr = (i == EditSlot) and 0 or 1
		if animate then
			Tween(ch.stroke, 0.2, {Transparency = tr})
		else
			ch.stroke.Transparency = tr
		end
	end
end

-- Pilihan warna 1 / warna 2
for i = 1, 2 do
	local chip = Make("TextButton", {
		Size = UDim2.new(0, 100, 0, 22),
		Position = UDim2.new(0, 10 + (i - 1) * 112, 0, 30),
		BackgroundColor3 = CustomColor(i),
		Text = "WARNA " .. i,
		Font = Enum.Font.GothamBlack,
		TextSize = 10,
		TextColor3 = Colors.White,
		TextStrokeTransparency = 0.5,
		AutoButtonColor = false,
		Parent = Picker,
	})
	Corner(chip, 8)
	local st = Stroke(chip, Colors.White, 1.5, 1)
	Chips[i] = {btn = chip, stroke = st}
	chip.MouseButton1Click:Connect(function()
		PlayClick()
		EditSlot = i
		RefreshPicker(true)
	end)
end

-- Slider
local rainbow = {}
for i = 0, 6 do
	table.insert(rainbow, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
end

local function UpdateSliderFromX(sl, x)
	local t = math.clamp((x - sl.track.AbsolutePosition.X) / math.max(sl.track.AbsoluteSize.X, 1), 0, 1)
	local c = CustomHSV[EditSlot]
	if sl.key == 1 then
		c[1] = math.min(t, 0.999)
	elseif sl.key == 2 then
		c[2] = t
	else
		c[3] = 0.2 + 0.8 * t
	end
	ApplyCustom()
	RefreshPicker(false)
end

local SliderDefs = {"Warna", "Pekat", "Terang"}
for n, name in ipairs(SliderDefs) do
	local y = 68 + (n - 1) * 30

	local lbl = Label({
		Size = UDim2.new(0, 40, 0, 16),
		Position = UDim2.new(0, 10, 0, y - 8),
		Text = name,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Picker,
	})
	Bind(lbl, "TextColor3", "TextDim")

	local hit = Make("Frame", {
		Size = UDim2.new(0, 182, 0, 26),
		Position = UDim2.new(0, 48, 0, y - 13),
		BackgroundTransparency = 1,
		Active = true,
		Parent = Picker,
	})
	local track = Make("Frame", {
		Size = UDim2.new(1, -16, 0, 12),
		Position = UDim2.new(0, 8, 0.5, -6),
		BackgroundColor3 = Colors.White,
		BorderSizePixel = 0,
		Parent = hit,
	})
	Corner(track, "full")
	local tg = Grad(track, Colors.White, Colors.White, 0)
	if n == 1 then tg.Color = ColorSequence.new(rainbow) end

	local knob = Make("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Colors.White,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	})
	Corner(knob, "full")
	Stroke(knob, Color3.fromRGB(0, 0, 0), 1.5, 0.45)

	local sl = {key = n, track = track, knob = knob, grad = tg}
	Sliders[n] = sl

	hit.InputBegan:Connect(function(input)
		if IsPointer(input) then
			activeSlider = sl
			UpdateSliderFromX(sl, input.Position.X)
		end
	end)
end

OpenPicker = function()
	if pickerOpen then return end
	pickerOpen = true
	pickerToken += 1
	Picker.Visible = true
	Picker.GroupTransparency = 1
	Picker.Position = UDim2.new(1, -12, 0, 30)
	RefreshPicker(false)
	Tween(Picker, 0.45, {GroupTransparency = 0, Position = UDim2.new(1, -12, 0, 42)}, ES.Back)
end

ClosePicker = function()
	if not pickerOpen then return end
	pickerOpen = false
	activeSlider = nil
	pickerToken += 1
	local my = pickerToken
	Tween(Picker, 0.22, {GroupTransparency = 1, Position = UDim2.new(1, -12, 0, 34)}, ES.Quad, ED.In)
	task.delay(0.25, function()
		if my == pickerToken then Picker.Visible = false end
	end)
end

TogglePicker = function()
	if pickerOpen then ClosePicker() else OpenPicker() end
end

PClose.MouseButton1Click:Connect(function()
	PlayClick()
	ClosePicker()
end)

-------------------------------------------------
-- CONTENT + PAGES
-------------------------------------------------
local Content = Make("Frame", {
	Size = UDim2.new(1, -144, 1, -56),
	Position = UDim2.new(0, 135, 0, 46),
	BackgroundTransparency = 1,
	Parent = Main,
})

local Pages = {}
local PAGE_BASE = UDim2.new(0, -4, 0, -4)

local function CreatePage(name)
	local group = Make("CanvasGroup", {
		Name = name,
		Size = UDim2.new(1, 8, 1, 8),
		Position = PAGE_BASE,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = Content,
	})
	local inner = Make("Frame", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.new(0, 4, 0, 4),
		BackgroundTransparency = 1,
		Parent = group,
	})
	Pages[name] = group
	return inner
end

local InfoPage = CreatePage("INFO")
local FightPage = CreatePage("Pertarungan")
local GlitchPage = CreatePage("Glitches")
local UIPage = CreatePage("UI Customs")
local VisualPage = CreatePage("Visual")
local OtherPage = CreatePage("Lain-lain")

local function AddPlaceholder(page, text)
	local lbl = Label({
		Size = UDim2.new(1, -16, 0, 40),
		Position = UDim2.new(0, 8, 0.4, 0),
		Text = text,
		TextSize = 14,
		TextTransparency = 0.15,
		Parent = page,
	})
	Bind(lbl, "TextColor3", "TextDim")
	Loop(lbl, 1.6, {TextTransparency = 0.6})
end

AddPlaceholder(FightPage, "Pertarungan — Coming Soon")
AddPlaceholder(GlitchPage, "Glitches — Coming Soon")
AddPlaceholder(UIPage, "UI Customs — Coming Soon")
AddPlaceholder(VisualPage, "Visual — Coming Soon")

-------------------------------------------------
-- TAB BUTTONS + INDIKATOR
-------------------------------------------------
local TabButtons = {}
local TabNames = {"INFO", "Pertarungan", "Glitches", "UI Customs", "Visual", "Lain-lain"}
local CurrentTab

local function TabY(i)
	return 62 + ((i - 1) * 36)
end

local Indicator = Make("Frame", {
	Size = UDim2.new(1, -12, 0, 30),
	Position = UDim2.new(0, 6, 0, TabY(1)),
	BackgroundColor3 = Colors.White,
	BorderSizePixel = 0,
	ZIndex = 1,
	Parent = Sidebar,
})
Corner(Indicator, 8)
BGrad(Indicator, "Accent", "Accent2", 0)

OnTheme(function(T)
	for n, btn in pairs(TabButtons) do
		if n ~= CurrentTab then btn.TextColor3 = T.TextDim end
	end
end)

-------------------------------------------------
-- JARING LABA-LABA + EFEK RADAR (pojok kanan bawah kartu Tentang, warnanya ikut tema)
-------------------------------------------------
;(function()
	pcall(function()
		local web = Make("Frame", {
			Name = "WebLogo",
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(0, 504, 0, 292),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Active = false,
			Parent = Main,
		})
		local function Ring(size)
			local r = Make("Frame", {
				Size = UDim2.new(0, size, 0, size),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				ZIndex = 6,
				Active = false,
				Parent = web,
			})
			Corner(r, size / 2)
			local st = Stroke(r, Cur.Accent, 1.2, 0)
			Bind(st, "Color", "Accent")
		end
		Ring(30)
		Ring(20)
		Ring(10)
		for _, rot in ipairs({0, 45, 90, 135}) do
			local s = Make("Frame", {
				Size = UDim2.new(0, 1.5, 0, 30),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = rot,
				BackgroundColor3 = Cur.Accent,
				BorderSizePixel = 0,
				ZIndex = 6,
				Active = false,
				Parent = web,
			})
			Bind(s, "BackgroundColor3", "Accent")
		end

		-- garis sapuan radar yang berputar terus
		local sweep = Make("Frame", {
			Size = UDim2.new(0, 1.5, 0, 15),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Cur.Accent,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			ZIndex = 6,
			Active = false,
			Parent = web,
		})
		Bind(sweep, "BackgroundColor3", "Accent")
		Spin(sweep, 2.5)

		-- titik deteksi: muncul acak di jaring lalu memudar seperti blip radar
		task.spawn(function()
			while Alive() do
				if not Root.Visible then
					task.wait(0.5)
					continue
				end
				local ang = math.random() * math.pi * 2
				local rad = math.random(4, 14)
				local dot = Make("Frame", {
					Size = UDim2.new(0, 3, 0, 3),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, math.cos(ang) * rad, 0.5, math.sin(ang) * rad),
					BackgroundColor3 = Cur.Accent,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 7,
					Active = false,
					Parent = web,
				})
				Corner(dot, 2)
				Tween(dot, 0.25, {BackgroundTransparency = 0})
				task.delay(1.2, function()
					Tween(dot, 0.6, {BackgroundTransparency = 1})
					task.delay(0.7, function()
						if dot.Parent then dot:Destroy() end
					end)
				end)
				task.wait(math.random(3, 7) / 10)
			end
		end)
	end)
end)()

local function SetActiveTab(name, silent)
	if CurrentTab == name then return end
	if not silent then PlayClick("tab") end
	CurrentTab = name
	if SV.lookAt then SV.lookAt(name) end

	for i, n in ipairs(TabNames) do
		local btn = TabButtons[n]
		local active = (n == name)
		Tween(btn, 0.3, {
			TextColor3 = active and Colors.White or Cur.TextDim,
			BackgroundTransparency = 1,
		})
		if active then
			if silent then
				Indicator.Position = UDim2.new(0, 6, 0, TabY(i))
			else
				Tween(Indicator, 0.4, {Position = UDim2.new(0, 6, 0, TabY(i))}, ES.Quint)
			end
		end
	end

	for n, group in pairs(Pages) do
		if n == name then
			group.Visible = true
			if silent then
				group.GroupTransparency = 0
				group.Position = PAGE_BASE
			else
				group.GroupTransparency = 1
				group.Position = UDim2.new(0, -4, 0, 6)
				Tween(group, 0.45, {GroupTransparency = 0, Position = PAGE_BASE})
			end
		elseif group.Visible then
			Tween(group, 0.15, {GroupTransparency = 1}, ES.Quad, ED.In)
			task.delay(0.17, function()
				if CurrentTab ~= n then group.Visible = false end
			end)
		end
	end
end

for i, name in ipairs(TabNames) do
	local btn = Make("TextButton", {
		Size = UDim2.new(1, -12, 0, 30),
		Position = UDim2.new(0, 6, 0, TabY(i)),
		BackgroundColor3 = Cur.Accent,
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Cur.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		ZIndex = 2,
		Parent = Sidebar,
	})
	Corner(btn, 8)
	Bind(btn, "BackgroundColor3", "Accent")
	do
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 12)
		p.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		if CurrentTab ~= name then
			Tween(btn, 0.2, {BackgroundTransparency = 0.85, TextColor3 = Colors.Text})
		end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentTab ~= name then
			Tween(btn, 0.25, {BackgroundTransparency = 1, TextColor3 = Cur.TextDim})
		end
	end)
	btn.MouseButton1Click:Connect(function()
		SetActiveTab(name)
	end)

	TabButtons[name] = btn
end

SetActiveTab("INFO", true)

-------------------------------------------------
-- KARTU
-------------------------------------------------
local function Card(parent, size, pos)
	local f = Make("Frame", {
		Size = size,
		Position = pos,
		BackgroundColor3 = Colors.White,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Corner(f, 13)
	BGrad(f, "Card0", "Card1", 90)
	local s = Stroke(f, Cur.Accent, 1.2, 0.5)
	Bind(s, "Color", "Accent")
	f.MouseEnter:Connect(function() Tween(s, 0.25, {Transparency = 0.1}) end)
	f.MouseLeave:Connect(function() Tween(s, 0.4, {Transparency = 0.5}) end)
	return f
end

local function CardTitle(parent, text)
	return Label({
		Size = UDim2.new(1, -12, 0, 16),
		Position = UDim2.new(0, 10, 0, 6),
		Text = text,
		Font = Enum.Font.GothamBlack,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
end

-------------------------------------------------
-- INFO PAGE : PROFIL
-------------------------------------------------
local Profile = Card(InfoPage, UDim2.new(0, 190, 1, 0), UDim2.new(0, 0, 0, 0))

local Avatar = Make("ImageLabel", {
	Size = UDim2.new(0, 64, 0, 64),
	Position = UDim2.new(0.5, -32, 0, 16),
	BackgroundColor3 = Cur.Box,
	ImageTransparency = 1,
	Parent = Profile,
})
Bind(Avatar, "BackgroundColor3", "Box")
Corner(Avatar, "full")
local AvatarStroke = Stroke(Avatar, Colors.White, 2, 0)

-- kepala hacker di sebelah kanan avatar: muncul sebentar dengan kedipan, lalu hilang
;(function()
	pcall(function()
		local head = Make("Frame", {
			Name = "HackHead",
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(0, 140, 0, 186),
			BackgroundTransparency = 1,
			ZIndex = 8,
			Visible = false,
			Active = false,
			Parent = Profile,
		})
		local sc = Instance.new("UIScale")
		sc.Scale = 0
		sc.Parent = head

		local body = Make("Frame", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(0, 2, 0, 8),
			BackgroundColor3 = Color3.fromRGB(12, 12, 12),
			BorderSizePixel = 0,
			ZIndex = 9,
			Active = false,
			Parent = head,
		})
		Corner(body, 4)
		local bs = Stroke(body, Cur.Accent, 1.5, 0)
		Bind(bs, "Color", "Accent")

		-- mahkota hijau
		for _, x in ipairs({4, 11, 18}) do
			local spike = Make("Frame", {
				Size = UDim2.new(0, 3, 0, 7),
				Position = UDim2.new(0, x, 0, 0),
				BackgroundColor3 = Cur.Accent,
				BorderSizePixel = 0,
				ZIndex = 9,
				Active = false,
				Parent = head,
			})
			Bind(spike, "BackgroundColor3", "Accent")
		end

		-- mata merah yang berkedip
		for _, x in ipairs({5, 15}) do
			local eye = Make("Frame", {
				Size = UDim2.new(0, 5, 0, 3),
				Position = UDim2.new(0, x, 0, 13),
				BackgroundColor3 = Color3.fromRGB(255, 40, 40),
				BorderSizePixel = 0,
				ZIndex = 10,
				Active = false,
				Parent = head,
			})
			Corner(eye, 2)
			Loop(eye, 0.4, {BackgroundTransparency = 0.5})
		end

		-- senyum lebar yang menyeramkan: mulut terus melebar dan menyempit
		local mouth = Make("Frame", {
			Size = UDim2.new(0, 16, 0, 4),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0, 13, 0, 19),
			BackgroundColor3 = Color3.fromRGB(70, 0, 6),
			BorderSizePixel = 0,
			ZIndex = 10,
			Active = false,
			Parent = head,
		})
		Corner(mouth, 3)
		for k = 1, 5 do
			Make("Frame", {
				Size = UDim2.new(0.13, 0, 0.5, 0),
				Position = UDim2.new(0.06 + (k - 1) * 0.2, 0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(240, 240, 240),
				BorderSizePixel = 0,
				ZIndex = 11,
				Active = false,
				Parent = mouth,
			})
		end
		Loop(mouth, 0.7, {Size = UDim2.new(0, 22, 0, 7)})

		-- garis pipi di sudut mulut, supaya senyumnya melengkung lebar
		for _, cfg in ipairs({{2, 19, -40}, {24, 19, 40}}) do
			local cheek = Make("Frame", {
				Size = UDim2.new(0, 7, 0, 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, cfg[1], 0, cfg[2]),
				Rotation = cfg[3],
				BackgroundColor3 = Cur.Accent,
				BorderSizePixel = 0,
				ZIndex = 10,
				Active = false,
				Parent = head,
			})
			Bind(cheek, "BackgroundColor3", "Accent")
		end

		task.spawn(function()
			while Alive() do
				if Root.Visible and SV.hackOn then
					if not head.Visible then
						head.Visible = true
						Tween(sc, 0.25, {Scale = 1}, ES.Back, ED.Out)
					end
				elseif head.Visible then
					Tween(sc, 0.2, {Scale = 0}, ES.Quad, ED.In)
					task.wait(0.2)
					head.Visible = false
				end
				task.wait(0.5)
			end
		end)
	end)
end)()
local AvatarMode, AvatarGrad = "Putar", nil -- dipakai menu Bingkai Avatar
do
	local g = Instance.new("UIGradient")
	g.Parent = AvatarStroke
	AvatarGrad = g
	OnTheme(function(T)
		if AvatarMode == "Pelangi" then return end
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, T.Accent2),
			ColorSequenceKeypoint.new(0.5, T.Dark),
			ColorSequenceKeypoint.new(1, T.Accent2),
		})
	end)
	Spin(g, 3.5)
end

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and img and Alive() then
		Avatar.Image = img
		Tween(Avatar, 0.5, {ImageTransparency = 0})
	end
end)

local NameContainer = Make("Frame", {
	Size = UDim2.new(1, -10, 0, 22),
	Position = UDim2.new(0, 5, 0, 88),
	BackgroundTransparency = 1,
	Parent = Profile,
})

local function NameLayer(color, x, z, transparency)
	local nl = Label({
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, x, 0, 0),
		Text = LocalPlayer.DisplayName,
		Font = Enum.Font.GothamBlack,
		TextSize = 15,
		TextColor3 = color,
		TextTransparency = transparency,
		ZIndex = z,
		Parent = NameContainer,
	})
	SV.nameLbls = SV.nameLbls or {}
	table.insert(SV.nameLbls, {lbl = nl, real = LocalPlayer.DisplayName, fake = "1x1x1x1"})
	return nl
end
local NameG1 = NameLayer(Colors.GlitchCyan, -2, 1, 0.7)
local NameG2 = NameLayer(Colors.GlitchRed, 2, 1, 0.7)
NameLayer(Colors.Text, 0, 2, 0)
Glitcher(NameG1, NameG2, -2, 2, 0.7, 0.15, 5, 1.5, 3.2)

local UserLbl = Label({
	Size = UDim2.new(1, -10, 0, 15),
	Position = UDim2.new(0, 5, 0, 110),
	Text = "@" .. LocalPlayer.Name,
	TextSize = 11,
	Parent = Profile,
})
Bind(UserLbl, "TextColor3", "Accent2")
SV.nameLbls = SV.nameLbls or {}
table.insert(SV.nameLbls, {lbl = UserLbl, real = "@" .. LocalPlayer.Name, fake = "@1x1x1x1"})
SV.applyNames = function(hacked)
	SV.nameTok = (SV.nameTok or 0) + 1
	local my = SV.nameTok
	local chars = {"0", "1", "#", "/", "%", "&", "?", "x"}
	local function alive() return SV.nameTok == my and SV.hackOn end
	local function scramble(dur)
		local t0 = os.clock()
		while os.clock() - t0 < dur and alive() do
			for _, e in ipairs(SV.nameLbls) do
				if e.lbl.Parent then
					local out = {}
					for k = 1, #e.real do out[k] = chars[math.random(#chars)] end
					e.lbl.Text = table.concat(out)
				end
			end
			task.wait(0.06)
		end
	end
	local function set(fakeOn)
		for _, e in ipairs(SV.nameLbls) do
			if e.lbl.Parent then e.lbl.Text = fakeOn and e.fake or e.real end
		end
	end
	if not hacked then
		set(false)
		return
	end
	task.spawn(function()
		while alive() do
			scramble(0.7)
			if not alive() then break end
			set(true)
			task.wait(2.2)
			if not alive() then break end
			scramble(0.5)
			if not alive() then break end
			set(false)
			task.wait(7)
		end
		if SV.nameTok == my then set(false) end
	end)
end

local FriendCount, FollowerCount, FollowingCount = 0, 0, 0
;(function()
	SV.decrypt = function()
		for _, s in ipairs(SV.statLbls or {}) do
			task.spawn(function()
				local t0 = os.clock()
				while os.clock() - t0 < 1.4 and s.lbl.Parent do
					if math.random() < 0.5 then
						s.lbl.Text = tostring(math.random(0, 999)) .. "k"
					else
						s.lbl.Text = string.format("%03X", math.random(0, 4095))
					end
					task.wait(0.05)
				end
				if s.lbl.Parent then s.lbl.Text = tostring(s.value) end
			end)
		end
	end
	task.spawn(function()
		while Alive() do
			task.wait(6)
			if SV.hackOn and Root.Visible then SV.decrypt() end
		end
	end)
end)()
pcall(function()
	local friends = LocalPlayer:GetFriendsOnline()
	if friends then FriendCount = #friends end
end)

local function MiniStat(title, value, x)
	local f = Make("Frame", {
		Size = UDim2.new(0, 56, 0, 40),
		Position = UDim2.new(0, 9 + (x * 60), 0, 140),
		BackgroundColor3 = Cur.Box,
		BorderSizePixel = 0,
		Parent = Profile,
	})
	Bind(f, "BackgroundColor3", "Box")
	Corner(f, 8)
	local num = Label({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 4),
		Text = tostring(value),
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = Colors.Green,
		Parent = f,
	})
	SV.statLbls = SV.statLbls or {}
	table.insert(SV.statLbls, {lbl = num, value = value})
	local t = Label({
		Size = UDim2.new(1, 0, 0, 13),
		Position = UDim2.new(0, 0, 0, 23),
		Text = title,
		TextSize = 8,
		Parent = f,
	})
	Bind(t, "TextColor3", "TextDim")
end

MiniStat("TEMAN", FriendCount, 0)
MiniStat("PENGIKUT", FollowerCount, 1)
MiniStat("MENGIKUTI", FollowingCount, 2)

-- UMUR AKUN (di celah antara statistik dan kotak jam)
do
	local okA, errA = pcall(function()
		local d = LocalPlayer.AccountAge
		local y = math.floor(d / 365)
		local m = math.floor((d % 365) / 30)
		local txt
		if y > 0 then
			txt = y .. " th " .. m .. " bln"
		elseif d >= 30 then
			txt = math.floor(d / 30) .. " bln"
		else
			txt = d .. " hari"
		end
		local AgeLbl = Label({
			Size = UDim2.new(1, -10, 0, 14),
			Position = UDim2.new(0, 5, 0, 190),
			Text = "Umur akun: " .. txt,
			TextSize = 10,
			Parent = Profile,
		})
		Bind(AgeLbl, "TextColor3", "TextDim")
	end)
	if not okA then table.insert(BootErr, "Umur akun: " .. tostring(errA)) end
end

local TimeLbl = Label({
	Size = UDim2.new(1, -10, 0, 24),
	Position = UDim2.new(0, 5, 1, -66),
	Text = os.date("%H:%M:%S"),
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	Parent = Profile,
})
Bind(TimeLbl, "TextColor3", "Accent2")

-- KOTAK JAM dengan efek pecah lalu nyambung lagi
do
	local okC, errC = pcall(function()
		local BW, BH, N = 160, 44, 3
		local Box = Make("Frame", {
			Name = "ClockBox",
			Size = UDim2.new(0, BW, 0, BH),
			Position = UDim2.new(0.5, -BW / 2, 1, -78),
			BackgroundColor3 = Cur.Box,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = Profile,
		})
		Bind(Box, "BackgroundColor3", "Box")
		Corner(Box, 10)
		local BoxStroke = Stroke(Box, Cur.Accent, 1.5, 0.25)
		Bind(BoxStroke, "Color", "Accent")

		-- jam dipotong jadi 3 bagian (atas, tengah, bawah) supaya bisa "pecah"
		local Bands, Labels = {}, {}
		for i = 1, N do
			local band = Make("Frame", {
				Size = UDim2.new(1, 0, 1 / N, 0),
				Position = UDim2.new(0, 0, (i - 1) / N, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Parent = Box,
			})
			local lbl = Label({
				Size = UDim2.new(1, 0, N, 0),
				Position = UDim2.new(0, 0, -(i - 1), 0),
				Text = TimeLbl.Text,
				Font = Enum.Font.GothamBlack,
				TextSize = 22,
				Parent = band,
			})
			Bind(lbl, "TextColor3", "Accent2")
			Bands[i] = band
			Labels[i] = lbl
		end

		-- teks jam asli tetap jadi sumber waktu, hanya disembunyikan
		TimeLbl:GetPropertyChangedSignal("Text"):Connect(function()
			for _, l in ipairs(Labels) do l.Text = TimeLbl.Text end
		end)
		TimeLbl.Visible = false

		local function Shatter()
			-- pecah: tiap potongan bergeser ke arah berbeda
			Tween(BoxStroke, 0.06, {Transparency = 0}, ES.Linear)
			for _ = 1, math.random(2, 3) do
				for i, band in ipairs(Bands) do
					local dir = (math.random() < 0.5) and 1 or -1
					local dx = math.random(5, 16) * dir
					local dy = math.random(-2, 2)
					Tween(band, 0.06, {Position = UDim2.new(0, dx, (i - 1) / N, dy)}, ES.Linear)
					Tween(Labels[i], 0.06, {TextTransparency = math.random() * 0.5}, ES.Linear)
				end
				task.wait(0.07)
			end
			-- nyambung lagi
			for i, band in ipairs(Bands) do
				Tween(band, 0.4, {Position = UDim2.new(0, 0, (i - 1) / N, 0)}, ES.Back, ED.Out)
				Tween(Labels[i], 0.3, {TextTransparency = 0}, ES.Quad)
			end
			Tween(BoxStroke, 0.4, {Transparency = 0.25}, ES.Quad)
		end

		task.spawn(function()
			while Alive() do
				task.wait(2 + math.random() * 2.5)
				if not Alive() then break end
				if Root.Visible then pcall(Shatter) end
			end
		end)
	end)
	if not okC then table.insert(BootErr, "Jam: " .. tostring(errC)) end
end

local Watermark = Label({
	Size = UDim2.new(1, -10, 0, 14),
	Position = UDim2.new(0, 5, 1, -26),
	Text = "@aanantamng",
	TextSize = 11,
	TextTransparency = 0.12,
	Parent = Profile,
})
Bind(Watermark, "TextColor3", "Accent2")
Loop(Watermark, 1.8, {TextTransparency = 0.5})

-------------------------------------------------
-- PENGATURAN (tombol roda gigi di kanan atas profil)
-------------------------------------------------
local CloseSettings = function() end
local Closers = {Crystal = function() end, Font = function() end, Mode = function() end, Avatar = function() end, Anim = function() end, Sound = function() end}
do
	local okS, errS = pcall(function()
	local open, token = false, 0

	local Gear = Make("TextButton", {
		Name = "SettingsBtn",
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(1, -34, 0, 8),
		BackgroundColor3 = Cur.Btn,
		Text = "",
		AutoButtonColor = false,
		Parent = Profile,
	})
	Corner(Gear, 8)
	Interactive(Gear, "Btn", "Accent")

	-- ikon roda gigi digambar dari frame (tanpa asset)
	local Icon = Make("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1,
		Active = false,
		Parent = Gear,
	})
	for _, rot in ipairs({0, 45, 90, 135}) do
		local bar = Make("Frame", {
			Size = UDim2.new(0, 4, 0, 18),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = rot,
			BackgroundColor3 = Colors.Text,
			BorderSizePixel = 0,
			Parent = Icon,
		})
		Corner(bar, 1)
	end
	local body = Make("Frame", {
		Size = UDim2.new(0, 13, 0, 13),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Colors.Text,
		BorderSizePixel = 0,
		Parent = Icon,
	})
	Corner(body, "full")
	local hole = Make("Frame", {
		Size = UDim2.new(0, 6, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Gear.BackgroundColor3,
		BorderSizePixel = 0,
		Parent = Icon,
	})
	Corner(hole, "full")
	Gear:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		hole.BackgroundColor3 = Gear.BackgroundColor3
	end)

	-- panel pengaturan
	local Panel = Make("CanvasGroup", {
		Name = "SettingsPanel",
		Position = UDim2.new(0, 326, 0, 52),
		Size = UDim2.new(0, 196, 0, 160),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 40,
		Parent = Main,
	})
	Corner(Panel, 12)
	local PBg = Make("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Colors.White,
		BorderSizePixel = 0,
		Active = true,
		Parent = Panel,
	})
	BGrad(PBg, "Card0", "Card1", 90)
	local PBd = Make("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Parent = Panel,
	})
	Corner(PBd, 11)
	do
		local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
		Bind(st, "Color", "Accent")
	end

	Label({
		Size = UDim2.new(1, -40, 0, 16),
		Position = UDim2.new(0, 10, 0, 8),
		Text = "PENGATURAN",
		Font = Enum.Font.GothamBlack,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Panel,
	})
	local XBtn = Make("TextButton", {
		Size = UDim2.new(0, 22, 0, 18),
		Position = UDim2.new(1, -30, 0, 7),
		BackgroundColor3 = Cur.Btn,
		Text = "X",
		Font = Enum.Font.GothamBlack,
		TextSize = 10,
		TextColor3 = Colors.Text,
		AutoButtonColor = false,
		Parent = Panel,
	})
	Corner(XBtn, 6)
	Interactive(XBtn, "Btn", "Accent")

	local function Row(y, text, default, onChange, reg)
		local lbl = Label({
			Size = UDim2.new(1, -70, 0, 20),
			Position = UDim2.new(0, 10, 0, y),
			Text = text,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local state = default
		local track = Make("TextButton", {
			Size = UDim2.new(0, 36, 0, 18),
			Position = UDim2.new(1, -46, 0, y + 1),
			BackgroundColor3 = Cur.Btn,
			Text = "",
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(track, "full")
		local knob = Make("Frame", {
			Size = UDim2.new(0, 14, 0, 14),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = track,
		})
		Corner(knob, "full")
		local function Render(animate)
			local pos = state and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
			local col = state and Cur.Accent or Cur.Btn
			if animate then
				Tween(knob, 0.2, {Position = pos})
				Tween(track, 0.2, {BackgroundColor3 = col})
			else
				knob.Position = pos
				track.BackgroundColor3 = col
			end
		end
		Render(false)
		OnTheme(function() Render(false) end)
		if reg then reg(function(v) state = v; Render(true) end) end
		track.MouseButton1Click:Connect(function()
			state = not state
			PlayClick(state and "on" or "off")
			Render(true)
			onChange(state)
		end)
	end

	FX.Visible = (SV.saved.kristal ~= false)
	Row(36, "Suara Klik", SoundOn, function(v)
		SetSound(v)
	end, function(f) table.insert(SoundRenders, f) end)
	Row(66, "Kristal Melayang", FX.Visible, function(v)
		FX.Visible = v
		SV.Set("kristal", v)
	end)
	Row(96, "Efek Percikan", CFX.Spark, function(v)
		CFX.Spark = v
		SV.Set("percik", v)
	end)
	Row(126, "Simpan Otomatis", SV.auto, function(v)
		SV.auto = v
		SV.Write()
		ShowToast(v and "Simpan otomatis: ON" or "Simpan otomatis: OFF")
	end)

	local function Open()
		if open then return end
		open = true
		token += 1
		ClosePicker()
		Closers.Crystal()
		Closers.Font()
		Closers.Mode()
		Closers.Avatar()
		Closers.Anim()
			Closers.Sound()
		Panel.Visible = true
		Panel.GroupTransparency = 1
		Panel.Position = UDim2.new(0, 326, 0, 60)
		Tween(Panel, 0.4, {GroupTransparency = 0, Position = UDim2.new(0, 326, 0, 52)}, ES.Back)
		Tween(Icon, 0.5, {Rotation = 90}, ES.Back)
	end

	CloseSettings = function()
		if not open then return end
		open = false
		token += 1
		local my = token
		Tween(Panel, 0.22, {GroupTransparency = 1, Position = UDim2.new(0, 326, 0, 60)}, ES.Quad, ED.In)
		Tween(Icon, 0.3, {Rotation = 0}, ES.Quad)
		task.delay(0.25, function()
			if my == token then Panel.Visible = false end
		end)
	end

	Gear.MouseButton1Click:Connect(function()
		PlayClick(open and "close" or "open")
		if open then CloseSettings() else Open() end
	end)
	XBtn.MouseButton1Click:Connect(function()
		PlayClick("close")
		CloseSettings()
	end)
	end)
	if not okS then table.insert(BootErr, "Pengaturan: " .. tostring(errS)) end
end

-------------------------------------------------
-- HIASAN (tombol kristal di bawah roda gigi, pilih bentuk benda yang berterbangan)
-------------------------------------------------
do
	local okH, errH = pcall(function()
		local STYLES = CFX.Names
		local open, token = false, 0

		local CBtn = Make("TextButton", {
			Name = "CrystalBtn",
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(1, -34, 0, 40),
			BackgroundColor3 = Cur.Btn,
			Text = "",
			AutoButtonColor = false,
			Parent = Profile,
		})
		Corner(CBtn, 8)
		Interactive(CBtn, "Btn", "Accent")

		-- ikon permata digambar dari frame (tanpa asset)
		local Icon = Make("Frame", {
			Size = UDim2.new(0, 18, 0, 18),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1,
			Active = false,
			Parent = CBtn,
		})
		local gem = Make("Frame", {
			Size = UDim2.new(0, 11, 0, 11),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = 45,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = Icon,
		})
		Corner(gem, 2)
		local gemGrad = Grad(gem, Colors.White, Cur.Accent2, 45)
		OnTheme(function(T) gemGrad.Color = ColorSequence.new(Colors.White, T.Accent2) end)
		local facet = Make("Frame", {
			Size = UDim2.new(0, 4, 0, 4),
			Position = UDim2.new(0.18, 0, 0.18, 0),
			BackgroundColor3 = Colors.White,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Parent = gem,
		})
		Corner(facet, 1)
		local spark = Make("Frame", {
			Size = UDim2.new(0, 3, 0, 3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -1, 0, 2),
			Rotation = 45,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = Icon,
		})
		Loop(spark, 0.9, {BackgroundTransparency = 0.8})

		-- panel daftar hiasan (gaya sama dengan daftar font)
		local Panel = Make("CanvasGroup", {
			Name = "CrystalPanel",
			Position = UDim2.new(0, 326, 0, 52),
			Size = UDim2.new(0, 196, 0, 176),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 40,
			Parent = Main,
		})
		Corner(Panel, 12)
		local PBg = Make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Panel,
		})
		BGrad(PBg, "Card0", "Card1", 90)
		local PBd = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Parent = Panel,
		})
		Corner(PBd, 11)
		do
			local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
			Bind(st, "Color", "Accent")
		end
		Label({
			Size = UDim2.new(1, -40, 0, 16),
			Position = UDim2.new(0, 10, 0, 8),
			Text = "HIASAN TERBANG",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local XBtn = Make("TextButton", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(1, -30, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "X",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(XBtn, 6)
		Interactive(XBtn, "Btn", "Accent")

		local List = Make("ScrollingFrame", {
			Size = UDim2.new(1, -16, 1, -40),
			Position = UDim2.new(0, 8, 0, 32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, #STYLES * 34),
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = Panel,
		})
		Bind(List, "ScrollBarImageColor3", "Accent")

		local Rows = {}
		local previewGrads = {}
		OnTheme(function(T)
			for _, g in ipairs(previewGrads) do
				g.Color = ColorSequence.new(T.Accent2, T.Accent)
			end
		end)

		local function Mark()
			for name, r in pairs(Rows) do
				local on = (name == CFX.Style)
				r.BackgroundColor3 = on and Cur.Accent or Cur.Btn
				r.TextColor3 = on and Colors.White or Colors.Text
			end
		end

		for i, name in ipairs(STYLES) do
			local row = Make("TextButton", {
				Size = UDim2.new(1, -6, 0, 30),
				Position = UDim2.new(0, 0, 0, (i - 1) * 34),
				BackgroundColor3 = Cur.Btn,
				Text = name,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				Parent = List,
			})
			Corner(row, 6)
			do
				local p = Instance.new("UIPadding")
				p.PaddingLeft = UDim.new(0, 58)
				p.Parent = row
			end
			Rows[name] = row

			-- contoh bentuk di sebelah kiri nama
			local holder = Make("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 28, 0.5, 0),
				BackgroundTransparency = 1,
				Active = false,
				Rotation = (name == "Kristal") and 45 or 0,
				Parent = row,
			})
			local w, h = CFX.Build(holder, name, 12, false, previewGrads)
			holder.Size = UDim2.new(0, w, 0, h)

			row.MouseButton1Click:Connect(function()
				PlayClick("pilih")
				CFX.Apply(name)
				SV.Set("hiasan", name)
				Mark()
				ShowToast("Hiasan: " .. name)
			end)
		end
		OnTheme(function() Mark() end)

		local function Open()
			if open then return end
			open = true
			token += 1
			ClosePicker()
			CloseSettings()
			Closers.Font()
			Closers.Mode()
			Closers.Avatar()
			Closers.Anim()
			Closers.Sound()
			Panel.Visible = true
			Panel.GroupTransparency = 1
			Panel.Position = UDim2.new(0, 326, 0, 60)
			Tween(Panel, 0.4, {GroupTransparency = 0, Position = UDim2.new(0, 326, 0, 52)}, ES.Back)
			Tween(Icon, 0.5, {Rotation = 90}, ES.Back)
		end

		Closers.Crystal = function()
			if not open then return end
			open = false
			token += 1
			local my = token
			Tween(Panel, 0.22, {GroupTransparency = 1, Position = UDim2.new(0, 326, 0, 60)}, ES.Quad, ED.In)
			Tween(Icon, 0.3, {Rotation = 0}, ES.Quad)
			task.delay(0.25, function()
				if my == token then Panel.Visible = false end
			end)
		end

		CBtn.MouseButton1Click:Connect(function()
			PlayClick(open and "close" or "open")
			if open then Closers.Crystal() else Open() end
		end)
		XBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			Closers.Crystal()
		end)
	end)
	if not okH then table.insert(BootErr, "Hiasan: " .. tostring(errH)) end
end

-------------------------------------------------
-- MODE SPESIAL (tombol di bawah tombol kristal: Helowin, Hacker, Blood Moon)
-------------------------------------------------
do
	local okM, errM = pcall(function()
		local ROWS = {"Normal"}
		for _, k in ipairs(CFX.ModeOrder) do table.insert(ROWS, k) end
		local open, token = false, 0

		local MBtn = Make("TextButton", {
			Name = "ModeBtn",
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(1, -34, 0, 72),
			BackgroundColor3 = Cur.Btn,
			Text = "",
			AutoButtonColor = false,
			Parent = Profile,
		})
		Corner(MBtn, 8)
		Interactive(MBtn, "Btn", "Accent")

		-- ikon kilau bintang (digambar dari frame)
		local Icon = Make("Frame", {
			Size = UDim2.new(0, 18, 0, 18),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1,
			Active = false,
			Parent = MBtn,
		})
		local function SBar(bw, bh, rot)
			local b = Make("Frame", {
				Size = UDim2.new(0, bw, 0, bh),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = rot,
				BackgroundColor3 = Colors.White,
				BorderSizePixel = 0,
				Parent = Icon,
			})
			Corner(b, "full")
			Bind(b, "BackgroundColor3", "Accent2")
		end
		SBar(2, 16, 0)
		SBar(16, 2, 0)
		SBar(2, 10, 45)
		SBar(2, 10, -45)
		local dot = Make("Frame", {
			Size = UDim2.new(0, 5, 0, 5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = 45,
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Parent = Icon,
		})

		-- maskot kecil di bawah sidebar, berganti sesuai mode
		local Pump = Make("Frame", {
			Size = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			BackgroundTransparency = 1,
			Visible = false,
			Active = false,
			Parent = Sidebar,
		})
		local ps = Instance.new("UIScale")
		ps.Parent = Pump
		Loop(ps, 1.3, {Scale = 1.1})
		function CFX.SetMascot(style)
			for _, ch in ipairs(Pump:GetChildren()) do
				if not ch:IsA("UIScale") then ch:Destroy() end
			end
			if not style then
				Pump.Visible = false
				return
			end
			local pw, ph = CFX.Build(Pump, style, 14, false, {})
			Pump.Size = UDim2.new(0, pw, 0, ph)
			Pump.Visible = true
		end

		-- panel pilihan mode (gaya sama dengan daftar font)
		local Panel = Make("CanvasGroup", {
			Name = "ModePanel",
			Position = UDim2.new(0, 326, 0, 52),
			Size = UDim2.new(0, 196, 0, 228),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 40,
			Parent = Main,
		})
		Corner(Panel, 12)
		local PBg = Make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Panel,
		})
		BGrad(PBg, "Card0", "Card1", 90)
		local PBd = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Parent = Panel,
		})
		Corner(PBd, 11)
		do
			local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
			Bind(st, "Color", "Accent")
		end
		Label({
			Size = UDim2.new(1, -40, 0, 16),
			Position = UDim2.new(0, 10, 0, 8),
			Text = "MODE SPESIAL",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local XBtn = Make("TextButton", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(1, -30, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "X",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(XBtn, 6)
		Interactive(XBtn, "Btn", "Accent")

		local List = Make("ScrollingFrame", {
			Size = UDim2.new(1, -16, 0, 176),
			Position = UDim2.new(0, 8, 0, 32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, #ROWS * 34),
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = Panel,
		})
		Bind(List, "ScrollBarImageColor3", "Accent")

		local Rows = {}
		local previewGrads = {}
		OnTheme(function(T)
			for _, g in ipairs(previewGrads) do
				g.Color = ColorSequence.new(T.Accent, T.Accent2)
			end
		end)

		local function Mark()
			local curMode = CFX.ModeCur or "Normal"
			for key, r in pairs(Rows) do
				local on = (key == curMode)
				r.BackgroundColor3 = on and Cur.Accent or Cur.Btn
				r.TextColor3 = on and Colors.White or Colors.Text
			end
		end

		for i, key in ipairs(ROWS) do
			local m = CFX.Modes[key]
			local row = Make("TextButton", {
				Size = UDim2.new(1, -6, 0, 30),
				Position = UDim2.new(0, 0, 0, (i - 1) * 34),
				BackgroundColor3 = Cur.Btn,
				Text = m and m.name or "Normal",
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				Parent = List,
			})
			Corner(row, 6)
			do
				local pd = Instance.new("UIPadding")
				pd.PaddingLeft = UDim.new(0, 58)
				pd.Parent = row
			end
			Rows[key] = row

			-- contoh di sebelah kiri nama
			local holder = Make("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 28, 0.5, 0),
				BackgroundTransparency = 1,
				Active = false,
				Parent = row,
			})
			if m then
				local w, h = CFX.Build(holder, m.preview, 12, false, {})
				holder.Size = UDim2.new(0, w, 0, h)
			else
				holder.Size = UDim2.new(0, 22, 0, 12)
				holder.BackgroundTransparency = 0
				holder.BackgroundColor3 = Colors.White
				Corner(holder, 4)
				table.insert(previewGrads, Grad(holder, Cur.Accent, Cur.Accent2, 0))
			end

			row.MouseButton1Click:Connect(function()
				PlayClick("pilih")
				if m then
					CFX.EnterMode(key)
				else
					CFX.ExitMode(false)
				end
				Mark()
			end)
		end
		OnTheme(function() Mark() end)

		Label({
			Size = UDim2.new(1, -20, 0, 12),
			Position = UDim2.new(0, 10, 0, 212),
			Text = "Geser untuk melihat mode lain",
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})

		local function Open()
			if open then return end
			open = true
			token += 1
			ClosePicker()
			CloseSettings()
			Closers.Crystal()
			Closers.Font()
			Closers.Avatar()
			Closers.Anim()
			Closers.Sound()
			Mark()
			Panel.Visible = true
			Panel.GroupTransparency = 1
			Panel.Position = UDim2.new(0, 326, 0, 60)
			Tween(Panel, 0.4, {GroupTransparency = 0, Position = UDim2.new(0, 326, 0, 52)}, ES.Back)
			Tween(Icon, 0.5, {Rotation = 90}, ES.Back)
		end

		Closers.Mode = function()
			if not open then return end
			open = false
			token += 1
			local my = token
			Tween(Panel, 0.22, {GroupTransparency = 1, Position = UDim2.new(0, 326, 0, 60)}, ES.Quad, ED.In)
			Tween(Icon, 0.3, {Rotation = 0}, ES.Quad)
			task.delay(0.25, function()
				if my == token then Panel.Visible = false end
			end)
		end

		MBtn.MouseButton1Click:Connect(function()
			PlayClick(open and "close" or "open")
			if open then Closers.Mode() else Open() end
		end)
		XBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			Closers.Mode()
		end)
	end)
	if not okM then table.insert(BootErr, "Mode: " .. tostring(errM)) end
end

-- Keadaan animasi buka (dipakai menu Animasi Buka dan SetVisible)
local OA = {idx = 1, base = nil, busy = false, gen = 0, list = {}}

-------------------------------------------------
-- BINGKAI AVATAR (tombol di kiri atas profil, mengimbangi roda gigi di kanan)
-------------------------------------------------
do
	local okA, errA = pcall(function()
		local STYLES = {
			{"Putar", "Putar (bawaan)"},
			{"Polos", "Polos"},
			{"Denyut", "Denyut"},
			{"Pelangi", "Pelangi"},
			{"Ganda", "Ganda"},
			{"Neon", "Neon"},
			{"Tanpa", "Tanpa bingkai"},
		}
		local cur = 1
		if type(SV.saved.bingkai) == "number" and STYLES[SV.saved.bingkai] then cur = SV.saved.bingkai end
		local open, token = false, 0

		local RAINBOW = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 60, 60)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 40)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 255, 120)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 200, 255)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 90, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 60, 60)),
		})
		local function ThemeSeq(T)
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, T.Accent2),
				ColorSequenceKeypoint.new(0.5, T.Dark),
				ColorSequenceKeypoint.new(1, T.Accent2),
			})
		end

		-- cincin luar (dipakai gaya Ganda dan Neon)
		local Outer = Make("Frame", {
			Name = "AvatarOuter",
			Size = UDim2.new(0, 76, 0, 76),
			Position = UDim2.new(0.5, -38, 0, 10),
			BackgroundTransparency = 1,
			Visible = false,
			Active = false,
			Parent = Profile,
		})
		Corner(Outer, "full")
		local OuterStroke = Stroke(Outer, Cur.Accent, 1.5, 0.2)

		-- animasi yang sedang jalan (dibatalkan saat ganti gaya)
		local fx = {}
		local function StopFx()
			for _, tw in ipairs(fx) do pcall(function() tw:Cancel() end) end
			table.clear(fx)
		end
		local function Pulse(obj, t, props)
			local tw = TweenService:Create(obj, TweenInfo.new(t, ES.Sine, ED.InOut, -1, true), props)
			tw:Play()
			table.insert(fx, tw)
		end

		local function Apply()
			StopFx()
			local name = STYLES[cur][1]
			AvatarMode = name
			local T = Cur
			AvatarStroke.Enabled = true
			AvatarStroke.Thickness = 2
			AvatarStroke.Transparency = 0
			AvatarStroke.Color = Colors.White
			AvatarGrad.Enabled = true
			AvatarGrad.Color = ThemeSeq(T)
			Outer.Visible = false
			OuterStroke.Thickness = 1.5
			OuterStroke.Transparency = 0.2
			OuterStroke.Color = T.Accent
			if name == "Polos" then
				AvatarGrad.Enabled = false
				AvatarStroke.Color = T.Accent2
			elseif name == "Denyut" then
				AvatarStroke.Thickness = 1.5
				Pulse(AvatarStroke, 0.8, {Thickness = 4})
			elseif name == "Pelangi" then
				AvatarGrad.Color = RAINBOW
			elseif name == "Ganda" then
				Outer.Visible = true
			elseif name == "Neon" then
				AvatarGrad.Enabled = false
				AvatarStroke.Color = T.Accent2
				AvatarStroke.Thickness = 2.5
				Outer.Visible = true
				OuterStroke.Color = T.Accent2
				OuterStroke.Thickness = 3
				OuterStroke.Transparency = 0.25
				Pulse(OuterStroke, 0.9, {Transparency = 0.85})
			elseif name == "Tanpa" then
				AvatarStroke.Enabled = false
			end
		end

		-- warna ikut tema (ringan: tidak memulai ulang animasi)
		OnTheme(function(T)
			local name = AvatarMode
			if name == "Polos" or name == "Neon" then AvatarStroke.Color = T.Accent2 end
			if name == "Ganda" then OuterStroke.Color = T.Accent end
			if name == "Neon" then OuterStroke.Color = T.Accent2 end
		end)

		-- tombol di kiri atas profil
		local ABtn = Make("TextButton", {
			Name = "AvatarFrameBtn",
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(0, 8, 0, 8),
			BackgroundColor3 = Cur.Btn,
			Text = "",
			AutoButtonColor = false,
			Parent = Profile,
		})
		Corner(ABtn, 8)
		Interactive(ABtn, "Btn", "Accent")

		-- ikon: cincin + titik di tengah
		local IconRing = Make("Frame", {
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1,
			Active = false,
			Parent = ABtn,
		})
		Corner(IconRing, "full")
		Stroke(IconRing, Colors.Text, 2, 0)
		local IconDot = Make("Frame", {
			Size = UDim2.new(0, 6, 0, 6),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = false,
			Parent = ABtn,
		})
		Corner(IconDot, "full")
		Bind(IconDot, "BackgroundColor3", "Accent2")

		-- panel pilihan (gaya sama dengan panel Mode)
		local Panel = Make("CanvasGroup", {
			Name = "AvatarPanel",
			Position = UDim2.new(0, 176, 0, 52),
			Size = UDim2.new(0, 176, 0, 212),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 40,
			Parent = Main,
		})
		Corner(Panel, 12)
		local PBg = Make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Panel,
		})
		BGrad(PBg, "Card0", "Card1", 90)
		local PBd = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Parent = Panel,
		})
		Corner(PBd, 11)
		do
			local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
			Bind(st, "Color", "Accent")
		end
		Label({
			Size = UDim2.new(1, -40, 0, 16),
			Position = UDim2.new(0, 10, 0, 8),
			Text = "BINGKAI AVATAR",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local XBtn = Make("TextButton", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(1, -30, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "X",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(XBtn, 6)
		Interactive(XBtn, "Btn", "Accent")

		local List = Make("ScrollingFrame", {
			Size = UDim2.new(1, -16, 0, 166),
			Position = UDim2.new(0, 8, 0, 32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, #STYLES * 34),
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = Panel,
		})
		Bind(List, "ScrollBarImageColor3", "Accent")

		local Rows = {}
		local function Mark()
			for i, r in ipairs(Rows) do
				r.BackgroundColor3 = (i == cur) and Cur.Accent or Cur.Btn
				r.TextColor3 = (i == cur) and Colors.White or Colors.Text
			end
		end

		for i, st in ipairs(STYLES) do
			local row = Make("TextButton", {
				Size = UDim2.new(1, -6, 0, 30),
				Position = UDim2.new(0, 0, 0, (i - 1) * 34),
				BackgroundColor3 = Cur.Btn,
				Text = st[2],
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				Parent = List,
			})
			Corner(row, 6)
			do
				local pd = Instance.new("UIPadding")
				pd.PaddingLeft = UDim.new(0, 40)
				pd.Parent = row
			end
			Rows[i] = row

			-- contoh cincin kecil di kiri nama
			local pv = Make("Frame", {
				Size = UDim2.new(0, 16, 0, 16),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 20, 0.5, 0),
				BackgroundTransparency = 1,
				Active = false,
				Parent = row,
			})
			Corner(pv, "full")
			if st[1] ~= "Tanpa" then
				local ps = Stroke(pv, Colors.White, st[1] == "Neon" and 3 or 2, 0)
				if st[1] == "Pelangi" then
					local g = Instance.new("UIGradient")
					g.Color = RAINBOW
					g.Rotation = 45
					g.Parent = ps
				elseif st[1] == "Putar" or st[1] == "Denyut" or st[1] == "Ganda" then
					local g = Instance.new("UIGradient")
					g.Parent = ps
					OnTheme(function(T) g.Color = ThemeSeq(T) end)
				else
					OnTheme(function(T) ps.Color = T.Accent2 end)
				end
			else
				local ps = Stroke(pv, Colors.White, 1, 0.7)
			end

			row.MouseButton1Click:Connect(function()
				PlayClick("pilih")
				cur = i
				SV.Set("bingkai", i)
				Apply()
				Mark()
				ShowToast("Bingkai: " .. st[2])
			end)
		end
		OnTheme(function() Mark() end)

		Label({
			Size = UDim2.new(1, -20, 0, 12),
			Position = UDim2.new(0, 10, 0, 198),
			Text = "Geser untuk melihat gaya lain",
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})

		local function Open()
			if open then return end
			open = true
			token += 1
			ClosePicker()
			CloseSettings()
			Closers.Crystal()
			Closers.Font()
			Closers.Mode()
			Closers.Anim()
			Closers.Sound()
			Mark()
			Panel.Visible = true
			Panel.GroupTransparency = 1
			Panel.Position = UDim2.new(0, 176, 0, 60)
			Tween(Panel, 0.4, {GroupTransparency = 0, Position = UDim2.new(0, 176, 0, 52)}, ES.Back)
		end

		Closers.Avatar = function()
			if not open then return end
			open = false
			token += 1
			local my = token
			Tween(Panel, 0.22, {GroupTransparency = 1, Position = UDim2.new(0, 176, 0, 60)}, ES.Quad, ED.In)
			task.delay(0.25, function()
				if my == token then Panel.Visible = false end
			end)
		end

		ABtn.MouseButton1Click:Connect(function()
			PlayClick(open and "close" or "open")
			if open then Closers.Avatar() else Open() end
		end)
		XBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			Closers.Avatar()
		end)

		Apply()
	end)
	if not okA then table.insert(BootErr, "Bingkai: " .. tostring(errA)) end
end

-------------------------------------------------
-- DAFTAR SUARA (tombol di bawah tombol bingkai avatar)
-------------------------------------------------
do
	local okS, errS = pcall(function()
		local SOUNDS = {
			{"Bawaan", "click"}, {"Ketuk", "ketuk"}, {"Percikan Air", "percikan"},
			{"Gelembung", "gelembung"}, {"Lonceng", "lonceng"}, {"Laser", "laser"},
			{"Petir", "petir"}, {"Koin", "koin"}, {"Whoosh", "whoosh"}, {"Pop", "pop"},
			{"Ding", "ding"}, {"Tik", "tik"}, {"Bip", "bip"}, {"Soft", "soft"},
			{"Pilih", "pilih"}, {"Buka", "open"}, {"Tab", "tab"},
		}
		local cur = 1
		for i, s in ipairs(SOUNDS) do
			if s[2] == SV.saved.gaya then cur = i end
		end
		local open, token = false, 0
		local Opts = {}

		local SndBtn = Make("TextButton", {
			Name = "SoundBtn",
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(0, 8, 0, 40),
			BackgroundColor3 = Cur.Btn,
			Text = "",
			AutoButtonColor = false,
			Parent = Profile,
		})
		Corner(SndBtn, 8)
		Interactive(SndBtn, "Btn", "Accent")

		-- ikon speaker
		Make("Frame", {
			Size = UDim2.new(0, 4, 0, 6),
			Position = UDim2.new(0, 6, 0.5, -3),
			BackgroundColor3 = Colors.Text,
			BorderSizePixel = 0,
			Active = false,
			Parent = SndBtn,
		})
		local Waves = Make("Frame", {
			Size = UDim2.new(0, 6, 0, 12),
			Position = UDim2.new(0, 12, 0.5, -6),
			BackgroundTransparency = 1,
			Active = false,
			Parent = SndBtn,
		})
		Corner(Waves, "full")
		Stroke(Waves, Colors.Text, 1.5, 0)

		-- panel daftar suara
		local Panel = Make("CanvasGroup", {
			Name = "SoundPanel",
			Position = UDim2.new(0, 176, 0, 52),
			Size = UDim2.new(0, 176, 0, 212),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 40,
			Parent = Main,
		})
		Corner(Panel, 12)
		local PBg = Make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Panel,
		})
		BGrad(PBg, "Card0", "Card1", 90)
		local PBd = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Parent = Panel,
		})
		Corner(PBd, 11)
		do
			local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
			Bind(st, "Color", "Accent")
		end
		Label({
			Size = UDim2.new(1, -40, 0, 16),
			Position = UDim2.new(0, 10, 0, 8),
			Text = "SUARA",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local XBtn = Make("TextButton", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(1, -30, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "X",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(XBtn, 6)
		Interactive(XBtn, "Btn", "Accent")

		local List = Make("ScrollingFrame", {
			Size = UDim2.new(1, -16, 1, -40),
			Position = UDim2.new(0, 8, 0, 32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, #SOUNDS * 28),
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = Panel,
		})
		Bind(List, "ScrollBarImageColor3", "Accent")

		local function Mark()
			for i, b in ipairs(Opts) do
				b.BackgroundColor3 = (i == cur) and Cur.Accent or Cur.Btn
				b.TextColor3 = (i == cur) and Colors.White or Colors.Text
			end
		end

		for i, s in ipairs(SOUNDS) do
			local b = Make("TextButton", {
				Size = UDim2.new(1, -6, 0, 24),
				Position = UDim2.new(0, 0, 0, (i - 1) * 28),
				BackgroundColor3 = Cur.Btn,
				Text = s[1],
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = Colors.Text,
				AutoButtonColor = false,
				Parent = List,
			})
			Corner(b, 6)
			Opts[i] = b
			b.MouseButton1Click:Connect(function()
				cur = i
				SV.Set("gaya", s[2])
				SetStyle(s[2])
				Mark()
				PlayClick(s[2]) -- coba bunyinya
				ShowToast("Suara: " .. s[1])
			end)
		end
		OnTheme(function() Mark() end)

		local function Open()
			if open then return end
			open = true
			token += 1
			ClosePicker()
			CloseSettings()
			Closers.Crystal()
			Closers.Font()
			Closers.Mode()
			Closers.Avatar()
			Closers.Anim()
			Panel.Visible = true
			Panel.GroupTransparency = 1
			Panel.Position = UDim2.new(0, 176, 0, 60)
			Tween(Panel, 0.35, {GroupTransparency = 0, Position = UDim2.new(0, 176, 0, 52)}, ES.Back)
		end
		local function Close()
			if not open then return end
			open = false
			token += 1
			local my = token
			Tween(Panel, 0.2, {GroupTransparency = 1, Position = UDim2.new(0, 176, 0, 60)}, ES.Quad, ED.In)
			task.delay(0.23, function()
				if my == token then Panel.Visible = false end
			end)
		end
		Closers.Sound = Close

		SndBtn.MouseButton1Click:Connect(function()
			PlayClick(open and "close" or "open")
			if open then Close() else Open() end
		end)
		XBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			Close()
		end)
		Root:GetPropertyChangedSignal("Visible"):Connect(function()
			if not Root.Visible then Close() end
		end)
	end)
	if not okS then table.insert(BootErr, "Suara: " .. tostring(errS)) end
end

-------------------------------------------------
-- RIWAYAT NOTIFIKASI (tombol lonceng di bawah tombol suara)
-------------------------------------------------
do
	local okH, errH = pcall(function()
		local open, token = false, 0

		local BellBtn = Make("TextButton", {
			Name = "HistoryBtn",
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(0, 8, 0, 72),
			BackgroundColor3 = Cur.Btn,
			Text = "",
			AutoButtonColor = false,
			Parent = Profile,
		})
		Corner(BellBtn, 8)
		Interactive(BellBtn, "Btn", "Accent")
		local BellTop = Make("Frame", {
			Size = UDim2.new(0, 8, 0, 8),
			Position = UDim2.new(0, 9, 0, 6),
			BackgroundColor3 = Colors.Text,
			BorderSizePixel = 0,
			Active = false,
			Parent = BellBtn,
		})
		Corner(BellTop, 4)
		Make("Frame", {
			Size = UDim2.new(0, 12, 0, 2),
			Position = UDim2.new(0, 7, 0, 15),
			BackgroundColor3 = Colors.Text,
			BorderSizePixel = 0,
			Active = false,
			Parent = BellBtn,
		})

		local Panel = Make("CanvasGroup", {
			Name = "HistoryPanel",
			Position = UDim2.new(0, 176, 0, 52),
			Size = UDim2.new(0, 176, 0, 212),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 40,
			Parent = Main,
		})
		Corner(Panel, 12)
		local PBg = Make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Panel,
		})
		BGrad(PBg, "Card0", "Card1", 90)
		local PBd = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Parent = Panel,
		})
		Corner(PBd, 11)
		do
			local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
			Bind(st, "Color", "Accent")
		end
		Label({
			Size = UDim2.new(1, -70, 0, 16),
			Position = UDim2.new(0, 10, 0, 8),
			Text = "RIWAYAT",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local ClearBtn = Make("TextButton", {
			Size = UDim2.new(0, 40, 0, 18),
			Position = UDim2.new(1, -72, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "HAPUS",
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(ClearBtn, 6)
		Interactive(ClearBtn, "Btn", "Accent")
		local XBtn = Make("TextButton", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(1, -30, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "X",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(XBtn, 6)
		Interactive(XBtn, "Btn", "Accent")

		local List = Make("ScrollingFrame", {
			Size = UDim2.new(1, -16, 1, -40),
			Position = UDim2.new(0, 8, 0, 32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = Panel,
		})
		Bind(List, "ScrollBarImageColor3", "Accent")
		Make("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = List,
		})

		local function Rebuild()
			for _, c in ipairs(List:GetChildren()) do
				if c:IsA("TextLabel") then c:Destroy() end
			end
			if #SV.notif == 0 then
				Label({
					Size = UDim2.new(1, -6, 0, 40),
					Text = "Belum ada notifikasi",
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextColor3 = Colors.Text,
					Parent = List,
				})
				return
			end
			for i, h in ipairs(SV.notif) do
				Label({
					Size = UDim2.new(1, -6, 0, 26),
					Text = h.time .. "  " .. h.text,
					Font = Enum.Font.GothamBold,
					TextSize = 10,
					TextColor3 = Colors.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					LayoutOrder = i,
					Parent = List,
				})
			end
		end

		local function Open()
			if open then return end
			open = true
			token += 1
			ClosePicker()
			CloseSettings()
			Closers.Crystal()
			Closers.Font()
			Closers.Mode()
			Closers.Avatar()
			Closers.Anim()
			Closers.Sound()
			Rebuild()
			Panel.Visible = true
			Panel.GroupTransparency = 1
			Panel.Position = UDim2.new(0, 176, 0, 60)
			Tween(Panel, 0.35, {GroupTransparency = 0, Position = UDim2.new(0, 176, 0, 52)}, ES.Back)
		end
		local function Close()
			if not open then return end
			open = false
			token += 1
			local my = token
			Tween(Panel, 0.2, {GroupTransparency = 1, Position = UDim2.new(0, 176, 0, 60)}, ES.Quad, ED.In)
			task.delay(0.23, function()
				if my == token then Panel.Visible = false end
			end)
		end

		BellBtn.MouseButton1Click:Connect(function()
			PlayClick(open and "close" or "open")
			if open then Close() else Open() end
		end)
		XBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			Close()
		end)
		ClearBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			table.clear(SV.notif)
			Rebuild()
		end)
		Root:GetPropertyChangedSignal("Visible"):Connect(function()
			if not Root.Visible then Close() end
		end)
	end)
	if not okH then table.insert(BootErr, "Riwayat: " .. tostring(errH)) end
end

-------------------------------------------------
-- RESET PENGATURAN (halaman Lain-lain, klik dua kali untuk konfirmasi)
-------------------------------------------------
do
	local okR, errR = pcall(function()
		local ResetBtn = Make("TextButton", {
			Name = "ResetBtn",
			Size = UDim2.new(1, -24, 0, 36),
			Position = UDim2.new(0, 12, 0, 16),
			BackgroundColor3 = Cur.Btn,
			Text = "Reset Pengaturan",
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = OtherPage,
		})
		Corner(ResetBtn, 8)
		Interactive(ResetBtn, "Btn", "Accent")

		local RESET_KEYS = {"theme", "font", "mode", "bingkai", "gaya", "animbuka", "kristal", "percik", "suara", "hiasan", "custom"}
		local armed = false

		ResetBtn.MouseButton1Click:Connect(function()
			if not armed then
				armed = true
				ResetBtn.Text = "Klik lagi untuk konfirmasi"
				task.delay(3, function()
					if armed then
						armed = false
						ResetBtn.Text = "Reset Pengaturan"
					end
				end)
				return
			end
			armed = false
			ResetBtn.Text = "Reset Pengaturan"
			for _, k in ipairs(RESET_KEYS) do
				SV.saved[k] = nil
				SV.cur[k] = nil
			end
			SV.Write()
			SetSound(true)
			SetStyle(nil)
			FX.Visible = true
			CFX.Spark = true
			if CFX.ExitMode then pcall(CFX.ExitMode, true) end
			ShowToast("Reset selesai. Jalankan ulang script untuk tema & font")
		end)
	end)
	if not okR then table.insert(BootErr, "Reset: " .. tostring(errR)) end
end

-------------------------------------------------
-- ANIMASI BUKA (tombol di sebelah logo N)
-------------------------------------------------
OA.list = {
	{"zoom", "Zoom (bawaan)"},
	{"pegas", "Pegas"},
	{"geser", "Geser dari kiri"},
	{"jatuh", "Jatuh memantul"},
	{"naik", "Naik dari bawah"},
	{"putar", "Putar"},
	{"glitch", "Glitch"},
	{"pudar", "Pudar"},
}
if type(SV.saved.animbuka) == "number" and OA.list[SV.saved.animbuka] then OA.idx = SV.saved.animbuka end

do
	local okO, errO = pcall(function()
		local open, token = false, 0

		local OBtn = Make("TextButton", {
			Name = "OpenAnimBtn",
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 124, 0.5, -10),
			BackgroundColor3 = Cur.Btn,
			Text = "",
			AutoButtonColor = false,
			Parent = TitleBar,
		})
		Corner(OBtn, 8)
		Interactive(OBtn, "Btn", "Accent")

		-- ikon: kotak besar (bingkai) + kotak kecil di tengah yang membesar
		local IconBox = Make("Frame", {
			Size = UDim2.new(0, 16, 0, 16),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1,
			Active = false,
			Parent = OBtn,
		})
		Corner(IconBox, 4)
		Stroke(IconBox, Colors.Text, 2, 0)
		local IconIn = Make("Frame", {
			Size = UDim2.new(0, 7, 0, 7),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = false,
			Parent = OBtn,
		})
		Corner(IconIn, 2)
		Bind(IconIn, "BackgroundColor3", "Accent2")
		Loop(IconIn, 0.7, {Size = UDim2.new(0, 11, 0, 11)})

		local Panel = Make("CanvasGroup", {
			Name = "OpenAnimPanel",
			Position = UDim2.new(0, 176, 0, 52),
			Size = UDim2.new(0, 176, 0, 212),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 40,
			Parent = Main,
		})
		Corner(Panel, 12)
		local PBg = Make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Panel,
		})
		BGrad(PBg, "Card0", "Card1", 90)
		local PBd = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Parent = Panel,
		})
		Corner(PBd, 11)
		do
			local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
			Bind(st, "Color", "Accent")
		end
		Label({
			Size = UDim2.new(1, -40, 0, 16),
			Position = UDim2.new(0, 10, 0, 8),
			Text = "ANIMASI BUKA",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local XBtn = Make("TextButton", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(1, -30, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "X",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(XBtn, 6)
		Interactive(XBtn, "Btn", "Accent")

		local List = Make("ScrollingFrame", {
			Size = UDim2.new(1, -16, 0, 166),
			Position = UDim2.new(0, 8, 0, 32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, #OA.list * 34),
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = Panel,
		})
		Bind(List, "ScrollBarImageColor3", "Accent")

		local Rows = {}
		local function Mark()
			for i, r in ipairs(Rows) do
				r.BackgroundColor3 = (i == OA.idx) and Cur.Accent or Cur.Btn
				r.TextColor3 = (i == OA.idx) and Colors.White or Colors.Text
			end
		end

		for i, st in ipairs(OA.list) do
			local row = Make("TextButton", {
				Size = UDim2.new(1, -6, 0, 30),
				Position = UDim2.new(0, 0, 0, (i - 1) * 34),
				BackgroundColor3 = Cur.Btn,
				Text = st[2],
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				Parent = List,
			})
			Corner(row, 6)
			do
				local pd = Instance.new("UIPadding")
				pd.PaddingLeft = UDim.new(0, 12)
				pd.Parent = row
			end
			Rows[i] = row
			row.MouseButton1Click:Connect(function()
				PlayClick("pilih")
				OA.idx = i
				SV.Set("animbuka", i)
				Mark()
				ShowToast("Animasi: " .. st[2])
				OA.Replay() -- langsung diperlihatkan
			end)
		end
		OnTheme(function() Mark() end)

		Label({
			Size = UDim2.new(1, -20, 0, 12),
			Position = UDim2.new(0, 10, 0, 198),
			Text = "Pilih gaya, langsung diputar ulang",
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})

		local function Open()
			if open then return end
			open = true
			token += 1
			ClosePicker()
			CloseSettings()
			Closers.Crystal()
			Closers.Font()
			Closers.Mode()
			Closers.Avatar()
			Mark()
			Panel.Visible = true
			Panel.GroupTransparency = 1
			Panel.Position = UDim2.new(0, 176, 0, 60)
			Tween(Panel, 0.4, {GroupTransparency = 0, Position = UDim2.new(0, 176, 0, 52)}, ES.Back)
		end

		Closers.Anim = function()
			if not open then return end
			open = false
			token += 1
			local my = token
			Tween(Panel, 0.22, {GroupTransparency = 1, Position = UDim2.new(0, 176, 0, 60)}, ES.Quad, ED.In)
			task.delay(0.25, function()
				if my == token then Panel.Visible = false end
			end)
		end

		OBtn.MouseButton1Click:Connect(function()
			PlayClick(open and "close" or "open")
			if open then Closers.Anim()
			Closers.Sound() else Open() end
		end)
		XBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			Closers.Anim()
			Closers.Sound()
		end)
	end)
	if not okO then table.insert(BootErr, "AnimBuka: " .. tostring(errO)) end
end

-------------------------------------------------
-- INFO PAGE : STATISTIK SERVER
-------------------------------------------------
local RIGHT_X, RIGHT_W = 198, 218

local Server = Card(InfoPage, UDim2.new(0, RIGHT_W, 0, 90), UDim2.new(0, RIGHT_X, 0, 0))
CardTitle(Server, "STATISTIK SERVER")

local function StatBox(name, value, color, x)
	local box = Make("Frame", {
		Size = UDim2.new(0, 47, 0, 46),
		Position = UDim2.new(0, 10 + (x * 51), 0, 32),
		BackgroundColor3 = Cur.Box,
		BorderSizePixel = 0,
		Parent = Server,
	})
	Bind(box, "BackgroundColor3", "Box")
	Corner(box, 8)
	local val = Label({
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 6),
		Text = value,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = color,
		Parent = box,
	})
	local nm = Label({
		Size = UDim2.new(1, 0, 0, 13),
		Position = UDim2.new(0, 0, 0, 27),
		Text = name,
		TextSize = 8,
		Parent = box,
	})
	Bind(nm, "TextColor3", "TextDim")
	return val
end

local FPSVal = StatBox("FPS", "--", Colors.Green, 0)
local PingVal = StatBox("PING", "--", Colors.Yellow, 1)
local PlayerVal = StatBox("PLAYER", #Players:GetPlayers() .. "/" .. Players.MaxPlayers, Colors.White, 2)
Bind(PlayerVal, "TextColor3", "Accent2")
local UptimeVal = StatBox("UPTIME", "0:00", Colors.Pink, 3)

-------------------------------------------------
-- INFO PAGE : TOMBOL CEPAT
-------------------------------------------------
local Quick = Card(InfoPage, UDim2.new(0, RIGHT_W, 0, 98), UDim2.new(0, RIGHT_X, 0, 100))
CardTitle(Quick, "TOMBOL CEPAT")

-- Area tombol cepat bisa di-scroll (tombol + daftar server di bawahnya)
local QuickScroll = Make("ScrollingFrame", {
	Name = "QuickScroll",
	Size = UDim2.new(1, 0, 1, -30),
	Position = UDim2.new(0, 0, 0, 26),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 100),
	ScrollBarThickness = 3,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	Parent = Quick,
})
Bind(QuickScroll, "ScrollBarImageColor3", "Accent")

-- Panel kedua: daftar server asli (pemain paling sedikit duluan)
local MAX_ROWS, ROW_H, ROW_GAP = 8, 24, 4
local PANEL_Y = 104
local QUICK_BASE = 100
local PANEL_H = 12 + 16 + (ROW_H + ROW_GAP)
local serverOpen, serverToken = false, 0

local ServerPanel = Make("Frame", {
	Name = "ServerPanel",
	Size = UDim2.new(0, 198, 0, PANEL_H),
	Position = UDim2.new(0, 10, 0, PANEL_Y),
	BackgroundColor3 = Cur.Box,
	BorderSizePixel = 0,
	Visible = false,
	Parent = QuickScroll,
})
Bind(ServerPanel, "BackgroundColor3", "Box")
Corner(ServerPanel, 8)
do
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, ROW_GAP)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = ServerPanel
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, 6)
	p.PaddingBottom = UDim.new(0, 6)
	p.PaddingLeft = UDim.new(0, 6)
	p.PaddingRight = UDim.new(0, 6)
	p.Parent = ServerPanel
end

local ServerHeaderBar = Make("Frame", {
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	LayoutOrder = 0,
	Parent = ServerPanel,
})
local ServerHeader = Label({
	Size = UDim2.new(1, -56, 1, 0),
	Text = "DAFTAR SERVER",
	Font = Enum.Font.GothamBlack,
	TextSize = 9,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = ServerHeaderBar,
})
Bind(ServerHeader, "TextColor3", "Accent2")

local RefreshBtn = Make("TextButton", {
	Size = UDim2.new(0, 52, 0, 14),
	Position = UDim2.new(1, -52, 0.5, -7),
	BackgroundColor3 = Cur.Btn,
	Text = "REFRESH",
	Font = Enum.Font.GothamBlack,
	TextSize = 8,
	TextColor3 = Colors.Text,
	AutoButtonColor = false,
	Parent = ServerHeaderBar,
})
Corner(RefreshBtn, 6)
Interactive(RefreshBtn, "Btn", "Accent")

local function SetPanelRows(n)
	PANEL_H = 12 + 16 + math.max(n, 1) * (ROW_H + ROW_GAP)
	ServerPanel.Size = UDim2.new(0, 198, 0, PANEL_H)
	if serverOpen then
		QuickScroll.CanvasSize = UDim2.new(0, 0, 0, PANEL_Y + PANEL_H + 6)
	end
end

-- Baris server dibuat SEKALI di awal (pool), setelah itu hanya diisi ulang.
-- Jadi membuka daftar tidak membuat objek baru dan tidak lag.
local StatusLbl = Label({
	Size = UDim2.new(1, 0, 0, ROW_H),
	Text = "",
	TextSize = 10,
	LayoutOrder = 1,
	Visible = false,
	Parent = ServerPanel,
})
Bind(StatusLbl, "TextColor3", "TextDim")

local Pool = {}
for i = 1, MAX_ROWS do
	local row = Make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundColor3 = Cur.Btn,
		BorderSizePixel = 0,
		LayoutOrder = i,
		Visible = false,
		Parent = ServerPanel,
	})
	Bind(row, "BackgroundColor3", "Btn")
	Corner(row, 6)

	local nameLbl = Label({
		Size = UDim2.new(0, 64, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		Text = "Server #" .. i,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local countLbl = Label({
		Size = UDim2.new(0, 40, 1, 0),
		Position = UDim2.new(0, 76, 0, 0),
		Text = "",
		TextSize = 10,
		TextColor3 = Colors.Green,
		Parent = row,
	})
	local join = Make("TextButton", {
		Size = UDim2.new(0, 52, 0, 18),
		Position = UDim2.new(1, -58, 0.5, -9),
		BackgroundColor3 = Cur.Accent,
		Text = "GABUNG",
		Font = Enum.Font.GothamBlack,
		TextSize = 9,
		TextColor3 = Colors.White,
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(join, 6)
	Interactive(join, "Accent", "Accent2")

	local slot = {row = row, name = nameLbl, count = countLbl, join = join, sv = nil, armed = false, armToken = 0}
	Pool[i] = slot

	join.MouseButton1Click:Connect(function()
		PlayClick()
		local sv = slot.sv
		if not sv then return end
		if not slot.armed then
			-- tekan pertama: minta konfirmasi dulu
			slot.armed = true
			slot.armToken += 1
			local my = slot.armToken
			join.Text = "YAKIN?"
			ShowToast("Tekan lagi untuk masuk Server #" .. i)
			task.delay(3, function()
				if my == slot.armToken and slot.armed then
					slot.armed = false
					join.Text = "GABUNG"
				end
			end)
			return
		end
		-- tekan kedua: baru masuk
		slot.armed = false
		slot.armToken += 1
		join.Text = "MASUK..."
		ShowToast("Masuk ke Server #" .. i .. "...")
		local ok = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, LocalPlayer)
		end)
		if not ok then
			ShowToast("Gagal masuk server")
			join.Text = "GABUNG"
		end
	end)
end

local function ShowStatus(text)
	for i = 1, MAX_ROWS do
		Pool[i].row.Visible = false
		Pool[i].sv = nil
	end
	StatusLbl.Text = text
	StatusLbl.Visible = true
	SetPanelRows(1)
end

local function ShowRows(list, n)
	StatusLbl.Visible = false
	for i = 1, MAX_ROWS do
		local slot = Pool[i]
		if i <= n then
			local sv = list[i]
			slot.sv = sv
			slot.armed = false
			slot.armToken += 1
			slot.join.Text = "GABUNG"
			slot.name.Text = "Server #" .. i
			slot.count.Text = (sv.playing or 0) .. "/" .. (sv.maxPlayers or Players.MaxPlayers)
			slot.row.Visible = true
		else
			slot.row.Visible = false
			slot.sv = nil
		end
	end
	SetPanelRows(n)
end

-- Ambil JSON dari URL (pakai request bawaan executor kalau ada)
local function HttpGetJson(url)
	local ok, body = pcall(function()
		local req = (syn and syn.request) or http_request or request or (http and http.request)
		if req then
			local r = req({Url = url, Method = "GET"})
			return r and r.Body
		end
		return game:HttpGet(url)
	end)
	if not ok or not body then return nil end
	local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
	if ok2 then return data end
	return nil
end

pcall(function()
	TeleportService.TeleportInitFailed:Connect(function(_, result)
		if Alive() then ShowToast("Gagal masuk: " .. tostring(result)) end
	end)
end)

local fetchToken, lastFetch, hasList = 0, 0, false
local function RefreshServers(force)
	-- kalau baru diambil < 15 detik lalu, pakai daftar yang sama (tidak ambil ulang)
	if not force and hasList and os.clock() - lastFetch < 15 then return end
	fetchToken += 1
	local my = fetchToken
	hasList = false
	ShowStatus("Memuat server...")

	task.spawn(function()
		local path = "/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=25"
		local data
		for _, host in ipairs({"https://games.roblox.com", "https://games.roproxy.com"}) do
			data = HttpGetJson(host .. path)
			if data and type(data.data) == "table" then break end
			if my ~= fetchToken or not Alive() then return end
			task.wait(0.4)
		end
		if my ~= fetchToken or not Alive() then return end

		if not data or type(data.data) ~= "table" then
			ShowStatus("Gagal memuat server")
			return
		end

		local list = {}
		for _, sv in ipairs(data.data) do
			local maxP = sv.maxPlayers or Players.MaxPlayers
			if sv.id ~= game.JobId and (sv.playing or 0) < maxP then
				table.insert(list, sv)
			end
		end
		table.sort(list, function(x, y) return (x.playing or 0) < (y.playing or 0) end)

		if #list == 0 then
			ShowStatus("Tidak ada server lain")
			return
		end

		ShowRows(list, math.min(#list, MAX_ROWS))
		hasList = true
		lastFetch = os.clock()
	end)
end

RefreshBtn.MouseButton1Click:Connect(function()
	PlayClick()
	RefreshServers(true)
end)

local function ToggleServerPanel()
	serverOpen = not serverOpen
	serverToken += 1
	local my = serverToken
	if serverOpen then
		QuickScroll.CanvasSize = UDim2.new(0, 0, 0, PANEL_Y + PANEL_H + 6)
		ServerPanel.Visible = true
		QuickScroll.CanvasPosition = Vector2.new(0, PANEL_Y - 4)
		ShowToast("Daftar server dibuka")
		RefreshServers()
	else
		QuickScroll.CanvasPosition = Vector2.new(0, 0)
		ShowToast("Daftar server ditutup")
		task.delay(0.35, function()
			if my == serverToken then
				ServerPanel.Visible = false
				QuickScroll.CanvasSize = UDim2.new(0, 0, 0, QUICK_BASE)
			end
		end)
	end
end

local function QBtn(text, x, y, func)
	local b = Make("TextButton", {
		Size = UDim2.new(0, 98, 0, 28),
		Position = UDim2.new(0, 10 + (x * 104), 0, 2 + (y * 33)),
		BackgroundColor3 = Cur.Btn,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = Colors.Text,
		TextScaled = true,
		AutoButtonColor = false,
		Parent = QuickScroll,
	})
	Corner(b, 8)
	do
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = 10
		c.MinTextSize = 7
		c.Parent = b
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 5)
		p.PaddingRight = UDim.new(0, 5)
		p.Parent = b
	end
	Interactive(b, "Btn", "Accent")
	b.MouseButton1Click:Connect(function()
		PlayClick()
		func()
	end)
	return b
end

local function CopyText(txt, okMsg)
	if setclipboard then
		pcall(setclipboard, txt)
		PlayClick("pilih")
		ShowToast(okMsg)
	else
		ShowToast("Executor tidak support clipboard")
	end
end

QBtn("SALIN USER ID", 0, 0, function()
	CopyText(tostring(LocalPlayer.UserId), "User ID disalin")
end)
QBtn("SALIN LINK PROFIL", 1, 0, function()
	CopyText("https://www.roblox.com/users/" .. LocalPlayer.UserId .. "/profile", "Link profil disalin")
end)
QBtn("REJOIN", 0, 1, function()
	ShowToast("Menghubungkan ulang...")
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
QBtn("SERVER HOP", 1, 1, function()
	ToggleServerPanel()
end)
QBtn("SALIN JOB ID", 0, 2, function()
	CopyText(tostring(game.JobId), "Job ID disalin")
end)
QBtn("SALIN PLACE ID", 1, 2, function()
	CopyText(tostring(game.PlaceId), "Place ID disalin")
end)

-------------------------------------------------
-- INFO PAGE : TENTANG
-------------------------------------------------
local About = Card(InfoPage, UDim2.new(0, RIGHT_W, 0, 90), UDim2.new(0, RIGHT_X, 0, 206))
CardTitle(About, "TENTANG")
do
local AboutScroll = Make("ScrollingFrame", {
	Name = "AboutScroll",
	Size = UDim2.new(1, -10, 1, -30),
	Position = UDim2.new(0, 6, 0, 26),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 3,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	Parent = About,
})
Bind(AboutScroll, "ScrollBarImageColor3", "Accent")

local AboutText = Label({
	Size = UDim2.new(1, -6, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Position = UDim2.new(0, 4, 0, 0),
	Text = "",
	TextSize = 10,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = AboutScroll,
})
Bind(AboutText, "TextColor3", "TextDim")

local LoadedAt = os.date("%H:%M - %d/%m/%Y")
local GameName = "memuat..."
local function RefreshAbout()
	local job = (game.JobId ~= "") and game.JobId or "-"
	AboutText.Text = "Script : NimeroHub\nVersi  : v2.1 Kristal\nPemain : " .. LocalPlayer.Name
		.. "\nExecutor : Delta\nDimuat : " .. LoadedAt
		.. "\nGame : " .. GameName
		.. "\nPlace ID : " .. tostring(game.PlaceId)
		.. "\nJob ID : " .. job
end
RefreshAbout()

task.spawn(function()
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	GameName = (ok and info and info.Name) or "tidak diketahui"
	if Alive() then RefreshAbout() end
end)
end

-------------------------------------------------
-- BUKA / TUTUP UI
-------------------------------------------------
local UIVisible = false
local toggleToken = 0

local function GetFit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.clamp(math.min((vp.X - 24) / MAIN_W, (vp.Y - 24) / MAIN_H), 0.5, 1)
end

-- Animasi saat menu muncul (gaya dipilih lewat menu Animasi Buka)
OA.Show = function(fit, my)
	local key = (OA.list[OA.idx] or OA.list[1] or {"zoom"})[1]
	if not OA.busy then OA.base = Root.Position end
	OA.busy = true
	OA.gen += 1
	local g = OA.gen
	task.delay(1.2, function()
		if OA.gen == g then OA.busy = false end
	end)
	local base = OA.base or Root.Position
	local function Off(dx, dy)
		return UDim2.new(base.X.Scale, base.X.Offset + dx, base.Y.Scale, base.Y.Offset + dy)
	end
	Root.Position = base
	Root.Rotation = 0
	Tween(Glow, 0.5, {ImageTransparency = 0.78})
	Tween(MainStroke, 0.4, {Transparency = 0.1})
	local fadeT = 0.35
	if key == "pegas" then
		RootScale.Scale = fit * 0.35
		Tween(RootScale, 0.9, {Scale = fit}, ES.Elastic, ED.Out)
	elseif key == "geser" then
		RootScale.Scale = fit
		Root.Position = Off(-700, 0)
		Tween(Root, 0.65, {Position = base}, ES.Quint, ED.Out)
		fadeT = 0.2
	elseif key == "jatuh" then
		RootScale.Scale = fit
		Root.Position = Off(0, -520)
		Tween(Root, 0.9, {Position = base}, ES.Bounce, ED.Out)
		fadeT = 0.2
	elseif key == "naik" then
		RootScale.Scale = fit
		Root.Position = Off(0, 520)
		Tween(Root, 0.6, {Position = base}, ES.Back, ED.Out)
		fadeT = 0.25
	elseif key == "putar" then
		RootScale.Scale = fit * 0.3
		Root.Rotation = -140
		Tween(RootScale, 0.75, {Scale = fit}, ES.Back, ED.Out)
		Tween(Root, 0.75, {Rotation = 0}, ES.Quint, ED.Out)
	elseif key == "glitch" then
		RootScale.Scale = fit
		task.spawn(function()
			for i = 1, 7 do
				if my ~= toggleToken or not Alive() then return end
				Main.GroupTransparency = (i % 2 == 0) and 0.75 or 0.1
				Root.Position = Off(math.random(-16, 16), math.random(-3, 3))
				RootScale.Scale = fit * (0.96 + math.random() * 0.07)
				task.wait(0.055)
			end
			if my ~= toggleToken or not Alive() then return end
			Root.Position = base
			Tween(RootScale, 0.15, {Scale = fit})
			Tween(Main, 0.12, {GroupTransparency = 0})
		end)
		return
	elseif key == "pudar" then
		RootScale.Scale = fit
		fadeT = 0.7
	else
		Tween(RootScale, 0.55, {Scale = fit}, ES.Back, ED.Out)
	end
	Tween(Main, fadeT, {GroupTransparency = 0}, ES.Quad, ED.Out)
end

-- Putar ulang animasi tanpa menutup panel (untuk pratinjau saat memilih gaya)
OA.Replay = function()
	if not UIVisible then return end
	toggleToken += 1
	local my = toggleToken
	local fit = GetFit()
	Tween(Main, 0.16, {GroupTransparency = 1}, ES.Quad, ED.In)
	Tween(RootScale, 0.16, {Scale = fit * 0.9}, ES.Quad, ED.In)
	task.delay(0.2, function()
		if my ~= toggleToken or not Alive() then return end
		OA.Show(fit, my)
	end)
end

RootScale.Scale = GetFit() * 0.88

local function SetStatus(on)
	if on then
		Tween(StatusDot, 0.3, {BackgroundColor3 = Colors.Green})
		StatusText.Text = "ON"
		Tween(StatusText, 0.3, {TextColor3 = Colors.Green})
	else
		Tween(StatusDot, 0.3, {BackgroundColor3 = Color3.fromRGB(110, 40, 55)})
		StatusText.Text = "OFF"
		Tween(StatusText, 0.3, {TextColor3 = Color3.fromRGB(170, 90, 105)})
	end
end

local function SetVisible(show)
	toggleToken += 1
	local my = toggleToken
	UIVisible = show
	local fit = GetFit()
	SetStatus(show)

	if show then
		Root.Visible = true
		OA.Show(fit, my)
	else
		ClosePicker()
		CloseSettings()
		Closers.Crystal()
		Closers.Mode()
		Closers.Avatar()
		Closers.Anim()
			Closers.Sound()
		Tween(RootScale, 0.26, {Scale = fit * 0.9}, ES.Quad, ED.In)
		Tween(Main, 0.24, {GroupTransparency = 1}, ES.Quad, ED.In)
		Tween(Glow, 0.24, {ImageTransparency = 1}, ES.Quad, ED.In)
		Tween(MainStroke, 0.24, {Transparency = 1}, ES.Quad, ED.In)
		task.delay(0.3, function()
			if toggleToken == my then Root.Visible = false end
		end)
	end
end

local function ToggleUI()
	pcall(PlayClick, UIVisible and "close" or "open")
	local okV, errV = pcall(SetVisible, not UIVisible)
	if not okV then
		-- tampilkan error di layar (di luar UI utama, jadi tidak ikut tersembunyi)
		pcall(function()
			local sg = Instance.new("ScreenGui")
			sg.Name = "NimeroErr"
			sg.ResetOnSpawn = false
			sg.IgnoreGuiInset = true
			sg.DisplayOrder = 999
			local okP, pg = pcall(function()
				return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
			end)
			sg.Parent = (typeof(gethui) == "function" and gethui()) or (okP and pg) or game:GetService("CoreGui")
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(0.9, 0, 0, 160)
			t.Position = UDim2.new(0.05, 0, 0.35, 0)
			t.BackgroundColor3 = Color3.fromRGB(30, 10, 14)
			t.TextColor3 = Color3.fromRGB(255, 140, 140)
			t.TextWrapped = true
			t.TextSize = 14
			t.Font = Enum.Font.Code
			t.Text = "NimeroHub gagal dibuka:\n" .. tostring(errV)
			t.Parent = sg
		end)
	end
end

do
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if UIVisible then Tween(RootScale, 0.3, {Scale = GetFit()}) end
		end)
	end
end

-------------------------------------------------
-- DRAG (panel + tombol NH + slider warna)
-------------------------------------------------
local dragNH, dragStartNH, startPosNH, nhMoved = false, nil, nil, false
local dragMain, dragStartMain, startPosMain, mainMoved = false, nil, nil, false
local nhPressed = false

NHButton.InputBegan:Connect(function(input)
	if IsPointer(input) then
		dragNH = true
		nhPressed = true
		nhMoved = false
		dragStartNH = input.Position
		startPosNH = NHButton.Position
	end
end)

-- Ketukan tombol NH: dihitung saat jari diangkat di mana saja (tidak harus tepat di atas tombol),
-- plus cadangan lewat Activated. Jeda singkat mencegah buka-tutup dua kali.
local lastNH = 0
local function NHTap()
	local now = os.clock()
	if now - lastNH < 0.3 then return end
	lastNH = now
	ToggleUI()
end

NHButton.InputEnded:Connect(function(input)
	if IsPointer(input) and nhPressed then
		nhPressed = false
		if not nhMoved then NHTap() end
	end
end)

NHButton.Activated:Connect(function()
	if not nhMoved then NHTap() end
end)

TitleBar.InputBegan:Connect(function(input)
	if IsPointer(input) then
		dragMain = true
		mainMoved = false
		dragStartMain = input.Position
		startPosMain = Root.Position
	end
end)

local conns = {}

table.insert(conns, UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if activeSlider then
		UpdateSliderFromX(activeSlider, input.Position.X)
	end
	if dragNH then
		local d = input.Position - dragStartNH
		if d.Magnitude > 14 then nhMoved = true end
		if nhMoved then
			NHButton.Position = UDim2.new(startPosNH.X.Scale, startPosNH.X.Offset + d.X, startPosNH.Y.Scale, startPosNH.Y.Offset + d.Y)
			pcall(CFX.Trail, NHButton)
		end
	end
	if dragMain then
		local d = input.Position - dragStartMain
		if d.Magnitude > 8 then mainMoved = true end
		if mainMoved then
			Tween(Root, 0.07, {
				Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + d.X, startPosMain.Y.Scale, startPosMain.Y.Offset + d.Y)
			}, ES.Quad)
		end
	end
end))

table.insert(conns, UserInputService.InputEnded:Connect(function(input)
	if IsPointer(input) then
		if nhPressed then
			nhPressed = false
			if not nhMoved then NHTap() end
		end
		dragNH = false
		dragMain = false
		activeSlider = nil
	end
end))

-- Cadangan untuk PC: RightControl buka/tutup menu
table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.RightControl then
		ToggleUI()
	end
end))

-------------------------------------------------
-- REALTIME
-------------------------------------------------
local startTime = os.clock()
local frames = 0
table.insert(conns, RunService.RenderStepped:Connect(function()
	frames += 1
end))

task.spawn(function()
	local lastFps = os.clock()
	while Alive() do
		task.wait(0.25)
		if UIVisible then
			local now = os.clock()
			TimeLbl.Text = os.date("%H:%M:%S")

			if now - lastFps >= 0.5 then
				FPSVal.Text = tostring(math.floor(frames / (now - lastFps) + 0.5))
				frames = 0
				lastFps = now
			end

			local okPing, ping = pcall(function()
				return math.floor(LocalPlayer:GetNetworkPing() * 1000)
			end)
			if okPing then PingVal.Text = ping .. "ms" end

			PlayerVal.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers

			local up = math.floor(now - startTime)
			UptimeVal.Text = string.format("%d:%02d", math.floor(up / 60), up % 60)
		else
			frames = 0
			lastFps = os.clock()
		end
	end
end)

ScreenGui.Destroying:Connect(function()
	for _, c in ipairs(conns) do c:Disconnect() end
end)

-------------------------------------------------
-- FONT TEKS (tombol FONT di sebelah FPS BOOST, pilih font untuk semua teks)
-------------------------------------------------
do
	local okF, errF = pcall(function()
		local FONTS = {
			{"Asli", nil},
			{"Gotham", Enum.Font.Gotham},
			{"Arial", Enum.Font.Arial},
			{"Source Sans", Enum.Font.SourceSans},
			{"Code", Enum.Font.Code},
			{"SciFi", Enum.Font.SciFi},
			{"Michroma", Enum.Font.Michroma},
			{"Jura", Enum.Font.Jura},
			{"Oswald", Enum.Font.Oswald},
			{"Ubuntu", Enum.Font.Ubuntu},
			{"Nunito", Enum.Font.Nunito},
			{"Roboto Mono", Enum.Font.RobotoMono},
			{"Fredoka One", Enum.Font.FredokaOne},
			{"Bangers", Enum.Font.Bangers},
			{"Special Elite", Enum.Font.SpecialElite},
		}
		-- font tambahan; yang tidak tersedia di Roblox akan dilewati otomatis
		for _, fe in ipairs({
			{"Luckiest Guy", "LuckiestGuy"},
			{"Permanent Marker", "PermanentMarker"},
			{"Indie Flower", "IndieFlower"},
			{"Patrick Hand", "PatrickHand"},
			{"Kalam", "Kalam"},
			{"Amatic SC", "AmaticSC"},
			{"Creepster", "Creepster"},
			{"Fondamento", "Fondamento"},
			{"Grenze Gotisch", "GrenzeGotisch"},
			{"Denk One", "DenkOne"},
			{"Merriweather", "Merriweather"},
			{"Josefin Sans", "JosefinSans"},
			{"Titillium Web", "TitilliumWeb"},
			{"Sarpanch", "Sarpanch"},
			{"Arcade", "Arcade"},
			{"Fantasy", "Fantasy"},
		}) do
			local okf, fv = pcall(function() return Enum.Font[fe[2]] end)
			if okf and fv then table.insert(FONTS, {fe[1], fv}) end
		end
		local cur = 1
		if type(SV.saved.font) == "number" and FONTS[SV.saved.font] then cur = SV.saved.font end
		local open, token = false, 0
		local orig = setmetatable({}, {__mode = "k"})
		local skip = setmetatable({}, {__mode = "k"})

		-- tombol FONT di title bar
		local FontBtn = Make("TextButton", {
			Name = "FontBtn",
			Size = UDim2.new(0, 50, 0, 20),
			Position = UDim2.new(0, 236, 0.5, -10),
			BackgroundColor3 = Cur.Btn,
			Text = "FONT",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = TitleBar,
		})
		Corner(FontBtn, "full")
		do
			local st = Stroke(FontBtn, Cur.Accent, 1, 0.4)
			Bind(st, "Color", "Accent")
		end
		Bind(FontBtn, "BackgroundColor3", "Btn")
		local FScale = Instance.new("UIScale")
		FScale.Parent = FontBtn
		FontBtn.MouseButton1Down:Connect(function() Tween(FScale, 0.08, {Scale = 0.94}, ES.Quad) end)
		FontBtn.MouseButton1Up:Connect(function() Tween(FScale, 0.25, {Scale = 1}, ES.Back) end)

		-- panel daftar font
		local Panel = Make("CanvasGroup", {
			Name = "FontPanel",
			Position = UDim2.new(0, 196, 0, 44),
			Size = UDim2.new(0, 170, 0, 176),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			ZIndex = 40,
			Parent = Main,
		})
		Corner(Panel, 12)
		local PBg = Make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Colors.White,
			BorderSizePixel = 0,
			Active = true,
			Parent = Panel,
		})
		BGrad(PBg, "Card0", "Card1", 90)
		local PBd = Make("Frame", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Parent = Panel,
		})
		Corner(PBd, 11)
		do
			local st = Stroke(PBd, Cur.Accent, 1.2, 0.2)
			Bind(st, "Color", "Accent")
		end
		Label({
			Size = UDim2.new(1, -40, 0, 16),
			Position = UDim2.new(0, 10, 0, 8),
			Text = "FONT TEKS",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Panel,
		})
		local XBtn = Make("TextButton", {
			Size = UDim2.new(0, 22, 0, 18),
			Position = UDim2.new(1, -30, 0, 7),
			BackgroundColor3 = Cur.Btn,
			Text = "X",
			Font = Enum.Font.GothamBlack,
			TextSize = 10,
			TextColor3 = Colors.Text,
			AutoButtonColor = false,
			Parent = Panel,
		})
		Corner(XBtn, 6)
		Interactive(XBtn, "Btn", "Accent")

		local List = Make("ScrollingFrame", {
			Size = UDim2.new(1, -16, 1, -40),
			Position = UDim2.new(0, 8, 0, 32),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, #FONTS * 28),
			ScrollBarThickness = 3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = Panel,
		})
		Bind(List, "ScrollBarImageColor3", "Accent")

		local Opts = {}
		local function Mark()
			for i, b in ipairs(Opts) do
				b.BackgroundColor3 = (i == cur) and Cur.Accent or Cur.Btn
				b.TextColor3 = (i == cur) and Colors.White or Colors.Text
			end
		end

		-- ganti font semua teks (dikerjakan bertahap supaya tidak lag)
		local function IsText(o)
			return o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")
		end
		local function ApplyTo(o)
			if skip[o] then return end
			if orig[o] == nil then orig[o] = o.Font end
			o.Font = FONTS[cur][2] or orig[o]
		end
		local applyToken = 0
		local function ApplyAll()
			applyToken += 1
			local my = applyToken
			task.spawn(function()
				local n = 0
				for _, o in ipairs(ScreenGui:GetDescendants()) do
					if my ~= applyToken then return end
					if IsText(o) then
						pcall(ApplyTo, o)
						n += 1
						if n % 150 == 0 then task.wait() end
					end
				end
			end)
		end

		for i, f in ipairs(FONTS) do
			local b = Make("TextButton", {
				Size = UDim2.new(1, -6, 0, 24),
				Position = UDim2.new(0, 0, 0, (i - 1) * 28),
				BackgroundColor3 = Cur.Btn,
				Text = f[1],
				Font = f[2] or Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = Colors.Text,
				AutoButtonColor = false,
				Parent = List,
			})
			Corner(b, 6)
			skip[b] = true -- contoh font di daftar tetap pakai fontnya sendiri
			Opts[i] = b
			b.MouseButton1Click:Connect(function()
				PlayClick("pilih")
				cur = i
				SV.Set("font", i)
				Mark()
				ApplyAll()
				ShowToast("Font: " .. f[1])
			end)
		end
		OnTheme(function() Mark() end)
		if cur ~= 1 then ApplyAll() end

		-- dipakai mode spesial: nama font = paksa font itu, nil = kembali ke pilihan pengguna
		CFX.SetFont = function(name)
			local idx
			if name then
				for i, f in ipairs(FONTS) do
					if f[1] == name then idx = i end
				end
			else
				idx = (type(SV.cur.font) == "number" and FONTS[SV.cur.font]) and SV.cur.font or 1
			end
			if idx and idx ~= cur then
				cur = idx
				Mark()
				ApplyAll()
			end
		end

		-- teks baru yang muncul belakangan ikut font yang dipilih
		ScreenGui.DescendantAdded:Connect(function(o)
			if cur ~= 1 and IsText(o) then pcall(ApplyTo, o) end
		end)

		local function Open()
			if open then return end
			open = true
			token += 1
			ClosePicker()
			CloseSettings()
			Closers.Crystal()
			Closers.Mode()
			Closers.Avatar()
			Closers.Anim()
			Closers.Sound()
			Panel.Visible = true
			Panel.GroupTransparency = 1
			Panel.Position = UDim2.new(0, 196, 0, 52)
			Tween(Panel, 0.35, {GroupTransparency = 0, Position = UDim2.new(0, 196, 0, 44)}, ES.Back)
		end
		local function Close()
			if not open then return end
			open = false
			token += 1
			local my = token
			Tween(Panel, 0.2, {GroupTransparency = 1, Position = UDim2.new(0, 196, 0, 52)}, ES.Quad, ED.In)
			task.delay(0.23, function()
				if my == token then Panel.Visible = false end
			end)
		end

		Closers.Font = Close

		FontBtn.MouseButton1Click:Connect(function()
			PlayClick(open and "close" or "open")
			if open then Close() else Open() end
		end)
		XBtn.MouseButton1Click:Connect(function()
			PlayClick("close")
			Close()
		end)
		Root:GetPropertyChangedSignal("Visible"):Connect(function()
			if not Root.Visible then Close() end
		end)
	end)
	if not okF then table.insert(BootErr, "Font: " .. tostring(errF)) end
end

-------------------------------------------------
-- PERCIKAN SAAT TOMBOL DITEKAN (semua tombol di UI)
-------------------------------------------------
do
	local okP, errP = pcall(function()
		local function Hook(o)
			if o:IsA("TextButton") then
				o.MouseButton1Click:Connect(function()
					pcall(CFX.Burst, o)
				end)
			end
		end
		for _, o in ipairs(ScreenGui:GetDescendants()) do Hook(o) end
		ScreenGui.DescendantAdded:Connect(Hook)
	end)
	if not okP then table.insert(BootErr, "Percikan: " .. tostring(errP)) end
end

if not SV.Can() then
	task.delay(1.4, function()
		if Alive() then ShowToast("Executor tidak support simpan") end
	end)
end

if type(SV.saved.mode) == "string" and CFX.Modes[SV.saved.mode] then
	task.defer(function()
		if Alive() then CFX.EnterMode(SV.saved.mode, true) end
	end)
end

-------------------------------------------------
-- ANIMASI MUNCUL
-------------------------------------------------
SetVisible(true)

if #BootErr > 0 then
	warn("NimeroHub: " .. table.concat(BootErr, " | "))
	task.delay(0.8, function()
		ShowToast("Error " .. string.sub(BootErr[1], 1, 52))
	end)
end

print("NimeroHub v2.1 berhasil dimuat!")
