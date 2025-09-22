-- Combined Panel + Functionality Script (com Wall Hacker e UI de Armas)
-- Integrates features from script.lua into the floating panel (base.lua) UI.
-- Self-contained. No external dependencies. Paste into a LocalScript in StarterPlayerScripts or execute via executor.

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

-- retorna o ponto de mira no personagem: respeita AimMode ("Head" ou "Chest")
local function GetAimPoint(character)
    if not character then return nil end

    local head = character:FindFirstChild("Head")
    local upperTorso = character:FindFirstChild("UpperTorso")
    local torso = character:FindFirstChild("Torso")
    local hrp  = character:FindFirstChild("HumanoidRootPart")

    -- prefer head when requested
    if AimMode == "Head" then
        if head and head:IsA("BasePart") then
            return head.Position
        end
        -- fallback to chest/torso/hrp if head missing
        if upperTorso and upperTorso:IsA("BasePart") then
            return upperTorso.Position + Vector3.new(0, 0.3, 0)
        elseif torso and torso:IsA("BasePart") then
            return torso.Position + Vector3.new(0, 0.3, 0)
        elseif hrp and hrp:IsA("BasePart") then
            return hrp.Position + Vector3.new(0, 1.0, 0)
        end
    else -- AimMode == "Chest"
        -- prefer chest (UpperTorso/Torso) first
        if upperTorso and upperTorso:IsA("BasePart") then
            return upperTorso.Position + Vector3.new(0, 0.3, 0)
        elseif torso and torso:IsA("BasePart") then
            return torso.Position + Vector3.new(0, 0.3, 0)
        elseif hrp and hrp:IsA("BasePart") then
            return hrp.Position + Vector3.new(0, 1.0, 0)
        end
        -- fallback to head if chest parts missing
        if head and head:IsA("BasePart") then
            return head.Position
        end
    end

    return nil
end

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

-- Wall Hacker (noclip) adicional
local NoclipEnabled = false
local noclipConn = nil

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
minimizeBtn.Text = "â"
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
local btnOptim = makeSideButton("OtimizaÃ§Ã£o", 150)

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
    frameOptim.Visible = (name == "OtimizaÃ§Ã£o")
    btnESP.BackgroundColor3 = (name=="ESP") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnAimbot.BackgroundColor3 = (name=="Aimbot") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnVisual.BackgroundColor3 = (name=="Visual") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
    btnOptim.BackgroundColor3 = (name=="OtimizaÃ§Ã£o") and Color3.fromRGB(80,40,160) or Color3.fromRGB(15,15,15)
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

-- ========== ESP BOX (ATUALIZADO) ==========
local ESPBoxEnabled = false
local ESPBoxTeamCheck = true
local ESPBoxColor = HighlightColor -- inicial

local lblESPBox, btnESPBox = createToggle(frameESP, "Ativar ESP Box", 138)
local lblESPBoxTeam, btnESPBoxTeam = createToggle(frameESP, "Checagem de time (Box)", 178)

local lblBoxColor = Instance.new("TextLabel", frameESP)
lblBoxColor.Size = UDim2.new(1, -24, 0, 20)
lblBoxColor.Position = UDim2.new(0, 12, 0, 218)
lblBoxColor.BackgroundTransparency = 1
lblBoxColor.Text = "Cor do Box (R,G,B)"
lblBoxColor.TextXAlignment = Enum.TextXAlignment.Left
lblBoxColor.Font = Enum.Font.Gotham
lblBoxColor.TextSize = 14
lblBoxColor.TextColor3 = Color3.fromRGB(220,220,220)

local boxColorBox = Instance.new("TextBox", frameESP)
boxColorBox.Size = UDim2.new(0, 110, 0, 32)
boxColorBox.Position = UDim2.new(1, -126, 0, 212)
boxColorBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
boxColorBox.TextColor3 = Color3.fromRGB(255,255,255)
boxColorBox.Text = tostring(math.floor(ESPBoxColor.R*255))..","..tostring(math.floor(ESPBoxColor.G*255))..","..tostring(math.floor(ESPBoxColor.B*255))
boxColorBox.Font = Enum.Font.GothamBold
boxColorBox.TextSize = 13
Instance.new("UICorner", boxColorBox).CornerRadius = UDim.new(0,8)

