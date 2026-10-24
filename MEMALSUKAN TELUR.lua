-- Hanya berjalan di game: [🎃] Fake an Egg
local ALLOWED = { 97289366402005 }
if not table.find(ALLOWED, game.PlaceId) then
    warn("[NIMEROHUB] Script ini bukan untuk game ini")
    return
end

--[[
    NIMEROHUB (versi ringan)
    - Bubble "NB" cair (memercik lalu menyatu) untuk buka/tutup menu (bisa digeser)
    - Tab ESP   : Fake Egg ESP
    - Tab Base  : Save Pos + Auto Balik Base (sudah termasuk Instant ProximityPrompt)
    - Tab Telur : daftar telur Rahasia / Ilahi / Eksotis / Mythic / Legendary (berwarna),
                  ketuk untuk teleport. Telur palsu / pemain menyamar disaring berlapis.
    - Tab Server: server hop (server 1/2/3 pemain) + cari server pemain
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local parent = (gethui and gethui()) or game:GetService("CoreGui")
if parent:FindFirstChild("NemeroHub") then parent.NemeroHub:Destroy() end
if parent:FindFirstChild("NemeroHub_Intro") then parent.NemeroHub_Intro:Destroy() end
local ESP_TAG = "NemeroHub_ESP"
for _, c in ipairs(parent:GetChildren()) do
    if c.Name == ESP_TAG then c:Destroy() end
end

----------------------------------------------------------------
-- Tema & helper (dibuat ringan: sedikit efek, tanpa loop animasi)
----------------------------------------------------------------
local C = {
    bg     = Color3.fromRGB(8, 10, 22),
    row    = Color3.fromRGB(16, 22, 42),
    rowHov = Color3.fromRGB(26, 38, 70),
    accent = Color3.fromRGB(0, 224, 255),
    pink   = Color3.fromRGB(255, 62, 200),
    text   = Color3.fromRGB(235, 245, 255),
    muted  = Color3.fromRGB(125, 150, 190),
    off    = Color3.fromRGB(38, 50, 84),
    good   = Color3.fromRGB(60, 255, 170),
    warn   = Color3.fromRGB(255, 200, 70),
    bad    = Color3.fromRGB(255, 70, 105),
}

-- Bendera: pekerjaan berat (indeks objek, percikan bubble) menunggu intro selesai
local introDone = false
task.delay(6, function() introDone = true end) -- jaga-jaga

local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
    return c
end

local function newLabel(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextColor3 = C.text
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k, v in pairs(props) do l[k] = v end
    return l
end

-- Drag langsung (tanpa tween) supaya ringan. Return: fungsi "baru di-drag?"
local function makeDraggable(handle, target)
    local dragging, startPos, startInput, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startInput = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end
    end)
    return function() return moved end
end

----------------------------------------------------------------
-- ScreenGui & Menu
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemeroHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = parent

----------------------------------------------------------------
-- Intro NIMEROHUB
----------------------------------------------------------------
task.spawn(function()
    local ig = Instance.new("ScreenGui")
    ig.Name = "NemeroHub_Intro"
    ig.IgnoreGuiInset = true
    ig.ResetOnSpawn = false
    ig.DisplayOrder = 999
    ig.Parent = parent

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(4, 5, 14)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.Active = true
    bg.Parent = ig
    tween(bg, 0.15, { BackgroundTransparency = 0 })

    local word = "NIMEROHUB"
    local letters = Instance.new("Frame")
    letters.AnchorPoint = Vector2.new(0.5, 0.5)
    letters.Position = UDim2.new(0.5, 0, 0.45, 0)
    letters.Size = UDim2.new(0, 360, 0, 56)
    letters.BackgroundTransparency = 1
    letters.Parent = bg
    local ll = Instance.new("UIListLayout")
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ll.VerticalAlignment = Enum.VerticalAlignment.Center
    ll.Padding = UDim.new(0, 2)
    ll.Parent = letters

    local labels = {}
    for i = 1, #word do
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(0, 36, 0, 56)
        lb.BackgroundTransparency = 1
        lb.Text = string.sub(word, i, i)
        lb.Font = Enum.Font.GothamBlack
        lb.TextSize = 46
        lb.TextColor3 = Color3.new(1, 1, 1)
        lb.TextTransparency = 1
        lb.Parent = letters
        local g = Instance.new("UIGradient")
        local col = C.accent:Lerp(C.pink, (i - 1) / (#word - 1))
        g.Color = ColorSequence.new(col, col)
        g.Parent = lb
        labels[i] = { lb = lb }
    end

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0)
    sub.Position = UDim2.new(0.5, 0, 0.45, 42)
    sub.Size = UDim2.new(0, 300, 0, 18)
    sub.BackgroundTransparency = 1
    sub.Text = "Memulai..."
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextColor3 = C.muted
    sub.TextTransparency = 1
    sub.Parent = bg

    local barBg = Instance.new("Frame")
    barBg.AnchorPoint = Vector2.new(0.5, 0)
    barBg.Position = UDim2.new(0.5, 0, 0.45, 70)
    barBg.Size = UDim2.new(0, 220, 0, 4)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 36, 66)
    barBg.BackgroundTransparency = 1
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    corner(barBg, 2)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.new(1, 1, 1)
    bar.BorderSizePixel = 0
    bar.Parent = barBg
    corner(bar, 2)
    local barGrad = Instance.new("UIGradient")
    barGrad.Color = ColorSequence.new(C.accent, C.pink)
    barGrad.Parent = bar

    task.wait(0.12)
    tween(barBg, 0.2, { BackgroundTransparency = 0 })
    tween(sub, 0.2, { TextTransparency = 0 })

    -- huruf muncul satu per satu (zoom dari besar + fade)
    for _, l in ipairs(labels) do
        tween(l.lb, 0.2, { TextTransparency = 0 })
        task.wait(0.04)
    end

    -- bar loading + status
    local steps = { "Memuat modul...", "Menyiapkan fitur...", "Siap!" }
    tween(bar, 0.7, { Size = UDim2.new(1, 0, 1, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    for _, txt in ipairs(steps) do
        sub.Text = txt
        task.wait(0.23)
    end

    -- keluar
    for _, l in ipairs(labels) do tween(l.lb, 0.2, { TextTransparency = 1 }) end
    tween(sub, 0.2, { TextTransparency = 1 })
    tween(barBg, 0.2, { BackgroundTransparency = 1 })
    tween(bar, 0.2, { BackgroundTransparency = 1 })
    task.wait(0.08)
    tween(bg, 0.22, { BackgroundTransparency = 1 })
    task.wait(0.25)
    ig:Destroy()
    introDone = true
end)


local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.45, 0)
main.Size = UDim2.new(0, 440, 0, 262)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
corner(main, 16)

local mainScale = Instance.new("UIScale")
mainScale.Scale = 0.9
mainScale.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.new(1, 1, 1)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.35
mainStroke.Parent = main
local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new(C.accent, C.pink)
mainGrad.Rotation = 35
mainGrad.Parent = mainStroke
mainStroke.Transparency = 0.15

-- Watermark TikTok (logo nada TikTok efek glitch cyan/pink + @username)
local function drawNote(parent, color, dx, dy)
    local g = Instance.new("Frame")
    g.BackgroundTransparency = 1
    g.Position = UDim2.fromOffset(dx, dy)
    g.Size = UDim2.fromOffset(16, 16)
    g.Parent = parent
    local function part(x, y, w, h, round, rot)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = color
        f.BorderSizePixel = 0
        f.Position = UDim2.fromOffset(x, y)
        f.Size = UDim2.fromOffset(w, h)
        f.Rotation = rot or 0
        f.Parent = g
        if round then corner(f, round) end
        return f
    end
    part(8, 1, 2.6, 10.5, 1)        -- tangkai
    part(3.6, 9, 6.6, 5.4, 4)       -- kepala nada
    part(10.2, 1.4, 5, 2.6, 2, 38)  -- bendera
end

local function makeWatermark(parent, anchor, position, textSize)
    local w = Instance.new("Frame")
    w.AnchorPoint = anchor
    w.Position = position
    w.Size = UDim2.fromOffset(112, 18)
    w.BackgroundTransparency = 1
    w.Parent = parent

    local logo = Instance.new("Frame")
    logo.BackgroundTransparency = 1
    logo.Position = UDim2.fromOffset(0, 1)
    logo.Size = UDim2.fromOffset(16, 16)
    logo.Parent = w
    drawNote(logo, Color3.fromRGB(37, 244, 238), -1, -1) -- cyan
    drawNote(logo, Color3.fromRGB(254, 44, 85), 1, 1)    -- pink
    drawNote(logo, Color3.new(1, 1, 1), 0, 0)            -- putih (depan)

    local t = newLabel({
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(20, 0),
        Text = "@aanantamng",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = textSize or 11,
    })
    t.Parent = w
    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new(Color3.fromRGB(37, 244, 238), Color3.new(1, 1, 1), Color3.fromRGB(254, 44, 85))
    tg.Parent = t
    return w
end

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundTransparency = 1
header.Parent = main

local title = newLabel({
    Size = UDim2.new(0, 140, 1, 0),
    Position = UDim2.new(0, 18, 0, 0),
    Text = "NIMEROHUB",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
})
title.Parent = header
title.Size = UDim2.new(0, 190, 1, 0)
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new(C.accent, C.pink)
titleGrad.Parent = title

local subtitle = newLabel({
    Size = UDim2.new(0, 150, 1, 0),
    Position = UDim2.new(0, 142, 0, 1),
    Text = "◆ Egg Toolkit  v2",
    TextColor3 = C.muted,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
})
subtitle.Parent = header
makeWatermark(header, Vector2.new(1, 0.5), UDim2.new(1, -48, 0.5, 0), 11)

local minBtn = Instance.new("TextButton")
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Position = UDim2.new(1, -14, 0.5, 0)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.BackgroundColor3 = C.row
minBtn.Text = "-"
minBtn.TextColor3 = C.text
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.AutoButtonColor = false
minBtn.Parent = header
corner(minBtn, 13)

local line = Instance.new("Frame")
line.Position = UDim2.new(0, 16, 0, 42)
line.Size = UDim2.new(1, -32, 0, 1)
line.BackgroundColor3 = Color3.new(1, 1, 1)
line.BackgroundTransparency = 0.35
line.BorderSizePixel = 0
line.Parent = main
local lineGrad = Instance.new("UIGradient")
lineGrad.Color = ColorSequence.new(C.accent, C.pink)
lineGrad.Parent = line

makeDraggable(header, main)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Position = UDim2.new(0, 14, 0, 54)
sidebar.Size = UDim2.new(0, 100, 1, -66)
sidebar.BackgroundTransparency = 1
sidebar.Parent = main

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(1, 0, 0, 36)
indicator.BackgroundColor3 = C.accent
indicator.BackgroundTransparency = 0.2
indicator.BorderSizePixel = 0
indicator.Parent = sidebar
corner(indicator, 10)

-- Area isi
local content = Instance.new("Frame")
content.Position = UDim2.new(0, 124, 0, 54)
content.Size = UDim2.new(1, -138, 1, -66)
content.BackgroundTransparency = 1
content.Parent = main

local pages, tabs, current = {}, {}, nil

local function makePage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = C.accent
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible = false
    sf.Parent = content

    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 7)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = sf
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 2)
    p.PaddingRight = UDim.new(0, 5)
    p.Parent = sf

    pages[name] = sf
    return sf
end

local function selectTab(name)
    if current == name then return end
    current = name
    for n, t in pairs(tabs) do
        t.btn.TextColor3 = (n == name) and Color3.new(1, 1, 1) or C.muted
        pages[n].Visible = (n == name)
    end
    tween(indicator, 0.3, { Position = UDim2.new(0, 0, 0, tabs[name].y) }, Enum.EasingStyle.Back)
    local pg = pages[name]
    pg.Position = UDim2.new(0, 0, 0, 12)
    tween(pg, 0.3, { Position = UDim2.new(0, 0, 0, 0) })
end

local function makeTab(name, index, label)
    local y = (index - 1) * 42
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(0, 0, 0, y)
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundTransparency = 1
    b.Text = label or name
    b.TextColor3 = C.muted
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 14
    b.AutoButtonColor = false
    b.ZIndex = 2
    b.Parent = sidebar
    tabs[name] = { btn = b, y = y }
    b.MouseButton1Click:Connect(function() selectTab(name) end)
end

----------------------------------------------------------------
-- Komponen baris
----------------------------------------------------------------
local function makeRow(scroll, titleText, descText, barColor)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, -4, 0, 50)
    row.BackgroundColor3 = C.row
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = scroll
    corner(row, 11)
    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = C.accent
    rowStroke.Thickness = 1
    rowStroke.Transparency = 0.86
    rowStroke.Parent = row

    local bar
    if barColor then
        bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 4, 1, -14)
        bar.Position = UDim2.new(0, 6, 0, 7)
        bar.BackgroundColor3 = barColor
        bar.BorderSizePixel = 0
        bar.Parent = row
        corner(bar, 2)
    end
    local pad = barColor and 20 or 14

    local t = newLabel({
        Size = UDim2.new(1, -pad - 56, 0, 18),
        Position = UDim2.new(0, pad, 0, 8),
        Text = titleText,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    t.Parent = row
    local d = newLabel({
        Size = UDim2.new(1, -pad - 56, 0, 14),
        Position = UDim2.new(0, pad, 0, 28),
        Text = descText or "",
        TextColor3 = C.muted,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    d.Parent = row

    -- efek tekan ringan
    row.MouseEnter:Connect(function()
        tween(rowStroke, 0.2, { Transparency = 0.45 })
    end)
    row.MouseButton1Down:Connect(function()
        row.BackgroundColor3 = C.rowHov
        rowStroke.Transparency = 0.1
    end)
    row.MouseButton1Up:Connect(function()
        tween(row, 0.25, { BackgroundColor3 = C.row })
        tween(rowStroke, 0.25, { Transparency = 0.45 })
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = C.row
        tween(rowStroke, 0.25, { Transparency = 0.86 })
    end)
    return row, t, d, bar
end

-- callback(on) boleh return false untuk menolak
local function addToggle(scroll, titleText, descText, callback, default)
    local row, t, d = makeRow(scroll, titleText, descText)

    local pill = Instance.new("Frame")
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, -12, 0.5, 0)
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.BackgroundColor3 = C.off
    pill.Parent = row
    corner(pill, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = pill
    corner(knob, 9)

    local on = default and true or false
    if on then
        pill.BackgroundColor3 = C.accent
        knob.Position = UDim2.new(1, -20, 0.5, -9)
    end
    row.MouseButton1Click:Connect(function()
        local want = not on
        if callback(want) == false then
            row.BackgroundColor3 = C.bad
            task.delay(0.25, function() tween(row, 0.3, { BackgroundColor3 = C.row }) end)
            return
        end
        on = want
        tween(pill, 0.2, { BackgroundColor3 = on and C.accent or C.off })
        tween(knob, 0.25, {
            Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        })
    end)
    return { row = row, title = t, desc = d }
end

local function addButton(scroll, titleText, descText, callback)
    local row, t, d = makeRow(scroll, titleText, descText)
    local arrow = newLabel({
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 20),
        Text = ">",
        TextColor3 = C.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
    })
    arrow.Parent = row
    row.MouseButton1Click:Connect(callback)
    return { row = row, title = t, desc = d }
end

local function addSection(scroll, text, order)
    local l = newLabel({
        Size = UDim2.new(1, -4, 0, 16),
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
    })
    l.LayoutOrder = order or 0
    l.Parent = scroll
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(C.accent, C.pink)
    g.Parent = l
    return l
end

local espPage = makePage("ESP")
local basePage = makePage("Base")
local eggPage = makePage("Telur")
local serverPage = makePage("Server")
makeTab("ESP", 1, "👁  ESP")
makeTab("Base", 2, "🏠  Base")
makeTab("Telur", 3, "🥚  Telur")
makeTab("Server", 4, "🌐  Server")

----------------------------------------------------------------
-- Bubble "NB" (cair: memercik lalu menyatu)
----------------------------------------------------------------
local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.new(0, 50, 0.62, 0)
holder.Size = UDim2.new(0, 50, 0, 50)
holder.BackgroundTransparency = 1
holder.Parent = gui

local bubble = Instance.new("TextButton")
bubble.AnchorPoint = Vector2.new(0.5, 0.5)
bubble.Position = UDim2.new(0.5, 0, 0.5, 0)
bubble.Size = UDim2.new(1, 0, 1, 0)
bubble.BackgroundColor3 = Color3.new(1, 1, 1)
bubble.Text = "NB"
bubble.TextColor3 = Color3.fromRGB(8, 10, 22)
bubble.Font = Enum.Font.GothamBlack
bubble.TextSize = 18
bubble.AutoButtonColor = false
bubble.ZIndex = 3
bubble.Parent = holder
corner(bubble, 100)

local bStroke = Instance.new("UIStroke")
bStroke.Color = Color3.new(1, 1, 1)
bStroke.Thickness = 2
bStroke.Transparency = 0.5
bStroke.Parent = bubble
local bGrad = Instance.new("UIGradient")
bGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.accent),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 110, 255)),
    ColorSequenceKeypoint.new(1, C.pink),
})
bGrad.Rotation = 45
bGrad.Parent = bubble
-- gradasi berputar pelan (1 tween, ringan)
TweenService:Create(bGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    { Rotation = 405 }):Play()
-- cincin luar berdenyut
TweenService:Create(bStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Transparency = 0.85 }):Play()

