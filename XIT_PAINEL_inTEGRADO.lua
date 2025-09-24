-- XIT PAINEL - INTEGRADO (corrigido layout: toggles alinhados e botões em abas corretas)
-- Coloque este arquivo em um LocalScript em StarterPlayerScripts ou execute via executor.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- Aim mode: "Head" or "Chest"
local AimMode = "Chest" -- default to chest (peito). User can toggle in UI.

local function GetAimPoint(character)
    if not character then return nil end
    local head = character:FindFirstChild("Head")
    local upperTorso = character:FindFirstChild("UpperTorso")
    local torso = character:FindFirstChild("Torso")
    local hrp  = character:FindFirstChild("HumanoidRootPart")

    if AimMode == "Head" then
        if head and head:IsA("BasePart") then return head.Position end
        if upperTorso and upperTorso:IsA("BasePart") then return upperTorso.Position + Vector3.new(0,0.3,0) end
        if torso and torso:IsA("BasePart") then return torso.Position + Vector3.new(0,0.3,0) end
        if hrp and hrp:IsA("BasePart") then return hrp.Position + Vector3.new(0,1.0,0) end
    else
        if upperTorso and upperTorso:IsA("BasePart") then return upperTorso.Position + Vector3.new(0,0.3,0) end
        if torso and torso:IsA("BasePart") then return torso.Position + Vector3.new(0,0.3,0) end
        if hrp and hrp:IsA("BasePart") then return hrp.Position + Vector3.new(0,1.0,0) end
        if head and head:IsA("BasePart") then return head.Position end
    end
    return nil
end

-- State variables
local AimbotEnabled = false
local TeamCheck = false
local WallCheck = false
local FOVRadius = 100
local ESPEnabled = false
local ESPTeamCheck = false
local HighlightColor = Color3.fromRGB(255,255,255)
local FOVRainbow = false
local FOVColor = Color3.fromRGB(255,255,255)
local FPSUnlockerEnabled = false

local SlowMotionEnabled = false
local PvPSkyEnabled = false

local NoclipEnabled = false
local noclipConn = nil

local OriginalAmbient = Lighting.Ambient
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient
local OriginalBrightness = Lighting.Brightness
local OriginalClockTime = Lighting.ClockTime
local OriginalSky = Lighting:FindFirstChildOfClass("Sky")

local StarsGui = nil

-- Drawing ESP (replacement for name-box ESP)
local Drawing = Drawing or (not pcall(function() return Drawing end) and nil) -- keep safe for executors that don't have Drawing

-- GUI setup
local gui = Instance.new("ScreenGui")
gui.Name = "ModMenu_Combined_GUI"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local drawContainer = Instance.new("Frame")
drawContainer.Name = "DrawContainer"
drawContainer.Size = UDim2.new(1,0,1,0)
drawContainer.BackgroundTransparency = 1
drawContainer.ZIndex = 50
drawContainer.Parent = gui

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOV"
FOVFrame.Parent = drawContainer
FOVFrame.AnchorPoint = Vector2.new(0.5,0.5)
FOVFrame.Position = UDim2.new(0.5,0,0.5,0)
FOVFrame.Size = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = false

local UIStroke = Instance.new("UIStroke", FOVFrame)
UIStroke.Thickness = 2
UIStroke.Color = FOVColor
local UICorner = Instance.new("UICorner", FOVFrame)
UICorner.CornerRadius = UDim.new(1,0)

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Parent = drawContainer
StatsLabel.Size = UDim2.new(0,200,0,50)
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

-- Floating Panel
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModMenuGuiMain"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local rootFrame = Instance.new("Frame")
rootFrame.Size = UDim2.new(0, 360, 0, 420) -- increased height for more space
rootFrame.Position = UDim2.new(0, 20, 0, 20)
rootFrame.BackgroundColor3 = Color3.fromRGB(12,12,14)
rootFrame.BorderSizePixel = 0
rootFrame.Active = true
rootFrame.Draggable = true
rootFrame.Parent = screenGui
Instance.new("UICorner", rootFrame).CornerRadius = UDim.new(0,12)
local uiStroke = Instance.new("UIStroke", rootFrame); uiStroke.Color = Color3.fromRGB(30,30,30); uiStroke.Transparency = 0.7

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
minimizeBtn.Text = "Min _"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,8)

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
local btnOutros = makeSideButton("Outros", 150)
local btnOptim = makeSideButton("Otimização", 196)

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

local frameOutros = Instance.new("Frame", content)
frameOutros.Size = UDim2.new(1,0,1,0)
frameOutros.BackgroundTransparency = 1
frameOutros.Visible = false

local frameOptim = Instance.new("Frame", content)
frameOptim.Size = UDim2.new(1,0,1,0)
frameOptim.BackgroundTransparency = 1
frameOptim.Visible = false

local function showTab(name)
    frameESP.Visible = (name == "ESP")
    frameAimbot.Visible = (name == "Aimbot")
    frameVisual.Visible = (name == "Visual")
    frameOutros.Visible = (name == "Outros")
    frameOptim.Visible = (name == "Otimização")
    btnESP.BackgroundColor3 = (name=="ESP") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnAimbot.BackgroundColor3 = (name=="Aimbot") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnVisual.BackgroundColor3 = (name=="Visual") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnOutros.BackgroundColor3 = (name=="Outros") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnOptim.BackgroundColor3 = (name=="Otimização") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
end

btnESP.MouseButton1Click:Connect(function() showTab("ESP") end)
btnAimbot.MouseButton1Click:Connect(function() showTab("Aimbot") end)
btnVisual.MouseButton1Click:Connect(function() showTab("Visual") end)
btnOutros.MouseButton1Click:Connect(function() showTab("Outros") end)
btnOptim.MouseButton1Click:Connect(function() showTab("Otimização") end)
showTab("ESP")

-- Helper: create scroll area inside a tab so items don't overlap
local function createTabScroll(parent)
    local scroll = Instance.new("ScrollingFrame", parent)
    scroll.Size = UDim2.new(1, -24, 1, -24)
    scroll.Position = UDim2.new(0, 12, 0, 12)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 8
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0,10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return scroll, layout
end

local espScroll, espLayout = createTabScroll(frameESP)
local aimbotScroll, aimbotLayout = createTabScroll(frameAimbot)
local visualScroll, visualLayout = createTabScroll(frameVisual)
local outrosScroll, outrosLayout = createTabScroll(frameOutros)
local optimScroll, optimLayout = createTabScroll(frameOptim)

-- helper to create label + toggle inside a scroll (keeps them aligned)
local function createToggleInScroll(scrollParent, text)
    local container = Instance.new("Frame", scrollParent)
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(1, -140, 1, 0) -- leave space for toggle button on right
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(220,220,220)

    local toggle = Instance.new("TextButton", container)
    toggle.Size = UDim2.new(0, 110, 0, 32)
    toggle.Position = UDim2.new(1, -126, 0, 4)
    toggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
    toggle.TextColor3 = Color3.fromRGB(255,255,255)
    toggle.Text = "OFF"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 13
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

    return container, lbl, toggle
