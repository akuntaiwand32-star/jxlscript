-- NemeroHub | UNIVERSAL  (V2 - Purple x Green + Bubble Animation)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local lp = Players.LocalPlayer

------------------------------------------------------------
-- Bersihkan eksekusi sebelumnya
------------------------------------------------------------
local G = (getgenv and getgenv()) or _G
if G.NemeroHubCleanup then pcall(G.NemeroHubCleanup) end

local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

------------------------------------------------------------
-- Util
------------------------------------------------------------
local function getChar() return lp.Character end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r) return mk("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function round(o) return mk("UICorner", {CornerRadius = UDim.new(1, 0)}, o) end
local function stroke(o, color, th, tr)
    return mk("UIStroke", {
        Color = color, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end

local function tw(o, t, props, style, dir)
    local tr = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tr:Play()
    return tr
end

local function grad(o, c1, c2, rot)
    local g = o:FindFirstChildOfClass("UIGradient") or mk("UIGradient", {}, o)
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 25
    return g
end

------------------------------------------------------------
-- State
------------------------------------------------------------
local MODES = {"TELEPORT", "SPEED", "FLY"}
local mode = 1
local speedVal = 10
local flySpeed = 10
local positions = {}
local flying, noclip, infjump, esp = false, false, false, true

------------------------------------------------------------
-- Warna (ungu x hijau)
------------------------------------------------------------
local C = {
    purple = rgb(150, 85, 255),
    purple2 = rgb(95, 45, 190),
    lilac = rgb(215, 195, 255),
    green = rgb(55, 235, 145),
    green2 = rgb(18, 105, 68),
    field = rgb(20, 12, 38),
    white = Color3.new(1, 1, 1),
}
local MODE_G = {
    {rgb(70, 35, 130), rgb(150, 85, 255)},
    {rgb(105, 60, 225), rgb(45, 205, 135)},
    {rgb(18, 105, 68), rgb(60, 235, 150)},
}

------------------------------------------------------------
-- GUI root
------------------------------------------------------------
local function guiParent()
    local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    if ok and p then return p end
    return lp:WaitForChild("PlayerGui")
end
local parent = guiParent()
for _, n in ipairs({"NemeroHub", "NemeroHubESP"}) do
    local o = parent:FindFirstChild(n)
    if o then o:Destroy() end
end

local gui = mk("ScreenGui", {Name = "NemeroHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, parent)
local espRoot = mk("Folder", {Name = "NemeroHubESP"}, parent)

------------------------------------------------------------
-- Drag helper
------------------------------------------------------------
local function drag(handle, target, st)
    local dragging, startIn, startPos = false, nil, nil
    bind(handle.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startIn = i.Position
            startPos = target.Position
            if st then st.moved = false end
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startIn
            if st and d.Magnitude > 6 then st.moved = true end
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

------------------------------------------------------------
-- Window utama
------------------------------------------------------------
local W, FULL_H, MINI_H = 310, 344, 44
local UI_SCALE = 0.85  -- ukuran menu (1 = besar, makin kecil makin mungil)

local main = mk("Frame", {
    Size = UDim2.fromOffset(W, FULL_H),
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0.5, -172),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true,
}, gui)
corner(main, 14)
grad(main, rgb(24, 12, 44), rgb(8, 5, 18), 90)
local mainScale = mk("UIScale", {Scale = 0}, main)

-- Border gradient berputar
local mainStroke = stroke(main, C.white, 2.5, 0)
local borderGrad = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.purple),
        ColorSequenceKeypoint.new(0.5, C.green),
        ColorSequenceKeypoint.new(1, C.purple),
    }),
}, mainStroke)
TweenService:Create(borderGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}):Play()

-- Layer gelembung (di belakang isi)
local bubbleLayer = mk("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 0,
    ClipsDescendants = true,
}, main)

