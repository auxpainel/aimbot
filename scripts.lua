local Painel = loadstring(game:HttpGet('https://raw.githubusercontent.com/auxpainel/aimbot/main/base.lua'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Configurações
local AimbotEnabled = false
local TeamCheck = true
local WallCheck = true
local FOVRadius = 100
local ESPEnabled = false
local ESPTeamCheck = true
local HighlightColor = Color3.fromRGB(255, 0, 0)
local FOVRainbow = false
local FOVColor = Color3.fromRGB(0, 255, 0)

-- FPS Unlocker (simulado)
local function setfpscap(value)
    if type(setfpscap) == "function" then
        setfpscap(value)
    else
        warn("FPS Unlocker não está disponível")
    end
end

-- FOV Circle
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XITPainelGui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOV"
FOVCircle.Parent = ScreenGui
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = false

local UIStroke = Instance.new("UIStroke", FOVCircle)
UIStroke.Thickness = 2
UIStroke.Color = FOVColor

local UICorner = Instance.new("UICorner", FOVCircle)
UICorner.CornerRadius = UDim.new(1, 0)

-- Display de FPS e Ping
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Parent = ScreenGui
StatsLabel.Size = UDim2.new(0, 200, 0, 30)
StatsLabel.Position = UDim2.new(1, -210, 0, 10)
StatsLabel.BackgroundTransparency = 0.7
StatsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
StatsLabel.TextColor3 = Color3.new(1, 1, 1)
StatsLabel.TextStrokeTransparency = 0.5
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextSize = 16
StatsLabel.TextXAlignment = Enum.TextXAlignment.Right
StatsLabel.BorderSizePixel = 0

local UICornerStats = Instance.new("UICorner", StatsLabel)
UICornerStats.CornerRadius = UDim.new(0, 6)

local lastUpdate = tick()
RunService.RenderStepped:Connect(function()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    if tick() - lastUpdate >= 0.5 then
        local ping = tonumber(string.match(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString(), "%d+")) or 0
        StatsLabel.Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms"
        lastUpdate = tick()
    end
end)

-- Criar janela principal com a base.lua
local Window = Painel:CreateWindow({
    Name = "XIT PAINEL",
    LoadingTitle = "Carregando Script...",
    LoadingSubtitle = "Criador: Mlk Mau",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- Aba Principal
local MainTab = Window:CreateTab("Main", "rbxassetid://4483362458")
MainTab:CreateToggle({
    Name = "Ativar Aimbot",
    CurrentValue = AimbotEnabled,
    Flag = "AimbotToggle",
    Callback = function(value)
        AimbotEnabled = value
        FOVCircle.Visible = value
    end
})

MainTab:CreateToggle({
    Name = "Não grudar no time",
    CurrentValue = TeamCheck,
    Flag = "TeamCheckToggle",
    Callback = function(value)
        TeamCheck = value
    end
})

MainTab:CreateToggle({
    Name = "Checagem de Paredes",
    CurrentValue = WallCheck,
    Flag = "WallCheckToggle",
    Callback = function(value)
        WallCheck = value
    end
})

MainTab:CreateSlider({
    Name = "Tamanho FOV",
    Range = {50, 300},
    Increment = 5,
    Suffix = "px",
    CurrentValue = FOVRadius,
    Flag = "FOVSlider",
    Callback = function(value)
        FOVRadius = value
        FOVCircle.Size = UDim2.new(0, value * 2, 0, value * 2)
    end
})

-- Aba ESP
local ESPTab = Window:CreateTab("ESP", "rbxassetid://4483362458")
ESPTab:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = ESPEnabled,
    Flag = "ESPToggle",
    Callback = function(value)
        ESPEnabled = value
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local highlight = player.Character and player.Character:FindFirstChild("ESPHighlight")
                if highlight then
                    highlight.Enabled = value and (not ESPTeamCheck or player.Team ~= LocalPlayer.Team)
                end
            end
        end
    end
})

ESPTab:CreateToggle({
    Name = "Checagem de time",
    CurrentValue = ESPTeamCheck,
    Flag = "ESPTeamToggle",
    Callback = function(value)
        ESPTeamCheck = value
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local highlight = player.Character and player.Character:FindFirstChild("ESPHighlight")
                if highlight then
                    highlight.Enabled = ESPEnabled and (not value or player.Team ~= LocalPlayer.Team)
                end
            end
        end
    end
})

ESPTab:CreateColorPicker({
    Name = "Cor do ESP",
    Color = HighlightColor,
    Flag = "ESPColorPicker",
    Callback = function(value)
        HighlightColor = value
        for _, player in ipairs(Players:GetPlayers()) do
            local highlight = player.Character and player.Character:FindFirstChild("ESPHighlight")
            if highlight then
                highlight.OutlineColor = value
                highlight.FillColor = value
            end
        end
    end
})

-- Aba Visual
local VisualTab = Window:CreateTab("Visual", "rbxassetid://4483362458")
VisualTab:CreateToggle({
    Name = "FOV RGB",
    CurrentValue = FOVRainbow,
    Flag = "FOVRainbowToggle",
    Callback = function(value)
        FOVRainbow = value
    end
})

VisualTab:CreateColorPicker({
    Name = "Cor do FOV",
    Color = FOVColor,
    Flag = "FOVColorPicker",
    Callback = function(value)
        FOVColor = value
        if not FOVRainbow then
            UIStroke.Color = value
        end
    end
})

VisualTab:CreateToggle({
    Name = "Slow Motion PvP",
    CurrentValue = false,
    Flag = "SlowMotionToggle",
    Callback = function(enabled)
        if enabled then
            local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 0.25})
            tween:Play()
            workspace.Gravity = 100
        else
            local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 1})
            tween:Play()
            workspace.Gravity = 196.2
        end
    end
})

