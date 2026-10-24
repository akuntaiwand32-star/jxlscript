-- NimeroHub: TRACE EGG + QUICK GET
-- Telur liar dibaca dari folder "EggRuntime" di Workspace (telur di akuarium/kandang
-- tidak ikut). GET = teleport ke telur lalu coba ambil lewat ProximityPrompt.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ===== KONFIGURASI =====
local EGG_ROOT = "EggRuntime"   -- folder tempat telur liar muncul
local RADAR_INTERVAL = 4        -- detik, scan ulang saat RADAR ON
local LOOP_INTERVAL = 3         -- detik, jeda antar ambil saat AUTO LOOP
local TP_HEIGHT = 5
local GRAB_FROM_AFAR = false      -- true = coba ambil dari tempat berdiri dulu (tanpa teleport)
local HOP_SETTLE = 0.3           -- detik, jeda setelah teleport sebelum ambil telur
local GRAB_WAIT = 0.4            -- detik, tunggu setelah menekan ambil
local RETURN_DELAY = 0.15        -- detik, jeda sebelum balik ke posisi awal
local AUTO_INVENTORY = true      -- setelah telur diamankan, otomatis tekan "PUT TO INVENTORY"
local INVENTORY_TEXT = "put to inventory"
local FALLBACK_INTERVAL = 20     -- detik, jarak antar scan seluruh Workspace (hemat performa)
local REQUIRE_PROMPT = true      -- true = hanya telur yang punya ProximityPrompt aktif (siap diambil)
local RETRY_COOLDOWN = 60        -- detik, telur yang sudah pernah di-TP tidak didatangi lagi
local AUTO_TRACE_RARE = true     -- TRACE EGG otomatis menampilkan telur langka yang sedang spawn
local AUTO_TRACE_COUNT = 3       -- jumlah telur langka yang ditampilkan di TRACE EGG
local AUTO_TRACE_MIN_TIER = "Rare" -- rarity terendah yang ikut (Mythic > Legendary > Epic > Rare > Common)
local AQUARIUM_CHECK = true      -- tolak telur yang berada di dalam kaca/akuarium atau yang sedang ditaruh (ada timer/berat)
local GLASS_RADIUS = 7            -- stud, jarak cek kaca di sekitar telur
local FALLBACK_FULL_SCAN = true  -- telur trace yang tak ketemu di EggRuntime dicari juga di seluruh Workspace
local MANUAL_STAY = 2           -- detik, tunggu di telur jika harus ambil manual (sebelum balik)

-- Telur yang namanya/induknya mengandung kata ini diabaikan (akuarium, kandang, zona aman, dll):
local EXCLUDE_KEYWORDS = { "safe", "lobby", "zonaaman", "kandang", "plot", "coop", "pen", "tycoon",
    "habitat", "enclosure", "incubat", "aquarium", "akuarium", "tank" }

-- Telur yang di-trace secara default (ketuk nama telur di daftar untuk ubah)
local DEFAULT_TRACE = { "Kraken Glory Egg", "Inferno Egg", "Mamba Egg" }

-- ===== KATALOG TELUR (urut rarity: termahal di atas) =====
local CATALOG = {
    { name = "Admin Abuse Seraph Egg", alias = { "adminabuse", "seraph", "admin" }, special = true, min = 80e9,  max = 2e12,  txt = "80B–2T" },
    { name = "KingKalolo Egg",         alias = { "kalolo" }, special = true, min = 130e9, max = 400e9, txt = "130B–400B" },
    { name = "Inferno Egg",            min = 350e9, max = 350e9, txt = "350B" },
    { name = "Mamba Egg",              min = 300e9, max = 300e9, txt = "300B" },
    { name = "Spikey Egg",             min = 250e9, max = 250e9, txt = "250B" },
    { name = "Solar Orbit Egg",        min = 200e9, max = 200e9, txt = "200B" },
    { name = "Azure Crown Egg",        min = 170e9, max = 170e9, txt = "170B" },
    { name = "Amethyst Spiral Egg",    min = 140e9, max = 140e9, txt = "140B" },
    { name = "Kraken Glory Egg",       alias = { "kraken" }, min = 24e9,  max = 140e9, txt = "24B–140B" },
    { name = "Glacial Spiral Egg",     min = 115e9, max = 115e9, txt = "115B" },
    { name = "Coral Reef Egg",         min = 90e9,  max = 90e9,  txt = "90B" },
    { name = "Eternal Egg",            min = 70e9,  max = 70e9,  txt = "70B" },
    { name = "Celestial Egg",          min = 20e9,  max = 20e9,  txt = "20B" },
    { name = "Sovereign Egg",          min = 1e9,   max = 1e9,   txt = "1B" },
    { name = "Trench Egg",             min = 60e6,  max = 60e6,  txt = "60M" },
    { name = "Abyss Egg",              min = 3e6,   max = 3e6,   txt = "3M" },
    { name = "Deep Egg",               min = 160e3, max = 160e3, txt = "160K" },
    { name = "Tidal Egg",              min = 8e3,   max = 8e3,   txt = "8K" },
    { name = "Reef Egg",               min = 400,   max = 400,   txt = "400" },
    { name = "Coral Egg",              min = 20,    max = 20,    txt = "20" },
    { name = "Common Egg",             min = 1,     max = 1,     txt = "1" },
}

local TIERS = {
    { name = "Mythic",    min = 140e9, color = Color3.fromRGB(255, 40, 120) },
    { name = "Legendary", min = 20e9,  color = Color3.fromRGB(255, 215, 0) },
    { name = "Epic",      min = 1e6,   color = Color3.fromRGB(190, 60, 255) },
    { name = "Rare",      min = 400,   color = Color3.fromRGB(0, 170, 255) },
    { name = "Common",    min = 0,     color = Color3.fromRGB(140, 150, 185) },
}
local TIER_COLOR = {}
for _, t in ipairs(TIERS) do TIER_COLOR[t.name] = t.color end

local T = {
    bg = Color3.fromRGB(5, 11, 8),
    panel = Color3.fromRGB(9, 20, 14),
    row = Color3.fromRGB(13, 27, 19),
    accent = Color3.fromRGB(0, 185, 85),     -- hijau neon (isi tombol/tab)
    cyan = Color3.fromRGB(70, 255, 140),     -- hijau neon terang (judul)
    green = Color3.fromRGB(110, 220, 0),     -- lime neon (tombol aktif)
    text = Color3.fromRGB(234, 255, 240),
    sub = Color3.fromRGB(140, 180, 155),
    off = Color3.fromRGB(18, 40, 28),
}

-- Gradasi neon (ujung = awal supaya putarannya mulus)
local NEON = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(57, 255, 20)),
    ColorSequenceKeypoint.new(0.3,  Color3.fromRGB(0, 255, 140)),
    ColorSequenceKeypoint.new(0.6,  Color3.fromRGB(0, 190, 110)),
    ColorSequenceKeypoint.new(0.8,  Color3.fromRGB(150, 255, 0)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(57, 255, 20)),
})

-- ===== SIAPKAN KATALOG =====
local function norm(s) return (s:lower():gsub("[^%w]", "")) end

table.sort(CATALOG, function(a, b)
    if a.max ~= b.max then return a.max > b.max end
    return a.min > b.min
end)

local keyList, byName = {}, {}
for _, e in ipairs(CATALOG) do
    e.key = (norm(e.name):gsub("egg$", ""))
    for _, t in ipairs(TIERS) do
        if e.max >= t.min then e.tier = t.name break end
    end
    table.insert(keyList, { key = e.key, entry = e })
    for _, al in ipairs(e.alias or {}) do
        table.insert(keyList, { key = norm(al), entry = e })
    end
    byName[e.name] = e
