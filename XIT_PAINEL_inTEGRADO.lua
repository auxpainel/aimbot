
-- Combined Panel + Functionality Script
-- Integrates features from script.lua into the floating panel (base.lua) UI.
-- Self-contained. No external dependencies. Paste into a LocalScript in StarterPlayerScripts or execute via executor.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- =======================
-- State variables (from script.lua)
-- =======================
local AimbotEnabled = false
local TeamCheck = true
local WallCheck = true
local FOVRadius = 100
local ESPEnabled = false
local ESPTeamCheck = true
local HighlightColor = Color3.fromRGB(255, 0, 0)
local FOVRainbow = false
local FOVColor = Color3.fromRGB(0, 255, 0)
local FPSUnlockerEnabled = false

-- For Visual tab
local SlowMotionEnabled = false
local PvPSkyEnabled = false

-- Keep originals to restore
local OriginalAmbient = Lighting.Ambient
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient
local OriginalBrightness = Lighting.Brightness
local OriginalClockTime = Lighting.ClockTime
local OriginalSky = Lighting:FindFirstChildOfClass("Sky")

-- Containers for dynamic objects
local StarsGui = nil

-- =======================
-- Screen GUI / Draw layers
-- =======================
local gui = Instance.new("ScreenGui")
gui.Name = "ModMenu_Combined_GUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Draw container for 2D elements like lines, boxes, FOV circle, stats
local drawContainer = Instance.new("Frame")
drawContainer.Name = "DrawContainer"
drawContainer.Size = UDim2.new(1,0,1,0)
drawContainer.BackgroundTransparency = 1
drawContainer.ZIndex = 50
drawContainer.Parent = gui

-- FOV Circle (Frame with stroke + corner)
local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOV"
FOVFrame.Parent = drawContainer
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false

local UIStroke = Instance.new("UIStroke", FOVFrame)
UIStroke.Thickness = 2
UIStroke.Color = FOVColor

local UICorner = Instance.new("UICorner", FOVFrame)
UICorner.CornerRadius = UDim.new(1,0)

-- FPS & Ping display
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Parent = drawContainer
StatsLabel.Size = UDim2.new(0, 200, 0, 50)
StatsLabel.Position = UDim2.new(1, -210, 0, 10)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.new(1,1,1)
StatsLabel.TextStrokeTransparency = 0
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextSize = 18
StatsLabel.TextXAlignment = Enum.TextXAlignment.Right
StatsLabel.ZIndex = 100

local lastUpdate = tick()
RunService.RenderStepped:Connect(function()
    -- FPS calculation (safely)
    local fps = math.floor(1 / math.max(0.0001, RunService.RenderStepped:Wait()))
    if tick() - lastUpdate >= 0.3 then
        local ping = 0
        pcall(function()
            local dataPing = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
            ping = tonumber(string.match(dataPing, "%d+")) or 0
        end)
        StatsLabel.Text = "FPS: " .. fps .. " | Ping: " .. tostring(ping) .. "ms"
        lastUpdate = tick()
    end
end)

-- =======================
-- Floating Panel (based on base.lua UI)
-- =======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModMenuGuiMain"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local rootFrame = Instance.new("Frame")
rootFrame.Size = UDim2.new(0, 360, 0, 360)
rootFrame.Position = UDim2.new(0, 20, 0, 20)
rootFrame.BackgroundColor3 = Color3.fromRGB(12,12,14)
rootFrame.BorderSizePixel = 0
rootFrame.Active = true
rootFrame.Draggable = true
rootFrame.Parent = screenGui
Instance.new("UICorner", rootFrame).CornerRadius = UDim.new(0,12)
local uiStroke = Instance.new("UIStroke", rootFrame); uiStroke.Color = Color3.fromRGB(30,30,30); uiStroke.Transparency = 0.7