local function spawnBubble()
    task.spawn(function()
        task.wait(math.random() * 5)
        while bubbleLayer.Parent do
            if main.Visible then
                local size = math.random(6, 22)
                local x = math.random(12, 88) / 100
                local sway = math.random(-28, 28)
                local dur = math.random(45, 90) / 10
                local b = mk("Frame", {
                    Size = UDim2.fromOffset(size, size),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(x, 0, 1, size),
                    BackgroundColor3 = (math.random() < 0.5) and rgb(170, 120, 255) or rgb(80, 255, 165),
                    BackgroundTransparency = 0.6,
                    BorderSizePixel = 0,
                }, bubbleLayer)
                round(b)
                local bs = stroke(b, C.white, 1.2, 0.45)
                local shine = mk("Frame", {
                    Size = UDim2.fromScale(0.28, 0.28),
                    Position = UDim2.fromScale(0.2, 0.17),
                    BackgroundColor3 = C.white,
                    BackgroundTransparency = 0.35,
                    BorderSizePixel = 0,
                }, b)
                round(shine)
                tw(bs, dur, {Transparency = 1}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tw(shine, dur, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                local t = tw(b, dur, {
                    Position = UDim2.new(x, sway, 0, -size),
                    BackgroundTransparency = 1,
                }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                t.Completed:Wait()
                b:Destroy()
            else
                task.wait(0.6)
            end
        end
    end)
end
for _ = 1, 10 do spawnBubble() end

-- Header
local HDR = rgb(32, 17, 58)
local header = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = HDR,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 2,
}, main)
corner(header, 14)
-- tambalan supaya sisi bawah header tetap lurus (hanya atas yang membulat)
mk("Frame", {
    Size = UDim2.new(1, 0, 0.5, 0),
    Position = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3 = HDR,
    BorderSizePixel = 0,
    ZIndex = 0,
}, header)

local line = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    Position = UDim2.new(0, 0, 1, -2),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
}, header)
mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.purple),
        ColorSequenceKeypoint.new(1, C.green),
    }),
}, line)

local dot = mk("Frame", {
    Size = UDim2.fromOffset(12, 12),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 20, 0.5, 0),
    BackgroundColor3 = C.green,
    BorderSizePixel = 0,
}, header)
round(dot)
TweenService:Create(dot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 0.45,
}):Play()

local title = mk("TextLabel", {
    Size = UDim2.new(1, -96, 1, 0),
    Position = UDim2.new(0, 38, 0, 0),
    BackgroundTransparency = 1,
    Text = "NemeroHub | UNIVERSAL",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
local titleGrad = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, rgb(190, 140, 255)),
        ColorSequenceKeypoint.new(0.5, rgb(90, 255, 170)),
        ColorSequenceKeypoint.new(1, rgb(190, 140, 255)),
    }),
    Offset = Vector2.new(-0.4, 0),
}, title)
TweenService:Create(titleGrad, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Offset = Vector2.new(0.4, 0),
}):Play()

-- Tombol minimize
local minHolder = mk("Frame", {
    Size = UDim2.fromOffset(34, 26),
    Position = UDim2.new(1, -44, 0.5, -13),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
}, header)
corner(minHolder, 8)
grad(minHolder, C.purple2, C.purple, 30)
stroke(minHolder, C.white, 1, 0.8)
local minBtn = mk("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "-",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 18,
}, minHolder)

drag(header, main)

-- Body
local body = mk("Frame", {
    Size = UDim2.new(1, -24, 0, 276),
    Position = UDim2.new(0, 12, 0, 56),
    BackgroundTransparency = 1,
    ZIndex = 2,
}, main)

local collapsed = false
bind(minBtn.MouseButton1Click, function()
    if not collapsed then
        collapsed = true
        minBtn.Text = "+"
        tw(main, 0.3, {Size = UDim2.fromOffset(W, MINI_H)}, Enum.EasingStyle.Quint)
        task.delay(0.15, function() if collapsed then body.Visible = false end end)
    else
        collapsed = false
        minBtn.Text = "-"
        body.Visible = true
        tw(main, 0.4, {Size = UDim2.fromOffset(W, FULL_H)}, Enum.EasingStyle.Back)
    end
end)

------------------------------------------------------------
-- Komponen UI
------------------------------------------------------------
local function rowY(i) return (i - 1) * 40 end

local function press(btn, holder)
    local s = mk("UIScale", {Scale = 1}, holder)
    btn.MouseButton1Down:Connect(function() tw(s, 0.08, {Scale = 0.94}) end)
    local function up() tw(s, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end
    btn.MouseButton1Up:Connect(up)
    btn.MouseLeave:Connect(up)
end

local function button(par, text, pos, size, c1, c2)
    local holder = mk("Frame", {
        Position = pos, Size = size,
        BackgroundColor3 = C.white, BorderSizePixel = 0,
    }, par)
    corner(holder, 10)
    grad(holder, c1, c2, 25)
    stroke(holder, C.white, 1, 0.85)
    local b = mk("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
    }, holder)
    press(b, holder)
    return b, holder