end
table.sort(keyList, function(a, b) return #a.key > #b.key end)

local function matchEntry(name, loose)
    local n = norm(name)
    local hasEgg = n:find("egg", 1, true)
    if not hasEgg and not loose then return nil end
    for _, k in ipairs(keyList) do
        if hasEgg then
            if n:find(k.key, 1, true) then return k.entry end
        elseif n == k.key then
            return k.entry
        end
    end
end

local traced = {}
for _, nm in ipairs(DEFAULT_TRACE) do
    if byName[nm] then traced[byName[nm]] = true end
end

-- urutan rarity: Mythic = 1 (paling langka) ... Common = 5
local tierRank = {}
for i, t in ipairs(TIERS) do tierRank[t.name] = i end
local AUTO_MIN_RANK = tierRank[AUTO_TRACE_MIN_TIER] or 4

local autoSet = {}   -- telur langka yang sedang spawn (dipilih otomatis)

local function isTraced(entry)
    return traced[entry] or autoSet[entry] or false
end

-- a lebih langka dari b? (rarity dulu, lalu luck maksimum)
local function rarer(a, b)
    local ra, rb = tierRank[a.tier] or 99, tierRank[b.tier] or 99
    if ra ~= rb then return ra < rb end
    return a.max > b.max
end

-- ===== PARENT =====
local parent = (gethui and gethui()) or game:GetService("CoreGui")
if not pcall(function() return parent.Name end) then
    parent = player:WaitForChild("PlayerGui")
end
local old = parent:FindFirstChild("MenuUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MenuUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local hlFolder = Instance.new("Folder", gui)
hlFolder.Name = "Highlights"

-- ===== HELPER UI =====
local function tw(obj, t, props, style, dir)
    TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out), props):Play()
end

local function corner(o, r) local c = Instance.new("UICorner", o) c.CornerRadius = UDim.new(0, r) return c end

local function label(p, text, size, color, font, xalign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = xalign or Enum.TextXAlignment.Left
    l.Parent = p
    return l
end

local function animateButton(btn, base)
    local scale = Instance.new("UIScale", btn)
    local function cur() return btn:GetAttribute("Cur") or base end
    btn.AutoButtonColor = false
    btn.MouseEnter:Connect(function()
        tw(btn, 0.12, { BackgroundColor3 = cur():Lerp(Color3.new(1, 1, 1), 0.12) })
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, 0.12, { BackgroundColor3 = cur() })
        tw(scale, 0.12, { Scale = 1 })
    end)
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tw(scale, 0.08, { Scale = 0.94 })
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tw(scale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
        end
    end)
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos, moved
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            dragStart, startPos = input.Position, target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            TweenService:Create(target, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y) }):Play()
        end
    end)
    return function() return moved end
end

-- ===== JENDELA UTAMA =====
local main = Instance.new("CanvasGroup")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0, 600, 0, 352)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = T.bg
main.BorderSizePixel = 0
main.GroupTransparency = 1
main.Parent = gui
corner(main, 16)

local mainScale = Instance.new("UIScale", main)
mainScale.Scale = 0.9

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Thickness = 1.5
mainStroke.Color = Color3.new(1, 1, 1)
local sg = Instance.new("UIGradient", mainStroke)
sg.Color = NEON
sg.Rotation = 45
TweenService:Create(sg, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    { Rotation = 405 }):Play()

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 56)
header.BackgroundColor3 = T.panel
header.BorderSizePixel = 0
header.Parent = main
local hg = Instance.new("UIGradient", header)
hg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 46, 22)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 22, 14)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 50, 34)),
})
hg.Rotation = 0

local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 36, 0, 36)
icon.Position = UDim2.new(0, 14, 0, 10)
icon.BackgroundColor3 = T.accent
icon.Text = "N"
icon.TextColor3 = Color3.new(1, 1, 1)
icon.Font = Enum.Font.GothamBold
icon.TextSize = 18
icon.Parent = header
corner(icon, 10)
local ig = Instance.new("UIGradient", icon)
ig.Color = NEON
ig.Rotation = 45


local titleLbl = label(header, "NimeroHub", 18, Color3.new(1, 1, 1), Enum.Font.GothamBold)
titleLbl.Size = UDim2.new(0, 220, 0, 22)
titleLbl.Position = UDim2.new(0, 58, 0, 8)
local titleGrad = Instance.new("UIGradient", titleLbl)
titleGrad.Color = NEON
titleGrad.Offset = Vector2.new(-0.5, 0)
TweenService:Create(titleGrad, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Offset = Vector2.new(0.5, 0) }):Play()

local msg = label(header, "", 12, T.sub)
msg.Size = UDim2.new(1, -330, 0, 16)
msg.Position = UDim2.new(0, 58, 0, 31)
msg.TextTruncate = Enum.TextTruncate.AtEnd
msg:GetPropertyChangedSignal("Text"):Connect(function()
    msg.TextTransparency = 0.7
    tw(msg, 0.35, { TextTransparency = 0 })
end)

-- Pill status
local pill = Instance.new("Frame")
pill.Size = UDim2.new(0, 96, 0, 32)
pill.Position = UDim2.new(1, -196, 0, 12)
pill.BackgroundColor3 = Color3.fromRGB(7, 17, 11)
pill.Parent = header
corner(pill, 16)
local pillDot = Instance.new("Frame")
pillDot.Size = UDim2.new(0, 10, 0, 10)
pillDot.Position = UDim2.new(0, 12, 0.5, -5)
pillDot.BackgroundColor3 = T.sub
pillDot.Parent = pill
corner(pillDot, 5)
local pillTxt = label(pill, "IDLE", 12, T.text, Enum.Font.GothamBold)
pillTxt.Size = UDim2.new(1, -32, 1, 0)
pillTxt.Position = UDim2.new(0, 30, 0, 0)

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 76, 0, 32)
hideBtn.Position = UDim2.new(1, -88, 0, 12)
hideBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 100)
hideBtn.Text = "HIDE"
hideBtn.TextColor3 = T.text
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 13
hideBtn.Parent = header
corner(hideBtn, 10)
animateButton(hideBtn, Color3.fromRGB(255, 40, 100))

makeDraggable(header, main)

-- ===== PANEL KIRI: TRACE EGG =====
local left = Instance.new("Frame")
left.Size = UDim2.new(0, 248, 1, -86)
left.Position = UDim2.new(0, 12, 0, 62)
left.BackgroundColor3 = Color3.fromRGB(8, 21, 13)
left.BorderSizePixel = 0
left.Parent = main
corner(left, 12)

local traceTitle = label(left, "TRACE EGG", 13, T.cyan, Enum.Font.GothamBold)
traceTitle.Size = UDim2.new(1, -20, 0, 18)
traceTitle.Position = UDim2.new(0, 12, 0, 8)

local traceBox = Instance.new("Frame")
traceBox.Size = UDim2.new(1, -20, 0, 80)
traceBox.Position = UDim2.new(0, 10, 0, 30)
traceBox.BackgroundColor3 = Color3.fromRGB(7, 17, 11)
traceBox.BorderSizePixel = 0
traceBox.Parent = left
corner(traceBox, 10)

local function makeAction(text, y, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 36)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = T.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = left
    b:SetAttribute("Base", color)
    b:SetAttribute("Cur", color)
    corner(b, 10)
    animateButton(b, color)
    return b
end

local radarBtn = makeAction("RADAR: OFF", 118, Color3.fromRGB(0, 150, 85))
local onceBtn = makeAction("▸ RUN ONCE", 160, Color3.fromRGB(30, 170, 30))
local loopBtn = makeAction("AUTO LOOP: OFF", 202, Color3.fromRGB(0, 140, 120))

-- ===== PANEL KANAN: QUICK GET =====
local right = Instance.new("Frame")
right.Size = UDim2.new(1, -284, 1, -86)
right.Position = UDim2.new(0, 272, 0, 62)
right.BackgroundColor3 = Color3.fromRGB(6, 16, 12)
right.BorderSizePixel = 0
right.Parent = main
corner(right, 12)

local quickTitle = label(right, "QUICK GET", 13, T.cyan, Enum.Font.GothamBold)
quickTitle.Size = UDim2.new(0, 90, 0, 22)
quickTitle.Position = UDim2.new(0, 12, 0, 6)