-- header
local header = Instance.new("Frame", rootFrame)
header.Size = UDim2.new(1,0,0,48)
header.BackgroundTransparency = 1
local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -120, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "XIT PAINEL - INTEGRADO"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(235,235,235)
title.Font = Enum.Font.GothamBold
title.TextSize = 15

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.new(0, 36, 0, 26)
minimizeBtn.Position = UDim2.new(1, -48, 0, 10)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
minimizeBtn.TextColor3 = Color3.fromRGB(235,235,235)
minimizeBtn.Text = "—"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,8)

-- body
local body = Instance.new("Frame", rootFrame)
body.Size = UDim2.new(1,0,1,-48)
body.Position = UDim2.new(0,0,0,48)
body.BackgroundTransparency = 1

local sidebar = Instance.new("Frame", body)
sidebar.Size = UDim2.new(0,120,1,0)
sidebar.Position = UDim2.new(0,0,0,0)
sidebar.BackgroundColor3 = Color3.fromRGB(18,18,18)
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,8)

local content = Instance.new("Frame", body)
content.Size = UDim2.new(1,-120,1,0)
content.Position = UDim2.new(0,120,0,0)
content.BackgroundTransparency = 1

-- tabs buttons
local function makeSideButton(text, posY)
    local b = Instance.new("TextButton", sidebar)
    b.Size = UDim2.new(1,-12,0,36)
    b.Position = UDim2.new(0,6,0,posY)
    b.BackgroundColor3 = Color3.fromRGB(15,15,15)
    b.TextColor3 = Color3.fromRGB(210,210,210)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Text = text
    b.AutoButtonColor = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

local btnESP = makeSideButton("ESP", 12)
local btnAimbot = makeSideButton("Aimbot", 58)
local btnVisual = makeSideButton("Visual", 104)
local btnOptim = makeSideButton("Otimização", 150)

local frameESP = Instance.new("Frame", content)
frameESP.Size = UDim2.new(1,0,1,0)
frameESP.BackgroundTransparency = 1

local frameAimbot = Instance.new("Frame", content)
frameAimbot.Size = UDim2.new(1,0,1,0)
frameAimbot.BackgroundTransparency = 1
frameAimbot.Visible = false

local frameVisual = Instance.new("Frame", content)
frameVisual.Size = UDim2.new(1,0,1,0)
frameVisual.BackgroundTransparency = 1
frameVisual.Visible = false

local frameOptim = Instance.new("Frame", content)
frameOptim.Size = UDim2.new(1,0,1,0)
frameOptim.BackgroundTransparency = 1
frameOptim.Visible = false

local function showTab(name)
    frameESP.Visible = (name == "ESP")
    frameAimbot.Visible = (name == "Aimbot")
    frameVisual.Visible = (name == "Visual")
    frameOptim.Visible = (name == "Otimização")
    btnESP.BackgroundColor3 = (name=="ESP") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnAimbot.BackgroundColor3 = (name=="Aimbot") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnVisual.BackgroundColor3 = (name=="Visual") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnOptim.BackgroundColor3 = (name=="Otimização") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
end

btnESP.MouseButton1Click:Connect(function() showTab("ESP") end)
btnAimbot.MouseButton1Click:Connect(function() showTab("Aimbot") end)
btnVisual.MouseButton1Click:Connect(function() showTab("Visual") end)
btnOptim.MouseButton1Click:Connect(function() showTab("Otimização") end)
showTab("ESP")

-- helper to create label + toggle
local function createToggle(parent, labelText, y)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -24, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(220,220,220)

    local toggle = Instance.new("TextButton", parent)
    toggle.Size = UDim2.new(0, 110, 0, 32)
    toggle.Position = UDim2.new(1, -126, 0, y - 6)
    toggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
    toggle.TextColor3 = Color3.fromRGB(255,255,255)
    toggle.Text = "OFF"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 13
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)
    return lbl, toggle
end

