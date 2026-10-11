--[[
    ██████╗     ██╗
    ██╔══██╗    ██║
    ██║  ██║    ██║
    ██║  ██║██   ██║
    ╚██████╔╝╚█████╔╝
     ╚═════╝  ╚════╝
    STEAL A EGG | CUSTOM BUILD
    Author : CJ
    Build  : v1.1
    Changelog :
      - Fly Mode (Steal / Fast / Blatant)
      - Anti-Detect Developer
      - Fast Return ke Base
      - Anti-Crash Guard
      - Humanize Movement
--]]

--============================================================
-- SERVICES
--============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")
local Stats             = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--============================================================
-- CONFIG
--============================================================
local Config = {
    -- Auto Steal
    AutoSteal           = false,
    StealDelay          = 0.12,
    StealRange          = 600,
    ReturnToPlot        = true,
    ReturnMethod        = "Plot Center",

    -- FLY
    FlySteal            = false,
    FlySpeed            = 120,
    FlyMode             = "Stealth", -- Stealth / Fast / Blatant
    FlyHeight           = 6,

    -- Anti-Detect
    AntiDetect          = true,
    HumanizeMove        = true,
    RandomJitter        = true,
    AdminGuard          = true,
    DevList             = {},

    -- Auto Place / Hatch / Sell
    AutoPlace           = false,
    PlaceDelay          = 0.2,
    AutoHatch           = false,
    HatchDelay          = 0.3,
    AutoSell            = false,
    SellDelay           = 0.5,

    -- Player
    AntiAFK             = true,
    AntiRagdoll         = true,
    WalkSpeed           = 16,
    JumpPower           = 50,
    InfiniteJump        = false,
    NoClip              = false,

    -- ESP
    EggESP              = false,
    PlayerESP           = false,

    -- Perf
    FPSGuard            = true,
}

--============================================================
-- STATE
--============================================================
local State = {
    Connections = {},
    EggCache    = {},
    PlotPos     = nil,
    LastPos     = nil,
    Running     = true,
    FlyBV       = nil,
    FlyBG       = nil,
    AdminInGame = false,
    LastSteal   = 0,
}

--============================================================
-- HELPER
--============================================================
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = duration or 3,
        })
    end)
end

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function randFloat(a, b)
    return a + math.random() * (b - a)
end

--============================================================
-- FLY CORE (pakai BodyVelocity + BodyGyro)
--============================================================
local Fly = {}
Fly.Keys = {W = false, A = false, S = false, D = false, Space = false, Shift = false}

function Fly.Start()
    local hrp = getHRP()
    if not hrp or State.FlyBV then return end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "CJ_FlyBV"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "CJ_FlyBG"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 3000
    bg.D = 100
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    State.FlyBV = bv
    State.FlyBG = bg
end

function Fly.Stop()
    if State.FlyBV then State.FlyBV:Destroy() State.FlyBV = nil end
    if State.FlyBG then State.FlyBG:Destroy() State.FlyBG = nil end
end

function Fly.Update()
    if not State.FlyBV or not State.FlyBG then return end
    local hrp = getHRP()
    local cam = Camera
    if not hrp then return end

    local move = Vector3.zero
    local look = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector

    if Fly.Keys.W then move = move + look end
    if Fly.Keys.S then move = move - look end
    if Fly.Keys.A then move = move - right end
    if Fly.Keys.D then move = move + right end
    if Fly.Keys.Space then move = move + Vector3.new(0, 1, 0) end
    if Fly.Keys.Shift then move = move - Vector3.new(0, 1, 0) end

    -- jitter anti-detect
    if Config.AntiDetect and Config.RandomJitter then
        local j = randFloat(-2, 2)
        move = move + Vector3.new(j, j * 0.5, j)
    end

    local speed = Config.FlySpeed
    if move.Magnitude > 0 then
        State.FlyBV.Velocity = move.Unit * speed
    else
        State.FlyBV.Velocity = Vector3.zero
    end

    State.FlyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
end

-- keyboard binding fly
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then Fly.Keys.W = true end
    if input.KeyCode == Enum.KeyCode.A then Fly.Keys.A = true end
    if input.KeyCode == Enum.KeyCode.S then Fly.Keys.S = true end
    if input.KeyCode == Enum.KeyCode.D then Fly.Keys.D = true end
    if input.KeyCode == Enum.KeyCode.Space then Fly.Keys.Space = true end
    if input.KeyCode == Enum.KeyCode.LeftShift then Fly.Keys.Shift = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then Fly.Keys.W = false end
    if input.KeyCode == Enum.KeyCode.A then Fly.Keys.A = false end
    if input.KeyCode == Enum.KeyCode.S then Fly.Keys.S = false end
    if input.KeyCode == Enum.KeyCode.D then Fly.Keys.D = false end
    if input.KeyCode == Enum.KeyCode.Space then Fly.Keys.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then Fly.Keys.Shift = false end
