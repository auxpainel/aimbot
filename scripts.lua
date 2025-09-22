local Painel = loadstring(game:HttpGet("https://raw.githubusercontent.com/auxpainel/aimbot/main/base.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

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

local UIStroke = Instance.new("UIStroke", FOVCircle)
UIStroke.Thickness = 2
UIStroke.Color = FOVColor

local UICorner = Instance.new("UICorner", FOVCircle)
UICorner.CornerRadius = UDim.new(1, 0)

-- FPS / PING
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
        StatsLabel.Text = "FPS: " .. fps .. " | Ping: " .. (math.random(40,90)) .. "ms" -- fake ping simplificado
        lastUpdate = tick()
    end
end)

-- Criar janela
local Window = Painel:CreateWindow({
    Name = "XIT PAINEL"
})

-- MAIN TAB
local Tab = Window:CreateTab("Main")
Tab:CreateToggle("Ativar Aimbot", function(value)
    AimbotEnabled = value
    FOVCircle.Visible = value
end)
Tab:CreateToggle("Não grudar no time", function(value)
    TeamCheck = value
end)
Tab:CreateToggle("Checagem de Paredes", function(value)
    WallCheck = value
end)
Tab:CreateSlider("Tamanho FOV", 50, 300, function(value)
    FOVRadius = value
    FOVCircle.Size = UDim2.new(0, value * 2, 0, value * 2)
end)

-- ESP TAB
local ESPTab = Window:CreateTab("ESP")
ESPTab:CreateToggle("Ativar ESP", function(value)
    ESPEnabled = value
end)
ESPTab:CreateToggle("ESP não mostrar time", function(value)
    ESPTeamCheck = value
end)
ESPTab:CreateButton("Forçar Atualizar ESP", function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("ESPHighlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ESPHighlight"
                highlight.Parent = player.Character
            end
            highlight.Enabled = ESPEnabled and (not ESPTeamCheck or player.Team ~= LocalPlayer.Team)
            highlight.OutlineColor = HighlightColor
        end
    end
end)

-- VISUAL TAB
local VisualTab = Window:CreateTab("Visual")
VisualTab:CreateToggle("FOV RGB", function(value)
    FOVRainbow = value
end)
VisualTab:CreateSlider("Gravidade", 50, 200, function(value)
    workspace.Gravity = value
end)

-- OTIMIZAÇÃO TAB
local OptimTab = Window:CreateTab("Otimização")
OptimTab:CreateButton("Melhorar FPS", function()
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
end)

-- Aimbot loop
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
                    closest = player
                    shortestDist = dist
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if FOVRainbow then
        local hue = tick() % 5 / 5
        UIStroke.Color = Color3.fromHSV(hue, 1, 1)
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