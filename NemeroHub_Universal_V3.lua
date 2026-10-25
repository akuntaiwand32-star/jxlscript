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
-- Efek suara klik (saat fitur/tombol ditekan)
------------------------------------------------------------
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local SFX_ON = true       -- false = matikan semua suara ketuk
local SFX_VOLUME = 1.4    -- besar kecil suara ketuk (naikkan kalau kurang terdengar, mis. 2)
-- Gaya suara ketuk:
--   "pop"    = letupan gelembung kecil (cocok dengan tema gelembung)  <- bawaan
--   "tink"   = denting kaca bening
--   "soft"   = ketukan lembut, hampir tanpa nada
--   "klasik" = suara saklar bawaan Roblox (versi lama)
local SFX_STYLE = "pop"

local sfxId = nil
local sfxReady = false

-- Ubah deretan sampel (angka) menjadi file WAV 16-bit mono
local function encodeWav(buf, N, FS, level)
    local peak = 1
    for i = 1, N do
        local v = math.abs(buf[i])
        if v > peak then peak = v end
    end
    local scale = (level or 0.9) * 32767 / peak
    local function le32(v) return string.char(v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256) end
    local function le16(v) return string.char(v % 256, math.floor(v / 256) % 256) end
    local header = "RIFF" .. le32(36 + N * 2) .. "WAVEfmt " .. le32(16) .. le16(1) .. le16(1)
        .. le32(FS) .. le32(FS * 2) .. le16(2) .. le16(16) .. "data" .. le32(N * 2)
    local chunks = {}
    for i = 1, N, 4096 do
        local seg = {}
        for j = i, math.min(i + 4095, N) do
            local v = math.floor(buf[j] * scale)
            if v > 32767 then v = 32767 elseif v < -32768 then v = -32768 end
            if v < 0 then v = v + 65536 end
            seg[#seg + 1] = string.char(v % 256, math.floor(v / 256))
        end
        chunks[#chunks + 1] = table.concat(seg)
        if N > 20000 and i % 16384 == 1 then task.wait() end
    end
    return header .. table.concat(chunks)
end

-- Suara ketuk sudah dibuat jadi file mp3 kecil (disematkan di sini, tidak perlu internet)
local SFX_DATA = {
    pop  = "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Bw05Fj2ZSkqlKixBX+t/r5VolEcBpe4qmQMBcIAxNMlAYAlKbVSScFIiYOrCA9MSDCgabxoztvzef6nh2w70SzTmBA2DEY3ckOE5zylssCAkCmBgiTrFaGWRrdnuPIlK5DJRkOM5dDcnk0QBYur1iUzjePHg0eV3iFwd8qGjzCUS4a//BWW4lcJeS2FnndHBkNLDSvyqn/kqAIEoABYQjR04dKNngZdZgqgyJpeYYFHSBQ0wowDIDJyGQRpgwwAjmAAWjTraA/T+n8dp6HufBhGeXwyzVLESkmRQg+QhQMkKQLWHALmPwpyTGiX4upRFmUBRlQQIoSyMMvh1oxbaGVia2B+6jPYQVFRUVFBZ//uAxDqD0YyinMTl6UAAADSAAAAEAFFW+K3KFf4r8VSAhb//4sKsM/5oVFG1TEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=",
    tink = "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IAw1hhhhvude3UpLDuaBgABgdg9DwKwKBEMBUGkwOQ3jbxaJMCwBMwXQM5GYA4AOkAemCSRpjTzBFDcVuczPMzBi2Qi1F5zz0YlDgFu71vYlIz45eyzxLAwjGHMV/4BIZEfw++1PlxiPzcboiSxtHAmfNEhy7tDpak6wnroMFJTRUP/7gMTrA9Th7QAPLHdKr8AfweQPIRolECWN33so5WDjVlCEv3bL0r+hK819r4Pw/yjxOnxyAJWZvkVj85DMrg54vac2SaMCgEzEeRIuGCw4YHHxoCXmJtYfJPhmAQGUwOYODgCBY6AIy4qwt4ADMzggwEnWVvLGig6AMMHi0WTYqTSzUwdDwpYLeP7q6uTeYn+CmFrv9amJgbFsNglaura4npuZmlhnib2a12uJS+CiwatZVJqjKwlljX+r0hR5y5NrD1IEKhWNSWZYZmI+7Wa9jGy5OjuW3kfVazZjZrqSzsaiYsMqTEFNRTMuMTAwqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqWk67//uCxO2CFG2RBM8Udoq/wJ/FxA7xBWRNzbxpzDWMMULNBQNFBIwkRMkCDUww3p5NrwDNcwzmjNoZjeScI6TYyo0BDMVSBVDMPHyJMMVBBABo8JZl8S6xAAqrq0K6dGGJPLZVQphIomNJFoJHFmJjSRpR95+ss////PlzWz8jUMCcQKEhgaGdhiQwNDaoatSOZMsdWjk1Q1DAnJv+Q1aoaz/8mCg0cjWX5SNWshq1QxIYE4zEhxT//9gxKqsSiq+20QNWrV/dFd1MQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//uCxK4D1rWU3A2YeEgAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
    soft = "SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjYwLjE2LjEwMAAAAAAAAAAAAAAA//uAwAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAAGAAAJ/wBJSUlJSUlJSUlJSUlJSUlJbW1tbW1tbW1tbW1tbW1tbW2SkpKSkpKSkpKSkpKSkpKStra2tra2tra2tra2tra2trbb29vb29vb29vb29vb29vb2/////////////////////8AAAAATGF2YzYwLjMxAAAAAAAAAAAAAAAAJAJbAAAAAAAACf9ZkTXqAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD/+4DEAAAQmaNhdPQAAwC37b8zQACAAAAACB85hq9D1HGPwTcXMubPuBE0/BQAoAoCwGgpUuiIn8uhAoKIlbolf/u7////+jv+lboiIiIiO78IhAoLi5736ILi7u7+ju7vfw737u//6IiC57u7u7oiIiIn//y6IiIiIjuWe7u7oiIiJo98IiIYLi4Pg//ggCAJg+D4PwfB98u+ogAASQTNFZCNxpIEEAkAAwATqbckQDPUKjiAYzjFfGcKQDlJbzN1mnGTiRhBwIOVAwyUcYFFxFhAEXZCl0jSBmJ4W4YgzAW3FhScN6XGqORLQoAezclFCjGyJZjtXLJVPFYk0Dc4yZrTbPZHpmCZeJormqKner+MsViLT5ek8Xl0Vd//cuoGRsXjhfNGepVlqopJf/ZFMxYyZaSR01MyOL3SrRpOtHS//7mRuoxW1JAqpF5FSZs5h6iITGQhFwWUqAAAAIALjREpqRJnV9ZJgQFmBP/7gsQJgBQouUe9zYACnZukSe2qMBGFiQZy3J5s1GRw8sdlsUEYEEYKSaC44TeZ9BWYsFo03Ianscto6KxU3fxxqwy1kCGqPrixnmX1pU4RgIFJssu/jjVhljsu7/7x5WfZh8V1qmpssvqtyh6ls6psu62/tN0sDQNFA7UPDpEqLgsHYiKwVcewVcvVnX5ZQNHtQNKlhwNZ3/+GpV3lXOW7BXrAB0ZVBLZFZyQAQqgOkILgILHMgYREzlHCz+PDIMRgEcwYQHDAkAHRqMCMIIwdgTDB8BLMHASMxA7KzZaGDMGcGYxwpMFDkEqw0dn2mGPpCJz/y2VRGNO8rkwsQN0igeJlAgp97JHPSl0hQRNO1QU0suluX9wrs8MhEGvXdYd5+EuXxN2MM7P8ygFB2WEA2XxcCEzt8fM87NY4iG0sVkv2/9V/9H+S6n1dyxUii0plnHJqYDGBNGCRC/ZgwgYmYv4d/HIciCxhIQKKYP/7gsQRg9U8pRIM/4VCkhQhgf3KIHGBUGA2AN5gCoDQYDqBxmD2AoJgZQA+YDGD9mL/NTJhVocKYHUB3GUTSYgGxg8NmBgUYDAKOaGohGo8WW2giLxSRPEg2YEFxwvXGXxwMgFkD/xSQwM00wCCDDyiEkOoQ98spM90Cj5iYTqw1t/zv9pXpqZ95l+sY8uqj2Zx3k//////2/b/1MmUYHgAcWAIBIBPIgKQwLMAOMHoFVzDLQ1swuKMuOStF5DBtAakwLcDWMBgAkTAMQKAYCRTBnghUwH0C8MGVA2jIci/80RcEXAQg4L0w1sjz2GIAGF0T4AMGMRIBmM52mjL+rmBgyYRohmqjU8s9h9iNqaGnjiNjvyynzZI6NYDXhbkevSSX2VrLoztu/p0/HNexG9mj/s72dP2O5hXp/6UK96xygAADgLllltxR310ILgIBAwKQEzCODTMakLcwz9XjgZHCMAIGUCgRAwA8CgGGP/7gsQWghFktRtPYhBDTjJgAf2OMQwEOYB4JpgmgaGC+F8YoC+hq2huGDUByf4AJKKTLXWhlyoQ+Z5aBnTQNwbBpHoP6imAQjtV9RiKRPP76HX3+rd567pspfY56F2NOKvsfYV+x8m+42lRZywmwrZjTYo0ss4YAWAImAQAEhgHoCOYDkBDGB0gkJhNAJEZE2DXmPC8GhnWYz4YMuC6mA4AShgBYB6EAKRgbQCqYSqCJGCvgRxgLIZUYr7GnGSrigxgHoLeYJWBdfCxsCR0ABRfBJtfDUv13fcplR4wtAEhqW2ufzLFuwNFFvWf5r/3abln/5b7/cZv/1l/P/uv5NI25tYiGdPvocrlMnRkaanqnmqFm2zU5s561r9lKUjRyWRfDk9vlH0KEipI9pjWWdBVJmUQSAm0EivC9dDrWYv+N5OyEzPW3XxWgXPAAAYYAWAQmARAJhgKoFuYH4FHGJ3gMxisrhUcKBPhi9gsgP/7gMQTgxYItwQP+OlKqSDghe0OGYQADA1GAIBeYEAkRijimGACCaYZQKhq07OHBgNQYk4KZg3ALGBmACCgLAgBMuIpg5dJbfurkQLhg9nzXNEchW5y1KtSlFMKTdXRnqlqqkkhPr87SRl1FPVp4f72sXLao/5b/1F3nTEVEtgWXv/r/ch1/1lSvlBi5j+n+ibvv5FZd9ba1z7WqpVDFJfVuzRUyAuAWYAAFxgHg/mCMVUZiIfBoL9CHnYD0YoYCBg2AJmBiAoYDwEpgXh+GByGcYPQNZhiCDmYqoachQa5hygdHQHgJ8EDU1nyiERgzmeGO8f/N0Z3vPzrR6RZWzCHtCPPIGdhz0y+z/xBP31zqnbO5r5UdlpEeWXuo3f+kf/3c7mpkxnZ9XP4sF3McvrN/s7q4zGRoKHjNv/+U20xu/dey9RfdXFFIAGlcDQGm+qIDDsyITzdPsMjUBg0bSuTmmTFMYsLowCwcQ4E//uCxBIDFQkFAg54Z8HwiV/JrmzIcIABMFMCAwKAeRECCSghGdRE2bYwo5g5hADAIYMAEBwBb7tLbVrD/PLNT8pyi9AMAAWjOQiEIE5TOREKEZpSagoS+ftCrpIDTp/Wl9n/fjZtDv3y/MyTombWp+ufKIsItQNPlWEXEw8JUGtywVamHkmxrR5BBLumg4AxIHCiCyDJYrUIwBbWihbZlKwwqDRpznJrVBnYVnCM2awhh1VLGVDJj4INDoKLzUDsx8IN3yjWZk+yVMJXAxuIQYiBmeNvG5imjUajVNTU2JYGgaBoFVA0DQMgrUDQaxgM4lcVOzuVlc8CoLIks9QKHpESw77A0W+WPEueWG/Uezt///8t/UpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
}

local B64CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64LOOKUP = {}
for i = 1, #B64CHARS do B64LOOKUP[B64CHARS:sub(i, i)] = i - 1 end

local function b64decode(str)
    local out, n = {}, 0
    local acc, bits = 0, 0
    for i = 1, #str do
        local v = B64LOOKUP[str:sub(i, i)]
        if v then
            acc = acc * 64 + v
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                local p = 2 ^ bits
                local byte = math.floor(acc / p)
                acc = acc - byte * p
                n = n + 1
                out[n] = string.char(byte)
            end
        end
    end
    return table.concat(out)
end

local sfxSource = "-"

-- memutar satu suara ketuk
local function playSfx(speed, vol)
    if not SFX_ON or not sfxId then return end
    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId = sfxId
        snd.Volume = (vol or 1) * SFX_VOLUME * (0.94 + math.random() * 0.12)
        snd.PlaybackSpeed = (speed or 1) * (0.97 + math.random() * 0.06)
        snd.Looped = false
        snd.Parent = SoundService
        snd:Play()
        Debris:AddItem(snd, 3)
    end)
end

-- cek apakah suatu id suara benar-benar bisa dimuat (menunggu sampai 'maks' detik)
local function sfxLoadable(id, maks)
    local ok, good = pcall(function()
        local t = Instance.new("Sound")
        t.SoundId = id
        t.Volume = 0
        t.Parent = SoundService
        pcall(function() ContentProvider:PreloadAsync({t}) end)
        local t0 = os.clock()
        while not (t.IsLoaded or t.TimeLength > 0) and os.clock() - t0 < (maks or 2) do
            task.wait(0.05)
        end
        local ok2 = t.IsLoaded or t.TimeLength > 0
        t:Destroy()
        return ok2
    end)
    return ok and good
end

local SFX_FALLBACK = {
    "rbxasset://sounds/switch.wav",
    "rbxasset://sounds/button.wav",
    "rbxasset://sounds/snap.mp3",
    "rbxasset://sounds/electronicpingshort.wav",
    "rbxasset://sounds/clickfast.wav",
}

-- siapkan suara ketuk. Suara langsung dipakai begitu file siap (tanpa menunggu pengecekan),
-- lalu dicek di latar belakang; kalau ternyata tidak bisa dimuat, diganti suara bawaan Roblox.
local function prepareSfx()
    local getAsset = getcustomasset or getsynasset
    local custom
    if SFX_STYLE ~= "klasik" and SFX_DATA[SFX_STYLE] and getAsset and writefile then
        local ok, id = pcall(function()
            local fname = "NimeroHub_sfx_v3_" .. SFX_STYLE .. ".mp3"
            local need = true
            if isfile and readfile and isfile(fname) then
                local okr, old = pcall(readfile, fname)
                if okr and type(old) == "string" and #old > 500 then need = false end
            end
            if need then writefile(fname, b64decode(SFX_DATA[SFX_STYLE])) end
            return getAsset(fname)
        end)
        if ok and id and id ~= "" then custom = id end
    end

    -- pakai dulu supaya suara langsung ada
    if custom then
        sfxId = custom
        sfxSource = "buatan (" .. SFX_STYLE .. ")"
    else
        sfxId = SFX_FALLBACK[1]
        sfxSource = "bawaan Roblox"
    end
    sfxReady = true
    print("[NemeroHub] suara ketuk dipakai:", sfxSource)

    -- cek di latar belakang
    task.spawn(function()
        if custom and sfxLoadable(custom, 3) then
            sfxSource = "buatan (" .. SFX_STYLE .. ", terverifikasi)"
            print("[NemeroHub] suara ketuk:", sfxSource)
            return
        end
        for _, id in ipairs(SFX_FALLBACK) do
            if sfxLoadable(id, 2) then
                if not custom or not sfxLoadable(custom, 1) then
                    sfxId = id
                    sfxSource = "bawaan Roblox (" .. id .. ")"
                end
                print("[NemeroHub] suara ketuk:", sfxSource)
                return
            end
        end
        print("[NemeroHub] suara ketuk: tidak bisa diverifikasi, tetap dicoba:", sfxSource)
    end)
end

local okSfx, errSfx = pcall(prepareSfx)
if not okSfx then
    warn("[NemeroHub] gagal menyiapkan suara:", errSfx)
    sfxId = SFX_FALLBACK[1]
    sfxSource = "bawaan Roblox"
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
for _, n in ipairs({"NemeroHub", "NemeroHubESP", "NemeroHubIntro"}) do
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
    playSfx(0.95, 0.9)
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

local function press(btn, holder, silent)
    local s = mk("UIScale", {Scale = 1}, holder)
    if not silent then
        btn.MouseButton1Click:Connect(function() playSfx(1, 0.9) end)
    end
    btn.MouseButton1Down:Connect(function() tw(s, 0.08, {Scale = 0.94}) end)
    local function up() tw(s, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end
    btn.MouseButton1Up:Connect(up)
    btn.MouseLeave:Connect(up)
end

local function button(par, text, pos, size, c1, c2, silent)
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
    press(b, holder, silent)
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
    local b, h = button(pageB, text, UDim2.new(0, 0, 0, rowY(i)), UDim2.new(1, 0, 0, 34), rgb(42, 20, 76), rgb(78, 40, 135), true)
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
        playSfx(state and 1.3 or 0.8, 1)
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
    playSfx(isOpen and 0.85 or 1.25, 1)
    setOpen(not isOpen)
end)

------------------------------------------------------------
-- Mulai
------------------------------------------------------------
------------------------------------------------------------
-- Intro (tulisan + suara pembaca)
------------------------------------------------------------
local INTRO_TEXT = "NimeroHub"
local INTRO_SUB = "UNIVERSAL V3"
local INTRO_VOICE = true        -- false = intro tanpa suara
local INTRO_LAUGH = true        -- true = ada tawa di akhir intro
local INTRO_STATUS = false      -- true = tampilkan tulisan status suara kecil di bawah layar
local INTRO_STYLE = "anime"     -- "anime" = suara ala anime (Jepang) | "film" = suara sinematik ala film | "hacker" = gaya lama (berat & terdistorsi)
local INTRO_GENDER = "female"   -- "female" = suara perempuan | "male" = suara laki-laki
local INTRO_VOLUME = 0.8        -- volume suara intro (1 = penuh, turunkan kalau terdengar pecah)
local INTRO_LAUGH_MODE = "synth" -- "synth" = tawa buatan (manusiawi, selalu beda-beda) | "tts" = dibaca mesin

-- SUARA SENDIRI (paling natural): pakai rekaman asli, misalnya potongan suara anime/film pilihanmu.
-- Isi SALAH SATU: nama file di folder workspace executor (mp3/ogg), atau link langsung ke file mp3/ogg.
-- Kalau diisi, rekaman ini dipakai menggantikan suara mesin. Kosongkan ("") untuk pakai suara bawaan.
local INTRO_VOICE_FILE = ""    -- contoh: "suara_intro.mp3"
local INTRO_VOICE_URL  = ""    -- contoh: "https://situsmu.com/suara_intro.mp3"
local INTRO_LAUGH_FILE = ""    -- contoh: "tawa.mp3"
local INTRO_LAUGH_URL  = ""

-- Setiap bagian ucapan/tawa dibaca terpisah supaya nada, kecepatan, dan volumenya bisa diatur sendiri-sendiri:
--   t       = teks yang dibaca            speed   = kecepatan putar (juga memengaruhi nada)
--   oct     = tinggi nada tambahan        vol     = volume
--   contour = perubahan nada sepanjang bagian (+ naik / - turun, mis. 0.06 = naik 6%)
--   vib     = getaran nada (efek "bergetar" saat tertawa)
--   gap     = jeda setelah bagian ini     layer   = lapisan suara kedua yang lebih dalam (untuk tawa sinematik)
local STYLES = {
    anime = {
        lang = "ja",
        voices = {female = "Mizuki", male = "Takumi"},
        genderOct = {female = 1.0, male = 0.93},
        laughDelay = 0.30,
        tail = 0.7,
        speech = {
            {t = "ニメロ…", speed = 0.97, oct = 1.00, vol = 2.6, contour = 0.00, vib = 0.004, gap = 0.12},
            {t = "ハブ！",  speed = 1.06, oct = 1.07, vol = 3.0, contour = 0.05, vib = 0.006, gap = 0.00},
        },
        laugh = {
            {t = "ふふ…",         speed = 0.95, oct = 1.00, vol = 1.6, contour = -0.03, vib = 0.006, gap = 0.22},
            {t = "ふふふ…",       speed = 0.98, oct = 1.02, vol = 1.9, contour = 0.03,  vib = 0.008, gap = 0.14},
            {t = "あはは！",      speed = 1.05, oct = 1.06, vol = 2.6, contour = 0.05,  vib = 0.012, gap = 0.06},
            {t = "あはははは！",  speed = 1.10, oct = 1.10, vol = 3.2, contour = 0.08,  vib = 0.018, gap = 0.12},
            {t = "ふふっ…",       speed = 0.95, oct = 0.99, vol = 1.5, contour = -0.05, vib = 0.005, gap = 0.00},
        },
    },
    film = {
        lang = "en",
        voices = {female = "Amy", male = "Brian"},
        genderOct = {female = 1.12, male = 1.0},
        laughDelay = 0.60,
        tail = 1.0,
        speech = {
            {t = "Nimero...", speed = 0.92, oct = 0.92, vol = 2.6, contour = -0.02, vib = 0.004, gap = 0.32},
            {t = "Hub.",      speed = 0.90, oct = 0.88, vol = 3.0, contour = -0.04, vib = 0.004, gap = 0.00},
        },
        laugh = {
            {t = "Heh...",              speed = 0.90, oct = 0.88, vol = 1.8, contour = -0.03, vib = 0.006, gap = 0.30},
            {t = "Heh heh heh...",      speed = 0.92, oct = 0.88, vol = 2.2, contour = 0.02,  vib = 0.010, gap = 0.20},
            {t = "Ha ha ha ha!",        speed = 0.98, oct = 0.86, vol = 3.2, contour = 0.05,  vib = 0.016, gap = 0.06, layer = 0.72},
            {t = "Ha ha ha ha ha ha!",  speed = 1.02, oct = 0.84, vol = 3.8, contour = 0.07,  vib = 0.020, gap = 0.00, layer = 0.70},
        },
    },
    hacker = {   -- gaya lama: berat, bergema, terdistorsi
        lang = "en",
        voices = {female = "Brian", male = "Brian"},
        genderOct = {female = 1.0, male = 1.0},
        laughDelay = 0.0,
        tail = 1.0,
        speech = {
            {t = "Nimero... Hub.", speed = 0.97, oct = 0.93, vol = 2.5, contour = 0, vib = 0, gap = 0},
        },
        laugh = {
            {t = "Mua ha ha ha! Ha ha ha ha!", speed = 0.93, oct = 0.88, vol = 3.5, contour = 0, vib = 0, gap = 0},
        },
    },
}

-- cek apakah data benar-benar file mp3 (bukan halaman error)
local function isMp3(b)
    if type(b) ~= "string" or #b < 1000 then return false end
    if b:sub(1, 3) == "ID3" then return true end
    local b1, b2 = b:byte(1, 2)
    return b1 == 0xFF and b2 ~= nil and b2 >= 0xE0
end

local function httpBody(url)
    local req = (syn and syn.request) or http_request or request
    if req then
        local r = req({Url = url, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if r and (r.StatusCode == nil or r.StatusCode == 200) then return r.Body end
        error("HTTP " .. tostring(r and r.StatusCode), 0)
    end
    return game:HttpGet(url)
end

-- Sumber suara: StreamElements (suara Polly) dulu, kalau gagal baru Google TTS
local function voiceUrls(text, lang, voiceName)
    local enc = game:GetService("HttpService"):UrlEncode(text)
    return {
        {"streamelements", "https://api.streamelements.com/kappa/v2/speech?voice=" .. voiceName .. "&text=" .. enc},
        {"google", "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=" .. lang .. "&q=" .. enc},
    }
end

-- Unduh satu potongan suara -> simpan sebagai file -> kembalikan asset id
local function fetchClipId(text, lang, voiceName)
    local getAsset = getcustomasset or getsynasset
    if not (getAsset and writefile) then error("executor tanpa getcustomasset/writefile", 0) end
    local h = 0
    local key = text .. "|" .. voiceName
    for i = 1, #key do h = (h * 31 + key:byte(i)) % 1000000 end
    local lastErr = "-"
    for _, src in ipairs(voiceUrls(text, lang, voiceName)) do
        local ok, res = pcall(function()
            local fname = "NimeroHub_" .. src[1] .. "_" .. lang .. "_" .. voiceName .. "_" .. h .. ".mp3"
            local body
            if isfile and readfile and isfile(fname) then body = readfile(fname) end
            if not isMp3(body) then
                body = httpBody(src[2])
                assert(isMp3(body), "respon bukan mp3")
                writefile(fname, body)
            end
            return getAsset(fname)
        end)
        if ok and res then return res end
        lastErr = src[1] .. ": " .. tostring(res)
    end
    error(lastErr, 0)
end

-- Rantai efek suara per gaya. Mengembalikan efek pitch (dipakai untuk kontur nada & getaran).
local function buildFx(snd, styleName, kind)
    local function fx(class, props)
        local ok, o = pcall(function() return mk(class, props, snd) end)
        return ok and o or nil
    end
    local pitch = fx("PitchShiftSoundEffect", {Octave = 1})
    if styleName == "anime" then
        -- cerah & ringan, sedikit gema seperti ruangan studio
        fx("EqualizerSoundEffect", {LowGain = -3, MidGain = 1, HighGain = 3})
        if kind == "laugh" then
            fx("EchoSoundEffect", {Delay = 0.2, Feedback = 0.15, DryLevel = 0, WetLevel = -19})
        end
        fx("ReverbSoundEffect", {DecayTime = 1.2, Density = 0.7, Diffusion = 0.7, DryLevel = -1, WetLevel = -17})
        fx("CompressorSoundEffect", {Threshold = -20, Ratio = 3, GainMakeup = 2})
    elseif styleName == "film" then
        -- dalam, hangat, bergema seperti aula sinema
        fx("EqualizerSoundEffect", {LowGain = 4, MidGain = 1, HighGain = -2})
        if kind == "laugh" then
            fx("EchoSoundEffect", {Delay = 0.34, Feedback = 0.25, DryLevel = 0, WetLevel = -18})
        end
        fx("ReverbSoundEffect", {DecayTime = 2.0, Density = 0.9, Diffusion = 0.85, DryLevel = -1, WetLevel = -14})
        fx("CompressorSoundEffect", {Threshold = -20, Ratio = 3, GainMakeup = 2})
    else
        -- gaya lama (hacker)
        if kind == "laugh" then
            fx("EqualizerSoundEffect", {LowGain = 4, MidGain = 4, HighGain = 0})
            fx("DistortionSoundEffect", {Level = 0.05})
            fx("EchoSoundEffect", {Delay = 0.3, Feedback = 0.35, DryLevel = 0, WetLevel = -11})
            fx("ReverbSoundEffect", {DecayTime = 2.6, Density = 0.9, Diffusion = 0.8, DryLevel = -1, WetLevel = -10})
        else
            fx("EqualizerSoundEffect", {LowGain = 3, MidGain = 3, HighGain = -1})
            fx("DistortionSoundEffect", {Level = 0.07})
            fx("EchoSoundEffect", {Delay = 0.18, Feedback = 0.22, DryLevel = 0, WetLevel = -15})
            fx("ReverbSoundEffect", {DecayTime = 1.8, Density = 0.8, Diffusion = 0.7, DryLevel = -1, WetLevel = -13})
        end
        fx("CompressorSoundEffect", {Threshold = -22, Ratio = 5, GainMakeup = 5})
    end
    return pitch
end

local function clampOct(x) return math.clamp(x, 0.5, 2) end

-- Siapkan satu "pertunjukan" (ucapan atau tawa) dari daftar bagian.
-- Mengembalikan {obj, len, core, name, play} atau nil.
local function prepareAct(parts, kind, status)
    local st = STYLES[INTRO_STYLE] or STYLES.anime
    local styleName = STYLES[INTRO_STYLE] and INTRO_STYLE or "anime"
    local voiceName = st.voices[INTRO_GENDER] or st.voices.female
    local gscale = (st.genderOct and st.genderOct[INTRO_GENDER]) or 1
    local ss = SoundService

    -- unduh semua bagian secara paralel
    local ids, pending, lastErr = {}, #parts, "-"
    for i, part in ipairs(parts) do
        task.spawn(function()
            local ok, res = pcall(fetchClipId, part.t, st.lang, voiceName)
            if ok then ids[i] = res else lastErr = tostring(res) end
            pending -= 1
        end)
    end
    local t0 = os.clock()
    while pending > 0 and os.clock() - t0 < 8 do task.wait(0.05) end

    -- buat Sound + efek untuk tiap bagian yang berhasil diunduh
    local list, total = {}, 0
    for i, part in ipairs(parts) do
        local id = ids[i]
        if id then
            local s = mk("Sound", {SoundId = id, Volume = 0, PlaybackSpeed = part.speed or 1}, ss)
            local pitch = buildFx(s, styleName, kind)
            local layer, lpitch
            if part.layer then
                layer = mk("Sound", {SoundId = id, Volume = 0, PlaybackSpeed = part.speed or 1}, ss)
                lpitch = mk("PitchShiftSoundEffect", {Octave = clampOct(part.layer * gscale)}, layer)
                pcall(function()
                    mk("ReverbSoundEffect", {DecayTime = 2.8, Density = 0.9, Diffusion = 0.9, DryLevel = -2, WetLevel = -8}, layer)
                end)
            end
            local w0 = os.clock()
            while s.TimeLength == 0 and os.clock() - w0 < 2.5 do task.wait(0.05) end
            if s.TimeLength > 0 then
                local dur = s.TimeLength / s.PlaybackSpeed
                list[#list + 1] = {snd = s, pitch = pitch, layer = layer, lpitch = lpitch, dur = dur, part = part}
                total = total + dur + (part.gap or 0)
            else
                s:Destroy()
                if layer then layer:Destroy() end
            end
        end
    end
    if #list == 0 then
        if status then status("suara gagal -> " .. string.sub(lastErr, 1, 100)) end
        return nil
    end

    -- putar berurutan, dengan kontur nada + getaran supaya terdengar hidup
    local function play()
        task.spawn(function()
            for _, c in ipairs(list) do
                local p = c.part
                local baseOct = (p.oct or 1) * gscale * (1 + (math.random() - 0.5) * 0.04)   -- variasi tipis, tidak persis sama tiap putar
                local vol = (p.vol or 2.5) * INTRO_VOLUME * (0.94 + math.random() * 0.12)
                if c.pitch then c.pitch.Octave = clampOct(baseOct) end
                c.snd.Volume = vol
                c.snd:Play()
                if c.layer then
                    c.layer.Volume = vol * 0.55
                    c.layer:Play()
                end
                task.spawn(function()
                    local ts = os.clock()
                    local contour, vib = p.contour or 0, p.vib or 0
                    while os.clock() - ts < c.dur and c.snd.Parent do
                        local el = os.clock() - ts
                        local k = el / c.dur
                        local wob = vib * math.sin(el * 2 * math.pi * 6.5)
                        if c.pitch then c.pitch.Octave = clampOct(baseOct * (1 + contour * k) + wob) end
                        if c.lpitch and c.layer and c.layer.Parent then
                            c.lpitch.Octave = clampOct(p.layer * gscale * (1 + contour * k) + wob)
                        end
                        task.wait()
                    end
                end)
                task.wait(c.dur + (p.gap or 0))
            end
        end)
    end

    return {
        obj = {Destroy = function()
            for _, c in ipairs(list) do
                pcall(function() c.snd:Destroy() end)
                if c.layer then pcall(function() c.layer:Destroy() end) end
            end
        end},
        core = total,
        len = total + (st.tail or 0.8),
        name = styleName .. ":" .. voiceName,
        play = play,
    }
end

-- Cadangan: suara bawaan Roblox (kalau unduhan gagal)
local function robloxTts(text, status)
    local ss = SoundService
    local tts, out, wire
    local ok2, res2 = pcall(function()
        tts = Instance.new("AudioTextToSpeech")
        tts.Text = text
        out = Instance.new("AudioDeviceOutput")
        wire = Instance.new("Wire")
        wire.SourceInstance = tts
        wire.TargetInstance = out
        tts.Parent = ss
        out.Parent = ss
        wire.Parent = ss
        pcall(function() tts:LoadAsync() end)
        local t0 = os.clock()
        while tts.TimeLength == 0 and os.clock() - t0 < 4 do task.wait(0.05) end
        if tts.TimeLength == 0 then error("tts bawaan tidak termuat", 0) end
        return {
            obj = {Destroy = function()
                pcall(function() tts:Destroy() end)
                pcall(function() out:Destroy() end)
                pcall(function() wire:Destroy() end)
            end},
            len = tts.TimeLength,
            core = tts.TimeLength,
            name = "roblox-tts",
            play = function() tts:Play() end,
        }
    end)
    if ok2 then
        status("suara: siap (roblox-tts)")
        return res2
    end
    for _, o in ipairs({tts, out, wire}) do
        if o then pcall(function() o:Destroy() end) end
    end
    status(string.sub("suara gagal -> " .. tostring(res2), 1, 120))
    return nil
end

-- Muat rekaman sendiri (file lokal atau link). Mengembalikan act atau nil.
local function loadCustom(file, url, tag, status)
    file, url = file or "", url or ""
    if file == "" and url == "" then return nil end
    local getAsset = getcustomasset or getsynasset
    if not getAsset then return nil end
    local ok, act = pcall(function()
        local path
        if file ~= "" and isfile and isfile(file) then
            path = file
        elseif url ~= "" and writefile then
            local ext = (url:lower():match("%.(ogg)") and "ogg") or "mp3"
            local fname = "NimeroHub_custom_" .. tag .. "." .. ext
            if not (isfile and isfile(fname)) then
                local body = httpBody(url)
                assert(type(body) == "string" and #body > 1000, "file terlalu kecil / bukan audio")
                writefile(fname, body)
            end
            path = fname
        end
        if not path then error("file tidak ditemukan", 0) end
        local snd = mk("Sound", {SoundId = getAsset(path), Volume = 3 * INTRO_VOLUME}, SoundService)
        local w0 = os.clock()
        while snd.TimeLength == 0 and os.clock() - w0 < 3 do task.wait(0.05) end
        if snd.TimeLength == 0 then snd:Destroy() error("audio tidak termuat", 0) end
        return {
            obj = snd, core = snd.TimeLength, len = snd.TimeLength + 0.3,
            name = "rekaman-sendiri", play = function() snd:Play() end,
        }
    end)
    if ok and act then
        if status then status("suara: rekaman sendiri") end
        return act
    end
    if status then status("rekaman sendiri gagal: " .. string.sub(tostring(act), 1, 80)) end
    return nil
end

-- Tawa buatan: sumber suara berdenyut + filter vokal (formant) + napas, dibuat acak tiap putar
local function synthLaughWav(styleName, gender)
    local FS = 22050
    local female = (gender ~= "male")
    local f0base
    if styleName == "film" then f0base = female and 205 or 112
    elseif styleName == "hacker" then f0base = female and 170 or 92
    else f0base = female and 345 or 150 end
    local F1, F2, F3
    if female then F1, F2, F3 = 850, 1220, 2810 else F1, F2, F3 = 730, 1090, 2440 end

    local bursts = (styleName == "film" or styleName == "hacker") and 6 or 8
    local baseGap = (styleName == "film" or styleName == "hacker") and 0.25 or 0.185
    local pre = 0.16

    -- jadwal tiap "ha" (waktu mulai, panjang, nada, kekerasan) dengan sedikit acak
    local plan, tcur = {}, pre
    for i = 1, bursts do
        local gap = baseGap * (1 + (math.random() - 0.5) * 0.30)
        local dur = gap * 0.66
        if i == bursts then dur = gap * 1.9 end
        local pos = (i - 0.5) / bursts
        local amp = (0.50 + 0.50 * math.sin(math.pi * math.min(pos * 1.25, 1))) * (0.88 + math.random() * 0.24)
        local f0 = f0base * (1.13 - 0.02 * i) * (1 + (math.random() - 0.5) * 0.05)
        plan[i] = {t = tcur, dur = dur, amp = amp, f0 = f0, fshift = 1 + (math.random() - 0.5) * 0.10}
        tcur = tcur + gap
    end
    local lastB = plan[bursts]
    local total = lastB.t + lastB.dur + 0.45
    local N = math.floor(FS * total)
    local buf = {}
    for i = 1, N do buf[i] = 0 end

    local function reso(f, bw)
        local r = math.exp(-math.pi * bw / FS)
        return 2 * r * math.cos(2 * math.pi * f / FS), -r * r, (1 - r)
    end

    -- tarikan napas sebelum tertawa
    do
        local a1, a2, g = reso(1700, 900)
        local y1, y2 = 0, 0
        local n0 = math.floor(FS * pre)
        for i = 1, n0 do
            local x = (math.random() * 2 - 1) * (i / n0) * 0.35
            local y = g * x + a1 * y1 + a2 * y2
            y2, y1 = y1, y
            buf[i] = buf[i] + y * 18
        end
    end

    -- tiap "ha"
    for _, b in ipairs(plan) do
        local a11, a12, g1 = reso(F1 * b.fshift, 95)
        local a21, a22, g2 = reso(F2 * b.fshift, 120)
        local a31, a32, g3 = reso(F3 * b.fshift, 180)
        local y11, y12, y21, y22, y31, y32 = 0, 0, 0, 0, 0, 0
        local n0 = math.floor(FS * b.t) + 1
        local nb = math.floor(FS * b.dur)
        local ph, lp = math.random(), 0
        for k = 0, nb - 1 do
            local t = k / FS
            local frac = k / nb
            -- nada: turun di dalam tiap "ha" + getaran halus
            local f = b.f0 * (1.08 - 0.14 * frac) * (1 + 0.012 * math.sin(2 * math.pi * 5.8 * (b.t + t)))
            ph = (ph + f / FS) % 1
            local saw = 1 - 2 * ph
            lp = lp + 0.40 * (saw - lp)
            local env = math.min(1, t / 0.012) * math.exp(-t / (b.dur * 0.62)) * math.min(1, (b.dur - t) / 0.02)
            if env < 0 then env = 0 end
            local breath = (math.random() * 2 - 1) * 0.55 * math.exp(-t / 0.035)   -- hembusan "h"
            local x = lp * env + breath * 0.9
            local yy1 = g1 * x + a11 * y11 + a12 * y12; y12, y11 = y11, yy1
            local yy2 = g2 * x + a21 * y21 + a22 * y22; y22, y21 = y21, yy2
            local yy3 = g3 * x + a31 * y31 + a32 * y32; y32, y31 = y31, yy3
            local out = (yy1 + 0.62 * yy2 + 0.30 * yy3) * b.amp
            local idx = n0 + k
            if idx >= 1 and idx <= N then buf[idx] = buf[idx] + out * 26 end
        end
    end

    -- hembusan napas di akhir
    do
        local a1, a2, g = reso(1400, 1000)
        local y1, y2 = 0, 0
        local n0 = math.floor(FS * (lastB.t + lastB.dur))
        local n1 = N - n0
        for k = 1, n1 do
            local env = math.exp(-k / (FS * 0.16))
            local x = (math.random() * 2 - 1) * env * 0.22
            local y = g * x + a1 * y1 + a2 * y2
            y2, y1 = y1, y
            if n0 + k <= N then buf[n0 + k] = buf[n0 + k] + y * 14 end
        end
    end

    return encodeWav(buf, N, FS, 0.9)
end

local function prepareSynthLaugh()
    local getAsset = getcustomasset or getsynasset
    if not (getAsset and writefile) then error("executor tanpa getcustomasset/writefile", 0) end
    local styleName = STYLES[INTRO_STYLE] and INTRO_STYLE or "anime"
    local data = synthLaughWav(styleName, INTRO_GENDER)
    local fname = "NimeroHub_laugh_" .. styleName .. "_" .. tostring(os.time()) .. tostring(math.random(100, 999)) .. ".wav"
    writefile(fname, data)
    local snd = mk("Sound", {SoundId = getAsset(fname), Volume = 3.2 * INTRO_VOLUME, PlaybackSpeed = 1}, SoundService)
    -- efek ringan saja (ruangan), supaya tetap terdengar seperti orang sungguhan
    pcall(function()
        mk("EqualizerSoundEffect", {LowGain = -2, MidGain = 1, HighGain = 2}, snd)
        mk("ReverbSoundEffect", {DecayTime = styleName == "film" and 2.0 or 1.2, Density = 0.8, Diffusion = 0.8, DryLevel = -1, WetLevel = -14}, snd)
    end)
    local w0 = os.clock()
    while snd.TimeLength == 0 and os.clock() - w0 < 3 do task.wait(0.05) end
    if snd.TimeLength == 0 then snd:Destroy() error("tawa buatan tidak termuat", 0) end
    return {
        obj = snd, core = snd.TimeLength, len = snd.TimeLength + 0.5,
        name = "tawa-buatan", play = function() snd:Play() end,
    }
end

local function prepareSpeech(status)
    status("suara: mengunduh...")
    local custom = loadCustom(INTRO_VOICE_FILE, INTRO_VOICE_URL, "voice", status)
    if custom then return custom end
    local st = STYLES[INTRO_STYLE] or STYLES.anime
    local act = prepareAct(st.speech, "speech", status)
    if act then
        status("suara: siap (" .. act.name .. ")")
        return act
    end
    return robloxTts("Nimero Hub", status)
end

local function prepareLaugh()
    local custom = loadCustom(INTRO_LAUGH_FILE, INTRO_LAUGH_URL, "laugh", nil)
    if custom then return custom end
    if INTRO_LAUGH_MODE == "synth" then
        local ok, act = pcall(prepareSynthLaugh)
        if ok and act then return act end
    end
    local st = STYLES[INTRO_STYLE] or STYLES.anime
    return prepareAct(st.laugh, "laugh", nil)
end

local function runIntro()
    local ig = mk("ScreenGui", {
        Name = "NemeroHubIntro", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)
    pcall(function() ig.ScreenInsets = Enum.ScreenInsets.None end)  -- tutup seluruh layar (termasuk sisi poni)

    local root = mk("CanvasGroup", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        GroupTransparency = 1, BorderSizePixel = 0,
    }, ig)
    local bgF = mk("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.white,
        BorderSizePixel = 0, Active = true,   -- Active: sentuhan tidak tembus ke game
    }, root)
    grad(bgF, rgb(26, 12, 50), rgb(5, 3, 12), 90)
    tw(root, 0.4, {GroupTransparency = 0})

    -- Tulisan status suara (kecil, di bawah)
    local statusLbl = mk("TextLabel", {
        Size = UDim2.new(0.8, 0, 0, 30),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -12),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.lilac,
        TextTransparency = 0.35,
        TextWrapped = true,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Visible = INTRO_STATUS,
    }, root)
    local function setStatus(txt)
        if statusLbl.Parent then statusLbl.Text = txt end
    end

    -- Suara (disiapkan paralel, diputar saat tulisan mulai mengetik)
    local voice, voiceDone, started = nil, not INTRO_VOICE, false
    if INTRO_VOICE then
        task.spawn(function()
            local ok, res = pcall(prepareSpeech, setStatus)
            if ok then voice = res else setStatus("suara error: " .. string.sub(tostring(res), 1, 90)) end
            voiceDone = true
            if started and voice then
                pcall(function() voice.obj:Destroy() end)  -- terlambat, intro sudah jalan
                voice = nil
            end
        end)
    end

    -- Tawa seram (disiapkan paralel, diputar di akhir intro)
    local laugh, laughDone, ended = nil, not (INTRO_VOICE and INTRO_LAUGH), false
    if INTRO_VOICE and INTRO_LAUGH then
        task.spawn(function()
            local ok, res = pcall(prepareLaugh)
            if ok then laugh = res end
            laughDone = true
            if ended and laugh then pcall(function() laugh.obj:Destroy() end) end
        end)
    end

    -- Gelembung naik memenuhi layar
    local bl = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, root)
    for i = 1, 16 do
        task.spawn(function()
            task.wait(math.random() * 2.5)
            if not bl.Parent then return end
            local s = math.random(10, 42)
            local x = math.random(4, 96) / 100
            local dur = math.random(30, 55) / 10
            local b = mk("Frame", {
                Size = UDim2.fromOffset(s, s),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(x, 0, 1, s),
                BackgroundColor3 = (i % 2 == 0) and rgb(170, 120, 255) or rgb(80, 255, 165),
                BackgroundTransparency = 0.6,
                BorderSizePixel = 0,
            }, bl)
            round(b)
            local bs = stroke(b, C.white, 1.2, 0.45)
            local sh = mk("Frame", {
                Size = UDim2.fromScale(0.28, 0.28), Position = UDim2.fromScale(0.2, 0.17),
                BackgroundColor3 = C.white, BackgroundTransparency = 0.35, BorderSizePixel = 0,
            }, b)
            round(sh)
            tw(bs, dur, {Transparency = 1}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(sh, dur, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(b, dur, {
                Position = UDim2.new(x, math.random(-40, 40), 0, -s),
                BackgroundTransparency = 1,
            }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            Debris:AddItem(b, dur + 0.2)
        end)
    end

    -- Bagian tengah
    local center = mk("Frame", {
        Size = UDim2.fromOffset(320, 240),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
    }, root)

    local logo = mk("Frame", {
        Size = UDim2.fromOffset(84, 84),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0,
    }, center)
    round(logo)
    grad(logo, rgb(28, 12, 58), rgb(72, 32, 135), 45)
    local ls = stroke(logo, C.white, 3, 0)
    local lg = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.purple),
            ColorSequenceKeypoint.new(0.5, C.green),
            ColorSequenceKeypoint.new(1, C.purple),
        }),
    }, ls)
    TweenService:Create(lg, TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360}):Play()
    local ln = mk("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "N",
        TextColor3 = C.white, Font = Enum.Font.GothamBlack, TextSize = 46,
    }, logo)
    mk("UIGradient", {Color = ColorSequence.new(rgb(200, 150, 255), rgb(90, 255, 170)), Rotation = 45}, ln)
    local logoScale = mk("UIScale", {Scale = 0}, logo)
    tw(logoScale, 0.7, {Scale = 1}, Enum.EasingStyle.Back)

    local ring = mk("Frame", {
        Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1,
    }, logo)
    round(ring)
    local rs = stroke(ring, C.green, 2, 0.3)
    TweenService:Create(ring, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {Size = UDim2.fromScale(1.5, 1.5)}):Play()
    TweenService:Create(rs, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1), {Transparency = 1}):Play()

    -- Tulisan utama (mengetik satu per satu)
    local t = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 52),
        Position = UDim2.new(0, 0, 0, 120),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = C.white,
        Font = Enum.Font.GothamBlack,
        TextSize = 40,
    }, center)
    local tg = mk("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(190, 140, 255)),
            ColorSequenceKeypoint.new(0.5, rgb(90, 255, 170)),
            ColorSequenceKeypoint.new(1, rgb(190, 140, 255)),
        }),
        Offset = Vector2.new(-0.4, 0),
    }, t)
    TweenService:Create(tg, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0.4, 0)}):Play()
    local tScale = mk("UIScale", {Scale = 1}, t)

    local sub = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 174),
        BackgroundTransparency = 1,
        Text = INTRO_SUB,
        TextColor3 = C.lilac,
        TextTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
    }, center)

    -- Bar loading
    local track = mk("Frame", {
        Size = UDim2.fromOffset(220, 6),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 212),
        BackgroundColor3 = rgb(40, 22, 70),
        BorderSizePixel = 0,
    }, center)
    round(track)
    local fill = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.white, BorderSizePixel = 0}, track)
    round(fill)
    mk("UIGradient", {Color = ColorSequence.new(C.purple, C.green)}, fill)

    -- Tunggu suara siap (maksimal 4 detik) supaya suara & tulisan mulai bersamaan
    task.wait(0.6)
    local w0 = os.clock()
    while not voiceDone and os.clock() - w0 < 6 do task.wait(0.05) end
    started = true
    local voiceEnd = os.clock()
    local voiceStart = os.clock()
    if voice then
        pcall(voice.play)
        voiceStart = os.clock()
        voiceEnd = voiceStart + voice.len
    end

    tw(fill, 3.6, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Linear)
    for i = 1, #INTRO_TEXT do
        t.Text = string.sub(INTRO_TEXT, 1, i)
        task.wait(0.11)
    end
    tScale.Scale = 1.18
    tw(tScale, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
    tw(sub, 0.5, {TextTransparency = 0})

    -- Begitu selesai membaca, langsung tertawa (judul ikut bergetar)
    local l0 = os.clock()
    while not laughDone and os.clock() - l0 < 6 do task.wait(0.05) end
    if voice then
        local gap = voiceStart + voice.core - os.clock()
        if gap > 0 then task.wait(gap) end
    end
    if laugh then
        local stl = STYLES[INTRO_STYLE] or STYLES.anime
        if (stl.laughDelay or 0) > 0 then task.wait(stl.laughDelay) end   -- jeda dramatis sebelum tertawa
        pcall(laugh.play)
        local tEnd = os.clock() + laugh.len * 0.7
        while os.clock() < tEnd do
            t.Position = UDim2.new(0, math.random(-5, 5), 0, 120 + math.random(-3, 3))
            task.wait(0.04)
        end
        t.Position = UDim2.new(0, 0, 0, 120)
        task.wait(math.max(laugh.len * 0.3 + 0.3, 0.3))
        pcall(function() laugh.obj:Destroy() end)
    elseif voice then
        task.wait(math.max(voiceEnd - os.clock() + 0.2, 0.5))   -- tanpa tawa: tunggu ekor suara selesai
    end
    if voice then pcall(function() voice.obj:Destroy() end) end

    -- Keluar
    tw(root, 0.5, {GroupTransparency = 1})
    task.wait(0.55)
    ended = true
    ig:Destroy()
end

applyMode(false)
espRefresh()
main.Visible = false
isOpen = false
bubbleF.Visible = false
task.spawn(function()
    pcall(runIntro)   -- kalau intro error, menu tetap muncul
    bubbleF.Visible = true
    setOpen(true)
end)

G.NemeroHubCleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    stopFly()
    pcall(function() gui:Destroy() end)
    pcall(function() espRoot:Destroy() end)
    pcall(function() local ii = parent:FindFirstChild("NemeroHubIntro"); if ii then ii:Destroy() end end)
end