local bScale = Instance.new("UIScale")
bScale.Scale = 0
bScale.Parent = bubble
tween(bScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)

local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(1, 0)
dot.Position = UDim2.new(1, -1, 0, 1)
dot.Size = UDim2.new(0, 12, 0, 12)
dot.BackgroundColor3 = C.bad
dot.BorderSizePixel = 0
dot.ZIndex = 5
dot.Parent = bubble
corner(dot, 6)

local wasDragged = makeDraggable(bubble, holder)

-- Efek cairan: tetesan memercik keluar dari bubble, lalu tersedot balik & menyatu
local function makeDrop(sz)
    local d = Instance.new("Frame")
    d.AnchorPoint = Vector2.new(0.5, 0.5)
    d.Position = UDim2.new(0.5, 0, 0.5, 0)
    d.Size = UDim2.new(0, sz, 0, sz)
    d.BackgroundColor3 = Color3.new(1, 1, 1)
    d.BorderSizePixel = 0
    d.ZIndex = 1 -- di belakang bubble -> terlihat "masuk" saat menyatu
    d.Parent = holder
    corner(d, 100)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(C.accent, C.pink)
    g.Rotation = math.random(0, 360)
    g.Parent = d
    return d
end

local function ripple()
    local r = Instance.new("Frame")
    r.AnchorPoint = Vector2.new(0.5, 0.5)
    r.Position = UDim2.new(0.5, 0, 0.5, 0)
    r.Size = UDim2.new(1, 0, 1, 0)
    r.BackgroundTransparency = 1
    r.ZIndex = 2
    r.Parent = holder
    corner(r, 100)
    local st = Instance.new("UIStroke")
    st.Color = C.accent
    st.Thickness = 3
    st.Transparency = 0.15
    st.Parent = r
    tween(r, 0.6, { Size = UDim2.new(2.1, 0, 2.1, 0) })
    tween(st, 0.6, { Transparency = 1, Thickness = 0.5 })
    task.delay(0.65, function() r:Destroy() end)
end

