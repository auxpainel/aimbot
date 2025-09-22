-- base.lua
local Painel = {}

-- Serviços
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Criar Janela Principal
function Painel:CreateWindow(config)
    local Window = Instance.new("ScreenGui")
    Window.Name = "PainelUI"
    Window.Parent = game:GetService("CoreGui")
    Window.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = Window
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Size = UDim2.new(0, 500, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
    MainFrame.Active = true
    MainFrame.Draggable = true -- arrastável

    -- Barra Superior
    local TopBar = Instance.new("Frame")
    TopBar.Parent = MainFrame
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    TopBar.Size = UDim2.new(1, 0, 0, 30)

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.Text = config.Name or "Painel"
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    -- Botão Minimizar
    local Minimize = Instance.new("TextButton")
    Minimize.Parent = TopBar
    Minimize.Size = UDim2.new(0, 30, 1, 0)
    Minimize.Position = UDim2.new(1, -35, 0, 0)
    Minimize.Text = "_"
    Minimize.TextSize = 18
    Minimize.TextColor3 = Color3.new(1,1,1)
    Minimize.BackgroundTransparency = 1

    local Body = Instance.new("Frame")
    Body.Parent = MainFrame
    Body.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Body.Position = UDim2.new(0, 0, 0, 30)
    Body.Size = UDim2.new(1, 0, 1, -30)

    local TabButtons = Instance.new("Frame")
    TabButtons.Parent = Body
    TabButtons.Size = UDim2.new(0, 120, 1, 0)
    TabButtons.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

    local Pages = Instance.new("Frame")
    Pages.Parent = Body
    Pages.Size = UDim2.new(1, -120, 1, 0)
    Pages.Position = UDim2.new(0, 120, 0, 0)
    Pages.BackgroundTransparency = 1

    -- Minimizar lógica
    local minimized = false
    Minimize.MouseButton1Click:Connect(function()
        minimized = not minimized
        Pages.Visible = not minimized
        TabButtons.Visible = not minimized
    end)

    -- Criar Tabs
    function Painel:CreateTab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Parent = TabButtons
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.Text = name
        TabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TabButton.TextColor3 = Color3.new(1,1,1)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 14

        local Page = Instance.new("ScrollingFrame")
        Page.Parent = Pages
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0,0,0,0)
        Page.Visible = false
        Page.ScrollBarThickness = 4

        local Layout = Instance.new("UIListLayout")
        Layout.Parent = Page
        Layout.Padding = UDim.new(0,5)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder

        TabButton.MouseButton1Click:Connect(function()
            for _, pg in ipairs(Pages:GetChildren()) do
                if pg:IsA("ScrollingFrame") then
                    pg.Visible = false
                end
            end
            for _, btn in ipairs(TabButtons:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                end
            end
            Page.Visible = true
            TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)

        if #Pages:GetChildren() == 1 then
            Page.Visible = true
            TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end

        local Elements = {}

        -- Toggle
        function Elements:CreateToggle(text, callback)
            local Button = Instance.new("TextButton")
            Button.Parent = Page
            Button.Size = UDim2.new(1, -10, 0, 30)
            Button.Text = "[ ] "..text
            Button.BackgroundColor3 = Color3.fromRGB(40,40,40)
            Button.TextColor3 = Color3.new(1,1,1)
            Button.Font = Enum.Font.Gotham
            Button.TextSize = 14

            local state = false
            Button.MouseButton1Click:Connect(function()
                state = not state
                Button.Text = (state and "[✔] " or "[ ] ")..text
                callback(state)
            end)
        end

        -- Button
        function Elements:CreateButton(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Parent = Page
            Btn.Size = UDim2.new(1, -10, 0, 30)
            Btn.Text = text
            Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            Btn.TextColor3 = Color3.new(1,1,1)
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 14
            Btn.MouseButton1Click:Connect(callback)
        end

        -- Slider
        function Elements:CreateSlider(text, min, max, callback)
            local Frame = Instance.new("Frame")
            Frame.Parent = Page
            Frame.Size = UDim2.new(1, -10, 0, 40)
            Frame.BackgroundColor3 = Color3.fromRGB(40,40,40)

            local Label = Instance.new("TextLabel")
            Label.Parent = Frame
            Label.Size = UDim2.new(1, 0, 0, 20)
            Label.Text = text..": "..min
            Label.TextColor3 = Color3.new(1,1,1)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 14
            Label.BackgroundTransparency = 1

            local Slider = Instance.new("TextButton")
            Slider.Parent = Frame
            Slider.Size = UDim2.new(1, -10, 0, 10)
            Slider.Position = UDim2.new(0, 5, 0, 25)
            Slider.BackgroundColor3 = Color3.fromRGB(80,80,80)
            Slider.Text = ""

            local Fill = Instance.new("Frame")
            Fill.Parent = Slider
            Fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            Fill.Size = UDim2.new(0, 0, 1, 0)

            local dragging = false
            Slider.MouseButton1Down:Connect(function()
                dragging = true
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            RunService = game:GetService("RunService")
            RunService.RenderStepped:Connect(function()
                if dragging then
                    local pos = math.clamp((UserInputService:GetMouseLocation().X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
                    Fill.Size = UDim2.new(pos, 0, 1, 0)
                    local value = math.floor(min + (max-min) * pos)
                    Label.Text = text..": "..value
                    callback(value)
                end
            end)
        end

        -- ColorPicker
        function Elements:CreateColorPicker(text, default, callback)
            local Btn = Instance.new("TextButton")
            Btn.Parent = Page
            Btn.Size = UDim2.new(1, -10, 0, 30)
            Btn.Text = text
            Btn.BackgroundColor3 = default
            Btn.TextColor3 = Color3.new(1,1,1)
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 14

            Btn.MouseButton1Click:Connect(function()
                local color = Color3.fromHSV(math.random(), 1, 1)
                Btn.BackgroundColor3 = color
                callback(color)
            end)
        end

        return Elements
    end

    -- Notify
    function Painel:Notify(title, text, time)
        local NotifyFrame = Instance.new("Frame")
        NotifyFrame.Parent = Window
        NotifyFrame.Size = UDim2.new(0, 200, 0, 60)
        NotifyFrame.Position = UDim2.new(1, -210, 1, -70)
        NotifyFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)

        local Title = Instance.new("TextLabel")
        Title.Parent = NotifyFrame
        Title.Size = UDim2.new(1, 0, 0, 20)
        Title.Text = title
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 14
        Title.TextColor3 = Color3.new(1,1,1)
        Title.BackgroundTransparency = 1

        local Msg = Instance.new("TextLabel")
        Msg.Parent = NotifyFrame
        Msg.Size = UDim2.new(1, -10, 0, 40)
        Msg.Position = UDim2.new(0, 5, 0, 20)
        Msg.Text = text
        Msg.TextWrapped = true
        Msg.Font = Enum.Font.Gotham
        Msg.TextSize = 12
        Msg.TextColor3 = Color3.new(1,1,1)
        Msg.BackgroundTransparency = 1

        TweenService:Create(NotifyFrame, TweenInfo.new(0.5), {Position = UDim2.new(1, -210, 1, -140)}):Play()
        task.delay(time or 3, function()
            TweenService:Create(NotifyFrame, TweenInfo.new(0.5), {Position = UDim2.new(1, 0, 1, 0)}):Play()
            task.delay(0.5, function()
                NotifyFrame:Destroy()
            end)
        end)
    end

    return Painel
end

return Painel