-- =======================
-- ESP TAB CONTROLS
-- =======================
local lblESPOn, btnESPOn = createToggle(frameESP, "Ativar personagem (Highlight)", 18)
local lblESPTeam, btnESPTeam = createToggle(frameESP, "Checagem de time (ESP)", 58)
-- Color picker substitute: textbutton to open color input (we'll use simple textboxes)
local lblESPColor = Instance.new("TextLabel", frameESP)
lblESPColor.Size = UDim2.new(1, -24, 0, 20)
lblESPColor.Position = UDim2.new(0, 12, 0, 98)
lblESPColor.BackgroundTransparency = 1
lblESPColor.Text = "Cor da Luz (R,G,B)"
lblESPColor.TextXAlignment = Enum.TextXAlignment.Left
lblESPColor.Font = Enum.Font.Gotham
lblESPColor.TextSize = 14
lblESPColor.TextColor3 = Color3.fromRGB(220,220,220)

local espColorBox = Instance.new("TextBox", frameESP)
espColorBox.Size = UDim2.new(0, 110, 0, 32)
espColorBox.Position = UDim2.new(1, -126, 0, 92)
espColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
espColorBox.TextColor3 = Color3.fromRGB(255,255,255)
espColorBox.Text = tostring(HighlightColor.R*255) .. "," .. tostring(HighlightColor.G*255) .. "," .. tostring(HighlightColor.B*255)
espColorBox.Font = Enum.Font.GothamBold
espColorBox.TextSize = 13
Instance.new("UICorner", espColorBox).CornerRadius = UDim.new(0,8)

btnESPOn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    if ESPEnabled then
        btnESPOn.Text = "ON"; btnESPOn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        FOVFrame.Visible = AimbotEnabled -- keep FOV visible only when aimbot on in original script
    else
        btnESPOn.Text = "OFF"; btnESPOn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end
    -- update existing highlights
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("ESPHighlight")
            if highlight then
                highlight.Enabled = ESPEnabled and (not ESPTeamCheck or player.Team ~= LocalPlayer.Team)
            end
        end
    end
end)

btnESPTeam.MouseButton1Click:Connect(function()
    ESPTeamCheck = not ESPTeamCheck
    if ESPTeamCheck then btnESPTeam.Text = "ON"; btnESPTeam.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnESPTeam.Text = "OFF"; btnESPTeam.BackgroundColor3 = Color3.fromRGB(60,60,60) end
    -- reflect change
    for _, player in ipairs(Players:GetPlayers()) do
        local highlight = player.Character and player.Character:FindFirstChild("ESPHighlight")
        if highlight then
            highlight.Enabled = ESPEnabled and (not ESPTeamCheck or player.Team ~= LocalPlayer.Team)
        end
    end
end)

espColorBox.FocusLost:Connect(function(enter)
    local txt = espColorBox.Text
    local r,g,b = txt:match("(%d+),%s*(%d+),%s*(%d+)")
    if r and g and b then
        local rr = math.clamp(tonumber(r)/255,0,1)
        local gg = math.clamp(tonumber(g)/255,0,1)
        local bb = math.clamp(tonumber(b)/255,0,1)
        HighlightColor = Color3.new(rr,gg,bb)
        -- update existing
        for _, player in ipairs(Players:GetPlayers()) do
            local highlight = player.Character and player.Character:FindFirstChild("ESPHighlight")
            if highlight then
                pcall(function()
                    highlight.OutlineColor = HighlightColor
                    highlight.FillColor = HighlightColor
                end)
            end
        end
    else
        -- revert text to current color if parsing fails
        espColorBox.Text = tostring(math.floor(HighlightColor.R*255)) .. "," .. tostring(math.floor(HighlightColor.G*255)) .. "," .. tostring(math.floor(HighlightColor.B*255))
    end
end)

-- =======================
-- Aimbot TAB CONTROLS
-- =======================
local lblAim, btnAim = createToggle(frameAimbot, "Ativar Aimbot", 18)
local lblTeam, btnTeam = createToggle(frameAimbot, "Não grudar no time", 58)
local lblWallCheck, btnWallCheck = createToggle(frameAimbot, "Checagem de Paredes", 98)