local splashActive = 0
local function splash(count, power, force)
    if splashActive > 0 and not force then return end
    splashActive += 1
    count, power = count or 5, power or 1

    local drops = {}
    local base = math.random() * math.pi * 2
    for i = 1, count do
        local ang = base + (i / count) * math.pi * 2 + (math.random() - 0.5) * 0.8
        local dist = (30 + math.random() * 18) * power
        local sz = math.random(7, 14)
        local d = makeDrop(sz)
        tween(d, 0.3 + math.random() * 0.12, {
            Position = UDim2.new(0.5, math.cos(ang) * dist, 0.5, math.sin(ang) * dist),
        }, Enum.EasingStyle.Quint)
        drops[i] = d
    end
    -- bubble melar sedikit saat memercik
    tween(bStroke, 0.15, { Thickness = 4 })

    task.delay(0.55, function()
        for i, d in ipairs(drops) do
            task.delay((i - 1) * 0.045, function()
                tween(d, 0.26, {
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 3, 0, 3),
                }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            end)
        end
        task.wait(0.28 + (#drops - 1) * 0.045)
        for _, d in ipairs(drops) do d:Destroy() end
        -- menyatu: bubble "plop" elastis + riak
        bScale.Scale = 0.88
        tween(bScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Elastic)
        tween(bStroke, 0.4, { Thickness = 2 })
        ripple()
        splashActive -= 1
    end)
end

-- percikan otomatis setiap beberapa detik
task.spawn(function()
    while not introDone do task.wait(0.2) end
    task.wait(0.6)
    while gui.Parent do
        splash(math.random(3, 5), 0.9)
        task.wait(2.4 + math.random() * 1.8)
    end
end)

----------------------------------------------------------------
-- Buka / tutup
----------------------------------------------------------------
local isOpen = false
local function setOpen(open)
    isOpen = open
    if open then
        main.Visible = true
        mainScale.Scale = 0.9
        tween(mainScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
        tween(dot, 0.2, { BackgroundColor3 = C.good })
    else
        local t = tween(mainScale, 0.15, { Scale = 0.92 })
        tween(dot, 0.2, { BackgroundColor3 = C.bad })
        t.Completed:Connect(function()
            if not isOpen then main.Visible = false end
        end)
    end
end

bubble.MouseButton1Click:Connect(function()
    if wasDragged() then return end
    tween(bScale, 0.07, { Scale = 0.86 })
    task.delay(0.07, function() tween(bScale, 0.2, { Scale = 1.08 }, Enum.EasingStyle.Back) end)
    splash(9, 1.2, true)
    setOpen(not isOpen)
end)
minBtn.MouseButton1Click:Connect(function() setOpen(false) end)

selectTab("ESP")

task.wait()

----------------------------------------------------------------
-- Fitur: Fake Egg ESP (pemain yang menyamar jadi telur)
----------------------------------------------------------------
local EGG_WORDS = { "egg", "telur" }
local FLAG_WORDS = { "fake", "disguise", "disguis", "hidden", "palsu", "menyamar", "morph", "transform", "egg", "telur" }

local BODY = {}
for _, n in ipairs({
    "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
}) do BODY[n] = true end

local espEnabled = false
local tracked = {} -- [player] = { bb, label, char }

local function hasWord(str, words)
    str = string.lower(tostring(str))
    for _, w in ipairs(words) do
        if string.find(str, w, 1, true) then return true end
    end
    return false
end

local function detectDisguise(plr)
    local char = plr.Character
    if not char then return false end

    for _, h in ipairs({ plr, char }) do
        for k, v in pairs(h:GetAttributes()) do
            if hasWord(k, FLAG_WORDS) and v and v ~= 0 and v ~= "" and v ~= false then
                return true, "atribut " .. k
            end
            if type(v) == "string" and hasWord(v, EGG_WORDS) then
                return true, "atribut " .. k .. "=" .. v
            end
        end
    end

    local bodyHidden, bodyCount, extraVisible = true, 0, false
    for _, d in ipairs(char:GetDescendants()) do
        if (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Accessory") or d:IsA("SpecialMesh"))
            and hasWord(d.Name, EGG_WORDS) then
            return true, "objek " .. d.Name
        end
        if d:IsA("BoolValue") and d.Value and hasWord(d.Name, FLAG_WORDS) then
            return true, "value " .. d.Name
        end
        if d:IsA("BasePart") then
            if BODY[d.Name] and d.Name ~= "HumanoidRootPart" then
                bodyCount += 1
                if d.Transparency < 0.95 then bodyHidden = false end
            elseif not BODY[d.Name] and d.Name ~= "Handle"
                and not d:FindFirstAncestorOfClass("Accessory") and d.Transparency < 0.5 then
                extraVisible = true
            end
        end
    end

    if bodyCount >= 3 and bodyHidden and extraVisible then
        return true, "badan tersembunyi + part lain"
    end
    return false
end

local function release(plr)
    local e = tracked[plr]
    if e then
        e.bb:Destroy()
        tracked[plr] = nil
    end
end

local function attach(plr, text)
    local char = plr.Character
    if not char then return end

    local e = tracked[plr]
    if e and e.char ~= char then
        release(plr)
        e = nil
    end
    if e then
        e.label.Text = text
        return
    end

    local part = char:FindFirstChild("HumanoidRootPart")
        or char.PrimaryPart
        or char:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = ESP_TAG
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 150, 0, 16)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 50, 50)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.Parent = bb

    tracked[plr] = { bb = bb, label = lbl, char = char }
end

local function clearAll()
    for plr in pairs(tracked) do release(plr) end
end

Players.PlayerRemoving:Connect(release)

task.spawn(function()
    while gui.Parent do
        if espEnabled then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    if detectDisguise(plr) then
                        attach(plr, "⚠ PALSU • " .. plr.Name)
                    else
                        release(plr)
                    end
                end
            end
        end
        task.wait(1)
    end
    clearAll()
end)

addSection(espPage, "◆ PENDETEKSI", -1)
addToggle(espPage, "Radar Telur Palsu", "Tandai pemain yang menyamar jadi telur", function(on)
    espEnabled = on
    if not on then clearAll() end
end)

task.wait()

----------------------------------------------------------------
-- Fitur: Auto Balik Base (Save Pos dulu, baru bisa teleport)
-- Sudah termasuk Instant ProximityPrompt
----------------------------------------------------------------
local autoBase = false
local autoSuspendUntil = 0
local savedCF = nil
local lastReturn = 0
local autoToggle, saveBtn
local IDLE_TEXT = "Teleport saat bawa telur • Instant PP aktif"

local function setStatus(text, color)
    if autoToggle then
        autoToggle.desc.Text = text
        autoToggle.desc.TextColor3 = color or C.muted
    end
end

local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function returnToBase(reason)
    if not savedCF then return end
    if os.clock() - lastReturn < 1.5 then return end
    lastReturn = os.clock()
    print("[NB] teleport ke base | alasan:", reason)
    task.wait(0.1)
    local root = getRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = savedCF + Vector3.new(0, 3, 0)
    end
end

-- Instant ProximityPrompt
local ppOriginal = setmetatable({}, { __mode = "k" })
local ppConn

local function makeInstant(inst)
    if inst:IsA("ProximityPrompt") then
        if ppOriginal[inst] == nil then ppOriginal[inst] = inst.HoldDuration end
        inst.HoldDuration = 0
    end
end

local function enableInstant()
    if ppConn then return end
    ppConn = workspace.DescendantAdded:Connect(makeInstant)
    task.spawn(function()
        for i, d in ipairs(workspace:GetDescendants()) do
            makeInstant(d)
            if i % 3000 == 0 then task.wait() end
        end
    end)
end

local function disableInstant()
    if ppConn then
        ppConn:Disconnect()
        ppConn = nil
    end
    for pp, v in pairs(ppOriginal) do
        if pp.Parent then pp.HoldDuration = v end
    end
    table.clear(ppOriginal)
end

----------------------------------------------------------------
-- Indeks objek (ringan): daftar TextLabel / Model dijaga lewat event,
-- jadi scan tidak perlu GetDescendants() seluruh workspace lagi
----------------------------------------------------------------
local function newSet() return setmetatable({}, { __mode = "k" }) end
local wsLabels, wsModels, pgText = newSet(), newSet(), newSet()

local function trackRoot(root, onAdd, onRemove)
    if not root then return end
    root.DescendantAdded:Connect(function(d) onAdd(d, false) end)
    root.DescendantRemoving:Connect(onRemove)
    task.spawn(function()
        while not introDone do task.wait(0.1) end
        local n = 0
        for _, d in ipairs(root:GetDescendants()) do
            onAdd(d, true)
            n += 1
            if n % 2500 == 0 then task.wait() end
        end
    end)
end

local function modelHasRarity(d)
    return type(d:GetAttribute("Rarity") or d:GetAttribute("rarity")) == "string"
end

trackRoot(workspace, function(d, initial)
    local cn = d.ClassName
    if cn == "TextLabel" then
        wsLabels[d] = true
    elseif cn == "Model" then
        if modelHasRarity(d) then
            wsModels[d] = true
        elseif not initial then
            task.defer(function()
                if d.Parent and modelHasRarity(d) then wsModels[d] = true end
            end)
        end
    end
end, function(d)
    wsLabels[d] = nil
    wsModels[d] = nil
end)

local pgRoot = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 5)
trackRoot(pgRoot, function(d)
    local cn = d.ClassName
    if cn == "TextLabel" or cn == "TextButton" then pgText[d] = true end
end, function(d)
    pgText[d] = nil
end)

-- Deteksi membawa telur: tombol "Jatuhkan"/"Drop" terlihat, atau objek telur di karakter
local function guiShown(o, root)
    local g = o
    while g and g ~= root do
        if g:IsA("GuiObject") and not g.Visible then return false end
        if g:IsA("ScreenGui") and not g.Enabled then return false end
        g = g.Parent
    end
    return true
end

local function isDropText(txt)
    txt = string.lower(txt or "")
    return string.find(txt, "jatuhkan", 1, true) ~= nil
        or string.match(txt, "^%s*drop%s*$") ~= nil
end

local function carryingEgg()
    local char = LP.Character
    if char then
        for _, c in ipairs(char:GetChildren()) do
            if (c:IsA("Model") or c:IsA("BasePart")) and hasWord(c.Name, EGG_WORDS) then
                return true, "objek di karakter: " .. c.Name
            end
        end
    end
    if pgRoot then
        for o in pairs(pgText) do
            if o.Parent and isDropText(o.Text) and o.AbsoluteSize.X > 0 and guiShown(o, pgRoot) then
                return true, "tombol: " .. o.Text
            end
        end
    end
    return false
end

task.spawn(function()
    local lastState
    while gui.Parent do
        if autoBase and savedCF and os.clock() >= autoSuspendUntil then
            local root = getRoot()
            if root then
                local far = (root.Position - savedCF.Position).Magnitude > 25
                local state
                if not far then
                    state = "di base"
                else
                    local carrying, why = carryingEgg()
                    if carrying then
                        state = "membawa telur"
                        returnToBase(why)
                    else
                        state = "menunggu telur"
                    end
                end
                if state ~= lastState then
                    lastState = state
                    setStatus("Status: " .. state,
                        state == "membawa telur" and C.warn or C.good)
                end
            end
        else
            lastState = nil
        end
        task.wait(1)
    end
end)

addSection(basePage, "◆ POSISI & AUTO BASE", -1)
saveBtn = addButton(basePage, "Simpan Posisi Base", "Berdiri di base, lalu ketuk", function()
    local root = getRoot()
    if root then
        savedCF = root.CFrame
        local p = savedCF.Position
        saveBtn.title.Text = "Posisi Tersimpan ✓"
        saveBtn.desc.Text = ("Posisi: %d, %d, %d"):format(
            math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
        saveBtn.desc.TextColor3 = C.good
    end
end)

autoToggle = addToggle(basePage, "Auto Balik Base", IDLE_TEXT, function(on)
    if on then
        if not savedCF then
            saveBtn.desc.Text = "Simpan posisi base dulu!"
            saveBtn.desc.TextColor3 = C.bad
            task.delay(1.8, function()
                if not savedCF then
                    saveBtn.desc.Text = "Berdiri di base, lalu ketuk"
                    saveBtn.desc.TextColor3 = C.muted
                end
            end)
            return false
        end
        autoBase = true
        enableInstant()
        setStatus("Status: aktif", C.good)
    else
        autoBase = false
        disableInstant()
        setStatus(IDLE_TEXT, C.muted)
    end
end)

task.wait()

----------------------------------------------------------------
-- Fitur: Daftar Telur (hanya Rahasia / Ilahi / Eksotis / Mythic)
-- Telur pemain yang menyamar TIDAK dimasukkan
----------------------------------------------------------------
local RARITY = {
    { name = "Hacker",    keys = { "hacker" },                                           color = Color3.fromRGB(60, 255, 90),  rank = 7 },
    { name = "Admin",     keys = { "admin" },                                            color = Color3.fromRGB(255, 60, 60),  rank = 6 },
    { name = "Rahasia",   keys = { "rahasia", "secret" },                                color = Color3.fromRGB(90, 225, 255), rank = 5 },
    { name = "Ilahi",     keys = { "ilahi", "divine" },                                  color = Color3.fromRGB(255, 215, 90), rank = 4 },
    { name = "Eksotis",   keys = { "eksotis", "exotic" },                                color = Color3.fromRGB(255, 85, 225), rank = 3 },
    { name = "Mythic",    keys = { "mythic", "mythical", "mitik", "mitos", "mistik", "mistis" }, color = Color3.fromRGB(255, 140, 50), rank = 2 },
    { name = "Legendary", keys = { "legendary", "legendaris" },                          color = Color3.fromRGB(255, 70, 80),  rank = 1 },
}

local function findRarity(text)
    local t = string.lower(text)
    for _, r in ipairs(RARITY) do
        for _, k in ipairs(r.keys) do
            if string.find(t, k, 1, true) then return r end
        end
    end
end

local eggRows = {} -- [instance] = { row, title, desc, bar }
local allEggResults = {} -- hasil scan penuh (tanpa filter rarity tertinggi, fake sudah dikecualikan)
local failedUntil = {}   -- [instance] = waktu sampai telur gagal diambil dilewati Auto Ambil
local eggRefreshing = false
local emptyLabel = newLabel({
    Size = UDim2.new(1, -4, 0, 18),
    Text = "🔎 Mencari telur langka…",
    TextColor3 = C.muted,
    TextSize = 11,
})
emptyLabel.LayoutOrder = -999
emptyLabel.Parent = eggPage

local actLabel = newLabel({
    Size = UDim2.new(1, -4, 0, 16),
    Text = "✦ Ketuk telur untuk teleport • ambil • pulang",
    TextColor3 = C.muted,
    TextSize = 11,
})
actLabel.LayoutOrder = -499
actLabel.Parent = eggPage

local optBase, optBack = true, true
local grabBusy = false

local function setAct(text, color)
    actLabel.Text = text
    actLabel.TextColor3 = color or C.muted
end

local tBase = addToggle(eggPage, "Antar ke Base", "Setelah ambil, teleport ke posisi base tersimpan", function(on)
    optBase = on
end, true)
tBase.row.LayoutOrder = -497
local tBack = addToggle(eggPage, "Kembali ke Posisi Awal", "Pulang ke tempat semula setelah selesai", function(on)
    optBack = on
end, true)
tBack.row.LayoutOrder = -496

-- Mode auto selalu butuh koordinat base: kalau belum disimpan, posisi sekarang dipakai
local function ensureBase()
    if savedCF then return end
    local root = getRoot()
    if not root then return end
    savedCF = root.CFrame
    local p = savedCF.Position
    if saveBtn then
        saveBtn.title.Text = "Posisi Tersimpan ✓"
        saveBtn.desc.Text = ("Posisi: %d, %d, %d"):format(math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
        saveBtn.desc.TextColor3 = C.good
    end
    setAct("📍 Posisi sekarang disimpan sebagai base", C.good)
end

local autoBest = false
local autoRebirth = false
local tAuto = addToggle(eggPage, "Auto Ambil Terbaik", "Eksotis ke atas • palsu diabaikan • otomatis ke base", function(on)
    autoBest = on
    if on then ensureBase() end
end)
tAuto.row.LayoutOrder = -498

local function eggPosition(inst)
    if inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        return ok and cf.Position or nil
    elseif inst:IsA("BasePart") then
        return inst.Position
    end
end

local function isPlayerPart(inst)
    for _, plr in ipairs(Players:GetPlayers()) do
        local ch = plr.Character
        if ch and (inst == ch or inst:IsDescendantOf(ch) or ch:IsDescendantOf(inst)) then
            return true
        end
    end
    return false
end

local function humanoidAncestor(inst)
    local p, g = inst, 0
    while p and p ~= workspace and g < 8 do
        if p:FindFirstChildOfClass("Humanoid") then return true end
        p = p.Parent
        g += 1
    end
    return false
end

local function nearAnyPlayer(pos, radius)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            for _, bp in ipairs(plr.Character:GetChildren()) do
                if bp:IsA("BasePart") and (bp.Position - pos).Magnitude < radius then
                    return plr
                end
            end
        end
    end
end

-- Pemeriksaan telur palsu / pemain menyamar. Return: true, alasan
-- structuralOnly = true: cek struktur saja (dipakai saat sedang mengambil, agar
-- pemain asli yang ikut berebut telur tidak membatalkan pengambilan)
local function isFakeEgg(egg, structuralOnly)
    if not egg or not egg.Parent or not egg:IsDescendantOf(workspace) then
        return true, "telur hilang"
    end
    if isPlayerPart(egg) then return true, "bagian dari pemain" end
    if humanoidAncestor(egg) then return true, "punya Humanoid" end
    if hasWord(egg.Name, { "fake", "palsu" }) then return true, "bernama fake" end
    for k, v in pairs(egg:GetAttributes()) do
        if hasWord(k, { "fake", "palsu", "disguis", "menyamar" })
            and v and v ~= 0 and v ~= "" and v ~= false then
            return true, "atribut " .. k
        end
    end
    if structuralOnly then return false end

    local pos = eggPosition(egg)
    if pos then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local r = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (r.Position - pos).Magnitude
                    if d < 6 then return true, "menempel di " .. plr.Name end
                    if d < 16 and detectDisguise(plr) then
                        return true, "dekat pemain menyamar " .. plr.Name
                    end
                end
            end
        end
        local part = egg:IsA("BasePart") and egg
            or (egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true))
        if part and not part.Anchored and part.AssemblyLinearVelocity.Magnitude > 6
            and nearAnyPlayer(pos, 22) then
            return true, "bergerak dekat pemain"
        end
    end
    return false
end

local function eggInfo(bb, egg)
    local name, price, fallback
    if bb then
        for _, d in ipairs(bb:GetDescendants()) do
            if d.ClassName == "TextLabel" and d.Text ~= "" then
                local tx = d.Text
                if not price and string.match(tx, "^%s*%$") then
                    price = tx
                elseif not name and hasWord(tx, EGG_WORDS) then
                    name = tx
                elseif not fallback and not findRarity(tx)
                    and not string.match(tx, "^%s*[%d%.:]+%s*[smhd]?%s*$") and #tx > 2 then
                    fallback = tx
                end
            end
        end
    end
    if not price and egg then
        for _, d in ipairs(egg:GetDescendants()) do
            if d.ClassName == "TextLabel" and string.match(d.Text, "^%s*%$") then
                price = d.Text
                break
            end
        end
    end
    local isEggName = (name ~= nil) or hasWord(egg.Name, EGG_WORDS)
        or (egg.Parent ~= nil and hasWord(egg.Parent.Name, EGG_WORDS))
    return name or fallback or egg.Name, price, isEggName
end

-- Objek terlalu besar (papan/bangunan) bukan telur
local function isHuge(inst)
    if inst:IsA("BasePart") then
        return inst.Size.Magnitude > 35
    elseif inst:IsA("Model") then
        local ok, size = pcall(function() return inst:GetExtentsSize() end)
        return ok and size.Magnitude > 35
    end
    return false
end

-- Telur yang sedang ditetaskan di kandang: ada timer "m:ss"/"menetas", atau berada di dalam kandang/plot pemain
local function isPenEgg(egg, bb)
    if bb then
        for _, d in ipairs(bb:GetDescendants()) do
            if d.ClassName == "TextLabel" then
                local t = string.lower(d.Text)
                if string.find(t, "menetas", 1, true) or string.find(t, "hatch", 1, true)
                    or string.match(t, "%d+:%d+") then
                    return true
                end
            end
        end
    end
    -- atribut pada telur itu sendiri: tanda sedang ditetaskan / milik pemain / hewan
    for k, v in pairs(egg:GetAttributes()) do
        if hasWord(k, { "owner", "player", "user", "hatch", "incubat", "tetas", "pet", "animal", "hewan" })
            and v and v ~= "" and v ~= 0 and v ~= false then
            return true
        end
    end
    local p, g = egg.Parent, 0
    while p and p ~= workspace and g < 10 do
        local n = string.lower(p.Name)
        if string.find(n, "base", 1, true) or string.find(n, "home", 1, true)
            or string.find(n, "rumah", 1, true) or string.find(n, "hewan", 1, true)
            or string.find(n, "animal", 1, true) or string.find(n, "pets", 1, true) then
            return true
        end
        if string.match(n, "^pens?[%d%s_%-]*$") or string.find(n, "pena", 1, true)
            or string.find(n, "kandang", 1, true) or string.find(n, "plot", 1, true)
            or string.find(n, "hatch", 1, true) or string.find(n, "incubat", 1, true) then
            return true
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if n == plr.Name:lower() or n == plr.DisplayName:lower() then return true end
        end
        for k, v in pairs(p:GetAttributes()) do
            if hasWord(k, { "owner", "player", "user" }) and v and v ~= "" and v ~= 0 then
                return true
            end
        end
        p = p.Parent
        g += 1
    end
    return false
end

local memoText, memoRar = newSet(), newSet()
local function labelRarity(l)
    local tx = l.Text
    if tx == "" then return nil end
    if memoText[l] == tx then return memoRar[l] or nil end
    local r = findRarity(tx)
    memoText[l] = tx
    memoRar[l] = r or false
    return r
end

local rejectUntil = newSet() -- telur yang jelas bukan target (papan/kandang/dll) tidak dicek ulang tiap scan

local function scanEggs()
    local st = { lw = 0, lp = 0, nobb = 0, noegg = 0, sign = 0, huge = 0, nopos = 0, fake = 0, ok = 0, noprice = 0, notegg = 0, pen = 0 }

    local myRoot = getRoot()
    local results, seen, excluded = {}, {}, 0
    local signCache = {}

    -- Model dengan Humanoid (karakter/NPC) bukan telur asli
    local function hasHumanoidAncestor(inst)
        local p = inst
        local g = 0
        while p and p ~= workspace and g < 8 do
            if p:FindFirstChildOfClass("Humanoid") then return true end
            p = p.Parent
            g += 1
        end
        return false
    end

    -- Papan jadwal restock punya teks "Dalam 00:17" -> bukan telur
    local function isSign(bb)
        if signCache[bb] ~= nil then return signCache[bb] end
        local res = false
        for _, d in ipairs(bb:GetDescendants()) do
            if d.ClassName == "TextLabel"
                and string.match(string.lower(d.Text), "dalam%s*%d+:%d+") then
                res = true
                break
            end
        end
        signCache[bb] = res
        return res
    end

    local function consider(egg, bb, rar)
        -- naik sampai ketemu Model/BasePart (Adornee bisa Attachment / Folder)
        local guard = 0
        while egg and egg ~= workspace and not (egg:IsA("Model") or egg:IsA("BasePart")) and guard < 6 do
            egg = egg.Parent
            guard += 1
        end
        if not egg or egg == workspace or not (egg:IsA("Model") or egg:IsA("BasePart")) then
            st.noegg += 1
            return
        end
        if seen[egg] then return end
        seen[egg] = true
        local now = os.clock()
        if (rejectUntil[egg] or 0) > now then return end

        if bb and isSign(bb) then st.sign += 1 rejectUntil[egg] = now + 3 return end

        local pos = eggPosition(egg)
        if not pos then st.nopos += 1 return end
        if isHuge(egg) then st.huge += 1 rejectUntil[egg] = now + 3 return end

        -- Harus telur (nama mengandung "telur"/"egg"); hewan di kandang dibuang
        local name, price, isEggName = eggInfo(bb, egg)
        if not isEggName then st.notegg += 1 rejectUntil[egg] = now + 3 return end
        -- Telur asli punya harga ($). Papan spawn/jadwal tidak punya -> dibuang
        if bb and not price then st.noprice += 1 rejectUntil[egg] = now + 2 return end
        if isPenEgg(egg, bb) then st.pen += 1 rejectUntil[egg] = now + 3 return end

        local isFake = isFakeEgg(egg)
        if isFake then
            excluded += 1
            st.fake += 1
            return
        end

        st.ok += 1
        table.insert(results, {
            inst = egg, name = name, price = price, rar = rar,
            dist = myRoot and (myRoot.Position - pos).Magnitude or 0,
        })
    end

    local function handle(label, rar, key)
        st[key] += 1
        local bb = label:FindFirstAncestorWhichIsA("BillboardGui") or label:FindFirstAncestorWhichIsA("SurfaceGui")
        if not bb then st.nobb += 1 return end
        local egg = bb:IsA("BillboardGui") and bb.Adornee or bb.Parent
        consider(egg, bb, rar)
    end

    for d in pairs(wsLabels) do
        if d.Parent then
            local rar = labelRarity(d)
            if rar then handle(d, rar, "lw") end
        end
    end
    for d in pairs(wsModels) do
        if d.Parent then
            local ra = d:GetAttribute("Rarity") or d:GetAttribute("rarity")
            if type(ra) == "string" then
                local rar = findRarity(ra)
                if rar then consider(d, nil, rar) end
            end
        end
    end
    for d in pairs(pgText) do
        if d.ClassName == "TextLabel" and d.Parent then
            local rar = labelRarity(d)
            if rar then handle(d, rar, "lp") end
        end
    end

    allEggResults = {}
    for i, r in ipairs(results) do allEggResults[i] = r end

    -- hanya tampilkan rarity tertinggi yang sedang ada
    local topRank = 0
    for _, r in ipairs(results) do
        if r.rar.rank > topRank then topRank = r.rar.rank end
    end
    for i = #results, 1, -1 do
        if results[i].rar.rank < topRank then table.remove(results, i) end
    end

    table.sort(results, function(a, b)
        if a.rar.rank ~= b.rar.rank then return a.rar.rank > b.rar.rank end
        return a.dist < b.dist
    end)
    while #results > 25 do table.remove(results) end
    return results, excluded, st
end

local function teleportToEgg(inst)
    if isFakeEgg(inst) then return end
    local pos = inst.Parent and eggPosition(inst)
    local root = getRoot()
    if pos and root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    end
end

local function teleportCF(cf)
    local root = getRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = cf
    end
end

-- Cari ProximityPrompt terdekat dari telur (di telur, di induknya, atau di sekitarnya)
local function nearestPrompt(egg, pos)
    for _, d in ipairs(egg:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then return d end
    end
    local best, bd
    local function check(pp, part)
        if pp:IsA("ProximityPrompt") and pp.Enabled and part then
            local dist = (part.Position - pos).Magnitude
            if not bd or dist < bd then best, bd = pp, dist end
        end
    end
    -- induk telur (mis. model dudukan yang memegang prompt)
    local par = egg.Parent
    if par and par ~= workspace and (par:IsA("Model") or par:IsA("Folder")) then
        local cnt = 0
        for _, d in ipairs(par:GetDescendants()) do
            cnt += 1
            if cnt > 300 then break end
            if d:IsA("ProximityPrompt") and d.Enabled then
                local part = d:FindFirstAncestorWhichIsA("BasePart")
                if part and (part.Position - pos).Magnitude <= 25 then check(d, part) end
            end
        end
    end
    if best then return best end
    local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(pos, 25) end)
    if not ok then return nil end
    for _, part in ipairs(parts) do
        for _, c in ipairs(part:GetChildren()) do
            check(c, part)
            if c:IsA("Attachment") then
                for _, cc in ipairs(c:GetChildren()) do check(cc, part) end
            end
        end
    end
    return best
end

local function pressPrompt(pp)
    pcall(function()
        pp.HoldDuration = 0
        pp.RequiresLineOfSight = false
        if pp.MaxActivationDistance < 40 then pp.MaxActivationDistance = 40 end
    end)
    if fireproximityprompt then
        pcall(fireproximityprompt, pp)
    else
        pcall(function()
            pp:InputHoldBegin()
            task.wait(0.05)
            pp:InputHoldEnd()
        end)
    end
end

local onGrabbed -- diisi oleh fitur Auto Rebirth

-- Teleport ke telur -> ambil otomatis -> balik ke base -> (opsional) kembali ke tempat awal
local function grabAndReturn(egg, name, auto)
    if grabBusy then return end
    local root = getRoot()
    if not root then return end
    local pos = egg.Parent and eggPosition(egg)
    if not pos then
        setAct("Telur sudah hilang, muat ulang daftar", C.bad)
        return
    end

    -- Lapis 1: tolak telur palsu / pemain menyamar SEBELUM teleport
    local fk, why = isFakeEgg(egg)
    if fk then
        failedUntil[egg] = os.clock() + 60
        local r = eggRows[egg]
        if r then r.row:Destroy() eggRows[egg] = nil end
        setAct("🚫 Dibatalkan: telur palsu (" .. why .. ")", C.bad)
        return
    end

    grabBusy = true
    autoSuspendUntil = os.clock() + 30 -- tahan Auto Balik Base selama urutan berjalan
    task.spawn(function()
        local origin = root.CFrame
        setAct("Teleport ke " .. tostring(name) .. "...", C.warn)
        teleportCF(CFrame.new(pos + Vector3.new(0, 3, 0)))
        task.wait()

        -- tekan prompt tiap frame sampai telur terbawa (maks 5 detik)
        local got, sawPrompt, vanished, fakeAbort = false, false, false, nil
        local t0 = os.clock()
        local pp, lastCarry = nil, 0
        while os.clock() - t0 < 5 do
            local alive = egg.Parent ~= nil and egg:IsDescendantOf(workspace)
            local p2 = alive and eggPosition(egg) or nil
            -- Lapis 2: kalau ternyata telur menempel di pemain / punya Humanoid, hentikan
            if alive then
                local f2, w2 = isFakeEgg(egg, true)
                if f2 then fakeAbort = w2 break end
            end
            local ch = LP.Character
            if ch and egg:IsDescendantOf(ch) then got = true break end
            if not alive or not p2 then
                -- telur lenyap: bisa karena terbawa kita atau diambil orang lain
                task.wait(0.15)
                if carryingEgg() then got = true else vanished = true end
                break
            end
            -- ikuti telur bila bergerak / kita terdorong menjauh
            local r = getRoot()
            if r and (r.Position - p2).Magnitude > 10 then
                teleportCF(CFrame.new(p2 + Vector3.new(0, 3, 0)))
            end
            if not pp or not pp.Parent or not pp.Enabled then
                pp = nearestPrompt(egg, p2)
            end
            if pp then
                sawPrompt = true
                pressPrompt(pp)
            end
            task.wait()
            if os.clock() - lastCarry > 0.12 then
                lastCarry = os.clock()
                if carryingEgg() then got = true break end
            end
        end

        if got then
            setAct("Telur terambil!", C.good)
            if onGrabbed then pcall(onGrabbed, egg, name) end
            local taken = eggRows[egg]
            if taken then
                taken.row:Destroy()
                eggRows[egg] = nil
            end
            -- mode auto (Terbaik / Rebirth): selalu ke koordinat base dan menetap di sana
            if optBase or auto then
                if savedCF then
                    teleportCF(savedCF + Vector3.new(0, 3, 0))
                    setAct("Sampai di base", C.good)
                    if optBack and not auto then task.wait(0.6) end
                else
                    setAct("Posisi base belum disimpan (tab Base), dilewati", C.warn)
                end
            end
            if optBack and not auto then
                teleportCF(origin)
                setAct("Kembali ke tempat sebelumnya", C.good)
            end
        else
            if fakeAbort then
                failedUntil[egg] = os.clock() + 60
                setAct("🚫 Telur palsu terdeteksi (" .. fakeAbort .. "), kembali", C.bad)
            elseif vanished then
                setAct("Telur sudah diambil pemain lain (kembali)", C.bad)
            elseif not sawPrompt then
                setAct("Prompt ambil telur tidak ditemukan (kembali)", C.bad)
            else
                setAct("Prompt ditekan tapi telur tidak terbawa (kembali)", C.bad)
            end
            failedUntil[egg] = os.clock() + 15
            if auto and savedCF then
                teleportCF(savedCF + Vector3.new(0, 3, 0))
            else
                teleportCF(origin)
            end
        end

        autoSuspendUntil = os.clock() + 6
        grabBusy = false
    end)
end

local function renderEggs(results, excluded, st)
    local keep = {}
    for i, r in ipairs(results) do
        keep[r.inst] = true
        local e = eggRows[r.inst]
        if not e then
            local row, t, d, bar = makeRow(eggPage, r.name, "", r.rar.color)
            local inst = r.inst
            row.MouseButton1Click:Connect(function() grabAndReturn(inst, r.name) end)
            e = { row = row, title = t, desc = d, bar = bar }
            eggRows[r.inst] = e
        end
        e.title.Text = r.name
        e.title.TextColor3 = r.rar.color
        e.bar.BackgroundColor3 = r.rar.color
        e.desc.Text = r.rar.name .. "  •  " .. (r.price or "-") .. "  •  " .. math.floor(r.dist) .. " stud"
        e.row.LayoutOrder = i - 900 -- daftar telur selalu di atas kontrol
    end
    for inst, e in pairs(eggRows) do
        if not keep[inst] then
            e.row:Destroy()
            eggRows[inst] = nil
        end
    end
    emptyLabel.Visible = next(eggRows) == nil
end

local function refreshEggs()
    if eggRefreshing then return end
    eggRefreshing = true
    local ok, res, excluded, st = pcall(scanEggs)
    if ok then
        if main.Visible and eggPage.Visible then renderEggs(res, excluded, st) end
    else
        warn("[NB] scan telur gagal:", res)
    end
    eggRefreshing = false
end

addSection(eggPage, "◆ KONTROL", -500)
addSection(eggPage, "◆ DAFTAR TELUR (teratas = terbaik)", -1000)

-- Refresh otomatis di latar belakang (tanpa tombol). Cepat saat Auto Ambil menyala atau daftar
-- sedang dibuka; pelan saat menu tertutup supaya daftar langsung siap ketika dibuka.
task.spawn(function()
    while not introDone do task.wait(0.2) end
    local acc, wasShown = 99, false
    while gui.Parent do
        acc += task.wait()
        local shown = main.Visible and eggPage.Visible
        if shown and not wasShown then acc = 99 end
        wasShown = shown
        local want = (autoBest or autoRebirth) and 0.15 or (shown and 0.25 or 2)
        if acc >= want and not grabBusy then
            acc = 0
            refreshEggs()
        end
    end
end)

-- Auto Ambil Telur Terbaik: rarity Eksotis (rank 3) ke atas, fake sudah dikecualikan oleh scan
local AUTO_MIN_RANK = 3
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoBest and not grabBusy and not eggRefreshing then
            local best
            for _, r in ipairs(allEggResults) do
                local inst = r.inst
                if r.rar.rank >= AUTO_MIN_RANK
                    and inst.Parent and inst:IsDescendantOf(workspace)
                    and not isPlayerPart(inst)
                    and (failedUntil[inst] or 0) < os.clock() then
                    if not best or r.rar.rank > best.rar.rank
                        or (r.rar.rank == best.rar.rank and r.dist < best.dist) then
                        best = r
                    end
                end
            end
            if best and isFakeEgg(best.inst) then
                failedUntil[best.inst] = os.clock() + 60
                best = nil
            end
            if best and not carryingEgg() then
                grabAndReturn(best.inst, best.name, true)
            end
        end
    end
end)

----------------------------------------------------------------
-- Auto Ambil Rebirth
--  * Membaca daftar "Kebutuhan" (papan pena milikmu / UI layar), atau isi manual
--  * Hanya mengambil telur yang masih dibutuhkan
--  * Telur yang sudah terambil dicatat -> tidak diambil lagi (Reset untuk mulai ulang)
----------------------------------------------------------------
local rebList, rebTaken = {}, {}

addSection(eggPage, "◆ AUTO REBIRTH", -493)

local rebStatus = newLabel({
    Size = UDim2.new(1, -4, 0, 34),
    Text = "🎯 Nyalakan untuk membaca daftar kebutuhan rebirth",
    TextColor3 = C.muted,
    TextSize = 11,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
})
rebStatus.LayoutOrder = -491
rebStatus.Parent = eggPage

local tReb = addToggle(eggPage, "Auto Ambil Rebirth", "Ambil yang dibutuhkan • otomatis ke base • berhenti jika cukup", function(on)
    autoRebirth = on
    if on then ensureBase() end
    if not on then rebStatus.Text = "🎯 Nyalakan untuk membaca daftar kebutuhan rebirth" end
end)
tReb.row.LayoutOrder = -492

-- Kolom manual (opsional): "garuda, minotaur x2, kitsune"
local rebInputRow = Instance.new("Frame")
rebInputRow.Size = UDim2.new(1, -4, 0, 40)
rebInputRow.BackgroundColor3 = C.row
rebInputRow.LayoutOrder = -490
rebInputRow.Parent = eggPage
corner(rebInputRow, 11)

local manualBox = Instance.new("TextBox")
manualBox.Size = UDim2.new(1, -24, 1, 0)
manualBox.Position = UDim2.new(0, 12, 0, 0)
manualBox.BackgroundTransparency = 1
manualBox.PlaceholderText = "Manual (opsional): garuda, minotaur, kitsune"
manualBox.PlaceholderColor3 = C.muted
manualBox.Text = ""
manualBox.TextColor3 = C.text
manualBox.Font = Enum.Font.Gotham
manualBox.TextSize = 13
manualBox.TextXAlignment = Enum.TextXAlignment.Left
manualBox.ClearTextOnFocus = false
manualBox.Parent = rebInputRow

local HEAD_WORDS = { "kebutuhan", "dibutuhkan", "requirement", "required", "needed", "butuh" }
local DONE_MARKS = { "✓", "✔", "☑", "✅" }

local function normKey(str)
    str = string.lower(tostring(str or ""))
    str = string.gsub(str, "<[^>]+>", "")
    str = string.gsub(str, "telur", "")
    str = string.gsub(str, "egg", "")
    str = string.gsub(str, "[\128-\255]", "")
    str = string.gsub(str, "[%s%p%d]", "")
    return str
end

local function keyMatch(a, b)
    if a == "" or b == "" then return false end
    if a == b then return true end
    if #a >= 3 and string.find(b, a, 1, true) then return true end
    if #b >= 3 and string.find(a, b, 1, true) then return true end
    return false
end

-- "Telur Garuda 0/1" -> butuh 1, belum selesai ; "Kitsune x2" -> butuh 2 ; "✓" -> selesai
local function parseEntry(text)
    local low = string.lower(text)
    local have, need
    local a, b = string.match(text, "(%d+)%s*/%s*(%d+)")
    if a then have, need = tonumber(a), tonumber(b) end
    if not need then
        local x = string.match(text, "[xX]%s*(%d+)") or string.match(text, "(%d+)%s*[xX]")
        if x then need = tonumber(x) end
    end
    local done = (have ~= nil and need ~= nil and have >= need)
    if not done then
        for _, m in ipairs(DONE_MARKS) do
            if string.find(text, m, 1, true) then done = true break end
        end
    end
    if not done and (string.find(low, "selesai", 1, true) or string.find(low, "terpenuhi", 1, true)
        or string.find(low, "complete", 1, true)) then
        done = true
    end
    local clean = string.gsub(text, "%d+%s*/%s*%d+", "")
    clean = string.gsub(clean, "[xX]%s*%d+", "")
    clean = string.gsub(clean, "%d+%s*[xX]", "")
    clean = string.gsub(clean, "^[%s%p]+", "")
    clean = string.gsub(clean, "%s+$", "")
    return math.clamp(need or 1, 1, 20), done, clean
end

local memoHeadText, memoHead = newSet(), newSet()
local function isHeadLabel(l)
    local tx = l.Text
    if tx == "" then return false end
    if memoHeadText[l] == tx then return memoHead[l] end
    local low = string.lower(tx)
    local r = false
    for _, w in ipairs(HEAD_WORDS) do
        if string.find(low, w, 1, true) then r = true break end
    end
    memoHeadText[l] = tx
    memoHead[l] = r
    return r
end

-- Kumpulkan semua baris teks dari papan yang memuat label "Kebutuhan"
local function containerLines(h)
    local root = h:FindFirstAncestorWhichIsA("BillboardGui") or h:FindFirstAncestorWhichIsA("SurfaceGui")
    if not root then
        root = h
        for _ = 1, 3 do
            local par = root.Parent
            if par and not par:IsA("LayerCollector") then root = par else break end
        end
    end
    local lines = {}
    local function add(l)
        if l.Text ~= "" then
            for line in string.gmatch(string.gsub(l.Text, "<[^>]+>", ""), "[^\n\r]+") do
                lines[#lines + 1] = line
            end
        end
    end
    if root:IsA("TextLabel") or root:IsA("TextButton") then add(root) end
    for _, d in ipairs(root:GetDescendants()) do
        if d.ClassName == "TextLabel" or d.ClassName == "TextButton" then add(d) end
    end
    return lines
end

local function buildRebList()
    local list, seen = {}, {}
    local function push(text, forceNotDone)
        local need, done, clean = parseEntry(text)
        local key = normKey(clean)
        if #key < 3 or seen[key] then return end
        seen[key] = true
        list[#list + 1] = { key = key, label = clean, need = need, done = (not forceNotDone) and done or false }
    end

    local manual = manualBox.Text or ""
    if string.match(manual, "%S") then
        for tok in string.gmatch(manual, "[^,;\n]+") do push(tok, true) end
        return list
    end

    local myName, myDisp = string.lower(LP.Name), string.lower(LP.DisplayName)
    local best
    local function scanSet(set, screen)
        for l in pairs(set) do
            if l.Parent and isHeadLabel(l) and not l:IsDescendantOf(gui) then
                local lines = containerLines(l)
                local blob = string.lower(table.concat(lines, "\n"))
                local mine = string.find(blob, myName, 1, true) ~= nil
                    or string.find(blob, myDisp, 1, true) ~= nil
                if mine then
                    best = { lines = lines }
                    return true
                elseif screen and not best then
                    best = { lines = lines }
                end
            end
        end
    end
    if not scanSet(wsLabels, false) then scanSet(pgText, true) end
    if not best then return list end

    for _, line in ipairs(best.lines) do
        local low = string.lower(line)
        local text = line
        for _, w in ipairs(HEAD_WORDS) do
            if string.find(low, w, 1, true) then
                text = string.match(line, ":%s*(.+)$")
                break
            end
        end
        if text then
            local lt = string.lower(text)
            if not string.find(lt, "milik", 1, true) and not string.find(lt, "owner", 1, true)
                and not string.find(lt, myName, 1, true) and not string.find(lt, myDisp, 1, true)
                and not string.match(text, "^[%d%s%.:,%$%%/xX%-]+$") then
                for part in string.gmatch(text, "[^,;]+") do push(part, false) end
            end
        end
    end
    return list
end

local function rebEffDone(e)
    return e.done or (rebTaken[e.key] or 0) >= e.need
end

local function rebStatusText()
    if #rebList == 0 then
        return "🔎 Daftar kebutuhan belum ditemukan • isi manual di bawah"
    end
    local parts, all = {}, true
    for _, e in ipairs(rebList) do
        local d = rebEffDone(e)
        if not d then all = false end
        local mark = d and " ✓" or (e.need > 1 and (" " .. (rebTaken[e.key] or 0) .. "/" .. e.need) or " ✗")
        parts[#parts + 1] = e.label .. mark
    end
    if all then return "✅ Semua kebutuhan terpenuhi • berhenti mengambil" end
    return "🎯 " .. table.concat(parts, " • ")
end

local function matchNeed(r)
    local nk, rk = normKey(r.name), normKey(r.rar.name)
    for _, e in ipairs(rebList) do
        if not rebEffDone(e) and (keyMatch(e.key, nk) or e.key == rk) then return e end
    end
end

-- Dipanggil saat telur berhasil terambil (dari mana pun): catat agar tidak diambil lagi
onGrabbed = function(egg, name)
    local nk, rk = normKey(name), ""
    for _, r in ipairs(allEggResults) do
        if r.inst == egg then rk = normKey(r.rar.name) break end
    end
    for _, e in ipairs(rebList) do
        if keyMatch(e.key, nk) or e.key == rk then
            rebTaken[e.key] = (rebTaken[e.key] or 0) + 1
        end
    end
    rebStatus.Text = rebStatusText()
end

local rebReset = addButton(eggPage, "Reset Terambil", "Hitung ulang dari nol (mis. setelah rebirth)", function()
    table.clear(rebTaken)
    rebStatus.Text = rebStatusText()
end)
rebReset.row.LayoutOrder = -489

task.spawn(function()
    while not introDone do task.wait(0.3) end
    local lastDetect = 0
    while gui.Parent do
        task.wait(0.2)
        if autoRebirth then
            if os.clock() - lastDetect > 1 then
                lastDetect = os.clock()
                local ok, list = pcall(buildRebList)
                if ok then rebList = list end
                rebStatus.Text = rebStatusText()
            end
            if not grabBusy and not eggRefreshing and #rebList > 0 then
                local best
                for _, r in ipairs(allEggResults) do
                    local inst = r.inst
                    if inst.Parent and inst:IsDescendantOf(workspace)
                        and not isPlayerPart(inst)
                        and (failedUntil[inst] or 0) < os.clock()
                        and matchNeed(r) then
                        if not best or r.dist < best.dist then best = r end
                    end
                end
                if best and isFakeEgg(best.inst) then
                    failedUntil[best.inst] = os.clock() + 60
                    best = nil
                end
                if best and not carryingEgg() then
                    grabAndReturn(best.inst, best.name, true)
                end
            end
        end
    end
end)

-- Bersihkan instan: telur yang sudah diambil / hilang / menempel di pemain langsung dihapus dari daftar
task.spawn(function()
    while true do
        task.wait(0.3)
        for inst, e in pairs(eggRows) do
            local gone = (not inst.Parent) or (not inst:IsDescendantOf(workspace)) or isPlayerPart(inst)
            if gone then
                e.row:Destroy()
                eggRows[inst] = nil
            end
        end
    end
end)


task.wait()

----------------------------------------------------------------
-- Fitur: Server Hop
--  * Daftar 3 server: berisi 1, 2, dan 3 pemain (minimal 1 pemain)
--  * Cari 1 pemain: join server publik tempat pemain itu berada
----------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local PLACE_ID = game.PlaceId
local hopBusy = false

local srvStatus = newLabel({
    Size = UDim2.new(1, -4, 0, 30),
    Text = "✦ Server Hop siap",
    TextColor3 = C.muted,
    TextSize = 11,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
})
srvStatus.LayoutOrder = 0
addSection(serverPage, "◆ SERVER HOP", -1)
srvStatus.Parent = serverPage

local function setSrv(text, color)
    srvStatus.Text = text
    srvStatus.TextColor3 = color or C.muted
end

local function getRequestFn()
    return (syn and syn.request) or (http and http.request) or http_request or request
end

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    local req = getRequestFn()
    if req then
        local ok2, r = pcall(function() return req({ Url = url, Method = "GET" }) end)
        if ok2 and r and r.Body then return r.Body end
    end
end

local function jdecode(body)
    local ok, d = pcall(function() return HttpService:JSONDecode(body) end)
    if ok then return d end
end

local function serverUrl(order, cursor)
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100"):format(PLACE_ID, order)
    if cursor then url = url .. "&cursor=" .. cursor end
    return url
end

local function joinServer(sv)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, sv.id, LP)
    end)
    task.delay(6, function() hopBusy = false end)
    return ok
end

-- Ambil beberapa halaman daftar server publik
local function fetchServers(pages, order)
    local list, cursor = {}, nil
    for i = 1, pages do
        local body = httpGet(serverUrl(order, cursor))
        local data = body and jdecode(body)
        if not data or not data.data then break end
        for _, sv in ipairs(data.data) do table.insert(list, sv) end
        cursor = data.nextPageCursor
        if not cursor then break end
        task.wait(0.4)
    end
    return list
end

-- Cari server tempat 1 pemain berada (server publik saja)
local function findPlayer(username)
    if hopBusy then return end
    username = ((username or ""):gsub("%s+", ""))
    if username == "" then
        setSrv("Isi username pemain dulu", C.bad)
        return
    end
    local req = getRequestFn()
    if not req then
        setSrv("Executor ini tidak mendukung request", C.bad)
        return
    end

    hopBusy = true
    task.spawn(function()
        local function finish(text, color)
            setSrv(text, color)
            hopBusy = false
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == username:lower() or p.DisplayName:lower() == username:lower() then
                return finish("Pemain itu sudah ada di server ini", C.good)
            end
        end

        setSrv("Mencari pemain...", C.warn)
        local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
        if not ok or not uid then return finish("Username tidak ditemukan", C.bad) end

        local tb = httpGet(("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=150x150&format=Png&isCircular=false"):format(uid))
        local td = tb and jdecode(tb)
        local targetUrl = td and td.data and td.data[1] and td.data[1].imageUrl
        if not targetUrl then return finish("Gagal mengambil data avatar pemain", C.bad) end

        local cursor
        local PAGES = 4
        for page = 1, PAGES do
            setSrv(("Memeriksa server publik... halaman %d/%d"):format(page, PAGES), C.warn)
            local body = httpGet(serverUrl("Asc", cursor))
            local data = body and jdecode(body)
            if not data or not data.data then
                return finish("Gagal mengambil daftar server (mungkin kena limit, coba lagi)", C.bad)
            end

            local tokens, owner = {}, {}
            for _, sv in ipairs(data.data) do
                if sv.id ~= game.JobId and sv.playerTokens then
                    for _, tk in ipairs(sv.playerTokens) do
                        table.insert(tokens, tk)
                        owner[tk] = sv
                    end
                end
            end

            for i = 1, #tokens, 100 do
                local batch = {}
                for j = i, math.min(i + 99, #tokens) do
                    table.insert(batch, {
                        requestId = tokens[j], token = tokens[j],
                        type = "AvatarHeadShot", size = "150x150",
                        format = "png", isCircular = false,
                    })
                end
                local okr, resp = pcall(function()
                    return req({
                        Url = "https://thumbnails.roblox.com/v1/batch",
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode(batch),
                    })
                end)
                local rd = okr and resp and resp.Body and jdecode(resp.Body)
                if rd and rd.data then
                    for _, item in ipairs(rd.data) do
                        if item.imageUrl == targetUrl and owner[item.requestId] then
                            local sv = owner[item.requestId]
                            setSrv(("Ditemukan! Pindah ke server %d/%d pemain..."):format(sv.playing or 0, sv.maxPlayers or 0), C.good)
                            joinServer(sv)
                            return
                        end
                    end
                end
                task.wait(0.35)
            end

            cursor = data.nextPageCursor
            if not cursor then break end
            task.wait(0.4)
        end
        finish("Pemain tidak ditemukan di server publik (offline / server privat)", C.bad)
    end)
end

-- Kolom input username
local inputRow = Instance.new("Frame")
inputRow.Size = UDim2.new(1, -4, 0, 44)
inputRow.BackgroundColor3 = C.row
inputRow.LayoutOrder = 1
inputRow.Parent = serverPage
corner(inputRow, 11)

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -24, 1, 0)
nameBox.Position = UDim2.new(0, 12, 0, 0)
nameBox.BackgroundTransparency = 1
nameBox.PlaceholderText = "Username pemain yang dicari"
nameBox.PlaceholderColor3 = C.muted
nameBox.Text = ""
nameBox.TextColor3 = C.text
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 14
nameBox.TextXAlignment = Enum.TextXAlignment.Left
nameBox.ClearTextOnFocus = false
nameBox.Parent = inputRow

local searchBtn = addButton(serverPage, "Cari & Join Pemain", "Masuk ke server publik tempat pemain berada", function()
    findPlayer(nameBox.Text)
end)
searchBtn.row.LayoutOrder = 2

-- Daftar server: Server 1 = 1 pemain, Server 2 = 2 pemain, Server 3 = 3 pemain
-- (kalau jumlah persis tidak ada, diambil yang terdekat di atasnya; minimal 1 pemain)
local serverRows = {}

local function clearServerRows()
    for _, r in ipairs(serverRows) do r:Destroy() end
    table.clear(serverRows)
end

local function loadServers()
    if hopBusy then return end
    hopBusy = true
    task.spawn(function()
        setSrv("Mengambil daftar server...", C.warn)
        local list = fetchServers(3, "Asc")

        local byCount = {}
        for _, sv in ipairs(list) do
            if sv.id ~= game.JobId and sv.playing and sv.playing >= 1
                and sv.maxPlayers and sv.playing < sv.maxPlayers then
                byCount[sv.playing] = byCount[sv.playing] or {}
                table.insert(byCount[sv.playing], sv)
            end
        end

        local picks, used = {}, {}
        for want = 1, 3 do
            local pick
            for c = want, 30 do
                local cands = {}
                for _, sv in ipairs(byCount[c] or {}) do
                    if not used[sv.id] then table.insert(cands, sv) end
                end
                if #cands > 0 then
                    pick = cands[math.random(#cands)]
                    break
                end
            end
            if pick then
                used[pick.id] = true
                table.insert(picks, { want = want, sv = pick })
            end
        end

        clearServerRows()
        if #picks == 0 then
            setSrv("Tidak ada server yang cocok (coba muat ulang)", C.bad)
            hopBusy = false
            return
        end

        for _, p in ipairs(picks) do
            local sv = p.sv
            local row, t, d = makeRow(serverPage,
                ("Server %d  •  %d pemain"):format(p.want, sv.playing),
                ("%d/%d pemain  •  ping %s"):format(sv.playing, sv.maxPlayers, sv.ping and (math.floor(sv.ping) .. " ms") or "-"))
            row.LayoutOrder = 3 + p.want
            local arrow = newLabel({
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 20),
                Text = ">",
                TextColor3 = C.accent,
                Font = Enum.Font.GothamBold,
                TextSize = 15,
            })
            arrow.Parent = row
            row.MouseButton1Click:Connect(function()
                if hopBusy then return end
                hopBusy = true
                setSrv(("Pindah ke server %d pemain..."):format(sv.playing), C.good)
                joinServer(sv)
            end)
            table.insert(serverRows, row)
        end

        setSrv("Pilih server (minimal 1 pemain)", C.good)
        hopBusy = false
    end)
end

local loadBtn = addButton(serverPage, "Muat Daftar Server", "Server 1 / 2 / 3 pemain • ketuk untuk join", loadServers)
loadBtn.row.LayoutOrder = 3



----------------------------------------------------------------
-- Tema otomatis: setiap 1 menit warna UI berganti (tidak pernah sama dua kali berturut-turut)
----------------------------------------------------------------
do
    local PALETTES = {
        { name = "Neon Ocean", a = Color3.fromRGB(0, 224, 255),   p = Color3.fromRGB(255, 62, 200) },
        { name = "Aurora",     a = Color3.fromRGB(80, 255, 170),  p = Color3.fromRGB(60, 140, 255) },
        { name = "Sunset",     a = Color3.fromRGB(255, 150, 60),  p = Color3.fromRGB(255, 60, 130) },
        { name = "Violet",     a = Color3.fromRGB(170, 110, 255), p = Color3.fromRGB(255, 110, 205) },
        { name = "Lava",       a = Color3.fromRGB(255, 80, 80),   p = Color3.fromRGB(255, 190, 60) },
        { name = "Lime",       a = Color3.fromRGB(170, 255, 60),  p = Color3.fromRGB(40, 220, 200) },
        { name = "Rose Gold",  a = Color3.fromRGB(255, 140, 170), p = Color3.fromRGB(255, 200, 110) },
        { name = "Ice",        a = Color3.fromRGB(140, 220, 255), p = Color3.fromRGB(190, 160, 255) },
    }
    for _, pal in ipairs(PALETTES) do pal.m = pal.a:Lerp(pal.p, 0.5) end
    local BUBBLE_MID = Color3.fromRGB(150, 110, 255) -- warna tengah gradasi bubble (awal)

    local function same(x, y)
        return math.abs(x.R - y.R) < 0.008 and math.abs(x.G - y.G) < 0.008 and math.abs(x.B - y.B) < 0.008
    end

    -- Warna mana pun yang berasal dari palet mana pun dipetakan ke palet baru
    local function mapColor(c, pal)
        if same(c, BUBBLE_MID) then return pal.m end
        for _, q in ipairs(PALETTES) do
            if same(c, q.a) then return pal.a end
            if same(c, q.p) then return pal.p end
            if same(c, q.m) then return pal.m end
        end
        return nil
    end

    local function applyTheme(pal)
        local jobs = {}
        local function addProp(inst, prop)
            local from = inst[prop]
            local to = mapColor(from, pal)
            if to and not same(from, to) then
                jobs[#jobs + 1] = { inst = inst, prop = prop, from = from, to = to }
            end
        end
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("UIStroke") then
                addProp(d, "Color")
            elseif d:IsA("UIGradient") then
                local kps, changed = {}, false
                for i, k in ipairs(d.Color.Keypoints) do
                    local to = mapColor(k.Value, pal)
                    if to then changed = true end
                    kps[i] = { t = k.Time, from = k.Value, to = to or k.Value }
                end
                if changed then jobs[#jobs + 1] = { grad = d, kps = kps } end
            elseif d:IsA("GuiObject") then
                addProp(d, "BackgroundColor3")
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    addProp(d, "TextColor3")
                end
            end
        end

        -- elemen yang dibuat setelah ini ikut memakai warna baru
        C.accent, C.pink = pal.a, pal.p
        subtitle.Text = "◆ Egg Toolkit  v2 • " .. pal.name

        -- transisi halus 1.2 detik (1 loop, di-update tiap frame)
        task.spawn(function()
            local t0 = os.clock()
            while true do
                local a = math.min((os.clock() - t0) / 1.2, 1)
                for _, j in ipairs(jobs) do
                    if j.grad then
                        if j.grad.Parent then
                            local seq = {}
                            for i, k in ipairs(j.kps) do
                                seq[i] = ColorSequenceKeypoint.new(k.t, k.from:Lerp(k.to, a))
                            end
                            j.grad.Color = ColorSequence.new(seq)
                        end
                    elseif j.inst.Parent then
                        j.inst[j.prop] = j.from:Lerp(j.to, a)
                    end
                end
                if a >= 1 then break end
                task.wait()
            end
        end)
    end

    task.spawn(function()
        while not introDone do task.wait(0.5) end
        local cur, bag = 1, {}
        while gui.Parent do
            task.wait(60)
            if not gui.Parent then break end
            if #bag == 0 then
                for i = 1, #PALETTES do
                    if i ~= cur then bag[#bag + 1] = i end
                end
                for i = #bag, 2, -1 do -- acak urutan
                    local j = math.random(1, i)
                    bag[i], bag[j] = bag[j], bag[i]
                end
            end
            cur = table.remove(bag)
            local ok, err = pcall(applyTheme, PALETTES[cur])
            if not ok then warn("[NB] ganti tema gagal:", err) end
        end
    end)
end

print("[NIMEROHUB] Loaded")