local espBoxes = {}

local function CreateBoxForPlayer(player)
    if espBoxes[player] then return end
    local outer = Instance.new("Frame", drawContainer)
    outer.Name = "ESPBox_"..player.Name
    outer.BackgroundTransparency = 1
    outer.BorderSizePixel = 0
    outer.ZIndex = 60

    local outline = Instance.new("Frame", outer)
    outline.Name = "Outline"
    outline.AnchorPoint = Vector2.new(0.5, 0.5)
    outline.BackgroundTransparency = 1
    outline.ZIndex = 61

    local top = Instance.new("Frame", outline); top.Name = "Top"; top.AnchorPoint = Vector2.new(0,0)
    local left = Instance.new("Frame", outline); left.Name = "Left"; left.AnchorPoint = Vector2.new(0,0)
    local right = Instance.new("Frame", outline); right.Name = "Right"; right.AnchorPoint = Vector2.new(0,0)
    local bottom = Instance.new("Frame", outline); bottom.Name = "Bottom"; bottom.AnchorPoint = Vector2.new(0,0)

    for _, part in pairs({top,left,right,bottom}) do
        part.BackgroundColor3 = ESPBoxColor
        part.BackgroundTransparency = 0
        part.BorderSizePixel = 0
        part.ZIndex = 62
    end

    local nameLabel = Instance.new("TextLabel", outline)
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = ESPBoxColor
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.ZIndex = 63
    nameLabel.Text = player.Name

    espBoxes[player] = {
        container = outer,
        top = top, left = left, right = right, bottom = bottom,
        nameLabel = nameLabel
    }
end

local function RemoveBoxForPlayer(player)
    local t = espBoxes[player]
    if t then
        pcall(function() t.container:Destroy() end)
        espBoxes[player] = nil
    end
end

-- Atualiza boxes (mantÃ©m entradas mesmo se char ausente)
local function UpdateESPBoxes()
    local cam = Camera
    if not cam then return end
    for player, data in pairs(espBoxes) do
        if not data or not data.container then
            espBoxes[player] = nil
        else
            -- Sempre manter o texto atualizado (nome + estado)
            local username = player.Name
            local char = player.Character
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
            -- apply team visibility rule
            if ESPBoxTeamCheck and player.Team == LocalPlayer.Team then
                data.container.Visible = false
            else
                data.container.Visible = ESPEnabled and ESPBoxEnabled
            end

            -- Se nÃ£o deve estar visÃ­vel, apenas atualizar label (por exemplo quando ESP desligado)
            if not (ESPEnabled and ESPBoxEnabled and (not (ESPBoxTeamCheck and player.Team == LocalPlayer.Team))) then
                -- atualizar nome/estado para manter sincronizado
                data.nameLabel.Text = username .. (hrp and "" or " (morto)")
                data.nameLabel.TextColor3 = ESPBoxColor
                -- manter invisÃ­vel e pular cÃ¡lculo de projeÃ§Ã£o
                data.container.Visible = false
            else
                if not hrp then
                    -- jogador respawnou ou morreu; esconder box mas manter label
                    data.nameLabel.Text = username .. " (morto)"
                    data.container.Visible = false
                else
                    -- calcular projeÃ§Ã£o mesmo que parte esteja parcialmente fora da tela
                    local head = char:FindFirstChild("Head") or hrp
                    local topPos, topOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0,0.3,0))
                    local bottomPos, bottomOn = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0,1.0,0))
                    -- se nenhum dos pontos estiverem onScreen, ainda atualizamos o nome (box invisÃ­vel)
                    if not topOn and not bottomOn then
                        data.container.Visible = false
                        data.nameLabel.Text = username
                        data.nameLabel.TextColor3 = ESPBoxColor
                    else
                        -- exibir e posicionar
                        data.container.Visible = true
                        local top2 = Vector2.new(topPos.X, topPos.Y)
                        local bot2 = Vector2.new(bottomPos.X, bottomPos.Y)
                        local height = math.max(10, (bot2 - top2).Magnitude)
                        local width = math.clamp(height * 0.45, 10, 400)
                        local center = (top2 + bot2) / 2
                        data.container.Position = UDim2.new(0, center.X - width/2, 0, center.Y - height/2)
                        data.container.Size = UDim2.new(0, width, 0, height)

                        local borderThickness = math.max(1, math.floor(math.clamp(width,1,10) * 0.06))
                        data.top.Position = UDim2.new(0, 0, 0, 0)
                        data.top.Size = UDim2.new(1, 0, 0, borderThickness)
                        data.bottom.Position = UDim2.new(0, 0, 1, -borderThickness)
                        data.bottom.Size = UDim2.new(1, 0, 0, borderThickness)
                        data.left.Position = UDim2.new(0, 0, 0, 0)
                        data.left.Size = UDim2.new(0, borderThickness, 1, 0)
                        data.right.Position = UDim2.new(1, -borderThickness, 0, 0)
                        data.right.Size = UDim2.new(0, borderThickness, 1, 0)

                        data.nameLabel.Position = UDim2.new(0.5, 0, 0, -18)
                        data.nameLabel.Size = UDim2.new(0, 200, 0, 16)
                        data.nameLabel.Text = username
                        data.nameLabel.TextColor3 = ESPBoxColor
                        data.nameLabel.TextStrokeTransparency = 0.8
                        data.nameLabel.TextXAlignment = Enum.TextXAlignment.Center
                        data.nameLabel.AnchorPoint = Vector2.new(0.5, 0)
                    end
                end
            end
        end
    end