local tab = Instance.new("TextLabel")
tab.Size = UDim2.new(0, 104, 0, 24)
tab.Position = UDim2.new(0, 108, 0, 5)
tab.BackgroundColor3 = T.accent
tab.Text = "LIST EGG"
tab.TextColor3 = T.text
tab.Font = Enum.Font.GothamBold
tab.TextSize = 12
tab.Parent = right
corner(tab, 8)

local countLbl = label(right, "0/" .. #CATALOG, 12, T.sub, Enum.Font.GothamMedium, Enum.TextXAlignment.Right)
countLbl.Size = UDim2.new(0, 60, 0, 22)
countLbl.Position = UDim2.new(1, -72, 0, 6)

local hint = label(right, "Tekan GET untuk langsung ambil telur  •  ketuk nama untuk trace", 11, T.sub)
hint.Size = UDim2.new(1, -24, 0, 16)
hint.Position = UDim2.new(0, 12, 0, 32)
hint.TextTruncate = Enum.TextTruncate.AtEnd

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -16, 1, -56)
list.Position = UDim2.new(0, 8, 0, 50)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = T.accent
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = right
local ll = Instance.new("UIListLayout", list)
ll.Padding = UDim.new(0, 6)
ll.SortOrder = Enum.SortOrder.LayoutOrder
local lp = Instance.new("UIPadding", list)
lp.PaddingRight = UDim.new(0, 6)

-- ===== WATERMARK =====
local WATERMARK = "TikTok  @aanantmng"

