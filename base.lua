-- base.lua
-- Menu flutuante independente (sem Rayfield/Orion externo)

-- Criador da GUI principal
local Library = {}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Cria ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeuPainel"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Função: Criar Janela
function Library:CreateWindow(settings)
    local Window = {}

    -- Janela principal
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 500, 0, 300)
    Frame.Position = UDim2.new(0.5, -250, 0.5, -150)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 8)

    -- Título
    local Title = Instance.new("TextLabel")
    Title.Text = settings.Name or "Painel"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Frame

    local UICorner2 = Instance.new("UICorner", Title)
    UICorner2.CornerRadius = UDim.new(0, 8)

    -- Container de abas
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 120, 1, -40)
    TabContainer.Position = UDim2.new(0, 0, 0, 40)
    TabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = Frame

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -120, 1, -40)
    ContentContainer.Position = UDim2.new(0, 120, 0, 40)
    ContentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ContentContainer.BorderSizePixel = 0
    ContentContainer.Parent = Frame

    local Tabs = {}

    -- Criar Abas
    function Window:CreateTab(name)
        local Tab = {}
        local Button = Instance.new("TextButton")
        Button.Text = name
        Button.Size = UDim2.new(1, 0, 0, 40)
        Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Button.TextColor3 = Color3.new(1, 1, 1)
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 14
        Button.Parent = TabContainer

        local TabFrame = Instance.new("Frame")
        TabFrame.Size = UDim2.new(1, 0, 1, 0)
        TabFrame.BackgroundTransparency = 1
        TabFrame.Visible = false
        TabFrame.Parent = ContentContainer

        Tabs[name] = TabFrame

        Button.MouseButton1Click:Connect(function()
            for _, frame in pairs(Tabs) do
                frame.Visible = false
            end
            TabFrame.Visible = true
        end)

        -- Funções da aba
        function Tab:CreateToggle(text, callback)
            local Toggle = Instance.new("TextButton")
            Toggle.Size = UDim2.new(0, 200, 0, 30)
            Toggle.Position = UDim2.new(0, 10, 0, #TabFrame:GetChildren() * 35)
            Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Toggle.TextColor3 = Color3.new(1, 1, 1)
            Toggle.Text = "[ OFF ] " .. text
            Toggle.Parent = TabFrame

            local state = false
            Toggle.MouseButton1Click:Connect(function()
                state = not state
                Toggle.Text = (state and "[ ON ] " or "[ OFF ] ") .. text
                if callback then callback(state) end
            end)
        end

        function Tab:CreateButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(0, 200, 0, 30)
            Button.Position = UDim2.new(0, 10, 0, #TabFrame:GetChildren() * 35)
            Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            Button.TextColor3 = Color3.new(1, 1, 1)
            Button.Text = text
            Button.Parent = TabFrame

            Button.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        function Tab:CreateSlider(text, min, max, callback)
            local Label = Instance.new("TextLabel")
            Label.Text = text .. ": " .. min
            Label.Size = UDim2.new(0, 200, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, #TabFrame:GetChildren() * 35)
            Label.TextColor3 = Color3.new(1, 1, 1)
            Label.BackgroundTransparency = 1
            Label.Parent = TabFrame

            local Slider = Instance.new("TextButton")
            Slider.Size = UDim2.new(0, 200, 0, 10)
            Slider.Position = Label.Position + UDim2.new(0, 0, 0, 20)
            Slider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            Slider.Text = ""
            Slider.Parent = TabFrame

            local value = min
            Slider.MouseButton1Down:Connect(function(x, y)
                local move
                move = game:GetService("UserInputService").InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        local percent = math.clamp((input.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
                        value = math.floor(min + (max - min) * percent)
                        Label.Text = text .. ": " .. value
                        if callback then callback(value) end
                    end
                end)
                game:GetService("UserInputService").InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        move:Disconnect()
                    end
                end)
            end)
        end

        return Tab
    end

    return Window
end

return Library