end

-- Hooks: criar entradas para todos os players jÃ¡ conectados e escutar CharacterAdded
for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then
        CreateBoxForPlayer(pl)
        -- quando o personagem aparecer, reaplicar dados (nÃ£o recriar duplicado)
        pl.CharacterAdded:Connect(function()
            -- small wait to allow parts to replicate
            repeat task.wait() until pl.Character and (pl.Character:FindFirstChild("HumanoidRootPart") or pl.Character:FindFirstChild("Torso") or pl.Character:FindFirstChild("UpperTorso")) or not pl.Parent
            -- garantir que o box exista
            CreateBoxForPlayer(pl)
        end)
        -- quando trocar team, forÃ§ar redraw (se teleportFrame visÃ­vel ou ESP ligado)
        pl:GetPropertyChangedSignal("Team"):Connect(function()
            -- nÃ£o destrÃ³i, apenas atualiza cor/vis
            if espBoxes[pl] and espBoxes[pl].nameLabel then
                espBoxes[pl].nameLabel.Text = pl.Name
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        CreateBoxForPlayer(p)
        p.CharacterAdded:Connect(function()
            repeat task.wait() until p.Character and (p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("UpperTorso"))
            CreateBoxForPlayer(p)
        end)
        p:GetPropertyChangedSignal("Team"):Connect(function()
            if espBoxes[p] and espBoxes[p].nameLabel then
                espBoxes[p].nameLabel.Text = p.Name
            end
        end)
    end
end)
Players.PlayerRemoving:Connect(function(p) RemoveBoxForPlayer(p) end)

-- Toggle handler
btnESPBox.MouseButton1Click:Connect(function()
    ESPBoxEnabled = not ESPBoxEnabled
    if ESPBoxEnabled then
        btnESPBox.Text = "ON"; btnESPBox.BackgroundColor3 = Color3.fromRGB(200,50,50)
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer then CreateBoxForPlayer(pl) end
        end
    else
        btnESPBox.Text = "OFF"; btnESPBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
        for p,_ in pairs(espBoxes) do
            if espBoxes[p] and espBoxes[p].container then espBoxes[p].container.Visible = false end
        end
    end
end)

btnESPBoxTeam.MouseButton1Click:Connect(function()
    ESPBoxTeamCheck = not ESPBoxTeamCheck
    if ESPBoxTeamCheck then btnESPBoxTeam.Text = "ON"; btnESPBoxTeam.BackgroundColor3 = Color3.fromRGB(200,50,50)
    else btnESPBoxTeam.Text = "OFF"; btnESPBoxTeam.BackgroundColor3 = Color3.fromRGB(60,60,60) end
end)