local wmFooter = label(main, WATERMARK, 11, Color3.new(1, 1, 1), Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
wmFooter.Position = UDim2.new(0, 0, 1, -20)
wmFooter.Size = UDim2.new(1, 0, 0, 16)
local wmGrad = Instance.new("UIGradient", wmFooter)
wmGrad.Color = NEON
wmGrad.Offset = Vector2.new(-0.5, 0)
wmGrad.Offset = Vector2.new(0, 0)

-- ===== DETEKSI TELUR LIAR =====
local OWNER_ATTRS = { "Owner", "OwnerId", "OwnerUserId", "UserId", "Player", "PlotOwner" }

local function getPosition(inst)
    if inst:IsA("Attachment") then return inst.WorldPosition end
    if inst:IsA("Model") then
        local ok, pv = pcall(function() return inst:GetPivot() end)
        return ok and pv.Position or nil
    elseif inst:IsA("BasePart") then
        return inst.Position
    end
end

local function hasKeyword(name)
    local s = name:lower()
    for _, k in ipairs(EXCLUDE_KEYWORDS) do
        if #k <= 3 then
            if s:find("%f[%a]" .. k .. "s?%f[%A]") then return k end
        elseif s:find(k, 1, true) then
            return k
        end
    end
    return nil
end

local function isExcluded(inst)
    local p = inst
    while p and p ~= workspace do
        local kw = hasKeyword(p.Name)
        if kw then return "kata '" .. kw .. "' di " .. p.Name end
        if Players:FindFirstChild(p.Name) then return "milik player " .. p.Name end
        for _, a in ipairs(OWNER_ATTRS) do
            if p:GetAttribute(a) ~= nil then return "atribut " .. a .. " di " .. p.Name end
        end
        local ov = p:FindFirstChild("Owner")
        if ov and (ov:IsA("ObjectValue") or ov:IsA("StringValue") or ov:IsA("IntValue")) then
            return "ada Owner di " .. p.Name
        end
        p = p.Parent
    end
    return nil
end

local function insideZoneParts(pos, parts)
    for _, part in ipairs(parts) do
        local rel = part.CFrame:PointToObjectSpace(pos)
        local h = part.Size / 2
        if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y + 6 and math.abs(rel.Z) <= h.Z then
            return part
        end
    end
    return nil
end

local function shortPath(inst)
    local names, p = {}, inst.Parent
    while p and p ~= workspace and #names < 2 do
        table.insert(names, 1, p.Name)
        p = p.Parent
    end
    return #names > 0 and table.concat(names, "/") or "Workspace"
end

-- telur yang sudah pernah di-TP: tried[inst] = waktu os.clock() sampai boleh dicoba lagi
local tried = setmetatable({}, { __mode = "k" })

local function findPrompt(inst)
    local p = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not p and inst.Parent and inst.Parent:IsA("Model") then
        p = inst.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
    return p
end

-- true jika telur masih liar & belum diambil (bukan di tas/karakter, belum dicoba, prompt aktif)
local function isAvailable(inst, entry, fromRoot)
    local t = tried[inst]
    if t and os.clock() < t then
        return false, (t == math.huge) and "sudah terambil" or "sudah dicoba (cooldown)"
    end
    local char = player.Character
    if char and inst:IsDescendantOf(char) then return false, "ada di karakter" end
    local prompt = findPrompt(inst)
    -- telur khusus boleh tanpa prompt HANYA jika ada di folder spawn liar (EggRuntime);
    -- di luar folder itu (mis. akuarium) prompt tetap wajib
    local needPrompt = REQUIRE_PROMPT and not (entry and entry.special and fromRoot)
    if needPrompt then
        if not prompt then return false, "tidak ada ProximityPrompt" end
        if not prompt.Enabled then return false, "prompt nonaktif" end
    elseif prompt and not prompt.Enabled then
        return false, "prompt nonaktif"
    end
    return true
end

-- ===== DETEKSI TELUR DI AKUARIUM / YANG SUDAH DITARUH =====
local glassParams = OverlapParams.new()
glassParams.FilterType = Enum.RaycastFilterType.Exclude

local function isGlassLike(p)
    if p.Material == Enum.Material.Glass then return true end
    local n = p.Name:lower()
    if n:find("glass", 1, true) or n:find("aquarium", 1, true)
    or n:find("akuarium", 1, true) or n:find("tank", 1, true) then
        return true
    end
    return p.Transparency >= 0.3 and p.Transparency < 0.97 and p.CanCollide and p.Size.Magnitude >= 5
end

-- telur dikelilingi >= 2 bagian kaca = di dalam tangki akuarium
local function inGlassTank(inst, pos)
    local ex = inst
    if inst:IsA("BasePart") and inst.Parent and inst.Parent:IsA("Model") then ex = inst.Parent end
    local filter = { ex }
    if player.Character then table.insert(filter, player.Character) end
    glassParams.FilterDescendantsInstances = filter
    local ok, parts = pcall(workspace.GetPartBoundsInRadius, workspace, pos, GLASS_RADIUS, glassParams)
    if not ok then return false end
    local n = 0
    for _, p in ipairs(parts) do
        if isGlassLike(p) then
            n += 1
            if n >= 2 then return true end
        end
    end
    return false
end

-- telur yang sudah ditaruh biasanya punya label timer (mis. "2h 28m") atau berat ("kg")
local function hasPlacedLabel(inst)
    local box = inst
    if inst.Parent and inst.Parent:IsA("Model") then box = inst.Parent end
    for _, d in ipairs(box:GetDescendants()) do
        if d:IsA("TextLabel") then
            local t = d.Text:lower()
            if t:find("%d%s*kg") or t:find("%d+d%s*%d+h") or t:find("%d+h%s*%d+m") then
                return true
            end
        end
    end
    return false
end

local function placedReason(inst, pos)
    if inGlassTank(inst, pos) then return "di dalam kaca/akuarium" end
    if hasPlacedLabel(inst) then return "ada timer/berat (sudah ditaruh)" end
    return nil
end

local live = {}          -- live[entry] = {count, inst, pos, dist, loc}
local scanStats = {}
local scanning = false
local cachedRoot, lastRootSearch, fbAt, fbCache = nil, 0, 0, nil

local function scanEggs()
    local root = cachedRoot
    if not (root and root.Parent) then
        root = nil
        if os.clock() - lastRootSearch > 5 then
            lastRootSearch = os.clock()
            root = workspace:FindFirstChild(EGG_ROOT) or workspace:FindFirstChild(EGG_ROOT, true)
        end
        cachedRoot = root
    end
    local cands, zoneParts, near, seen = {}, {}, {}, {}
    local n = 0

    -- kata pertama telur yang di-trace: dipakai untuk petunjuk jika nama tidak cocok persis
    local words = {}
    for _, entry in ipairs(CATALOG) do
        if traced[entry] or entry.special then
            local w = norm(entry.name:match("^%S+") or entry.name)
            if #w >= 4 then table.insert(words, { entry = entry, w = w }) end
        end
    end

    local function walk(source, loose, onlyMissing)
        for _, inst in ipairs(source:GetDescendants()) do
            n += 1
            if n % 3000 == 0 then task.wait() end
            if not seen[inst] then
                seen[inst] = true
                if not loose and inst:IsA("BasePart") and hasKeyword(inst.Name) then
                    table.insert(zoneParts, inst)
                end
                if (inst:IsA("Model") or inst:IsA("BasePart"))
                and not inst:IsA("Terrain")
                and not inst:FindFirstAncestorOfClass("Tool") then
                    local entry = matchEntry(inst.Name, loose)
                    if entry then
                        if not onlyMissing or onlyMissing[entry] then
                            local p = inst.Parent
                            local dupe = inst:IsA("BasePart") and p and p:IsA("Model")
                                and matchEntry(p.Name, loose) == entry
                            if not dupe then
                                local pos = getPosition(inst)
                                if pos then
                                    table.insert(cands, { inst = inst, pos = pos, entry = entry, fromRoot = loose })
                                end
                            end
                        end
                    else
                        local nn = norm(inst.Name)
                        for _, w in ipairs(words) do
                            if not near[w.entry] and nn:find(w.w, 1, true) then near[w.entry] = inst end
                        end
                    end
                end
            end
        end
    end

    walk(root or workspace, root ~= nil, nil)

    -- telur trace yang belum ketemu di EggRuntime: cari juga di seluruh Workspace
    if root and FALLBACK_FULL_SCAN then
        local found, missing, any = {}, {}, false
        for _, c in ipairs(cands) do found[c.entry] = true end
        for _, entry in ipairs(CATALOG) do
            if (traced[entry] or entry.special) and not found[entry] then
                missing[entry] = true
                any = true
            end
        end
        if any then
            if os.clock() - fbAt >= FALLBACK_INTERVAL then
                fbAt = os.clock()
                local cStart, zStart = #cands + 1, #zoneParts + 1
                walk(workspace, false, missing)
                fbCache = { cands = {}, zones = {} }
                for i = cStart, #cands do table.insert(fbCache.cands, cands[i]) end
                for i = zStart, #zoneParts do table.insert(fbCache.zones, zoneParts[i]) end
            elseif fbCache then
                -- pakai hasil scan terakhir (tidak scan ulang seluruh map tiap detik)
                for _, c in ipairs(fbCache.cands) do
                    if c.inst.Parent and missing[c.entry] then
                        c.pos = getPosition(c.inst) or c.pos
                        table.insert(cands, c)
                    end
                end
                for _, z in ipairs(fbCache.zones) do
                    if z.Parent then table.insert(zoneParts, z) end
                end
            end
        end
    end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local result, excluded, diag, firstWhy = {}, 0, {}, nil
    for _, c in ipairs(cands) do
        local reason = isExcluded(c.inst)
        if not reason and AQUARIUM_CHECK and not c.fromRoot then
            reason = placedReason(c.inst, c.pos)
        end
        if not reason and not c.fromRoot then
            local zp = insideZoneParts(c.pos, zoneParts)
            if zp then reason = "di area " .. zp.Name end
        end
        if not reason then
            local okAv, why = isAvailable(c.inst, c.entry, c.fromRoot)
            if not okAv then reason = why end
        end
        if reason then
            excluded += 1
            if not firstWhy then firstWhy = c.entry.name .. ": " .. shortPath(c.inst) .. " → " .. reason end
            if not diag[c.entry] then diag[c.entry] = shortPath(c.inst) .. " → " .. reason end
        else
            local dist = hrp and (c.pos - hrp.Position).Magnitude or nil
            local L = result[c.entry]
            if L then
                L.count += 1 -- telur sama digabung
                if dist and (not L.dist or dist < L.dist) then
                    L.inst, L.pos, L.dist, L.loc, L.fromRoot = c.inst, c.pos, dist, shortPath(c.inst), c.fromRoot
                end
            else
                result[c.entry] = { inst = c.inst, pos = c.pos, dist = dist,
                                    count = 1, loc = shortPath(c.inst), fromRoot = c.fromRoot }
            end
        end
    end
    for entry in pairs(result) do diag[entry] = nil end
    return result, { excluded = excluded, root = root ~= nil, diag = diag, near = near, cands = #cands, firstWhy = firstWhy }
end

-- ===== AKSI: GET (teleport + ambil) =====
local getBusy = false
local GuiService = game:GetService("GuiService")

local function isTaken(inst, prompt)
    if not inst.Parent or not prompt.Parent or not prompt.Enabled then return true end
    local ch = player.Character
    return ch ~= nil and inst:IsDescendantOf(ch)
end

-- tunggu per frame sampai telur terambil (keluar lebih awal begitu terkonfirmasi)
local function waitTaken(inst, prompt, maxT)
    local t0 = os.clock()
    while os.clock() - t0 < maxT do
        if isTaken(inst, prompt) then return true end
        task.wait()
    end
    return isTaken(inst, prompt)
end

-- ----- PUT TO INVENTORY otomatis -----
local invBtn, invScanAt = nil, 0

local function guiVisible(obj)
    local p = obj
    while p and p ~= game do
        if p:IsA("GuiObject") and not p.Visible then return false end
        if p:IsA("ScreenGui") and not p.Enabled then return false end
        p = p.Parent
    end
    return true
end

local function findInventoryButton()
    if invBtn and invBtn.Parent then return invBtn end
    invBtn = nil
    if os.clock() - invScanAt < 0.4 then return nil end -- batasi scan PlayerGui
    invScanAt = os.clock()
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local t = (d.Text:lower():gsub("%s+", " "))
            if t:find(INVENTORY_TEXT, 1, true) then
                invBtn = d:IsA("GuiButton") and d or d:FindFirstAncestorWhichIsA("GuiButton") or d
                return invBtn
            end
        end
    end
end

local function clickGui(btn)
    -- 1) panggil langsung handler tombol (tanpa menggerakkan layar)
    if getconnections and btn:IsA("GuiButton") then
        for _, ev in ipairs({ btn.Activated, btn.MouseButton1Click }) do
            local okc, conns = pcall(getconnections, ev)
            if okc and conns and #conns > 0 then
                for _, c in ipairs(conns) do pcall(function() c:Fire() end) end
                return true
            end
        end
    end
    -- 2) cadangan: ketuk lewat posisi layar
    return pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
        local sg = btn:FindFirstAncestorWhichIsA("ScreenGui")
        local dy = (sg and sg.IgnoreGuiInset) and 0 or GuiService:GetGuiInset().Y
        local x, y = pos.X + size.X / 2, pos.Y + size.Y / 2 + dy
        if UIS.TouchEnabled and not UIS.MouseEnabled then
            vim:SendTouchEvent(1, 0, x, y)
            task.wait(0.05)
            vim:SendTouchEvent(1, 2, x, y)
        else
            vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end
    end)
end

local function putToInventory(maxWait, eggName)
    local t0, btn = os.clock(), nil
    repeat
        local b = findInventoryButton()
        if b and guiVisible(b) then btn = b break end
        task.wait(0.1)
    until os.clock() - t0 >= maxWait
    if not btn then return false end
    clickGui(btn)
    msg.Text = "Masuk inventory: " .. eggName
    return true
end