local lblFOV = Instance.new("TextLabel", frameAimbot)
lblFOV.Size = UDim2.new(1, -24, 0, 20); lblFOV.Position = UDim2.new(0, 12, 0, 138)
lblFOV.BackgroundTransparency = 1; lblFOV.Text = "Tamanho FOV (50-300)"
lblFOV.TextXAlignment = Enum.TextXAlignment.Left; lblFOV.Font = Enum.Font.Gotham; lblFOV.TextSize = 14; lblFOV.TextColor3 = Color3.fromRGB(220,220,220)
local fovBox = Instance.new("TextBox", frameAimbot)
fovBox.Size = UDim2.new(0, 110, 0, 32)
fovBox.Position = UDim2.new(1, -126, 0, 132)
fovBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
fovBox.TextColor3 = Color3.fromRGB(255,255,255)
fovBox.Text = tostring(FOVRadius)
fovBox.Font = Enum.Font.GothamBold
fovBox.TextSize = 13
Instance.new("UICorner", fovBox).CornerRadius = UDim.new(0,8)

btnAim.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    if AimbotEnabled then
        btnAim.Text = "ON"; btnAim.BackgroundColor3 = Color3.fromRGB(200,50,50)
        FOVFrame.Visible = true
    else
        btnAim.Text = "OFF"; btnAim.BackgroundColor3 = Color3.fromRGB(60,60,60)
        FOVFrame.Visible = false
    end
end)

btnTeam.MouseButton1Click:Connect(function()
    TeamCheck = not TeamCheck
    if TeamCheck then btnTeam.Text = "ON"; btnTeam.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnTeam.Text = "OFF"; btnTeam.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)

btnWallCheck.MouseButton1Click:Connect(function()
    WallCheck = not WallCheck
    if WallCheck then btnWallCheck.Text = "ON"; btnWallCheck.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnWallCheck.Text = "OFF"; btnWallCheck.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)

fovBox.FocusLost:Connect(function(enter)
    local val = tonumber(fovBox.Text)
    if val then
        FOVRadius = math.clamp(val, 50, 300)
        FOVFrame.Size = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)
    else
        fovBox.Text = tostring(FOVRadius)
    end
end)

-- =======================
-- Visual TAB CONTROLS
-- =======================
local lblFOVRainbow, btnFOVRainbow = createToggle(frameVisual, "FOV RGB", 18)
local lblFOVColor = Instance.new("TextLabel", frameVisual)
lblFOVColor.Size = UDim2.new(1, -24, 0, 20)
lblFOVColor.Position = UDim2.new(0, 12, 0, 58)
lblFOVColor.BackgroundTransparency = 1
lblFOVColor.Text = "Cor do FOV (R,G,B)"
lblFOVColor.TextXAlignment = Enum.TextXAlignment.Left
lblFOVColor.Font = Enum.Font.Gotham
lblFOVColor.TextSize = 14
lblFOVColor.TextColor3 = Color3.fromRGB(220,220,220)

local fovColorBox = Instance.new("TextBox", frameVisual)
fovColorBox.Size = UDim2.new(0, 110, 0, 32)
fovColorBox.Position = UDim2.new(1, -126, 0, 52)
fovColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
fovColorBox.TextColor3 = Color3.fromRGB(255,255,255)
fovColorBox.Text = tostring(math.floor(FOVColor.R*255))..","..tostring(math.floor(FOVColor.G*255))..","..tostring(math.floor(FOVColor.B*255))
fovColorBox.Font = Enum.Font.GothamBold
fovColorBox.TextSize = 13
Instance.new("UICorner", fovColorBox).CornerRadius = UDim.new(0,8)

local lblSlow, btnSlow = createToggle(frameVisual, "Slow Motion PvP", 98)
local lblSkyMode, btnSkyMode = createToggle(frameVisual, "Modo Cielo PvP Suave", 138)