boxColorBox.FocusLost:Connect(function(enter)
    local txt = boxColorBox.Text
    local r,g,b = txt:match("(%d+),%s*(%d+),%s*(%d+)")
    if r and g and b then
        local rr = math.clamp(tonumber(r)/255,0,1)
        local gg = math.clamp(tonumber(g)/255,0,1)
        local bb = math.clamp(tonumber(b)/255,0,1)
        ESPBoxColor = Color3.new(rr,gg,bb)
        for _, data in pairs(espBoxes) do
            pcall(function()
                data.top.BackgroundColor3 = ESPBoxColor
                data.left.BackgroundColor3 = ESPBoxColor
                data.right.BackgroundColor3 = ESPBoxColor
                data.bottom.BackgroundColor3 = ESPBoxColor
                data.nameLabel.TextColor3 = ESPBoxColor
            end)
        end
    else
        boxColorBox.Text = tostring(math.floor(ESPBoxColor.R*255)) .. "," .. tostring(math.floor(ESPBoxColor.G*255)) .. "," .. tostring(math.floor(ESPBoxColor.B*255))
    end
end)

-- Bind render step (mantÃ©m o mesmo nome mas garante update contÃ­nuo)
RunService:BindToRenderStep("ESPBoxUpdater", Enum.RenderPriority.Camera.Value + 1, function()
    if ESPBoxEnabled and ESPEnabled then
        UpdateESPBoxes()
    else
        for p,data in pairs(espBoxes) do
            if data and data.container then data.container.Visible = false end
        end
    end
end)
-- ========== FIM ESP BOX ==========

-- =======================
-- Teleport to Enemy UI + Funcionalidade (MELHORADO)
-- =======================
local lblTeleport = Instance.new("TextLabel", frameESP)
lblTeleport.Size = UDim2.new(1, -24, 0, 20)
lblTeleport.Position = UDim2.new(0, 12, 0, 252)
lblTeleport.BackgroundTransparency = 1
lblTeleport.Text = "Teleportar para Inimigos"
lblTeleport.TextXAlignment = Enum.TextXAlignment.Left
lblTeleport.Font = Enum.Font.Gotham
lblTeleport.TextSize = 14
lblTeleport.TextColor3 = Color3.fromRGB(220,220,220)

local btnOpenTeleport = Instance.new("TextButton", frameESP)
btnOpenTeleport.Size = UDim2.new(0, 110, 0, 32)
btnOpenTeleport.Position = UDim2.new(1, -126, 0, 246)
btnOpenTeleport.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnOpenTeleport.TextColor3 = Color3.fromRGB(255,255,255)
btnOpenTeleport.Text = "Abrir"
btnOpenTeleport.Font = Enum.Font.GothamBold
btnOpenTeleport.TextSize = 13
Instance.new("UICorner", btnOpenTeleport).CornerRadius = UDim.new(0,8)

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
teleportTitle.Text = "Teleport â Inimigos"
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

local scroll = Instance.new("ScrollingFrame", teleportFrame)
scroll.Size = UDim2.new(1, -12, 1, -46)
scroll.Position = UDim2.new(0, 6, 0, 38)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 201

local uiList = Instance.new("UIListLayout", scroll)
uiList.Padding = UDim.new(0,6)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local function ClearTeleportButtons()
    for _, child in ipairs(scroll:GetChildren()) do
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

-- Teleport helper: tenta teleportar imediatamente; se HRP nÃ£o existir, tenta por alguns instantes atÃ© achar
local function TeleportToPlayer(pl)
    -- safety: check
    pcall(function()
        if not pl or not pl.Parent then
            ShowTempMsg(teleportFrame, "Alvo invÃ¡lido", 2)
            return
        end
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then
            ShowTempMsg(teleportFrame, "Seu personagem nÃ£o estÃ¡ pronto", 2)
            return
        end

        local attempts = 0
        local maxAttempts = 30 -- 30 * 0.1 = 3 segundos de tentativas
        local found = false

        spawn(function()
            while attempts < maxAttempts and not found do
                attempts = attempts + 1
                local targetChar = pl.Character
                local targetHRP = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso"))
                if targetHRP then
                    found = true
                    -- teleport seguro com offset
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
                -- Ãºltima tentativa: se nÃ£o encontrou, avisar e sugerir esperar aparecer (por streaming)
                ShowTempMsg(teleportFrame, "Falha: alvo nÃ£o replicado no cliente", 3)
            end
        end)
    end)