end

-- =======================
-- ESP TAB CONTROLS (using espScroll)
-- =======================
local lblESPOnCont, lblESPOn, btnESPOn = createToggleInScroll(espScroll, "Ativar personagem (Highlight)")
local lblESPTeamCont, lblESPTeamLabel, btnESPTeam = createToggleInScroll(espScroll, "Checagem de time (ESP)")
-- Color input row
local colorRow = Instance.new("Frame", espScroll)
colorRow.Size = UDim2.new(1,0,0,40)
colorRow.BackgroundTransparency = 1
local lblESPColor = Instance.new("TextLabel", colorRow)
lblESPColor.Size = UDim2.new(1, -140, 1, 0)
lblESPColor.Position = UDim2.new(0,8,0,0)
lblESPColor.BackgroundTransparency = 1
lblESPColor.Text = "Cor da Luz (R,G,B)"
lblESPColor.TextXAlignment = Enum.TextXAlignment.Left
lblESPColor.Font = Enum.Font.Gotham
lblESPColor.TextSize = 14
lblESPColor.TextColor3 = Color3.fromRGB(220,220,220)

local espColorBox = Instance.new("TextBox", colorRow)
espColorBox.Size = UDim2.new(0, 110, 0, 32)
espColorBox.Position = UDim2.new(1, -126, 0, 4)
espColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
espColorBox.TextColor3 = Color3.fromRGB(255,255,255)
espColorBox.Text = tostring(math.floor(HighlightColor.R*255)) .. "," .. tostring(math.floor(HighlightColor.G*255)) .. "," .. tostring(math.floor(HighlightColor.B*255))
espColorBox.Font = Enum.Font.GothamBold
espColorBox.TextSize = 13
Instance.new("UICorner", espColorBox).CornerRadius = UDim.new(0,8)

-- ESP Box controls (box drawing)
local lblESPBoxCont, lblESPBoxLabel, btnESPBox = createToggleInScroll(espScroll, "Ativar ESP Box")
local lblESPBoxTeamCont, lblESPBoxTeamLabel, btnESPBoxTeam = createToggleInScroll(espScroll, "Checagem de time (Box)")

local boxColorRow = Instance.new("Frame", espScroll)
boxColorRow.Size = UDim2.new(1,0,0,40)
boxColorRow.BackgroundTransparency = 1
local lblBoxColor = Instance.new("TextLabel", boxColorRow)
lblBoxColor.Size = UDim2.new(1, -140, 1, 0)
lblBoxColor.Position = UDim2.new(0,8,0,0)
lblBoxColor.BackgroundTransparency = 1
lblBoxColor.Text = "Cor do Box (R,G,B)"
lblBoxColor.TextXAlignment = Enum.TextXAlignment.Left
lblBoxColor.Font = Enum.Font.Gotham
lblBoxColor.TextSize = 14
lblBoxColor.TextColor3 = Color3.fromRGB(220,220,220)

local boxColorBox = Instance.new("TextBox", boxColorRow)
boxColorBox.Size = UDim2.new(0, 110, 0, 32)
boxColorBox.Position = UDim2.new(1, -126, 0, 4)
boxColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
boxColorBox.TextColor3 = Color3.fromRGB(255,255,255)
boxColorBox.Text = tostring(255)..","..tostring(0)..","..tostring(0)
boxColorBox.Font = Enum.Font.GothamBold
boxColorBox.TextSize = 13
Instance.new("UICorner", boxColorBox).CornerRadius = UDim.new(0,8)

-- Additional ESP Drawing toggles
local lblLineCont, lblLineLabel, btnLineToggle = createToggleInScroll(espScroll, "Ativar ESP Linha (Drawing)")
local lblLineTeamCont, lblLineTeamLabel, btnLineTeam = createToggleInScroll(espScroll, "Checagem de time (Linha)")
local lblLineColorRow = Instance.new("Frame", espScroll)
lblLineColorRow.Size = UDim2.new(1,0,0,40)
lblLineColorRow.BackgroundTransparency = 1
local lblLineColorLabel = Instance.new("TextLabel", lblLineColorRow)
lblLineColorLabel.Size = UDim2.new(1, -140, 1, 0)
lblLineColorLabel.Position = UDim2.new(0,8,0,0)
lblLineColorLabel.BackgroundTransparency = 1
lblLineColorLabel.Text = "Cor da Linha (R,G,B)"
lblLineColorLabel.TextXAlignment = Enum.TextXAlignment.Left
lblLineColorLabel.Font = Enum.Font.Gotham
lblLineColorLabel.TextSize = 14
lblLineColorLabel.TextColor3 = Color3.fromRGB(220,220,220)
local lineColorBox = Instance.new("TextBox", lblLineColorRow)
lineColorBox.Size = UDim2.new(0,110,0,32)
lineColorBox.Position = UDim2.new(1, -126, 0, 4)
lineColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
lineColorBox.TextColor3 = Color3.fromRGB(255,255,255)
lineColorBox.Text = "255,0,0"
lineColorBox.Font = Enum.Font.GothamBold
lineColorBox.TextSize = 13
Instance.new("UICorner", lineColorBox).CornerRadius = UDim.new(0,8)

-- Name/DIST Drawing toggles
local lblNameCont, lblNameLabel, btnNameToggle = createToggleInScroll(espScroll, "Ativar ESP Nome (Drawing)")
local lblNameTeamCont, lblNameTeamLabel, btnNameTeam = createToggleInScroll(espScroll, "Checagem de time (Nome)")
local lblNameColorRow = Instance.new("Frame", espScroll)
lblNameColorRow.Size = UDim2.new(1,0,0,40)
lblNameColorRow.BackgroundTransparency = 1
local lblNameColorLabel = Instance.new("TextLabel", lblNameColorRow)
lblNameColorLabel.Size = UDim2.new(1, -140, 1, 0)
lblNameColorLabel.Position = UDim2.new(0,8,0,0)
lblNameColorLabel.BackgroundTransparency = 1
lblNameColorLabel.Text = "Cor do Nome (R,G,B)"
lblNameColorLabel.TextXAlignment = Enum.TextXAlignment.Left
lblNameColorLabel.Font = Enum.Font.Gotham
lblNameColorLabel.TextSize = 14
lblNameColorLabel.TextColor3 = Color3.fromRGB(220,220,220)
local nameColorBox = Instance.new("TextBox", lblNameColorRow)
nameColorBox.Size = UDim2.new(0,110,0,32)
nameColorBox.Position = UDim2.new(1, -126, 0, 4)
nameColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
nameColorBox.TextColor3 = Color3.fromRGB(255,255,255)
nameColorBox.Text = "255,0,0"
nameColorBox.Font = Enum.Font.GothamBold
nameColorBox.TextSize = 13
Instance.new("UICorner", nameColorBox).CornerRadius = UDim.new(0,8)