end

local function label(par, text, y)
    return mk("TextLabel", {
        Size = UDim2.new(0, 72, 0, 34),
        Position = UDim2.new(0, 2, 0, y),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.lilac,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, par)
end

local function numBox(par, y, init, get, set)
    local box = mk("TextBox", {
        Size = UDim2.new(1, -78, 0, 34),
        Position = UDim2.new(0, 78, 0, y),
        BackgroundColor3 = C.field,
        Text = tostring(init),
        TextColor3 = C.white,
        Font = Enum.Font.GothamBlack,
        TextSize = 14,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
    }, par)
    corner(box, 10)
    local st = stroke(box, C.purple, 1.5, 0.3)
    box.Focused:Connect(function() tw(st, 0.2, {Color = C.green, Transparency = 0}) end)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n and n > 0 then set(n) end
        box.Text = tostring(get())
        tw(st, 0.2, {Color = C.purple, Transparency = 0.3})
    end)
    return box
end

-- Tombol mode
local modeBtn, modeHolder = button(body, "MODE: TELEPORT", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 34), MODE_G[1][1], MODE_G[1][2])
modeBtn.TextSize = 14
modeBtn.Font = Enum.Font.GothamBlack

local pageA = mk("Frame", {Size = UDim2.new(1, 0, 0, 240), Position = UDim2.new(0, 0, 0, 42), BackgroundTransparency = 1}, body)
local pageB = mk("Frame", {Size = UDim2.new(1, 0, 0, 240), Position = UDim2.new(0, 0, 0, 42), BackgroundTransparency = 1, Visible = false}, body)

------------------------------------------------------------
-- Halaman A: TELEPORT / SPEED
------------------------------------------------------------
label(pageA, "SPEED:", rowY(1))
numBox(pageA, rowY(1), speedVal, function() return speedVal end, function(n) speedVal = n end)