end

local function PopulateTeleportList()
    ClearTeleportButtons()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            if not ESPBoxTeamCheck or pl.Team ~= LocalPlayer.Team then
                local btn = Instance.new("TextButton", scroll)
                btn.Size = UDim2.new(1, -12, 0, 32)
                btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
                btn.TextColor3 = Color3.fromRGB(235,235,235)
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 14
                btn.Text = pl.Name
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
                btn.ZIndex = 202

                -- cria tooltip com distancia (se possÃ­vel)
                local distLabel = Instance.new("TextLabel", btn)
                distLabel.Size = UDim2.new(0, 56, 1, 0)
                distLabel.Position = UDim2.new(1, -60, 0, 0)
                distLabel.BackgroundTransparency = 1
                distLabel.TextColor3 = Color3.fromRGB(200,200,200)
                distLabel.Font = Enum.Font.Gotham
                distLabel.TextSize = 12
                distLabel.Text = ""

                -- update distance em loop leve (apenas enquanto janela aberta)
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
        for _, v in ipairs(scroll:GetChildren()) do
            if v:IsA("TextButton") then
                total = total + v.AbsoluteSize.Y + uiList.Padding.Offset
            end
        end
        scroll.CanvasSize = UDim2.new(0,0,0, total)
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Escape then
        if teleportFrame.Visible then
            teleportFrame.Visible = false
            btnOpenTeleport.Text = "Abrir"
        end
    end
end)
-- =======================
-- FIM Teleport melhorado
-- =======================

-- =======================
-- ARMS / WEAPONS UI (NOVO)
-- =======================
local lblWeapons = Instance.new("TextLabel", frameESP)
lblWeapons.Size = UDim2.new(1, -24, 0, 20)
lblWeapons.Position = UDim2.new(0, 12, 0, 290)
lblWeapons.BackgroundTransparency = 1
lblWeapons.Text = "Armas disponiveis"
lblWeapons.TextXAlignment = Enum.TextXAlignment.Left
lblWeapons.Font = Enum.Font.Gotham
lblWeapons.TextSize = 14
lblWeapons.TextColor3 = Color3.fromRGB(220,220,220)

local btnOpenWeapons = Instance.new("TextButton", frameESP)
btnOpenWeapons.Size = UDim2.new(0, 110, 0, 32)
btnOpenWeapons.Position = UDim2.new(1, -126, 0, 284)
btnOpenWeapons.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnOpenWeapons.TextColor3 = Color3.fromRGB(255,255,255)
btnOpenWeapons.Text = "Abrir"
btnOpenWeapons.Font = Enum.Font.GothamBold
btnOpenWeapons.TextSize = 13
Instance.new("UICorner", btnOpenWeapons).CornerRadius = UDim.new(0,8)

-- === weaponsFrame (centralizado e arrastÃ¡vel) ===
local weaponsFrame = Instance.new("Frame", screenGui)
weaponsFrame.Name = "WeaponsFrame"
weaponsFrame.Size = UDim2.new(0, 300, 0, 320)
-- posiÃ§Ã£o centralizada na tela (300x320 -> -150, -160 offsets)
weaponsFrame.Position = UDim2.new(0.5, -150, 0.5, -160)
weaponsFrame.AnchorPoint = Vector2.new(0,0)
weaponsFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
weaponsFrame.BorderSizePixel = 0
weaponsFrame.Visible = false
Instance.new("UICorner", weaponsFrame).CornerRadius = UDim.new(0,8)
weaponsFrame.ZIndex = 210

-- === CÃ³digo para arrastar o weaponsFrame ===
weaponsFrame.Active = true  -- necessÃ¡rio para receber Input
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    local newX = startPos.X.Offset + delta.X
    local newY = startPos.Y.Offset + delta.Y
    weaponsFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
end

weaponsFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = weaponsFrame.Position
        -- desconectar quando soltar o botÃ£o/touch
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

weaponsFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        pcall(function() update(input) end)
    end
end)