btnFOVRainbow.MouseButton1Click:Connect(function()
    FOVRainbow = not FOVRainbow
    if FOVRainbow then btnFOVRainbow.Text = "ON"; btnFOVRainbow.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnFOVRainbow.Text = "OFF"; btnFOVRainbow.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)

fovColorBox.FocusLost:Connect(function()
    local txt = fovColorBox.Text
    local r,g,b = txt:match("(%d+),%s*(%d+),%s*(%d+)")
    if r and g and b then
        local rr = math.clamp(tonumber(r)/255,0,1)
        local gg = math.clamp(tonumber(g)/255,0,1)
        local bb = math.clamp(tonumber(b)/255,0,1)
        FOVColor = Color3.new(rr,gg,bb)
        if not FOVRainbow then
            UIStroke.Color = FOVColor
        end
    else
        fovColorBox.Text = tostring(math.floor(FOVColor.R*255))..","..tostring(math.floor(FOVColor.G*255))..","..tostring(math.floor(FOVColor.B*255))
    end
end)

btnSlow.MouseButton1Click:Connect(function()
    SlowMotionEnabled = not SlowMotionEnabled
    if SlowMotionEnabled then
        btnSlow.Text = "ON"; btnSlow.BackgroundColor3 = Color3.fromRGB(200,50,50)
        local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 0.25})
        tween:Play()
        pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(true) end)
        workspace.Gravity = 100
    else
        btnSlow.Text = "OFF"; btnSlow.BackgroundColor3 = Color3.fromRGB(60,60,60)
        local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 1})
        tween:Play()
        workspace.Gravity = 196.2
    end
end)

btnSkyMode.MouseButton1Click:Connect(function()
    PvPSkyEnabled = not PvPSkyEnabled
    if PvPSkyEnabled then
        btnSkyMode.Text = "ON"; btnSkyMode.BackgroundColor3 = Color3.fromRGB(200,50,50)
        -- Apply soft PvP lighting
        Lighting.Ambient = Color3.fromRGB(120,130,140)
        Lighting.OutdoorAmbient = Color3.fromRGB(90,100,110)
        Lighting.Brightness = 1.5
        Lighting.ClockTime = 18.5
        if OriginalSky then OriginalSky.Enabled = false end
        local PvPSky = Instance.new("Sky")
        PvPSky.Name = "PvPSky"
        PvPSky.SkyboxBk = "rbxassetid://1022207611"
        PvPSky.SkyboxDn = "rbxassetid://1022207683"
        PvPSky.SkyboxFt = "rbxassetid://1022207746"
        PvPSky.SkyboxLf = "rbxassetid://1022207814"
        PvPSky.SkyboxRt = "rbxassetid://1022207886"
        PvPSky.SkyboxUp = "rbxassetid://1022207958"
        PvPSky.Parent = Lighting
        StarsGui = Instance.new("ScreenGui", game.CoreGui)
        StarsGui.Name = "StarsGui"
        StarsGui.IgnoreGuiInset = true
        StarsGui.ResetOnSpawn = false
        for i = 1, 50 do
            local star = Instance.new("Frame")
            star.Size = UDim2.new(0, 2, 0, 2)
            star.Position = UDim2.new(math.random(), 0, math.random(), 0)
            star.BackgroundColor3 = Color3.new(1, 1, 1)
            star.BackgroundTransparency = 0.7
            star.BorderSizePixel = 0
            star.AnchorPoint = Vector2.new(0.5, 0.5)
            star.Parent = StarsGui
            coroutine.wrap(function()
                while StarsGui and StarsGui.Parent do
                    star.BackgroundTransparency = 0.5 + math.sin(tick() * math.random(1,3)) * 0.4
                    wait(0.1)
                end
            end)()
        end
    else
        btnSkyMode.Text = "OFF"; btnSkyMode.BackgroundColor3 = Color3.fromRGB(60,60,60)
        -- restore
        Lighting.Ambient = OriginalAmbient
        Lighting.OutdoorAmbient = OriginalOutdoorAmbient
        Lighting.Brightness = OriginalBrightness
        Lighting.ClockTime = OriginalClockTime
        local PvPSky = Lighting:FindFirstChild("PvPSky")
        if PvPSky then PvPSky:Destroy() end
        if OriginalSky then OriginalSky.Enabled = true end
        if StarsGui then StarsGui:Destroy(); StarsGui = nil end
    end
end)