local moveId = 0
local function glide(cf)
    moveId += 1
    local id = moveId
    task.spawn(function()
        while id == moveId do
            local root = getRoot()
            if not root then break end
            local delta = cf.Position - root.Position
            local dist = delta.Magnitude
            local dt = RunService.Heartbeat:Wait()
            local step = math.max(speedVal, 0.1) * 20 * dt
            if dist <= step then
                root.CFrame = cf
                break
            end
            root.CFrame = root.CFrame + delta.Unit * step
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local goButtons = {}
for i = 1, 4 do
    local y = rowY(i + 1)
    label(pageA, "POS " .. i, y)
    local setB = button(pageA, "SET", UDim2.new(0, 78, 0, y), UDim2.new(0.5, -43, 0, 34), C.green2, rgb(40, 190, 115))
    local goB = button(pageA, "TP", UDim2.new(0.5, 43, 0, y), UDim2.new(0.5, -43, 0, 34), C.purple2, C.purple)
    goButtons[i] = goB

    setB.MouseButton1Click:Connect(function()
        local root = getRoot()
        if root then
            positions[i] = root.CFrame
            setB.Text = "OK!"
            task.delay(0.7, function() setB.Text = "SET" end)
        end
    end)

    goB.MouseButton1Click:Connect(function()
        local cf = positions[i]
        local root = getRoot()
        if not cf or not root then return end
        if mode == 1 then
            moveId += 1
            root.CFrame = cf
        else
            glide(cf)
        end
    end)
end

local resetB = button(pageA, "RESET ALL POS", UDim2.new(0, 0, 0, rowY(6)), UDim2.new(1, 0, 0, 34), rgb(95, 30, 110), rgb(170, 60, 160))
resetB.MouseButton1Click:Connect(function()
    positions = {}
    moveId += 1
    resetB.Text = "TERHAPUS!"
    task.delay(0.8, function() resetB.Text = "RESET ALL POS" end)
end)

------------------------------------------------------------
-- Fly / Noclip / Inf Jump / ESP / Respawn
------------------------------------------------------------
local bv, bg
local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    local root, hum = getRoot(), getHum()
    if not root or not hum then return end
    stopFly()
    bv = mk("BodyVelocity", {MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero}, root)
    bg = mk("BodyGyro", {MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 1e4, CFrame = root.CFrame}, root)
    hum.PlatformStand = true
end

bind(RunService.RenderStepped, function()
    if flying and bv and bg then
        local root, hum = getRoot(), getHum()
        local cam = workspace.CurrentCamera
        if root and hum and cam then
            local rel = cam.CFrame:VectorToObjectSpace(hum.MoveDirection)
            bv.Velocity = (cam.CFrame.LookVector * -rel.Z + cam.CFrame.RightVector * rel.X) * flySpeed * 5
            bg.CFrame = cam.CFrame
        end
    end
end)

bind(RunService.Stepped, function()
    if noclip then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

bind(UIS.JumpRequest, function()
    if infjump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ESP
local function espClear(p)
    local f = espRoot:FindFirstChild(tostring(p.UserId))
    if f then f:Destroy() end
end

local function espAdd(p)
    if p == lp then return end
    local ch = p.Character
    if not ch then return end
    espClear(p)
    local f = mk("Folder", {Name = tostring(p.UserId)}, espRoot)
    mk("Highlight", {
        Adornee = ch,
        FillColor = C.purple,
        FillTransparency = 0.55,
        OutlineColor = C.green,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
    }, f)
    local head = ch:FindFirstChild("Head")
    if head then
        local bb = mk("BillboardGui", {
            Adornee = head,
            Size = UDim2.fromOffset(110, 20),
            StudsOffset = Vector3.new(0, 2.5, 0),
            AlwaysOnTop = true,
        }, f)
        mk("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = p.DisplayName,
            TextColor3 = rgb(140, 255, 195),
            TextStrokeTransparency = 0.4,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
        }, bb)
    end
end

local function espRefresh()
    for _, f in ipairs(espRoot:GetChildren()) do f:Destroy() end
    if esp then
        for _, p in ipairs(Players:GetPlayers()) do espAdd(p) end
    end
end

local function hookPlayer(p)
    bind(p.CharacterAdded, function()
        task.wait(0.5)
        if esp then espAdd(p) end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= lp then hookPlayer(p) end
end
bind(Players.PlayerAdded, hookPlayer)
bind(Players.PlayerRemoving, espClear)

------------------------------------------------------------
-- Halaman B: FLY
------------------------------------------------------------
label(pageB, "FLY:", rowY(1))
numBox(pageB, rowY(1), flySpeed, function() return flySpeed end, function(n) flySpeed = n end)

local function toggle(text, i, init, cb)
    local b, h = button(pageB, text, UDim2.new(0, 0, 0, rowY(i)), UDim2.new(1, 0, 0, 34), rgb(42, 20, 76), rgb(78, 40, 135))
    local state = init
    local function refresh()
        b.Text = text .. ": " .. (state and "ON" or "OFF")
        if state then
            grad(h, C.green2, rgb(45, 200, 125))
        else
            grad(h, rgb(42, 20, 76), rgb(78, 40, 135))
        end
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        state = not state
        cb(state)
        refresh()
    end)
    return function(v) state = v; refresh() end
end

local setFlyUI = toggle("FLY", 2, false, function(s)
    flying = s
    if s then startFly() else stopFly() end
end)
toggle("NOCLIP", 3, false, function(s) noclip = s end)
toggle("INF JUMP", 4, false, function(s) infjump = s end)
toggle("ESP PLAYER", 5, true, function(s) esp = s; espRefresh() end)

local respawnB = button(pageB, "RESPAWN", UDim2.new(0, 0, 0, rowY(6)), UDim2.new(1, 0, 0, 34), rgb(120, 45, 130), rgb(215, 90, 150))
respawnB.MouseButton1Click:Connect(function()
    local hum = getHum()
    if hum then hum.Health = 0 end
end)

bind(lp.CharacterAdded, function()
    flying = false
    bv, bg = nil, nil
    setFlyUI(false)
end)

------------------------------------------------------------
-- Ganti mode (dengan animasi geser)
------------------------------------------------------------
local function showPage(p)
    p.Visible = true
    p.Position = UDim2.new(0, 0, 0, 56)
    tw(p, 0.3, {Position = UDim2.new(0, 0, 0, 42)}, Enum.EasingStyle.Back)
end

local function applyMode(animated)
    modeBtn.Text = "MODE: " .. MODES[mode]
    grad(modeHolder, MODE_G[mode][1], MODE_G[mode][2], 25)
    pageA.Visible = false
    pageB.Visible = false
    local page = (mode == 3) and pageB or pageA
    if animated then showPage(page) else page.Visible = true end
    for _, b in ipairs(goButtons) do
        b.Text = (mode == 1) and "TP" or "GO"
    end
end

modeBtn.MouseButton1Click:Connect(function()
    mode = mode % 3 + 1
    applyMode(true)
end)

------------------------------------------------------------
-- Gelembung buka/tutup menu
------------------------------------------------------------
local bubbleF = mk("Frame", {
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(0, 20, 0.25, 0),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
}, gui)
round(bubbleF)
grad(bubbleF, rgb(28, 12, 58), rgb(72, 32, 135), 45)

local bStroke = stroke(bubbleF, C.white, 2.5, 0)
local bGrad = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.purple),
        ColorSequenceKeypoint.new(0.5, C.green),
        ColorSequenceKeypoint.new(1, C.purple),
    }),
}, bStroke)
TweenService:Create(bGrad, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}):Play()