local function getEgg(entry, L)
    if getBusy then return false end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then msg.Text = "Karakter tidak ditemukan" return false end
    if not L.inst.Parent then msg.Text = "Telur sudah hilang, scan ulang" return false end

    if AQUARIUM_CHECK and not L.fromRoot then
        local why = placedReason(L.inst, getPosition(L.inst) or L.pos)
        if why then
            tried[L.inst] = os.clock() + RETRY_COOLDOWN
            msg.Text = "Dibatalkan (" .. why .. ")"
            return false
        end
    end

    getBusy = true
    local origin = hrp.CFrame -- posisi disimpan otomatis sebelum teleport
    local moved, taken = false, false

    local ok, err = pcall(function()
        local inst = L.inst
        local prompt = findPrompt(inst)
        if prompt and fireproximityprompt then
            pcall(function()
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
            end)

            -- 1) dari tempat berdiri: pemain diam, telur langsung diambil
            if GRAB_FROM_AFAR then
                pcall(fireproximityprompt, prompt)
                taken = waitTaken(inst, prompt, 0.25)
            end

            -- 2) kalau server menolak (terlalu jauh): teleport kilat, ambil, langsung balik
            if not taken then
                moved = true
                local pos = getPosition(inst) or L.pos
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, TP_HEIGHT, 0))
                task.wait(HOP_SETTLE)
                pcall(fireproximityprompt, prompt)
                task.wait(GRAB_WAIT)
                taken = isTaken(inst, prompt)
            end

            if taken then
                tried[inst] = math.huge -- sudah terambil, jangan didatangi lagi
                msg.Text = "Terambil: " .. entry.name
            else
                tried[inst] = os.clock() + RETRY_COOLDOWN
                msg.Text = "GET " .. entry.name .. " (belum terkonfirmasi)"
            end
        else
            -- tanpa prompt (telur khusus / ambil lewat sentuh atau klik)
            moved = true
            local pos = getPosition(inst) or L.pos
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
            task.wait(HOP_SETTLE)

            local cd = inst:FindFirstChildWhichIsA("ClickDetector", true)
            if not cd and inst.Parent and inst.Parent:IsA("Model") then
                cd = inst.Parent:FindFirstChildWhichIsA("ClickDetector", true)
            end
            if cd and fireclickdetector then pcall(fireclickdetector, cd) end

            local part = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
            if part and firetouchinterest then
                pcall(function()
                    firetouchinterest(hrp, part, 0)
                    task.wait()
                    firetouchinterest(hrp, part, 1)
                end)
            end

            local t0 = os.clock()
            while os.clock() - t0 < MANUAL_STAY and inst.Parent do task.wait(0.1) end
            taken = not inst.Parent
            if taken then
                tried[inst] = math.huge
                msg.Text = "Terambil: " .. entry.name
            else
                tried[inst] = os.clock() + RETRY_COOLDOWN
                msg.Text = "TP ke " .. entry.name .. " (ambil manual)"
            end
        end
    end)

    -- balik otomatis ke posisi sebelumnya (hanya jika tadi berpindah)
    if moved then
        task.wait(RETURN_DELAY)
        local back = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if back then
            back.CFrame = origin
            pcall(function()
                back.AssemblyLinearVelocity = Vector3.zero
                back.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end

    -- setelah telur diamankan dan sudah kembali: otomatis taruh ke inventory
    if ok and AUTO_INVENTORY then
        task.wait(0.1)
        pcall(putToInventory, taken and 1.2 or 0.3, entry.name)
    end
    getBusy = false

    if not ok then warn(err) msg.Text = "Error saat GET" return false end
    return true
end

-- pilih telur langka yang ada di list sekarang; jika Mythic 0, otomatis turun ke rarity berikutnya
local function computeAuto()
    table.clear(autoSet)
    if not AUTO_TRACE_RARE then return end
    local arr = {}
    for entry in pairs(live) do
        if (tierRank[entry.tier] or 99) <= AUTO_MIN_RANK then arr[#arr + 1] = entry end
    end
    table.sort(arr, rarer)
    for i = 1, math.min(AUTO_TRACE_COUNT, #arr) do autoSet[arr[i]] = true end
end

local function bestTarget()
    local arr = {}
    for entry in pairs(live) do
        if isTraced(entry) then arr[#arr + 1] = entry end
    end
    if #arr == 0 then return end
    table.sort(arr, rarer)
    return arr[1], live[arr[1]]
end

-- ===== STATUS / RENDER =====
local radarOn, loopOn = false, false
local scannedOnce = false

local function updatePill()
    local text, color = "IDLE", T.sub
    if loopOn then text, color = "LOOP", T.green
    elseif radarOn then text, color = "RADAR", T.cyan
    elseif scanning then text, color = "SCAN", T.accent end
    pillTxt.Text = text
    tw(pillDot, 0.2, { BackgroundColor3 = color })
end

local function setToggle(btn, on, textOn, textOff)
    btn.Text = on and textOn or textOff
    local base = on and T.green or (btn:GetAttribute("Base") or T.off)
    btn:SetAttribute("Cur", base)
    tw(btn, 0.2, { BackgroundColor3 = base })
end

local function whyNot(entry)
    if live[entry] or not scannedOnce then return nil end
    local d = scanStats.diag and scanStats.diag[entry]
    if d then return "difilter: " .. d end
    local nr = scanStats.near and scanStats.near[entry]
    if nr then
        local ok, nm = pcall(function() return nr.Name .. " (" .. shortPath(nr) .. ")" end)
        if ok then return "nama mirip: " .. nm .. ", tidak cocok" end
    end
    return "tidak ada di scan"
end

local render

local function renderTrace()
    for _, c in ipairs(traceBox:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end

    -- hanya telur yang benar-benar ada di list (count > 0), yang paling langka di atas
    local arr = {}
    for entry in pairs(live) do
        if isTraced(entry) then arr[#arr + 1] = entry end
    end
    table.sort(arr, rarer)

    for i = 1, math.min(3, #arr) do
        local entry = arr[i]
        local L = live[entry]
        local y = 6 + (i - 1) * 24
        local color = TIER_COLOR[entry.tier]

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.Position = UDim2.new(0, 12, 0, y + 7)
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        dot.Parent = traceBox
        corner(dot, 4)

        local nm = label(traceBox, entry.name, 12, T.text, Enum.Font.GothamMedium)
        nm.Size = UDim2.new(1, -118, 0, 22)
        nm.Position = UDim2.new(0, 28, 0, y)
        nm.TextTruncate = Enum.TextTruncate.AtEnd

        local cnt = label(traceBox, entry.tier .. "  " .. L.count .. "x", 11, color,
            Enum.Font.GothamBold, Enum.TextXAlignment.Right)
        cnt.Size = UDim2.new(0, 90, 0, 22)
        cnt.Position = UDim2.new(1, -98, 0, y)
    end

    local extra = #arr - 3
    traceTitle.Text = extra > 0 and ("TRACE EGG  +" .. extra) or "TRACE EGG"

    if #arr == 0 then
        local h = label(traceBox, "Belum ada telur langka\nyang spawn", 12, T.sub,
            Enum.Font.Gotham, Enum.TextXAlignment.Center)
        h.Size = UDim2.new(1, 0, 1, 0)
    end
end

render = function()
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    hlFolder:ClearAllChildren()

    local spawned = 0
    for i, entry in ipairs(CATALOG) do
        local L = live[entry]
        if L then spawned += 1 end
        local color = TIER_COLOR[entry.tier]

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 46)
        row.BackgroundColor3 = T.row
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = list
        corner(row, 10)
        local rs = Instance.new("UIStroke", row)
        rs.Color = isTraced(entry) and color or Color3.fromRGB(30, 85, 55)
        rs.Thickness = isTraced(entry) and 1.5 or 1
        rs.Transparency = 0.2

        local rowScale = Instance.new("UIScale", row)
        rowScale.Scale = 0.94
        local rowLight = T.row:Lerp(Color3.new(1, 1, 1), 0.07)
        row.MouseEnter:Connect(function()
            tw(row, 0.15, { BackgroundColor3 = rowLight })
            tw(rs, 0.15, { Transparency = 0 })
        end)
        row.MouseLeave:Connect(function()
            tw(row, 0.2, { BackgroundColor3 = T.row })
            tw(rs, 0.2, { Transparency = 0.2 })
        end)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(0, 12, 0.5, -5)
        dot.BackgroundColor3 = color
        dot.Parent = row
        corner(dot, 5)

        -- ketuk nama = tambah / hapus trace
        local nameBtn = Instance.new("TextButton")
        nameBtn.Size = UDim2.new(1, -170, 0, 22)
        nameBtn.Position = UDim2.new(0, 30, 0, 5)
        nameBtn.BackgroundTransparency = 1
        nameBtn.Text = entry.name
        nameBtn.TextColor3 = L and T.text or T.sub
        nameBtn.TextXAlignment = Enum.TextXAlignment.Left
        nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
        nameBtn.Font = Enum.Font.GothamMedium
        nameBtn.TextSize = 13
        nameBtn.Parent = row
        nameBtn.Activated:Connect(function()
            traced[entry] = not traced[entry] or nil
            renderTrace()
            render()
        end)

        local subTxt = "LUCK " .. entry.txt
        local why = whyNot(entry)
        if L then
            subTxt = subTxt .. "  •  " .. (L.dist and (math.floor(L.dist) .. " stud  •  ") or "") .. L.loc
        elseif why then
            subTxt = subTxt .. "  •  " .. why
        end
        local subLbl = label(row, subTxt, 10, L and color or T.sub, Enum.Font.Gotham)
        subLbl.Size = UDim2.new(1, -170, 0, 14)
        subLbl.Position = UDim2.new(0, 30, 0, 26)
        subLbl.TextTruncate = Enum.TextTruncate.AtEnd

        local cnt = label(row, (L and L.count or 0) .. "x", 13, L and color or T.sub,
            Enum.Font.GothamBold, Enum.TextXAlignment.Right)
        cnt.Size = UDim2.new(0, 44, 1, 0)
        cnt.Position = UDim2.new(1, -128, 0, 0)

        local get = Instance.new("TextButton")
        get.Size = UDim2.new(0, 70, 0, 30)
        get.Position = UDim2.new(1, -78, 0.5, -15)
        get.Font = Enum.Font.GothamBold
        get.TextSize = 12
        get.Parent = row
        corner(get, 8)
        if L then
            get.Text = "▸ GET"
            get.BackgroundColor3 = color
            get.TextColor3 = Color3.new(1, 1, 1)
            animateButton(get, color)
            get.Activated:Connect(function() task.spawn(getEgg, entry, L) end)
            if isTraced(entry) then
                local hl = Instance.new("Highlight")
                hl.Adornee = L.inst
                hl.FillColor = color
                hl.FillTransparency = 0.55
                hl.OutlineColor = color
                hl.Parent = hlFolder
            end
        else
            get.Text = "▸ GET"
            get.BackgroundColor3 = Color3.fromRGB(20, 38, 29)
            get.TextColor3 = T.sub
            -- ketuk GET pada telur yang 0 untuk melihat alasannya
            get.Activated:Connect(function()
                msg.Text = why or "Belum spawn"
                if why then warn("[NimeroHub] " .. entry.name .. " -> " .. why) end
            end)
        end

        if L then
            -- denyut halus pada tombol GET agar telur yang spawn terlihat hidup
            local glow = Instance.new("UIStroke", get)
            glow.Color = Color3.new(1, 1, 1)
            glow.Thickness = 1.5
            glow.Transparency = 0.4
        end

        task.delay(math.min(i, 10) * 0.03, function()
            if row.Parent then
                tw(row, 0.3, { BackgroundTransparency = 0 })
                tw(rowScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
            end
        end)
    end

    countLbl.Text = spawned .. "/" .. #CATALOG
    countLbl.TextColor3 = spawned > 0 and T.green or T.sub
    if scannedOnce and msg.Text == "" then
        msg.Text = spawned .. " spawn" .. (scanStats.root and "" or "  •  folder " .. EGG_ROOT .. " tidak ditemukan")
    end
    renderTrace()
end

local lastWhy = {}
local lastSig, lastInst = "", {}

local function doScan()
    if scanning then return end
    scanning = true
    updatePill()
    local ok, res, st = pcall(scanEggs)
    scanning = false
    if ok then
        live = res
        scanStats = st or {}
        scannedOnce = true
        computeAuto()
        for entry in pairs(traced) do
            local w = whyNot(entry)
            if w and lastWhy[entry] ~= w then
                lastWhy[entry] = w
                warn("[NimeroHub] " .. entry.name .. " 0x -> " .. w)
            end
        end
        local sp = 0
        for _ in pairs(live) do sp += 1 end
        msg.Text = sp .. " spawn"
            .. (scanStats.root and "" or ("  •  folder " .. EGG_ROOT .. " tidak ada, scan seluruh map"))
            .. ((scanStats.excluded or 0) > 0 and ("  •  " .. scanStats.excluded .. " diabaikan") or "")
            .. ((sp == 0 and scanStats.firstWhy) and ("  •  " .. scanStats.firstWhy) or "")
        if sp == 0 and scanStats.firstWhy and lastWhy._zero ~= scanStats.firstWhy then
            lastWhy._zero = scanStats.firstWhy
            warn("[NimeroHub] 0 spawn (" .. (scanStats.cands or 0) .. " kandidat): " .. scanStats.firstWhy)
        end

        -- bangun ulang daftar hanya jika ada yang berubah (lebih ringan)
        local parts = {}
        for i, entry in ipairs(CATALOG) do
            local Lv = live[entry]
            parts[i] = (Lv and (Lv.count .. ":" .. Lv.loc) or (whyNot(entry) or "-")) .. (isTraced(entry) and "T" or "")
        end
        local sig = table.concat(parts, "|")
        local changed = sig ~= lastSig
        for entry, Lv in pairs(live) do
            if lastInst[entry] ~= Lv.inst then changed = true end
        end
        for entry in pairs(lastInst) do
            if not live[entry] then changed = true end
        end
        lastSig, lastInst = sig, {}
        for entry, Lv in pairs(live) do lastInst[entry] = Lv.inst end
        if changed then render() end
    else
        msg.Text = "Error scan"
        warn(res)
    end
    updatePill()
end

local function runOnce()
    doScan()
    local entry, L = bestTarget()
    if entry then
        getEgg(entry, L)
    else
        msg.Text = "Tidak ada telur trace yang spawn"
    end
end

-- ===== TOMBOL AKSI =====
radarBtn.Activated:Connect(function()
    radarOn = not radarOn
    setToggle(radarBtn, radarOn, "RADAR: ON", "RADAR: OFF")
    updatePill()
    if radarOn then task.spawn(doScan) end
end)

onceBtn.Activated:Connect(function()
    task.spawn(runOnce)
end)

loopBtn.Activated:Connect(function()
    loopOn = not loopOn
    setToggle(loopBtn, loopOn, "AUTO LOOP: ON", "AUTO LOOP: OFF")
    updatePill()
end)

task.spawn(function()
    while gui.Parent do
        if radarOn and not loopOn then pcall(doScan) end
        task.wait(RADAR_INTERVAL)
    end
end)

task.spawn(function()
    while gui.Parent do
        if loopOn then
            pcall(function()
                doScan()
                local entry, L = bestTarget()
                if entry then
                    getEgg(entry, L)
                    task.wait(LOOP_INTERVAL)
                else
                    msg.Text = "Loop: menunggu telur trace spawn..."
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- ===== BUKA / TUTUP =====
local isOn = true
local bubble
local bubbleDot

local function fitScale()
    local cam = workspace.CurrentCamera
    if not cam then return 1 end
    local vp = cam.ViewportSize
    return math.clamp(math.min(vp.X / 640, vp.Y / 380), 0.55, 1)
end

local function setOpen(on)
    isOn = on
    if on then
        main.Visible = true
        tw(mainScale, 0.3, { Scale = fitScale() }, Enum.EasingStyle.Back)
        tw(main, 0.2, { GroupTransparency = 0 })
    else
        tw(mainScale, 0.18, { Scale = 0.9 })
        tw(main, 0.18, { GroupTransparency = 1 })
        task.delay(0.19, function() if not isOn then main.Visible = false end end)
    end
    if bubbleDot then
        tw(bubbleDot, 0.25, { BackgroundColor3 = on and T.green or Color3.fromRGB(255, 40, 100) })
    end
end

hideBtn.Activated:Connect(function() setOpen(false) end)

local function watchViewport()
    local cam = workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if isOn then tw(mainScale, 0.25, { Scale = fitScale() }) end
        end)
    end
end
watchViewport()

-- ===== GELEMBUNG =====
bubble = Instance.new("TextButton")
bubble.Name = "Bubble"
bubble.Size = UDim2.new(0, 44, 0, 44)
bubble.Position = UDim2.new(0, 20, 0.5, -22)
bubble.BackgroundTransparency = 1
bubble.Text = ""
bubble.AutoButtonColor = false
bubble.Parent = gui
corner(bubble, 22)

local bStroke = Instance.new("UIStroke", bubble)
bStroke.Color = Color3.new(1, 1, 1)
bStroke.Thickness = 2
bStroke.Transparency = 0.2

-- isi gelembung: dibungkus "inner" supaya bisa bernapas (membesar-mengecil) terus
local inner = Instance.new("Frame")
inner.AnchorPoint = Vector2.new(0.5, 0.5)
inner.Position = UDim2.new(0.5, 0, 0.5, 0)
inner.Size = UDim2.new(1, 0, 1, 0)
inner.BackgroundTransparency = 1
inner.Parent = bubble
TweenService:Create(inner, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Size = UDim2.new(1.08, 0, 1.08, 0) }):Play()

-- inti gelembung (latar neon) + huruf N dan b terpisah, masing-masing punya skala sendiri
local core = Instance.new("Frame")
core.Size = UDim2.new(1, 0, 1, 0)
core.BackgroundTransparency = 1
core.Parent = inner
local coreScale = Instance.new("UIScale", core)

local bubbleBg = Instance.new("Frame")
bubbleBg.Size = UDim2.new(1, 0, 1, 0)
bubbleBg.BackgroundColor3 = Color3.new(1, 1, 1)
bubbleBg.BorderSizePixel = 0
bubbleBg.Parent = core
local bubbleCorner = Instance.new("UICorner", bubbleBg)
bubbleCorner.CornerRadius = UDim.new(0.5, 0)
local bubbleGrad = Instance.new("UIGradient", bubbleBg)
bubbleGrad.Color = NEON
TweenService:Create(bubbleGrad, TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    { Rotation = 360 }):Play()

local function makeLetter(ch, xpos, align)
    local l = label(inner, ch, 18, Color3.new(1, 1, 1), Enum.Font.GothamBlack, align)
    l.Size = UDim2.new(0.5, 0, 1, 0)
    l.Position = UDim2.new(xpos, 0, 0, 0)
    l.ZIndex = 2
    l.TextStrokeColor3 = Color3.fromRGB(0, 60, 20)
    l.TextStrokeTransparency = 0.4
    return l, Instance.new("UIScale", l)
end
local letterN, scaleN = makeLetter("N", 0, Enum.TextXAlignment.Right)
local letterB, scaleB = makeLetter("b", 0.5, Enum.TextXAlignment.Left)

-- titik status: hijau = menu terbuka, merah = tertutup
bubbleDot = Instance.new("Frame")
bubbleDot.AnchorPoint = Vector2.new(0.5, 0.5)
bubbleDot.Position = UDim2.new(0.86, 0, 0.14, 0)
bubbleDot.Size = UDim2.new(0, 11, 0, 11)
bubbleDot.BackgroundColor3 = T.green
bubbleDot.BorderSizePixel = 0
bubbleDot.ZIndex = 3
bubbleDot.Parent = bubble
do
    local dc = Instance.new("UICorner", bubbleDot)
    dc.CornerRadius = UDim.new(0.5, 0)
    local ds = Instance.new("UIStroke", bubbleDot)
    ds.Color = Color3.new(1, 1, 1)
    ds.Thickness = 1.5
end

-- gelombang cincin pelangi yang memancar terus dari gelembung
for i = 1, 2 do
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.Size = UDim2.new(1, 0, 1, 0)
    ring.BackgroundTransparency = 1
    ring.Parent = bubble
    local rc = Instance.new("UICorner", ring)
    rc.CornerRadius = UDim.new(0.5, 0)
    local rsk = Instance.new("UIStroke", ring)
    rsk.Thickness = 2
    rsk.Color = Color3.new(1, 1, 1)
    rsk.Transparency = 1
    local rg = Instance.new("UIGradient", rsk)
    rg.Color = NEON
    task.spawn(function()
        task.wait((i - 1) * 1.1)
        while gui.Parent do
            ring.Size = UDim2.new(1, 0, 1, 0)
            rsk.Transparency = 0.2
            tw(ring, 2.2, { Size = UDim2.new(1.5, 0, 1.5, 0) }, Enum.EasingStyle.Sine)
            tw(rsk, 2.2, { Transparency = 1 }, Enum.EasingStyle.Sine)
            task.wait(2.2)
        end
    end)
end

-- ===== EFEK PECAH & MENYATU =====
-- gelembung pecah jadi serpihan neon, melayang sebentar, lalu tersedot dan menyatu lagi
do
    local rngB = Random.new()
    local COLS = {
        Color3.fromRGB(57, 255, 20), Color3.fromRGB(0, 255, 140), Color3.fromRGB(150, 255, 0),
        Color3.fromRGB(0, 200, 120), Color3.fromRGB(255, 255, 255),
    }
    local SHARDS = 16
    local shards = {}
    for i = 1, SHARDS do
        local sz = rngB:NextInteger(4, 8)
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(0.5, 0, 0.5, 0)
        f.Size = UDim2.new(0, sz, 0, sz)
        f.BackgroundColor3 = COLS[(i % #COLS) + 1]
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.ZIndex = 5
        f.Parent = bubble
        if i % 3 == 0 then
            local c = Instance.new("UICorner", f)
            c.CornerRadius = UDim.new(0.5, 0)
        end
        shards[i] = {
            f = f,
            ang = (i / SHARDS) * math.pi * 2 + rngB:NextNumber(-0.2, 0.2),
            dist = rngB:NextNumber(24, 44),
            spin = rngB:NextInteger(-300, 300),
        }
    end

    local flash = Instance.new("Frame")
    flash.AnchorPoint = Vector2.new(0.5, 0.5)
    flash.Position = UDim2.new(0.5, 0, 0.5, 0)
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(1, 1, 1)
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.ZIndex = 4
    flash.Parent = bubble
    local fc = Instance.new("UICorner", flash)
    fc.CornerRadius = UDim.new(0.5, 0)

    local function offset(s, extraAng, extraDist)
        return UDim2.new(0.5, math.cos(s.ang + extraAng) * (s.dist + extraDist),
            0.5, math.sin(s.ang + extraAng) * (s.dist + extraDist))
    end

    local function shatterCycle()
        -- 1) PECAH: huruf dan latar mengecil, serpihan meledak keluar
        tw(scaleN, 0.12, { Scale = 0 })
        tw(scaleB, 0.12, { Scale = 0 })
        tw(coreScale, 0.16, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        for _, s in ipairs(shards) do
            s.f.Position = UDim2.new(0.5, 0, 0.5, 0)
            s.f.Rotation = 0
            s.f.BackgroundTransparency = 0
            tw(s.f, 0.5, { Position = offset(s, 0, 0), Rotation = s.spin },
                Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        task.wait(0.55)

        -- 2) MELAYANG: serpihan berputar pelan
        for _, s in ipairs(shards) do
            tw(s.f, 0.5, { Position = offset(s, 0.5, 5), Rotation = s.spin * 1.5 },
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        end
        task.wait(0.5)

        -- 3) MENYATU: serpihan tersedot ke tengah
        for _, s in ipairs(shards) do
            tw(s.f, 0.4, { Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = s.spin * 2 },
                Enum.EasingStyle.Back, Enum.EasingDirection.In)
        end
        task.wait(0.4)
        for _, s in ipairs(shards) do
            s.f.BackgroundTransparency = 1
        end

        -- 4) BENTUK ULANG: kilatan, latar membal, lalu N dan b muncul bergantian
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundTransparency = 0.2
        tw(flash, 0.45, { Size = UDim2.new(1.4, 0, 1.4, 0), BackgroundTransparency = 1 })
        tw(coreScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
        task.delay(0.15, function() tw(scaleN, 0.4, { Scale = 1 }, Enum.EasingStyle.Back) end)
        task.delay(0.28, function() tw(scaleB, 0.4, { Scale = 1 }, Enum.EasingStyle.Back) end)
        task.wait(0.75)
    end

    task.spawn(function()
        task.wait(3)
        while gui.Parent do
            if bubble.Visible then
                local ok, err = pcall(shatterCycle)
                if not ok then
                    warn(err)
                    coreScale.Scale, scaleN.Scale, scaleB.Scale = 1, 1, 1
                end
            end
            task.wait(3.4)
        end
    end)
end

local bScale = Instance.new("UIScale", bubble)
local wasMoved = makeDraggable(bubble, bubble)

bubble.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        tw(bScale, 0.08, { Scale = 0.9 })
    end
end)
bubble.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        tw(bScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
    end
end)
bubble.Activated:Connect(function()
    if wasMoved() then return end
    setOpen(not isOn)
end)

task.spawn(function()
    while gui.Parent do
        tw(bStroke, 1.2, { Transparency = 0.7 }, Enum.EasingStyle.Sine)
        task.wait(1.2)
        tw(bStroke, 1.2, { Transparency = 0.1 }, Enum.EasingStyle.Sine)
        task.wait(1.2)
    end
end)

msg.Text = "Tekan RUN ONCE atau RADAR"
render()
updatePill()

-- warna judul/scrollbar/border gelembung berganti pelan dengan warna neon
do
    local hue, acc, conn = 0, 0, nil
    conn = RunService.Heartbeat:Connect(function(dt)
        if not gui.Parent then conn:Disconnect() return end
        acc += dt
        if acc < 0.1 then return end
        hue = (hue + acc * 0.12) % 1
        acc = 0
        local c1 = Color3.fromHSV(0.36 + 0.09 * math.sin(hue * 6.2832), 1, 1)
        local c2 = Color3.fromHSV(0.36 + 0.09 * math.sin(hue * 6.2832 + 2), 1, 1)
        traceTitle.TextColor3 = c1
        quickTitle.TextColor3 = c2
        list.ScrollBarImageColor3 = c1
        bStroke.Color = c1
    end)
end

-- ===== ANTI LAG / POTATO (otomatis, bawaan, tanpa tombol) =====
local Lighting = game:GetService("Lighting")

local EFFECT = {
    ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true,
    BloomEffect = true, BlurEffect = true, SunRaysEffect = true,
    ColorCorrectionEffect = true, DepthOfFieldEffect = true,
}

local function potatoInstance(inst)
    local cn = inst.ClassName
    if EFFECT[cn] then
        inst.Enabled = false
    elseif cn == "Atmosphere" then
        inst.Density = 0
        inst.Haze = 0
        inst.Glare = 0
    end
end

local function applyPotato()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    end)
    pcall(function()
        local t = workspace:FindFirstChildOfClass("Terrain")
        if t then
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
            t.Decoration = false
        end
    end)
    if sethiddenproperty then
        pcall(sethiddenproperty, Lighting, "Technology", Enum.Technology.Compatibility)
    end

    -- efek baru yang muncul belakangan ikut dimatikan (cek ringan lewat nama class)
    workspace.DescendantAdded:Connect(function(inst)
        if EFFECT[inst.ClassName] then pcall(potatoInstance, inst) end
    end)
    Lighting.DescendantAdded:Connect(function(inst) pcall(potatoInstance, inst) end)

    -- sapu efek yang sudah ada, bertahap supaya game tidak freeze
    local function sweep(root)
        local n = 0
        for _, inst in ipairs(root:GetDescendants()) do
            if EFFECT[inst.ClassName] or inst.ClassName == "Atmosphere" then pcall(potatoInstance, inst) end
            n += 1
            if n % 1500 == 0 then task.wait() end
        end
    end
    sweep(Lighting)
    if workspace.CurrentCamera then sweep(workspace.CurrentCamera) end
    sweep(workspace)
end

task.spawn(function()
    local ok, err = pcall(applyPotato)
    if not ok then warn("[NimeroHub] potato: " .. tostring(err)) end
end)

-- ===== INTRO =====
local function playIntro()
    bubble.Visible = false
    main.Visible = false

    -- overlay transparan (tanpa latar hitam), hanya dipakai untuk fade
    local ov = Instance.new("CanvasGroup")
    ov.Name = "Intro"
    ov.Position = UDim2.new(0, 0, 0, -120)
    ov.Size = UDim2.new(1, 0, 1, 240)
    ov.BackgroundTransparency = 1
    ov.BorderSizePixel = 0
    ov.GroupTransparency = 1
    ov.ZIndex = 100
    ov.Parent = gui

    -- gradasi lebih terang khusus intro
    local BRIGHT = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(190, 255, 150)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(110, 255, 200)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(215, 255, 90)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(190, 255, 150)),
    })

    local name = label(ov, "NimeroHub", 36, Color3.new(1, 1, 1), Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    name.AnchorPoint = Vector2.new(0.5, 0.5)
    name.Position = UDim2.new(0.5, 0, 0.5, 0)
    name.Size = UDim2.new(0, 340, 0, 48)
    name.MaxVisibleGraphemes = 0
    local nameScale = Instance.new("UIScale", name)
    nameScale.Scale = 0.85
    local glow = Instance.new("UIStroke", name) -- cahaya tipis di sekeliling teks
    glow.Color = Color3.fromRGB(120, 255, 170)
    glow.Thickness = 2
    glow.Transparency = 0.55
    local ng = Instance.new("UIGradient", name)
    ng.Color = BRIGHT
    ng.Offset = Vector2.new(-0.5, 0)
    TweenService:Create(ng, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Offset = Vector2.new(0.5, 0) }):Play()

    local wm = label(ov, WATERMARK, 14, Color3.new(1, 1, 1), Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    wm.AnchorPoint = Vector2.new(0.5, 0.5)
    wm.Position = UDim2.new(0.5, 0, 0.5, 36)
    wm.Size = UDim2.new(0, 300, 0, 20)
    wm.TextTransparency = 1
    local wg = Instance.new("UIGradient", wm)
    wg.Color = BRIGHT
    TweenService:Create(wg, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
        { Rotation = 360 }):Play()

    tw(ov, 0.3, { GroupTransparency = 0 })
    tw(nameScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
    for i = 1, #name.Text do
        name.MaxVisibleGraphemes = i
        task.wait(0.07)
    end
    tw(wm, 0.4, { TextTransparency = 0 })
    task.wait(0.9)

    tw(nameScale, 0.45, { Scale = 1.2 })
    tw(ov, 0.45, { GroupTransparency = 1 })
    task.wait(0.5)
    ov:Destroy()
end

task.spawn(function()
    local ok, err = pcall(playIntro)
    if not ok then
        warn(err)
        local ov = gui:FindFirstChild("Intro")
        if ov then ov:Destroy() end
    end
    bubble.Visible = true
    setOpen(true)
end)