-- ADDED: Distance (stund) toggles for ESP (injected as requested)
local lblDistCont, lblDistLabel, btnDistToggle = createToggleInScroll(espScroll, "Ativar ESP Distância (Drawing)")
local lblDistTeamCont, lblDistTeamLabel, btnDistTeam = createToggleInScroll(espScroll, "Checagem de time (Distância)")
-- no separate color box for distance; distance will use white by default

-- Teleport and Weapons moved to Outros tab (so they won't overlap with ESP scroll)
local lblTeleport = Instance.new("TextLabel", outrosScroll)
lblTeleport.Size = UDim2.new(1, -140, 0, 20)
lblTeleport.BackgroundTransparency = 1
lblTeleport.Text = "Teleportar para Inimigos"
lblTeleport.TextXAlignment = Enum.TextXAlignment.Left
lblTeleport.Font = Enum.Font.Gotham
lblTeleport.TextSize = 14
lblTeleport.TextColor3 = Color3.fromRGB(220,220,220)
lblTeleport.Parent = outrosScroll

local btnOpenTeleport = Instance.new("TextButton", outrosScroll)
btnOpenTeleport.Size = UDim2.new(0, 110, 0, 32)
btnOpenTeleport.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnOpenTeleport.TextColor3 = Color3.fromRGB(255,255,255)
btnOpenTeleport.Text = "Abrir"
btnOpenTeleport.Font = Enum.Font.GothamBold
btnOpenTeleport.TextSize = 13
Instance.new("UICorner", btnOpenTeleport).CornerRadius = UDim.new(0,8)

local lblWeapons = Instance.new("TextLabel", outrosScroll)
lblWeapons.Size = UDim2.new(1, -140, 0, 20)
lblWeapons.BackgroundTransparency = 1
lblWeapons.Text = "Armas disponiveis"
lblWeapons.TextXAlignment = Enum.TextXAlignment.Left
lblWeapons.Font = Enum.Font.Gotham
lblWeapons.TextSize = 14
lblWeapons.TextColor3 = Color3.fromRGB(220,220,220)
lblWeapons.Parent = outrosScroll

local btnOpenWeapons = Instance.new("TextButton", outrosScroll)
btnOpenWeapons.Size = UDim2.new(0, 110, 0, 32)
btnOpenWeapons.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnOpenWeapons.TextColor3 = Color3.fromRGB(255,255,255)
btnOpenWeapons.Text = "Abrir"
btnOpenWeapons.Font = Enum.Font.GothamBold
btnOpenWeapons.TextSize = 13
Instance.new("UICorner", btnOpenWeapons).CornerRadius = UDim.new(0,8)

-- Position teleport/weapons properly inside scroll using frames
local function addSimpleRow(scroll, labelObj, buttonObj)
    local container = Instance.new("Frame", scroll)
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundTransparency = 1
    labelObj.Parent = container
    labelObj.Size = UDim2.new(1, -140, 0, 20)
    labelObj.Position = UDim2.new(0, 8, 0, 6)
    buttonObj.Parent = container
    buttonObj.Position = UDim2.new(1, -126, 0, 6)
end

addSimpleRow(outrosScroll, lblTeleport, btnOpenTeleport)
addSimpleRow(outrosScroll, lblWeapons, btnOpenWeapons)

-- Weapons & Teleport implementation (same as previous)
local teleportFrame = Instance.new("Frame", screenGui)
teleportFrame.Name = "TeleportFrame"
teleportFrame.Size = UDim2.new(0, 220, 0, 260)
teleportFrame.Position = UDim2.new(0, 400, 0, 20)
teleportFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
teleportFrame.BorderSizePixel = 0
teleportFrame.Visible = false
Instance.new("UICorner", teleportFrame).CornerRadius = UDim.new(0,8)
teleportFrame.ZIndex = 200

local teleportTitle = Instance.new("TextLabel", teleportFrame)
teleportTitle.Size = UDim2.new(1, -12, 0, 28)
teleportTitle.Position = UDim2.new(0, 6, 0, 6)
teleportTitle.BackgroundTransparency = 1
teleportTitle.Text = "Teleport — Inimigos"
teleportTitle.Font = Enum.Font.GothamBold
teleportTitle.TextSize = 14
teleportTitle.TextColor3 = Color3.fromRGB(235,235,235)
teleportTitle.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", teleportFrame)
closeBtn.Size = UDim2.new(0, 52, 0, 24)
closeBtn.Position = UDim2.new(1, -58, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Text = "Fechar"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

local scrollTeleport = Instance.new("ScrollingFrame", teleportFrame)
scrollTeleport.Size = UDim2.new(1, -12, 1, -46)
scrollTeleport.Position = UDim2.new(0, 6, 0, 38)
scrollTeleport.CanvasSize = UDim2.new(0,0,0,0)
scrollTeleport.BackgroundTransparency = 1
scrollTeleport.ScrollBarThickness = 6
scrollTeleport.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
scrollTeleport.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollTeleport.ZIndex = 201

local uiList = Instance.new("UIListLayout", scrollTeleport)
uiList.Padding = UDim.new(0,6)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local function ClearTeleportButtons()
    for _, child in ipairs(scrollTeleport:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function ShowTempMsg(parent, text, time)
    local tmp = Instance.new("TextLabel", parent)
    tmp.Size = UDim2.new(1, -12, 0, 26)
    tmp.Position = UDim2.new(0,6,1,-32)
    tmp.BackgroundColor3 = Color3.fromRGB(30,30,30)
    tmp.TextColor3 = Color3.fromRGB(255,200,200)
    tmp.Font = Enum.Font.GothamBold
    tmp.TextSize = 12
    tmp.Text = text
    Instance.new("UICorner", tmp).CornerRadius = UDim.new(0,6)
    delay(time or 2, function() pcall(function() tmp:Destroy() end) end)
end

local function TeleportToPlayer(pl)
    pcall(function()
        if not pl or not pl.Parent then
            ShowTempMsg(teleportFrame, "Alvo inválido", 2)
            return
        end
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
            ShowTempMsg(teleportFrame, "Seu personagem não está pronto", 2)
            return
        end

        local attempts = 0
        local maxAttempts = 30
        local found = false

        spawn(function()
            while attempts < maxAttempts and not found do
                attempts = attempts + 1
                local targetChar = pl.Character
                local targetHRP = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso"))
                if targetHRP then
                    found = true
                    local dest = targetHRP.CFrame + Vector3.new(0, 5, 0)
                    pcall(function()
                        myChar:WaitForChild("HumanoidRootPart").CFrame = dest
                    end)
                    ShowTempMsg(teleportFrame, "Teleportado para " .. pl.Name, 2)
                    break
                end
                wait(0.1)
            end

            if not found then
                ShowTempMsg(teleportFrame, "Falha: alvo não replicado no cliente", 3)
            end
        end)
    end)
end

local function PopulateTeleportList()
    ClearTeleportButtons()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            if not btnESPBoxTeam or (not pl.Team == LocalPlayer.Team) then
                local btn = Instance.new("TextButton", scrollTeleport)
                btn.Size = UDim2.new(1, -12, 0, 32)
                btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
                btn.TextColor3 = Color3.fromRGB(235,235,235)
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 14
                btn.Text = pl.Name
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
                btn.ZIndex = 202

                local distLabel = Instance.new("TextLabel", btn)
                distLabel.Size = UDim2.new(0, 56, 1, 0)
                distLabel.Position = UDim2.new(1, -60, 0, 0)
                distLabel.BackgroundTransparency = 1
                distLabel.TextColor3 = Color3.fromRGB(200,200,200)
                distLabel.Font = Enum.Font.Gotham
                distLabel.TextSize = 12
                distLabel.Text = ""

                local conn
                conn = RunService.Heartbeat:Connect(function()
                    if not teleportFrame.Visible then
                        if conn then conn:Disconnect() end
                        return
                    end
                    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local theirHRP = pl.Character and (pl.Character:FindFirstChild("HumanoidRootPart") or pl.Character:FindFirstChild("UpperTorso"))
                    if myHRP and theirHRP then
                        local d = (myHRP.Position - theirHRP.Position).Magnitude
                        distLabel.Text = tostring(math.floor(d)) .. "m"
                    else
                        distLabel.Text = "--"
                    end
                end)

                btn.MouseButton1Click:Connect(function()
                    TeleportToPlayer(pl)
                end)
            end
        end
    end
    delay(0.05, function()
        local total = 0
        for _, v in ipairs(scrollTeleport:GetChildren()) do
            if v:IsA("TextButton") or v:IsA("Frame") then
                total = total + (v.AbsoluteSize.Y) + uiList.Padding.Offset
            end
        end
        scrollTeleport.CanvasSize = UDim2.new(0,0,0, total)
    end)
end

btnOpenTeleport.MouseButton1Click:Connect(function()
    teleportFrame.Visible = not teleportFrame.Visible
    if teleportFrame.Visible then
        btnOpenTeleport.Text = "Fechar"
        PopulateTeleportList()
    else
        btnOpenTeleport.Text = "Abrir"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    teleportFrame.Visible = false
    btnOpenTeleport.Text = "Abrir"
end)

Players.PlayerAdded:Connect(function() if teleportFrame.Visible then PopulateTeleportList() end end)
Players.PlayerRemoving:Connect(function() if teleportFrame.Visible then PopulateTeleportList() end end)
Players.PlayerAdded:Connect(function(p)
    p:GetPropertyChangedSignal("Team"):Connect(function() if teleportFrame.Visible then PopulateTeleportList() end end)
end)
for _, pl in ipairs(Players:GetPlayers()) do
    pl:GetPropertyChangedSignal("Team"):Connect(function() if teleportFrame.Visible then PopulateTeleportList() end end)
end

-- Weapons list implementation
local weaponsFrame = Instance.new("Frame", screenGui)
weaponsFrame.Name = "WeaponsFrame"
weaponsFrame.Size = UDim2.new(0, 300, 0, 320)
weaponsFrame.Position = UDim2.new(0.5, -150, 0.5, -160)
weaponsFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
weaponsFrame.BorderSizePixel = 0
weaponsFrame.Visible = false
Instance.new("UICorner", weaponsFrame).CornerRadius = UDim.new(0,8)
weaponsFrame.ZIndex = 210

local weaponsTitle = Instance.new("TextLabel", weaponsFrame)
weaponsTitle.Size = UDim2.new(1, -12, 0, 28)
weaponsTitle.Position = UDim2.new(0, 6, 0, 6)
weaponsTitle.BackgroundTransparency = 1
weaponsTitle.Text = "Armas — Lista"
weaponsTitle.Font = Enum.Font.GothamBold
weaponsTitle.TextSize = 14
weaponsTitle.TextColor3 = Color3.fromRGB(235,235,235)
weaponsTitle.TextXAlignment = Enum.TextXAlignment.Left

local weaponsClose = Instance.new("TextButton", weaponsFrame)
weaponsClose.Size = UDim2.new(0, 52, 0, 24)
weaponsClose.Position = UDim2.new(1, -58, 0, 6)
weaponsClose.BackgroundColor3 = Color3.fromRGB(60,60,60)
weaponsClose.TextColor3 = Color3.fromRGB(255,255,255)
weaponsClose.Text = "Fechar"
weaponsClose.Font = Enum.Font.GothamBold
weaponsClose.TextSize = 12
Instance.new("UICorner", weaponsClose).CornerRadius = UDim.new(0,6)

local weaponsScroll = Instance.new("ScrollingFrame", weaponsFrame)
weaponsScroll.Size = UDim2.new(1, -12, 1, -46)
weaponsScroll.Position = UDim2.new(0, 6, 0, 38)
weaponsScroll.CanvasSize = UDim2.new(0,0,0,0)
weaponsScroll.BackgroundTransparency = 1
weaponsScroll.ScrollBarThickness = 6
weaponsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
weaponsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
weaponsScroll.ZIndex = 211

local weaponsListLayout = Instance.new("UIListLayout", weaponsScroll)
weaponsListLayout.Padding = UDim.new(0,6)
weaponsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
weaponsListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function FindAvailableTools()
    local results = {}
    local seen = {}
    local function tryAdd(inst, source)
        if not inst or not inst.Parent then return end
        if inst:IsA("Tool") then
            local key = inst.Name .. ":" .. tostring(inst.ClassName) .. ":" .. source
            if not seen[key] then
                table.insert(results, {tool = inst, source = source})
                seen[key] = true
            end
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do tryAdd(v, "ReplicatedStorage") end
    for _, v in ipairs(Workspace:GetDescendants()) do tryAdd(v, "Workspace") end
    for _, v in ipairs(StarterPack:GetDescendants()) do tryAdd(v, "StarterPack") end
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do tryAdd(v, "Backpack") end
    end
    if LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do tryAdd(v, "Character") end
    end
    return results
end

local function GiveToolToPlayer(toolInstance)
    if not toolInstance then return false, "Tool inválida" end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false, "Backpack não disponível" end
    local ok, clone = pcall(function() return toolInstance:Clone() end)
    if not ok or not clone then return false, "Falha ao clonar" end
    local success, err = pcall(function()
        clone.Parent = backpack
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):EquipTool(clone) end)
        end
    end)
    if not success then return false, "Erro ao colocar no Backpack: " .. tostring(err) end
    return true, "Arma adicionada"
end

local function ClearWeaponsButtons()
    for _, child in ipairs(weaponsScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function PopulateWeaponsList()
    ClearWeaponsButtons()
    local tools = FindAvailableTools()
    if #tools == 0 then ShowTempMsg(weaponsFrame, "Nenhuma arma local encontrada", 3) return end
    for _, entry in ipairs(tools) do
        local t = entry.tool
        local source = entry.source
        local btn = Instance.new("TextButton", weaponsScroll)
        btn.Size = UDim2.new(1, -12, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        btn.TextColor3 = Color3.fromRGB(235,235,235)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Text = t.Name .. " (" .. source .. ")"
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
        btn.ZIndex = 212

        btn.MouseButton1Click:Connect(function()
            local ok, msg = GiveToolToPlayer(t)
            if ok then ShowTempMsg(weaponsFrame, "Pegou: " .. t.Name, 2) else ShowTempMsg(weaponsFrame, "Erro: " .. tostring(msg), 3) end
        end)
    end

    delay(0.05, function()
        local total = 0
        for _, v in ipairs(weaponsScroll:GetChildren()) do
            if v:IsA("TextButton") then total = total + v.AbsoluteSize.Y + weaponsListLayout.Padding.Offset end
        end
        weaponsScroll.CanvasSize = UDim2.new(0,0,0, total)
    end)
end

btnOpenWeapons.MouseButton1Click:Connect(function()
    weaponsFrame.Visible = not weaponsFrame.Visible
    if weaponsFrame.Visible then
        btnOpenWeapons.Text = "Fechar"
        PopulateWeaponsList()
    else
        btnOpenWeapons.Text = "Abrir"
    end
end)

weaponsClose.MouseButton1Click:Connect(function()
    weaponsFrame.Visible = false
    btnOpenWeapons.Text = "Abrir"
end)

-- =======================
-- Toggle handlers and behaviors
-- =======================
btnESPOn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    if ESPEnabled then
        btnESPOn.Text = "ON"; btnESPOn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        FOVFrame.Visible = AimbotEnabled
    else
        btnESPOn.Text = "OFF"; btnESPOn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end
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
        espColorBox.Text = tostring(math.floor(HighlightColor.R*255)) .. "," .. tostring(math.floor(HighlightColor.G*255)) .. "," .. tostring(math.floor(HighlightColor.B*255))
    end
end)

btnESPBox.MouseButton1Click:Connect(function()
    local enabled = btnESPBox.Text ~= "ON"
    if enabled then
        btnESPBox.Text = "ON"; btnESPBox.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else
        btnESPBox.Text = "OFF"; btnESPBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end
    -- this flag is local to drawing implementation below; we use btn states to drive drawing
end)

btnESPBoxTeam.MouseButton1Click:Connect(function()
    local enabled = btnESPBoxTeam.Text ~= "ON"
    if enabled then btnESPBoxTeam.Text = "ON"; btnESPBoxTeam.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnESPBoxTeam.Text = "OFF"; btnESPBoxTeam.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)

boxColorBox.FocusLost:Connect(function(enter)
    local txt = boxColorBox.Text
    local r,g,b = txt:match("(%d+),%s*(%d+),%s*(%d+)")
    if r and g and b then
        -- just keep text; drawing will pick up when needed
    else
        boxColorBox.Text = tostring(255)..","..tostring(0)..","..tostring(0)
    end
end)

-- Additional toggles (line/name)
btnLineToggle.MouseButton1Click:Connect(function()
    local en = btnLineToggle.Text ~= "ON"
    if en then btnLineToggle.Text = "ON"; btnLineToggle.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnLineToggle.Text = "OFF"; btnLineToggle.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)
btnLineTeam.MouseButton1Click:Connect(function()
    local en = btnLineTeam.Text ~= "ON"
    if en then btnLineTeam.Text = "ON"; btnLineTeam.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnLineTeam.Text = "OFF"; btnLineTeam.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)
btnNameToggle.MouseButton1Click:Connect(function()
    local en = btnNameToggle.Text ~= "ON"
    if en then btnNameToggle.Text = "ON"; btnNameToggle.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnNameToggle.Text = "OFF"; btnNameToggle.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)
btnNameTeam.MouseButton1Click:Connect(function()
    local en = btnNameTeam.Text ~= "ON"
    if en then btnNameTeam.Text = "ON"; btnNameTeam.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnNameTeam.Text = "OFF"; btnNameTeam.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)

-- ADDED: handlers for distance toggles
btnDistToggle.MouseButton1Click:Connect(function()
    local en = btnDistToggle.Text ~= "ON"
    if en then btnDistToggle.Text = "ON"; btnDistToggle.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnDistToggle.Text = "OFF"; btnDistToggle.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)
btnDistTeam.MouseButton1Click:Connect(function()
    local en = btnDistTeam.Text ~= "ON"
    if en then btnDistTeam.Text = "ON"; btnDistTeam.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnDistTeam.Text = "OFF"; btnDistTeam.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)

-- Aimbot tab controls (placed in scroll)
local lblAimCont, lblAim, btnAim = createToggleInScroll(aimbotScroll, "Ativar Aimbot")
local lblTeamCont2, lblTeam, btnTeam = createToggleInScroll(aimbotScroll, "Não grudar no time")
local lblWallCont, lblWallCheck, btnWallCheck = createToggleInScroll(aimbotScroll, "Checagem de Paredes")

local lblFOV = Instance.new("Frame", aimbotScroll)
lblFOV.Size = UDim2.new(1,0,0,44)
lblFOV.BackgroundTransparency = 1
local lblFOVText = Instance.new("TextLabel", lblFOV)
lblFOVText.Size = UDim2.new(1, -140, 0, 20)
lblFOVText.Position = UDim2.new(0,8,0,6)
lblFOVText.BackgroundTransparency = 1
lblFOVText.Text = "Tamanho FOV (50-300)"
lblFOVText.TextXAlignment = Enum.TextXAlignment.Left
lblFOVText.Font = Enum.Font.Gotham
lblFOVText.TextSize = 14
lblFOVText.TextColor3 = Color3.fromRGB(220,220,220)

local fovBox = Instance.new("TextBox", lblFOV)
fovBox.Size = UDim2.new(0, 110, 0, 32)
fovBox.Position = UDim2.new(1, -126, 0, 6)
fovBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
fovBox.TextColor3 = Color3.fromRGB(255,255,255)
fovBox.Text = tostring(FOVRadius)
fovBox.Font = Enum.Font.GothamBold
fovBox.TextSize = 13
Instance.new("UICorner", fovBox).CornerRadius = UDim.new(0,8)

local lblAimMode = Instance.new("Frame", aimbotScroll)
lblAimMode.Size = UDim2.new(1,0,0,44)
lblAimMode.BackgroundTransparency = 1
local lblAimModeText = Instance.new("TextLabel", lblAimMode)
lblAimModeText.Size = UDim2.new(1, -140, 0, 20)
lblAimModeText.Position = UDim2.new(0,8,0,6)
lblAimModeText.BackgroundTransparency = 1
lblAimModeText.Text = "Modo de Mira"
lblAimModeText.TextXAlignment = Enum.TextXAlignment.Left
lblAimModeText.Font = Enum.Font.Gotham
lblAimModeText.TextSize = 14
lblAimModeText.TextColor3 = Color3.fromRGB(220,220,220)

local btnAimHead = Instance.new("TextButton", lblAimMode)
btnAimHead.Size = UDim2.new(0, 80, 0, 32)
btnAimHead.Position = UDim2.new(1, -216, 0, 6)
btnAimHead.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnAimHead.TextColor3 = Color3.fromRGB(255,255,255)
btnAimHead.Text = "Head"
btnAimHead.Font = Enum.Font.GothamBold
btnAimHead.TextSize = 13
Instance.new("UICorner", btnAimHead).CornerRadius = UDim.new(0,8)

local btnAimChest = Instance.new("TextButton", lblAimMode)
btnAimChest.Size = UDim2.new(0, 80, 0, 32)
btnAimChest.Position = UDim2.new(1, -126, 0, 6)
btnAimChest.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnAimChest.TextColor3 = Color3.fromRGB(255,255,255)
btnAimChest.Text = "Chest"
btnAimChest.Font = Enum.Font.GothamBold
btnAimChest.TextSize = 13
Instance.new("UICorner", btnAimChest).CornerRadius = UDim.new(0,8)

local function updateAimModeButtons()
    if AimMode == "Head" then
        btnAimHead.BackgroundColor3 = Color3.fromRGB(200,50,50); btnAimHead.Text = "Head Ativado"
        btnAimChest.BackgroundColor3 = Color3.fromRGB(60,60,60); btnAimChest.Text = "Chest"
    else
        btnAimChest.BackgroundColor3 = Color3.fromRGB(200,50,50); btnAimChest.Text = "Chest Ativado"
        btnAimHead.BackgroundColor3 = Color3.fromRGB(60,60,60); btnAimHead.Text = "Head"
    end
end

btnAimHead.MouseButton1Click:Connect(function() AimMode = "Head"; updateAimModeButtons() end)
btnAimChest.MouseButton1Click:Connect(function() AimMode = "Chest"; updateAimModeButtons() end)
updateAimModeButtons()

btnAim.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    if AimbotEnabled then btnAim.Text = "ON"; btnAim.BackgroundColor3 = Color3.fromRGB(200,50,50); FOVFrame.Visible = true
    else btnAim.Text = "OFF"; btnAim.BackgroundColor3 = Color3.fromRGB(60,60,60); FOVFrame.Visible = false end
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

fovBox.FocusLost:Connect(function()
    local val = tonumber(fovBox.Text)
    if val then FOVRadius = math.clamp(val, 50, 300); FOVFrame.Size = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)
    else fovBox.Text = tostring(FOVRadius) end
end)

-- Visual tab controls (shortened - same behavior)
local lblFOVRainbowCont, lblFOVRainbow, btnFOVRainbow = createToggleInScroll(visualScroll, "FOV RGB")
local fovColorRowCont = Instance.new("Frame", visualScroll)
fovColorRowCont.Size = UDim2.new(1,0,0,44)
fovColorRowCont.BackgroundTransparency = 1
local fovColorBox = Instance.new("TextBox", fovColorRowCont)
fovColorBox.Size = UDim2.new(0, 110, 0, 32)
fovColorBox.Position = UDim2.new(1, -126, 0, 6)
fovColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
fovColorBox.TextColor3 = Color3.fromRGB(255,255,255)
fovColorBox.Text = tostring(math.floor(FOVColor.R*255))..","..tostring(math.floor(FOVColor.G*255))..","..tostring(math.floor(FOVColor.B*255))
fovColorBox.Font = Enum.Font.GothamBold
fovColorBox.TextSize = 13
Instance.new("UICorner", fovColorBox).CornerRadius = UDim.new(0,8)

local lblSlowCont, lblSlow, btnSlow = createToggleInScroll(visualScroll, "Slow Motion PvP")
local lblSkyCont, lblSkyMode, btnSkyMode = createToggleInScroll(visualScroll, "Modo Cielo PvP Suave")
local lblNoclipCont, lblNoclip, btnNoclip = createToggleInScroll(visualScroll, "Wall Hacker (Noclip)")

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
        if not FOVRainbow then UIStroke.Color = FOVColor end
    else fovColorBox.Text = tostring(math.floor(FOVColor.R*255))..","..tostring(math.floor(FOVColor.G*255))..","..tostring(math.floor(FOVColor.B*255)) end
end)