end)

-- fly loop
RunService.RenderStepped:Connect(function()
    if Config.FlySteal then
        Fly.Start()
        Fly.Update()
    else
        Fly.Stop()
    end
end)

--============================================================
-- ANTI-DETECT
--============================================================
local function scanAdmins()
    if not Config.AdminGuard then return end
    State.DevList = {}

    local suspects = {
        "Creator", "Developer", "Admin", "Moderator", "Owner",
        "Dev", "Staff", "Mod", "Test", "Tester",
    }

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local nm = string.lower(plr.Name)
        local dn = string.lower(plr.DisplayName or "")

        -- cek nama
        for _, s in ipairs(suspects) do
            if string.find(nm, string.lower(s)) or string.find(dn, string.lower(s)) then
                table.insert(State.DevList, plr.Name)
            end
        end

        -- cek badge / role di profile
        pcall(function()
            local rank = plr:GetRankInGroup(game.CreatorId)
            if rank >= 200 then
                table.insert(State.DevList, plr.Name)
            end
        end)
    end

    State.AdminInGame = #State.DevList > 0

    -- kalau ada admin, matiin auto steal + fly sementara
    if State.AdminInGame and Config.AntiDetect then
        notify("Anti-Detect", "⚠️ Admin/Dev terdeteksi! Auto pause.", 3)
    end
end

task.spawn(function()
    while State.Running do
        scanAdmins()
        task.wait(8)
    end
end)

--============================================================
-- AUTO STEAL CORE (dengan Fly integration)
--============================================================
local function findEggs()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not obj:IsA("Model") and not obj:IsA("Tool") and not obj:IsA("BasePart") then
            continue
        end
        local name = string.lower(obj.Name)
        if string.find(name, "egg") and not string.find(name, "eggplot") then
            local primary = obj:IsA("BasePart") and obj or obj.PrimaryPart
            if primary then
                table.insert(list, { obj = obj, part = primary })
            end
        end
    end
    return list
end

local function stealEgg(eggData)
    local hrp = getHRP()
    if not hrp or not eggData or not eggData.part then return false end

    State.LastPos = hrp.CFrame

    -- Fly ke telur (bukan teleport) supaya lebih natural
    if Config.FlySteal then
        local target = eggData.part.Position + Vector3.new(0, Config.FlyHeight, 0)
        local dist = (target - hrp.Position).Magnitude
        local t = math.clamp(dist / Config.FlySpeed, 0.05, 0.5)
        local start = hrp.Position
        local t0 = tick()

        -- tween manual pakai BodyVelocity
        while tick() - t0 < t do
            local alpha = (tick() - t0) / t
            local pos = start:Lerp(target, alpha)
            if State.FlyBV then
                State.FlyBV.Velocity = (pos - hrp.Position) * 15
            end
            RunService.RenderStepped:Wait()
            if (hrp.Position - target).Magnitude < 3 then break end
        end
    else
        -- fallback teleport (mode Blatant)
        hrp.CFrame = CFrame.new(eggData.part.Position + Vector3.new(0, 3, 0))
        task.wait(0.03)
    end

    -- fire prompt
    local prompt = eggData.obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        return true
    end

    -- fallback VirtualUser
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        VirtualUser:Button1Up(Vector2.new(0, 0))
    end)
    return true
end

local function fastReturn()
    if not Config.ReturnToPlot then return end
    local hrp = getHRP()
    if not hrp then return end

    local target = State.PlotPos or (State.LastPos and State.LastPos.Position)
    if not target then return end

    if Config.FlySteal then
        -- balik pakai fly boost (cepet)
        local t0 = tick()
        while (hrp.Position - target).Magnitude > 5 and tick() - t0 < 3 do
            if State.FlyBV then
                State.FlyBV.Velocity = (target - hrp.Position).Unit * (Config.FlySpeed * 1.5)
            end
            RunService.RenderStepped:Wait()
        end
        if State.FlyBV then State.FlyBV.Velocity = Vector3.zero end
    else
        hrp.CFrame = CFrame.new(target + Vector3.new(0, 3, 0))
    end
end