-- Aba Otimização
local OptimTab = Window:CreateTab("Otimização", "rbxassetid://4483362458")
OptimTab:CreateButton({
    Name = "Melhorar FPS",
    Callback = function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
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
    end
})

local FPSUnlockerEnabled = false
OptimTab:CreateToggle({
    Name = "FPS Desbloqueado",
    CurrentValue = FPSUnlockerEnabled,
    Flag = "FPSUnlockerToggle",
    Callback = function(value)
        FPSUnlockerEnabled = value
        if value then
            pcall(function() setfpscap(1000) end)
        else
            pcall(function() setfpscap(60) end)
        end
    end
})

OptimTab:CreateButton({
    Name = "Otimizar Ping",
    Callback = function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = false
            elseif obj:IsA("Explosion") then
                obj.Visible = false
            end
        end

        settings().Physics.AllowSleep = true
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Default

        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 100000

        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 1
    end
})

-- Sistema de Highlight (ESP)
local function ApplyHighlight(player)
    if not player.Character then return end
    local existing = player.Character:FindFirstChild("ESPHighlight")
    if existing then existing:Destroy() end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = HighlightColor
    highlight.FillColor = HighlightColor
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

-- Sistema de Aimbot
local function GetClosestTarget()
    local closest = nil
    local shortestDist = FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if TeamCheck and player.Team == LocalPlayer.Team then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude

                if dist <= shortestDist then
                    if WallCheck then
                        local origin = Camera.CFrame.Position
                        local direction = (player.Character.HumanoidRootPart.Position - origin).Unit * 1000
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

                        local result = workspace:Raycast(origin, direction, raycastParams)
                        if result and result.Instance:IsDescendantOf(player.Character) then
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

-- Loop principal
RunService.RenderStepped:Connect(function()
    if FOVRainbow then
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 1, 1)
        UIStroke.Color = color
    end

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

print("XIT PAINEL carregado com sucesso!")