btnSlow.MouseButton1Click:Connect(function()
    SlowMotionEnabled = not SlowMotionEnabled
    if SlowMotionEnabled then btnSlow.Text = "ON"; btnSlow.BackgroundColor3 = Color3.fromRGB(200,50,50)
        local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 0.25}); tween:Play(); pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(true) end); workspace.Gravity = 100
    else btnSlow.Text = "OFF"; btnSlow.BackgroundColor3 = Color3.fromRGB(60,60,60); local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 1}); tween:Play(); workspace.Gravity = 196.2 end
end)

btnSkyMode.MouseButton1Click:Connect(function()
    PvPSkyEnabled = not PvPSkyEnabled
    if PvPSkyEnabled then
        btnSkyMode.Text = "ON"; btnSkyMode.BackgroundColor3 = Color3.fromRGB(200,50,50)
        Lighting.Ambient = Color3.fromRGB(120,130,140); Lighting.OutdoorAmbient = Color3.fromRGB(90,100,110); Lighting.Brightness = 1.5; Lighting.ClockTime = 18.5
        if OriginalSky then OriginalSky.Enabled = false end
        local PvPSky = Instance.new("Sky"); PvPSky.Name = "PvPSky"
        PvPSky.SkyboxBk = "rbxassetid://1022207611"; PvPSky.SkyboxDn = "rbxassetid://1022207683"; PvPSky.SkyboxFt = "rbxassetid://1022207746"
        PvPSky.SkyboxLf = "rbxassetid://1022207814"; PvPSky.SkyboxRt = "rbxassetid://1022207886"; PvPSky.SkyboxUp = "rbxassetid://1022207958"
        PvPSky.Parent = Lighting
        StarsGui = Instance.new("ScreenGui", game.CoreGui); StarsGui.Name = "StarsGui"; StarsGui.IgnoreGuiInset = true; StarsGui.ResetOnSpawn = false
        for i = 1, 50 do
            local star = Instance.new("Frame")
            star.Size = UDim2.new(0, 2, 0, 2)
            star.Position = UDim2.new(math.random(), 0, math.random(), 0)
            star.BackgroundColor3 = Color3.new(1, 1, 1)
            star.BackgroundTransparency = 0.7
            star.BorderSizePixel = 0
            star.AnchorPoint = Vector2.new(0.5, 0.5)
            star.Parent = StarsGui
            coroutine.wrap(function() while StarsGui and StarsGui.Parent do star.BackgroundTransparency = 0.5 + math.sin(tick() * math.random(1,3)) * 0.4; wait(0.1) end end)()
        end
    else
        btnSkyMode.Text = "OFF"; btnSkyMode.BackgroundColor3 = Color3.fromRGB(60,60,60)
        Lighting.Ambient = OriginalAmbient; Lighting.OutdoorAmbient = OriginalOutdoorAmbient; Lighting.Brightness = OriginalBrightness; Lighting.ClockTime = OriginalClockTime
        local PvPSky = Lighting:FindFirstChild("PvPSky"); if PvPSky then PvPSky:Destroy() end
        if OriginalSky then OriginalSky.Enabled = true end
        if StarsGui then StarsGui:Destroy(); StarsGui = nil end
    end
end)