-- TÃ­tulo (mantive seu cÃ³digo jÃ¡ existente abaixo; nÃ£o precisa alterar)
local weaponsTitle = Instance.new("TextLabel", weaponsFrame)
weaponsTitle.Size = UDim2.new(1, -12, 0, 28)
weaponsTitle.Position = UDim2.new(0, 6, 0, 6)
weaponsTitle.BackgroundTransparency = 1
weaponsTitle.Text = "Armas â Lista"
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

local function ClearWeaponsButtons()
    for _, child in ipairs(weaponsScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function FindAvailableTools()
    -- procura Tools em ReplicatedStorage, Workspace, StarterPack e Backpack
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
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        tryAdd(v, "ReplicatedStorage")
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        tryAdd(v, "Workspace")
    end
    for _, v in ipairs(StarterPack:GetDescendants()) do
        tryAdd(v, "StarterPack")
    end
    -- tambÃ©m checar Backpack e Character tools
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            tryAdd(v, "Backpack")
        end
    end
    if LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
            tryAdd(v, "Character")
        end
    end
    return results
end

local function GiveToolToPlayer(toolInstance)
    if not toolInstance then return false, "Tool invÃ¡lida" end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        return false, "Backpack nÃ£o disponÃ­vel"
    end
    local ok, clone = pcall(function() return toolInstance:Clone() end)
    if not ok or not clone then
        return false, "Falha ao clonar"
    end
    local success, err = pcall(function()
        clone.Parent = backpack
        -- tentar equipar se houver humanoid
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):EquipTool(clone) end)
        end
    end)
    if not success then
        return false, "Erro ao colocar no Backpack: " .. tostring(err)
    end
    return true, "Arma adicionada"
end