-- main steal loop
task.spawn(function()
    while State.Running do
        if Config.AutoSteal and not (Config.AntiDetect and State.AdminInGame) then
            local eggs = findEggs()
            local hrp = getHRP()

            if hrp then
                table.sort(eggs, function(a, b)
                    return (a.part.Position - hrp.Position).Magnitude
                        < (b.part.Position - hrp.Position).Magnitude
                end)
            end

            for _, egg in ipairs(eggs) do
                if not Config.AutoSteal then break end
                if Config.AntiDetect and State.AdminInGame then break end

                local hrp2 = getHRP()
                if hrp2 and (egg.part.Position - hrp2.Position).Magnitude <= Config.StealRange then
                    -- humanize delay biar gak keliatan robot
                    local delay = Config.StealDelay
                    if Config.AntiDetect and Config.HumanizeMove then
                        delay = delay + randFloat(0.02, 0.08)
                    end
                    stealEgg(egg)
                    task.wait(delay)
                end
            end

            fastReturn()
            task.wait(0.08)
        else
            task.wait(0.3)
        end
    end
end)

--============================================================
-- AUTO PLACE / HATCH / SELL
--============================================================
task.spawn(function()
    while State.Running do
        if Config.AutoPlace and not (Config.AntiDetect and State.AdminInGame) then
            pcall(function()
                local plot = Workspace:FindFirstChild(LocalPlayer.Name .. "Plot")
                    or Workspace:FindFirstChild(LocalPlayer.Name .. "'s Plot")
                if plot then
                    local p = plot:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then fireproximityprompt(p) end
                end
            end)
            task.wait(Config.PlaceDelay)
        else task.wait(0.3) end
    end
end)

task.spawn(function()
    while State.Running do
        if Config.AutoHatch and not (Config.AntiDetect and State.AdminInGame) then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt")
                        and string.find(string.lower(obj.ActionText or ""), "hatch") then
                        fireproximityprompt(obj)
                        task.wait(0.05)
                    end
                end
            end)
            task.wait(Config.HatchDelay)
        else task.wait(0.3) end
    end
end)

task.spawn(function()
    while State.Running do
        if Config.AutoSell and not (Config.AntiDetect and State.AdminInGame) then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt")
                        and string.find(string.lower(obj.ActionText or ""), "sell") then
                        fireproximityprompt(obj)
                        task.wait(0.05)
                    end
                end
            end)
            task.wait(Config.SellDelay)
        else task.wait(0.3) end
    end
end)

--============================================================
-- ANTI AFK / RAGDOLL
--============================================================
if Config.AntiAFK then
    table.insert(State.Connections, LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0))
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0, 0))
        end)
    end))
end

task.spawn(function()
    while State.Running do
        if Config.AntiRagdoll then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.PlatformStand then hum.PlatformStand = false end
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("BallSocketConstraint") then obj.Enabled = false end
                end
            end
        end
        task.wait(0.3)
    end
end)

--============================================================
-- SPEED / JUMP / NOCLIP / INF JUMP
--============================================================
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        if hum.WalkSpeed ~= Config.WalkSpeed then hum.WalkSpeed = Config.WalkSpeed end
        if hum.JumpPower ~= Config.JumpPower then
            hum.JumpPower = Config.JumpPower
            hum.UseJumpPower = true
        end
    end
end)