-- Noclip functions
local originalCollision = {}
local function enableNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    originalCollision = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local ok, prev = pcall(function() return part.CanCollide end)
            if ok then originalCollision[part] = prev; pcall(function() part.CanCollide = false end) end
        end
    end
    if not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            local ch = LocalPlayer.Character
            if not ch then return end
            for _, part in ipairs(ch:GetDescendants()) do
                if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
            end
        end)
    end
end

local function disableNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    for part, prev in pairs(originalCollision) do
        if part and part.Parent then pcall(function() part.CanCollide = prev end) end
    end
    originalCollision = {}
end

btnNoclip.MouseButton1Click:Connect(function()
    NoclipEnabled = not NoclipEnabled
    if NoclipEnabled then btnNoclip.Text = "ON"; btnNoclip.BackgroundColor3 = Color3.fromRGB(200,50,50); enableNoclip(); ShowTempMsg(rootFrame, "Noclip ativado", 2)
    else btnNoclip.Text = "OFF"; btnNoclip.BackgroundColor3 = Color3.fromRGB(60,60,60); disableNoclip(); ShowTempMsg(rootFrame, "Noclip desativado", 2) end
end)

-- WalkSpeed
local WalkSpeedValue = 16
local lblSpeed = Instance.new("TextLabel", visualScroll)
lblSpeed.Size = UDim2.new(1, -140, 0, 20)
lblSpeed.Position = UDim2.new(0, 8, 0, 0)
lblSpeed.BackgroundTransparency = 1
lblSpeed.Text = "Velocidade (WalkSpeed)"
lblSpeed.TextXAlignment = Enum.TextXAlignment.Left
lblSpeed.Font = Enum.Font.Gotham
lblSpeed.TextSize = 14
lblSpeed.TextColor3 = Color3.fromRGB(220,220,220)