local function PopulateWeaponsList()
    ClearWeaponsButtons()
    local tools = FindAvailableTools()
    if #tools == 0 then
        ShowTempMsg(weaponsFrame, "Nenhuma arma local encontrada", 3)
        return
    end
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
            if ok then
                ShowTempMsg(weaponsFrame, "Pegou: " .. t.Name, 2)
            else
                ShowTempMsg(weaponsFrame, "Erro: " .. tostring(msg), 3)
            end
        end)
    end

    delay(0.05, function()
        local total = 0
        for _, v in ipairs(weaponsScroll:GetChildren()) do
            if v:IsA("TextButton") then
                total = total + v.AbsoluteSize.Y + weaponsListLayout.Padding.Offset
            end
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
-- FIM ARMS / WEAPONS UI
-- =======================

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

-- Aim Mode UI (Head / Chest)
local lblAimMode = Instance.new("TextLabel", frameAimbot)
lblAimMode.Size = UDim2.new(1, -24, 0, 20)
lblAimMode.Position = UDim2.new(0, 12, 0, 178)
lblAimMode.BackgroundTransparency = 1
lblAimMode.Text = "Modo de Mira"
lblAimMode.TextXAlignment = Enum.TextXAlignment.Left
lblAimMode.Font = Enum.Font.Gotham
lblAimMode.TextSize = 14
lblAimMode.TextColor3 = Color3.fromRGB(220,220,220)

local btnAimHead = Instance.new("TextButton", frameAimbot)
btnAimHead.Size = UDim2.new(0, 80, 0, 32)
btnAimHead.Position = UDim2.new(1, -216, 0, 172) -- left of chest button
btnAimHead.BackgroundColor3 = Color3.fromRGB(60,60,60)
btnAimHead.TextColor3 = Color3.fromRGB(255,255,255)
btnAimHead.Text = "Head"
btnAimHead.Font = Enum.Font.GothamBold
btnAimHead.TextSize = 13
Instance.new("UICorner", btnAimHead).CornerRadius = UDim.new(0,8)

local btnAimChest = Instance.new("TextButton", frameAimbot)
btnAimChest.Size = UDim2.new(0, 80, 0, 32)
btnAimChest.Position = UDim2.new(1, -126, 0, 172)
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

btnAimHead.MouseButton1Click:Connect(function()
    AimMode = "Head"
    updateAimModeButtons()
end)

btnAimChest.MouseButton1Click:Connect(function()
    AimMode = "Chest"
    updateAimModeButtons()
end)

-- initialize button states
updateAimModeButtons()

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
-- Visual TAB CONTROLS (inclui Noclip)
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

local SlowMotionEnabled = false
local PvPSkyEnabled = false

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

-- Novo: Wall Hacker (Noclip)
local lblNoclip, btnNoclip = createToggle(frameVisual, "Wall Hacker (Noclip)", 178)

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

-- === Noclip (versÃ£o com restore seguro) ===
local originalCollision = {}
-- local noclipConn = nil -- already declared above

local function enableNoclip()
    -- salva estados e desativa colisÃ£o nas partes atuais
    local char = LocalPlayer.Character
    if not char then return end

    -- limpar tabela antiga (caso)
    originalCollision = {}

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local ok, prev = pcall(function() return part.CanCollide end)
            if ok then
                originalCollision[part] = prev
                pcall(function() part.CanCollide = false end)
            end
        end
    end

    -- manter desativado para novas partes usando Stepped
    if not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            local ch = LocalPlayer.Character
            if not ch then return end
            for _, part in ipairs(ch:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end)
    end
end

local function disableNoclip()
    -- desconecta o loop
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end

    -- restaura os estados originais (somente para partes que ainda existem)
    for part, prev in pairs(originalCollision) do
        if part and part.Parent then
            pcall(function() part.CanCollide = prev end)
        end
    end

    originalCollision = {}
end

btnNoclip.MouseButton1Click:Connect(function()
    NoclipEnabled = not NoclipEnabled
    if NoclipEnabled then
        btnNoclip.Text = "ON"; btnNoclip.BackgroundColor3 = Color3.fromRGB(200,50,50)
        enableNoclip()
        ShowTempMsg(rootFrame, "Noclip ativado", 2)
    else
        btnNoclip.Text = "OFF"; btnNoclip.BackgroundColor3 = Color3.fromRGB(60,60,60)
        disableNoclip()
        ShowTempMsg(rootFrame, "Noclip desativado", 2)
    end
end)

-- WalkSpeed Control (aba Visual)
local WalkSpeedValue = 16

local lblSpeed = Instance.new("TextLabel", frameVisual)
lblSpeed.Size = UDim2.new(1, -24, 0, 20)
lblSpeed.Position = UDim2.new(0, 12, 0, 218)
lblSpeed.BackgroundTransparency = 1
lblSpeed.Text = "Velocidade (WalkSpeed)"
lblSpeed.TextXAlignment = Enum.TextXAlignment.Left
lblSpeed.Font = Enum.Font.Gotham
lblSpeed.TextSize = 14
lblSpeed.TextColor3 = Color3.fromRGB(220,220,220)

local speedBox = Instance.new("TextBox", frameVisual)
speedBox.Size = UDim2.new(0, 110, 0, 32)
speedBox.Position = UDim2.new(1, -126, 0, 212)
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
    else
        speedBox.Text = tostring(WalkSpeedValue)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = WalkSpeedValue
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
-- Substitua a funÃ§Ã£o GetClosestTarget inteira por esta:
local function GetClosestTarget()
    local closest = nil
    local shortestDist = FOVRadius
    local cam = Camera
    if not cam then return nil end

    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if TeamCheck and player.Team == LocalPlayer.Team then
                -- pular aliado se opÃ§Ã£o de checar team ativada
                continue
            end

            local aimPoint = GetAimPoint(player.Character)
            if not aimPoint then
                continue
            end

            local pos, onScreen = cam:WorldToViewportPoint(aimPoint)
            if not onScreen then
                continue
            end

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

    return closest
end

-- Substitua o bloco RenderStepped relacionado ao aimbot por este:
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

-- Cleanup Noclip quando personagem morrer/respawn
LocalPlayer.CharacterRemoving:Connect(function()
    -- restaurar para evitar ficar noclip para novos chars
    disableNoclip()
end)

-- Quando o personagem aparece, re-aplicar Noclip se estava ligado
LocalPlayer.CharacterAdded:Connect(function(char)
    if NoclipEnabled then
        -- pequena espera para partes replicarem
        task.defer(function()
            repeat task.wait() until char and char:FindFirstChild("HumanoidRootPart")
            enableNoclip()
        end)
    end
end)

-- =======================
-- End of script
-- =======================
print("[XIT PAINEL] carregado: painel integrado com Aimbot, ESP, Visual, OtimizaÃ§Ã£o, Noclip e Armas (AimMode: "..AimMode..")")