-- =======================
-- Optimization TAB CONTROLS
-- =======================
local btnImproveFPS = Instance.new("TextButton", frameOptim)
btnImproveFPS.Size = UDim2.new(0, 160, 0, 32)
btnImproveFPS.Position = UDim2.new(0, 12, 0, 18)
btnImproveFPS.Text = "Melhorar fps"
btnImproveFPS.Font = Enum.Font.GothamBold
btnImproveFPS.TextSize = 14
btnImproveFPS.TextColor3 = Color3.fromRGB(235,235,235)
Instance.new("UICorner", btnImproveFPS).CornerRadius = UDim.new(0,8)

btnImproveFPS.MouseButton1Click:Connect(function()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
    end
end)

local lblFPSUnlock, btnFPSUnlock = createToggle(frameOptim, "FPS desbloqueado", 68)
btnFPSUnlock.MouseButton1Click:Connect(function()
    FPSUnlockerEnabled = not FPSUnlockerEnabled
    if FPSUnlockerEnabled then
        btnFPSUnlock.Text = "ON"; btnFPSUnlock.BackgroundColor3 = Color3.fromRGB(200,50,50)
        pcall(function() setfpscap(1000) end)
    else
        btnFPSUnlock.Text = "OFF"; btnFPSUnlock.BackgroundColor3 = Color3.fromRGB(60,60,60)
        pcall(function() setfpscap(60) end)
    end
end)

local btnOptimizePing = Instance.new("TextButton", frameOptim)
btnOptimizePing.Size = UDim2.new(0, 160, 0, 32)
btnOptimizePing.Position = UDim2.new(0, 12, 0, 118)
btnOptimizePing.Text = "Otimizar Ping"
btnOptimizePing.Font = Enum.Font.GothamBold
btnOptimizePing.TextSize = 14
btnOptimizePing.TextColor3 = Color3.fromRGB(235,235,235)
Instance.new("UICorner", btnOptimizePing).CornerRadius = UDim.new(0,8)

btnOptimizePing.MouseButton1Click:Connect(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        elseif obj:IsA("Explosion") then
            pcall(function() obj.Visible = false end)
        end
    end
    pcall(function()
        settings().Physics.AllowSleep = true
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Default
    end)
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    if workspace:FindFirstChild("Terrain") then
        pcall(function()
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 1
        end)
    end
    for _, guiObj in ipairs(game.CoreGui:GetDescendants()) do
        if guiObj:IsA("ImageLabel") or guiObj:IsA("ImageButton") then
            pcall(function() guiObj.ImageTransparency = 0.2 end)
        end
    end
    -- Notify: simple text label popup
    local notify = Instance.new("TextLabel", rootFrame)
    notify.Size = UDim2.new(0, 200, 0, 40)
    notify.Position = UDim2.new(0.5, -100, 0, 10)
    notify.BackgroundColor3 = Color3.fromRGB(20,20,20)
    notify.TextColor3 = Color3.fromRGB(235,235,235)
    notify.Text = "Ping otimizado"
    notify.Font = Enum.Font.GothamBold
    notify.TextSize = 14
    Instance.new("UICorner", notify).CornerRadius = UDim.new(0,8)
    delay(3, function() pcall(function() notify:Destroy() end) end)
end)

local btnSkyboxOptim = Instance.new("TextButton", frameOptim)
btnSkyboxOptim.Size = UDim2.new(0, 160, 0, 32)
btnSkyboxOptim.Position = UDim2.new(0, 12, 0, 168)
btnSkyboxOptim.Text = "Skybox PvP"
btnSkyboxOptim.Font = Enum.Font.GothamBold
btnSkyboxOptim.TextSize = 14
btnSkyboxOptim.TextColor3 = Color3.fromRGB(235,235,235)
Instance.new("UICorner", btnSkyboxOptim).CornerRadius = UDim.new(0,8)