local speedBox = Instance.new("TextBox", visualScroll)
speedBox.Size = UDim2.new(0, 110, 0, 32)
speedBox.Position = UDim2.new(1, -126, 0, 6)
speedBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedBox.TextColor3 = Color3.fromRGB(255,255,255)
speedBox.Text = tostring(WalkSpeedValue)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 13
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0,8)

speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val and val > 0 then
        WalkSpeedValue = val
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = WalkSpeedValue
        end
    else speedBox.Text = tostring(WalkSpeedValue) end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = WalkSpeedValue
end)

-- Optimization tab (same as before)
local btnImproveFPS = Instance.new("TextButton", optimScroll)
btnImproveFPS.Size = UDim2.new(0, 220, 0, 32)
btnImproveFPS.BackgroundColor3 = Color3.fromRGB(45,45,45)
btnImproveFPS.Position = UDim2.new(0, 8, 0, 6)
btnImproveFPS.Text = "Melhorar fps"
btnImproveFPS.Font = Enum.Font.GothamBold
btnImproveFPS.TextSize = 14
btnImproveFPS.TextColor3 = Color3.fromRGB(235,235,235)
Instance.new("UICorner", btnImproveFPS).CornerRadius = UDim.new(0,8)

btnImproveFPS.MouseButton1Click:Connect(function()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
        elseif v:IsA("Decal") then v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
    end
end)