table.insert(State.Connections, UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

RunService.Stepped:Connect(function()
    if Config.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
end)

--============================================================
-- ESP
--============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "CJ_ESP"
ESPFolder.Parent = CoreGui

local function createESP(target, color, text)
    local box = Instance.new("BillboardGui")
    box.Name = "CJ_ESP_" .. target.Name
    box.Adornee = target
    box.Size = UDim2.new(0, 100, 0, 40)
    box.AlwaysOnTop = true
    box.Parent = ESPFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text or target.Name
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = box
    return box
end

task.spawn(function()
    while State.Running do
        for _, c in ipairs(ESPFolder:GetChildren()) do c:Destroy() end
        if Config.EggESP then
            for _, egg in ipairs(findEggs()) do
                createESP(egg.part, Color3.fromRGB(255, 215, 0), "🥚 " .. egg.obj.Name)
            end
        end
        if Config.PlayerESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local color = Color3.fromRGB(255, 80, 80)
                        for _, dev in ipairs(State.DevList) do
                            if dev == plr.Name then
                                color = Color3.fromRGB(255, 0, 0)
                            end
                        end
                        createESP(hrp, color, "👤 " .. plr.Name)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

--============================================================
-- PLOT POSITION
--============================================================
task.spawn(function()
    while State.Running do
        pcall(function()
            local plot = Workspace:FindFirstChild(LocalPlayer.Name .. "Plot")
                or Workspace:FindFirstChild(LocalPlayer.Name .. "'s Plot")
            if plot then
                local base = plot:FindFirstChild("Spawn")
                    or plot:FindFirstChild("Base")
                    or plot.PrimaryPart
                if base then
                    State.PlotPos = base.Position + Vector3.new(0, 5, 0)
                end
            end
        end)
        task.wait(2)
    end
end)

--============================================================
-- FPS GUARD
--============================================================
task.spawn(function()
    while State.Running do
        if Config.FPSGuard then
            local fps = Stats.FrameRateManager and Stats.FrameRateManager:GetFPS() or 60
            if fps < 20 then
                pcall(function()
                    for _, v in ipairs(Workspace:GetDescendants()) do
                        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                            v.Enabled = false
                        end
                    end
                end)
            end
        end
        task.wait(5)
    end
end)

--============================================================
-- UI
--============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CJ_StealAEgg_v11"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 340, 0, 480)
Main.Position = UDim2.new(0, 20, 0, 80)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MC = Instance.new("UICorner")
MC.CornerRadius = UDim.new(0, 10)
MC.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Title.BorderSizePixel = 0
Title.Text = "🥚 STEAL A EGG | CJ v1.1"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Main

local TC = Instance.new("UICorner")
TC.CornerRadius = UDim.new(0, 10)
TC.Parent = Title

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -60)
Scroll.Position = UDim2.new(0, 10, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Scroll

local function makeToggle(text, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 34)
    btn.BackgroundColor3 = Config[key] and Color3.fromRGB(40, 90, 60) or Color3.fromRGB(30, 30, 40)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. text .. " : " .. tostring(Config[key])
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Scroll

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        btn.Text = "  " .. text .. " : " .. tostring(Config[key])
        btn.BackgroundColor3 = Config[key]
            and Color3.fromRGB(40, 90, 60)
            or Color3.fromRGB(30, 30, 40)
    end)
end

local function makeSlider(text, key, min, max)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 50)
    holder.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    holder.BorderSizePixel = 0
    holder.Parent = Scroll

    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 6)
    hc.Parent = holder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. " : " .. tostring(Config[key])
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar.BorderSizePixel = 0
    bar.Parent = holder

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 4)
    fc.Parent = fill

    local dragging = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + (max - min) * rel)
            Config[key] = val
            label.Text = text .. " : " .. tostring(val)
        end
    end)
end

local function makeSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. text .. " ──"
    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Scroll
end

-- BUILD UI
makeSection("⚡ STEAL")
makeToggle("Auto Steal", "AutoSteal")
makeToggle("Fly Mode Steal", "FlySteal")
makeSlider("Fly Speed", "FlySpeed", 30, 400)
makeSlider("Steal Delay", "StealDelay", 0, 2)
makeSlider("Steal Range", "StealRange", 50, 2000)
makeToggle("Return To Plot", "ReturnToPlot")

makeSection("🛡️ ANTI-DETECT")
makeToggle("Anti Detect", "AntiDetect")
makeToggle("Humanize Move", "HumanizeMove")
makeToggle("Random Jitter", "RandomJitter")
makeToggle("Admin Guard", "AdminGuard")

makeSection("🏠 AUTO")
makeToggle("Auto Place", "AutoPlace")
makeToggle("Auto Hatch", "AutoHatch")
makeToggle("Auto Sell", "AutoSell")

makeSection("🏃 PLAYER")
makeToggle("Anti AFK", "AntiAFK")
makeToggle("Anti Ragdoll", "AntiRagdoll")
makeToggle("Infinite Jump", "InfiniteJump")
makeToggle("NoClip", "NoClip")
makeSlider("WalkSpeed", "WalkSpeed", 16, 200)
makeSlider("JumpPower", "JumpPower", 50, 300)

makeSection("👁️ VISUAL")
makeToggle("Egg ESP", "EggESP")
makeToggle("Player ESP", "PlayerESP")
makeToggle("FPS Guard", "FPSGuard")

--============================================================
-- CLEANUP
--============================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    State.PlotPos = nil
    if State.FlyBV then State.FlyBV:Destroy() State.FlyBV = nil end
    if State.FlyBG then State.FlyBG:Destroy() State.FlyBG = nil end
end)

notify("CJ Build v1.1", "Fly + Anti-Detect aktif. Gas lek. ☠️", 4)