btnSkyboxOptim.MouseButton1Click:Connect(function()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then v:Destroy() end
    end
    local sky = Instance.new("Sky", Lighting)
    sky.SkyboxBk = "rbxassetid://159454299"
    sky.SkyboxDn = "rbxassetid://159454296"
    sky.SkyboxFt = "rbxassetid://159454293"
    sky.SkyboxLf = "rbxassetid://159454286"
    sky.SkyboxRt = "rbxassetid://159454300"
    sky.SkyboxUp = "rbxassetid://159454288"
    pcall(function() sky.StarCount = 3000; sky.SunAngularSize = 0; sky.MoonAngularSize = 11 end)
    Lighting.TimeOfDay = "18:00:00"
end)

-- =======================
-- Highlight utilities (from original script.lua, adapted)
-- =======================
local function ApplyHighlight(player)
    if not player.Character then return end
    local existing = player.Character:FindFirstChild("ESPHighlight")
    if existing then existing:Destroy() end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    pcall(function() highlight.OutlineColor = HighlightColor end)
    pcall(function() highlight.FillColor = HighlightColor end)
    highlight.Enabled = ESPEnabled and (not ESPTeamCheck or player.Team ~= LocalPlayer.Team)
    highlight.Parent = player.Character
end

local function SetupCharacterHighlight(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            ApplyHighlight(player)
        end)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupCharacterHighlight(player)
    if player.Character then
        ApplyHighlight(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    SetupCharacterHighlight(player)
end)

Players.PlayerRemoving:Connect(function(p)
    -- cleanup if needed: nothing special as highlights are parented to Character
end)

-- =======================
-- Aimbot logic (GetClosestTarget + RenderStepped)
-- =======================
local function GetClosestTarget()
    local closest = nil
    local shortestDist = FOVRadius
    local cam = Camera
    if not cam then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if TeamCheck and player.Team == LocalPlayer.Team then continue end

            local pos, onScreen = cam:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude

                if dist <= shortestDist then
                    if WallCheck then
                        local origin = cam.CFrame.Position
                        local direction = (player.Character.HumanoidRootPart.Position - origin).Unit * 1000
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

                        local result = workspace:Raycast(origin, direction, raycastParams)
                        if result and result.Instance and result.Instance:IsDescendantOf(player.Character) then
                            closest = player
                            shortestDist = dist
                        end
                    else
                        closest = player
                        shortestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    -- FOV rainbow update
    if FOVRainbow then
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 1, 1)
        UIStroke.Color = color
    end

    -- Ensure FOVFrame follows center and size
    FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    FOVFrame.Size = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)

    if AimbotEnabled then
        local target = GetClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local head = target.Character.HumanoidRootPart.Position
            local camPos = Camera.CFrame.Position
            local newCF = CFrame.new(camPos, head)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, 0.4)
        end
    end
end)

-- =======================
-- Minimize behavior
-- =======================
local miniBtn = Instance.new("TextButton", screenGui)
miniBtn.Size = UDim2.new(0, 96, 0, 36)
miniBtn.Position = UDim2.new(0, 20, 0, 20)
miniBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
miniBtn.TextColor3 = Color3.fromRGB(235,235,235)
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = 14
miniBtn.Text = "Menu"
miniBtn.Visible = false
miniBtn.ZIndex = 110
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0,18)
miniBtn.Active = true
miniBtn.Draggable = true

minimizeBtn.MouseButton1Click:Connect(function()
    rootFrame.Visible = false
    miniBtn.Visible = true
end)
miniBtn.MouseButton1Click:Connect(function()
    rootFrame.Visible = true
    miniBtn.Visible = false
end)

-- =======================
-- End of script
-- =======================
print("[XIT PAINEL] carregado: painel integrado com Aimbot, ESP, Visual e Otimização")