local lblFPSUnlockCont, lblFPSUnlock, btnFPSUnlock = createToggleInScroll(optimScroll, "FPS desbloqueado")
btnFPSUnlock.MouseButton1Click:Connect(function()
    FPSUnlockerEnabled = not FPSUnlockerEnabled
    if FPSUnlockerEnabled then btnFPSUnlock.Text = "ON"; btnFPSUnlock.BackgroundColor3 = Color3.fromRGB(200,50,50); pcall(function() setfpscap(1000) end)
    else btnFPSUnlock.Text = "OFF"; btnFPSUnlock.BackgroundColor3 = Color3.fromRGB(60,60,60); pcall(function() setfpscap(60) end) end
end)

local btnOptimizePing = Instance.new("TextButton", optimScroll)
btnOptimizePing.Size = UDim2.new(0, 220, 0, 32)
btnOptimizePing.Position = UDim2.new(0, 8, 0, 52)
btnOptimizePing.BackgroundColor3 = Color3.fromRGB(45,45,45)
btnOptimizePing.Text = "Otimizar Ping"
btnOptimizePing.Font = Enum.Font.GothamBold
btnOptimizePing.TextSize = 14
btnOptimizePing.TextColor3 = Color3.fromRGB(235,235,235)
Instance.new("UICorner", btnOptimizePing).CornerRadius = UDim.new(0,8)

btnOptimizePing.MouseButton1Click:Connect(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = false
        elseif obj:IsA("Explosion") then pcall(function() obj.Visible = false end) end
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
        if guiObj:IsA("ImageLabel") or guiObj:IsA("ImageButton") then pcall(function() guiObj.ImageTransparency = 0.2 end) end
    end
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

local btnSkyboxOptim = Instance.new("TextButton", optimScroll)
btnSkyboxOptim.Size = UDim2.new(0, 220, 0, 32)
btnSkyboxOptim.Position = UDim2.new(0, 8, 0, 96)
btnSkyboxOptim.Text = "Skybox PvP"
btnSkyboxOptim.Font = Enum.Font.GothamBold
btnSkyboxOptim.TextSize = 14
btnSkyboxOptim.TextColor3 = Color3.fromRGB(235,235,235)
Instance.new("UICorner", btnSkyboxOptim).CornerRadius = UDim.new(0,8)

btnSkyboxOptim.MouseButton1Click:Connect(function()
    for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then v:Destroy() end end
    local sky = Instance.new("Sky", Lighting)
    sky.SkyboxBk = "rbxassetid://159454299"; sky.SkyboxDn = "rbxassetid://159454296"; sky.SkyboxFt = "rbxassetid://159454293"
    sky.SkyboxLf = "rbxassetid://159454286"; sky.SkyboxRt = "rbxassetid://159454300"; sky.SkyboxUp = "rbxassetid://159454288"
    pcall(function() sky.StarCount = 3000; sky.SunAngularSize = 0; sky.MoonAngularSize = 11 end)
    Lighting.TimeOfDay = "18:00:00"
end)

-- Highlight utilities
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
    if player.Character then ApplyHighlight(player) end
end
Players.PlayerAdded:Connect(function(player) SetupCharacterHighlight(player) end)

-- Aimbot logic
local function GetClosestTarget()
    local closest = nil
    local shortestDist = FOVRadius
    local cam = Camera
    if not cam then return nil end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if TeamCheck and player.Team == LocalPlayer.Team then continue end
            local aimPoint = GetAimPoint(player.Character)
            if not aimPoint then continue end
            local pos, onScreen = cam:WorldToViewportPoint(aimPoint)
            if not onScreen then continue end
            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
            if dist <= shortestDist then
                if WallCheck then
                    local origin = cam.CFrame.Position
                    local direction = (aimPoint - origin).Unit * 1000
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local result = workspace:Raycast(origin, direction, raycastParams)
                    if result and result.Instance and result.Instance:IsDescendantOf(player.Character) then
                        closest = player; shortestDist = dist
                    end
                else
                    closest = player; shortestDist = dist
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if FOVRainbow then
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 1, 1)
        UIStroke.Color = color
    end
    FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    FOVFrame.Size = UDim2.new(0, FOVRadius*2, 0, FOVRadius*2)
    if AimbotEnabled then
        local target = GetClosestTarget()
        if target and target.Character then
            local aimPos = GetAimPoint(target.Character)
            if aimPos then
                local camPos = Camera.CFrame.Position
                local newCF = CFrame.new(camPos, aimPos)
                Camera.CFrame = Camera.CFrame:Lerp(newCF, 0.4)
            end
        end
    end
