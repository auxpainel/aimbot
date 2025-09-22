-- base.lua
-- Painel Custom Completo

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local Painel = {}
Painel.__index = Painel

-- Notificações
function Painel:Notify(title, description, duration)
    local ScreenGui = CoreGui:FindFirstChild("PainelNotify") or Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "PainelNotify"
    ScreenGui.ResetOnSpawn = false

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 250, 0, 80)
    Frame.Position = UDim2.new(1, -270, 1, -100)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 6)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -10, 0, 25)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255,255,255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Text = title
    Title.Parent = Frame

    local Desc = Title:Clone()
    Desc.Text = description
    Desc.TextSize = 14
    Desc.Position = UDim2.new(0, 5, 0, 30)
    Desc.Parent = Frame

    Frame.BackgroundTransparency = 1
    TweenService:Create(Frame, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()

    task.delay(duration or 3, function()
        TweenService:Create(Frame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        task.wait(0.4)
        Frame:Destroy()
    end)
end

-- Criar Janela
function Painel:CreateWindow(options)
    local Window = {}
    Window.__index = Window
    Window.Tabs = {}

    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "PainelUI"
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", MainFrame)
    UICorner.CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(35,35,35)
    Title.Text = options.Name or "Painel"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    local TabHolder = Instance.new("Frame", MainFrame)
    TabHolder.Size = UDim2.new(0, 120, 1, -30)
    TabHolder.Position = UDim2.new(0, 0, 0, 30)
    TabHolder.BackgroundColor3 = Color3.fromRGB(30,30,30)
    TabHolder.BorderSizePixel = 0

    local TabContent = Instance.new("Frame", MainFrame)
    TabContent.Size = UDim2.new(1, -120, 1, -30)
    TabContent.Position = UDim2.new(0, 120, 0, 30)
    TabContent.BackgroundColor3 = Color3.fromRGB(20,20,20)
    TabContent.BorderSizePixel = 0

    function Window:CreateTab(name)
        local Tab = {}
        Tab.__index = Tab

        local Button = Instance.new("TextButton", TabHolder)
        Button.Size = UDim2.new(1, 0, 0, 30)
        Button.Text = name
        Button.BackgroundColor3 = Color3.fromRGB(40,40,40)
        Button.TextColor3 = Color3.new(1,1,1)
        Button.Font = Enum.Font.SourceSans
        Button.TextSize = 16

        local Page = Instance.new("ScrollingFrame", TabContent)
        Page.Visible = false
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.CanvasSize = UDim2.new(0,0,0,0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 6

        function Tab:Show()
            for _, child in ipairs(TabContent:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    child.Visible = false
                end
            end
            Page.Visible = true
        end

        Button.MouseButton1Click:Connect(function()
            Tab:Show()
        end)

        -- Elementos
        function Tab:CreateToggle(text, callback)
            local Toggle = Instance.new("TextButton", Page)
            Toggle.Size = UDim2.new(1, -10, 0, 30)
            Toggle.Position = UDim2.new(0, 5, 0, #Page:GetChildren()*35)
            Toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
            Toggle.Text = "[OFF] " .. text
            Toggle.TextColor3 = Color3.new(1,1,1)
            Toggle.Font = Enum.Font.SourceSans
            Toggle.TextSize = 16

            local state = false
            Toggle.MouseButton1Click:Connect(function()
                state = not state
                Toggle.Text = (state and "[ON] " or "[OFF] ") .. text
                pcall(callback, state)
            end)
        end

        function Tab:CreateButton(text, callback)
            local Btn = Instance.new("TextButton", Page)
            Btn.Size = UDim2.new(1, -10, 0, 30)
            Btn.Position = UDim2.new(0, 5, 0, #Page:GetChildren()*35)
            Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            Btn.Text = text
            Btn.TextColor3 = Color3.new(1,1,1)
            Btn.Font = Enum.Font.SourceSans
            Btn.TextSize = 16
            Btn.MouseButton1Click:Connect(callback)
        end

        function Tab:CreateSlider(text, min, max, callback)
            local SliderFrame = Instance.new("Frame", Page)
            SliderFrame.Size = UDim2.new(1, -10, 0, 40)
            SliderFrame.Position = UDim2.new(0, 5, 0, #Page:GetChildren()*45)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(45,45,45)

            local Label = Instance.new("TextLabel", SliderFrame)
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.BackgroundTransparency = 1
            Label.Text = text .. ": " .. min
            Label.TextColor3 = Color3.new(1,1,1)
            Label.Font = Enum.Font.SourceSans
            Label.TextSize = 14

            local Slider = Instance.new("TextButton", SliderFrame)
            Slider.Size = UDim2.new(1, 0, 0, 20)
            Slider.Position = UDim2.new(0, 0, 0, 20)
            Slider.BackgroundColor3 = Color3.fromRGB(70,70,70)
            Slider.Text = ""

            local dragging = false
            local value = min
            local function update(input)
                local pos = math.clamp((input.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * pos)
                Label.Text = text .. ": " .. value
                pcall(callback, value)
            end

            Slider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            Slider.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
        end

        function Tab:CreateColorPicker(text, callback)
            local Btn = Instance.new("TextButton", Page)
            Btn.Size = UDim2.new(1, -10, 0, 30)
            Btn.Position = UDim2.new(0, 5, 0, #Page:GetChildren()*35)
            Btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
            Btn.Text = text .. " (abrir seletor)"
            Btn.TextColor3 = Color3.new(1,1,1)
            Btn.Font = Enum.Font.SourceSans
            Btn.TextSize = 16

            Btn.MouseButton1Click:Connect(function()
                local ColorPicker = Instance.new("Color3Value")
                ColorPicker.Changed:Connect(function(newColor)
                    pcall(callback, newColor)
                end)
                ColorPicker.Value = Color3.fromRGB(255,255,255) -- valor inicial
                callback(ColorPicker.Value)
            end)
        end

        Tab:Show()
        return Tab
    end

    return Window
end

return Painel