local nLabel = mk("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "N",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 28,
}, bubbleF)
mk("UIGradient", {
    Color = ColorSequence.new(rgb(200, 150, 255), rgb(90, 255, 170)),
    Rotation = 45,
}, nLabel)
TweenService:Create(nLabel, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Position = UDim2.new(0, 0, 0, 3),
}):Play()
nLabel.Position = UDim2.new(0, 0, 0, -3)

-- Cincin denyut
local pulse = mk("Frame", {
    Size = UDim2.fromScale(1, 1),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, bubbleF)
round(pulse)
local pStroke = stroke(pulse, C.green, 2, 0.3)
TweenService:Create(pulse, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {
    Size = UDim2.fromScale(1.7, 1.7),
}):Play()
TweenService:Create(pStroke, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {
    Transparency = 1,
}):Play()

local bubbleBtn = mk("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "",
    ZIndex = 5,
}, bubbleF)
local bScale = mk("UIScale", {Scale = 1}, bubbleF)
bubbleBtn.MouseButton1Down:Connect(function() tw(bScale, 0.08, {Scale = 0.88}) end)
local function bUp() tw(bScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back) end
bubbleBtn.MouseButton1Up:Connect(bUp)
bubbleBtn.MouseLeave:Connect(bUp)

-- Letupan gelembung saat diklik
local function burst()
    for i = 1, 9 do
        local s = math.random(5, 11)
        local ang = math.rad(math.random(0, 359))
        local dist = math.random(34, 64)
        local p = mk("Frame", {
            Size = UDim2.fromOffset(s, s),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = (i % 2 == 0) and C.purple or C.green,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            ZIndex = 6,
        }, bubbleF)
        round(p)
        tw(p, 0.7, {
            Position = UDim2.new(0.5, math.cos(ang) * dist, 0.5, math.sin(ang) * dist),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(2, 2),
        })
        Debris:AddItem(p, 0.8)
    end
    local ring = mk("Frame", {
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 6,
    }, bubbleF)
    round(ring)
    local rs = stroke(ring, C.green, 3, 0)
    tw(ring, 0.6, {Size = UDim2.fromScale(2.4, 2.4)})
    tw(rs, 0.6, {Transparency = 1})
    Debris:AddItem(ring, 0.7)
end

-- Buka / tutup menu dengan animasi pop
local isOpen = true
local function setOpen(v)
    isOpen = v
    if v then
        main.Visible = true
        tw(mainScale, 0.45, {Scale = UI_SCALE}, Enum.EasingStyle.Back)
    else
        tw(mainScale, 0.2, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.2, function() if not isOpen then main.Visible = false end end)
    end
end

local bst = {moved = false}
drag(bubbleBtn, bubbleF, bst)
bubbleBtn.MouseButton1Click:Connect(function()
    if bst.moved then return end
    burst()
    setOpen(not isOpen)
end)

------------------------------------------------------------
-- Mulai
------------------------------------------------------------
applyMode(false)
espRefresh()
setOpen(true)

G.NemeroHubCleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    stopFly()
    pcall(function() gui:Destroy() end)
    pcall(function() espRoot:Destroy() end)
end
