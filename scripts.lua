local Painel = loadstring(game:HttpGet('https://raw.githubusercontent.com/auxpainel/aimbot/main/base.lua'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Config
local AimbotEnabled = false
local TeamCheck = true
local WallCheck = true
local FOVRadius = 100
local ESPEnabled = false
local ESPTeamCheck = true
local HighlightColor = Color3.fromRGB(255, 0, 0)
local FOVRainbow = false
local FOVColor = Color3.fromRGB(0, 255, 0)

-- FPS Unlocker
local function setfpscap(value)
    if setfpscap then
        setfpscap(value)
    else
        warn("FPS Unlocker não está disponível")
    end
end

-- FOV Circle
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false

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

-- FPS y Ping Display
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Parent = ScreenGui
StatsLabel.Size = UDim2.new(0, 200, 0, 50)
StatsLabel.Position = UDim2.new(1, -210, 0, 10)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.new(1, 1, 1)
StatsLabel.TextStrokeTransparency = 0
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextSize = 18
StatsLabel.TextXAlignment = Enum.TextXAlignment.Right

local lastUpdate = tick()
RunService.RenderStepped:Connect(function()
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    if tick() - lastUpdate >= 0.3 then
        local ping = tonumber(string.match(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString(), "%d+")) or 0
        StatsLabel.Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms"
        lastUpdate = tick()
    end
end)

-- Criar janela principal
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
local Tab = Window:CreateTab("Main")
Tab:CreateToggle({
    Name = "Ativar Aimbot",
    CurrentValue = false,
    Callback = function(value)
        AimbotEnabled = value
        FOVCircle.Visible = value
    end
})
Tab:CreateToggle({
    Name = "Não grudar no time",
    CurrentValue = true,
    Callback = function(value)
        TeamCheck = value
    end
})
Tab:CreateToggle({
    Name = "Checagem de Paredes",
    CurrentValue = true,
    Callback = function(value)
        WallCheck = value
    end
})
Tab:CreateSlider({
    Name = "Tamanho FOV",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 100,
    Callback = function(value)
        FOVRadius = value
        FOVCircle.Size = UDim2.new(0, value * 2, 0, value * 2)
    end
})

-- ESP Tab
local ESPTab = Window:CreateTab("ESP")
ESPTab:CreateToggle({
    Name = "Ativar personagem",
    CurrentValue = false,
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
    Name = "Checagem de luzes no time",
    CurrentValue = true,
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

-- Visual Tab
local VisualTab = Window:CreateTab("Visual")
VisualTab:CreateToggle({
    Name = "FOV RGB",
    CurrentValue = false,
    Callback = function(value)
        FOVRainbow = value
    end
})

VisualTab:CreateToggle({
    Name = "Slow Motion PvP",
    CurrentValue = false,
    Callback = function(enabled)
        if enabled then
            local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 0.25})
            tween:Play()
            game:GetService("RunService"):Set3dRenderingEnabled(true)
            workspace.Gravity = 100
        else
            local tween = TweenService:Create(game, TweenInfo.new(0.5), {ClockTime = 1})
            tween:Play()
            workspace.Gravity = 196.2
        end
    end
})

-- Função para aplicar destaque ESP
local function ApplyHighlight(player)
    if not player.Character then return end
    local existing = player.Character:FindFirstChild("ESPHighlight")
    if existing then existing:Destroy() end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = HighlightColor
    highlight.FillColor = HighlightColor
    highlight.Enabled = ESPEnabled and (not ESPTeamCheck or player.Team ~= LocalPlayer.Team)
    highlight.Parent = player.Character
end

-- Configurar destaque para jogadores
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

-- Função para encontrar o alvo mais próximo
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
    else
        UIStroke.Color = FOVColor
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

-- Otimização Tab
local OptimTab = Window:CreateTab("Optimização")
OptimTab:CreateButton({
    Name = "Melhorar fps",
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
    Name = "FPS desbloqueado",
    CurrentValue = false,
    Callback = function(value)
        FPSUnlockerEnabled = value
        if value then
            setfpscap(1000)
        else
            setfpscap(60)
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

        for _, gui in ipairs(game.CoreGui:GetDescendants()) do
            if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
                gui.ImageTransparency = 0.2
            end
        end
    end
})

print("Script XIT PAINEL carregado com sucesso!")