end)

-- Minimize behavior
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

minimizeBtn.MouseButton1Click:Connect(function() rootFrame.Visible = false; miniBtn.Visible = true end)
miniBtn.MouseButton1Click:Connect(function() rootFrame.Visible = true; miniBtn.Visible = false end)

LocalPlayer.CharacterRemoving:Connect(function() disableNoclip() end)
LocalPlayer.CharacterAdded:Connect(function(char)
    if NoclipEnabled then
        task.defer(function() repeat task.wait() until char and char:FindFirstChild("HumanoidRootPart"); enableNoclip() end)
    end
end)

-- ========== Drawing-based ESP implementation ==========
-- This uses Drawing API when available. It respects the toggle buttons states above.
local espObjects = {}
local function removeESP(plr)
    if espObjects[plr] then
        for _, obj in pairs(espObjects[plr]) do
            if obj and obj.Remove then
                pcall(function() obj:Remove() end)
            end
        end
        espObjects[plr] = nil
    end
end

local function parseColor(txt, default)
    local r,g,b = txt:match("(%d+),%s*(%d+),%s*(%d+)")
    if r and g and b then
        return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
    end
    return default
end

local function addESP(plr)
    if not Drawing then return end
    if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    removeESP(plr)
    espObjects[plr] = {}

    local box = Drawing.new("Square")
    box.Color = parseColor(boxColorBox.Text, Color3.fromRGB(255,0,0))
    box.Thickness = 1
    box.Filled = false
    box.Visible = false
    table.insert(espObjects[plr], box)

    local line = Drawing.new("Line")
    line.Color = parseColor(lineColorBox.Text, Color3.fromRGB(255,0,0))
    line.Thickness = 1
    line.Visible = false
    table.insert(espObjects[plr], line)

    local name = Drawing.new("Text")
    name.Color = parseColor(nameColorBox.Text, Color3.fromRGB(255,0,0))
    name.Size = 7
    name.Center = true
    name.Outline = true
    name.Text = plr.Name
    name.Visible = false
    table.insert(espObjects[plr], name)

    local distText = Drawing.new("Text")
    distText.Color = Color3.fromRGB(255,255,255)
    distText.Size = 8
    distText.Center = true
    distText.Outline = true
    distText.Visible = false
    table.insert(espObjects[plr], distText)

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not plr or not plr.Parent then
            if conn then conn:Disconnect() end
            removeESP(plr)
            return
        end
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local root = plr.Character.HumanoidRootPart
            local pos, vis = Camera:WorldToViewportPoint(root.Position)
            if vis then
                local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                local scale = humanoid and humanoid.HipHeight + 2 or 1
                local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, scale, 0))
                local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2, 0))
                local height = math.abs(top.Y - bottom.Y) * 1.5
local width = math.clamp(height * 0.45, 10, 400)

                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                box.Color = parseColor(boxColorBox.Text, box.Color)
                box.Visible = (btnESPBox.Text == "ON") and (not btnESPBoxTeam or btnESPBoxTeam.Text ~= "ON" or plr.Team ~= LocalPlayer.Team)

                line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Color = parseColor(lineColorBox.Text, line.Color)
                line.Visible = (btnLineToggle.Text == "ON") and (not btnLineTeam or btnLineTeam.Text ~= "ON" or plr.Team ~= LocalPlayer.Team)

                name.Position = Vector2.new(pos.X, pos.Y - height/2 - 14)
name.Text = plr.Name
name.Color = parseColor(nameColorBox.Text, name.Color)
name.Visible = (btnNameToggle.Text == "ON") and (not btnNameTeam or btnNameTeam.Text ~= "ON" or plr.Team ~= LocalPlayer.Team)

                local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude) or 0
                distText.Text = tostring(dist).."m"
                distText.Position = Vector2.new(pos.X, pos.Y + height/2 + 2)
                -- USE THE NEW DISTANCE TOGGLE HERE:
                distText.Visible = (btnDistToggle.Text == "ON") and (not btnDistTeam or btnDistTeam.Text ~= "ON" or plr.Team ~= LocalPlayer.Team)
            else
                for _, obj in pairs(espObjects[plr]) do obj.Visible = false end
            end
        else
            for _, obj in pairs(espObjects[plr]) do obj.Visible = false end
        end
    end)
end

local function tryAddESP(plr)
    if plr == LocalPlayer then return end
    local function onCharacter(char)
        task.wait(0.5)
        removeESP(plr)
        addESP(plr)
    end
    if plr.Character then onCharacter(plr.Character) end
    plr.CharacterAdded:Connect(onCharacter)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        tryAddESP(plr)
    end)
end)
for _, pl in ipairs(Players:GetPlayers()) do tryAddESP(pl) end

-- Bind ESP updater: ensures we remove objects when ESP disabled
RunService:BindToRenderStep("ESP_Draw_Update", Enum.RenderPriority.Camera.Value + 1, function()
    -- nothing heavy here because individual drawing connections handle visibility
end)

-- Reflow canvas sizes for tab scrolls (keeps layout tidy)
local function UpdateScrollCanvas(scroll)
    delay(0.05, function()
        local total = 0
        for _, v in ipairs(scroll:GetChildren()) do
            if v:IsA("Frame") then total = total + v.AbsoluteSize.Y end
            if v:IsA("TextButton") then total = total + v.AbsoluteSize.Y end
        end
        scroll.CanvasSize = UDim2.new(0,0,0, total + 20)
    end)
end

-- Update all scrolls periodically to ensure proper sizes (after UI construction)
UpdateScrollCanvas(espScroll)
UpdateScrollCanvas(aimbotScroll)
UpdateScrollCanvas(visualScroll)
UpdateScrollCanvas(outrosScroll)
UpdateScrollCanvas(optimScroll)

-- Final print
print("[XIT PAINEL] carregado: painel corrigido (layout de toggles/alinhamento), aimbot e ESP integrados.")